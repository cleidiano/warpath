Nonterminals expression index_access filter_exp filter filter_target number.

Terminals  
root property current_object comparator int float
dot open_bracket close_bracket question_mark 
open_parens close_parens wildcard minus.

Rootsymbol expression.

expression     -> root                                                    :   [unwrap('$1')].
expression     -> expression dot property                                 :   '$1' ++ [ {unwrap_token('$2'), unwrap('$3') } ].
expression     -> expression index_access                                 :   '$1' ++ ['$2'].
expression     -> expression filter_exp                                   :   '$1' ++ ['$2'].
expression     -> expression dot wildcard                                 :   '$1'.  
expression     -> expression open_bracket wildcard close_bracket          :   '$1' ++ [{array_wildcard, unwrap_value('$3')}].  


index_access   -> open_bracket int close_bracket                          :   {index_access, unwrap_value('$2')}.
filter_exp     -> open_bracket filter close_bracket                       :   {filter, '$2'}.  %{filter, @.age > 18}
filter         -> question_mark open_parens filter_target close_parens    :   '$3'. % @.age > 18
filter_target  -> current_object dot property comparator number           :   {unwrap('$3'), unwrap_value('$4'), '$5'}. %@.age > 18

number         -> int                                                     : unwrap_value('$1').
number         -> float                                                   : unwrap_value('$1').
number         -> minus int                                               : -1 * unwrap_value('$2').
number         -> minus float                                             : -1 * unwrap_value('$2').

Erlang code.

unwrap({T, _, V})       -> {T, V}.
unwrap_value({_, _, V}) -> V.
unwrap_token({T, _ ,_}) -> T.
