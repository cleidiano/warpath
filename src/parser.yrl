Nonterminals expression filter_exp filter filter_target number indexes array_indexes full_scan.

Terminals  
root property current_object comparator int float
dot open_bracket close_bracket question_mark 
open_parens close_parens wildcard minus comma scan.

Rootsymbol expression.

expression     -> root                                                    :     [unwrap('$1')].
expression     -> expression dot property                                 :     '$1' ++ [{unwrap_token('$2'), unwrap('$3')}].
expression     -> expression filter_exp                                   :     '$1' ++ ['$2'].
expression     -> expression dot wildcard                                 :     '$1'.  
expression     -> expression open_bracket wildcard close_bracket          :     '$1' ++ [{array_wildcard, unwrap_value('$3')}].  
expression     -> expression array_indexes                                :     '$1' ++ ['$2'].
expression     -> expression full_scan                                    :     '$1' ++ ['$2'].

array_indexes  -> open_bracket int close_bracket                          :     {array_indexes, [index_access_exp('$2')]}.
array_indexes  -> open_bracket indexes close_bracket                      :     {array_indexes, '$2'}.

full_scan      -> scan property                                           :     {scan, unwrap('$2')}.
full_scan      -> scan wildcard                                           :     {scan, unwrap('$2')}.

filter_exp     -> open_bracket filter close_bracket                       :     {filter, '$2'}.
filter         -> question_mark open_parens filter_target close_parens    :     '$3'.
filter_target  -> current_object dot property comparator number           :     {unwrap('$3'), unwrap_value('$4'), '$5'}.
filter_target  -> current_object dot property                             :     contains_exp('$3').

indexes        -> int comma int                                           :     [index_access_exp('$1'), index_access_exp('$3')].
indexes        -> indexes comma int                                       :     '$1' ++ [index_access_exp('$3')].  

number         -> int                                                     :     unwrap_value('$1').
number         -> float                                                   :     unwrap_value('$1').
number         -> minus int                                               :     unwrap_value('$2') * -1.
number         -> minus float                                             :     unwrap_value('$2') * -1.

Erlang code.

unwrap({T, _, V})       -> {T, V}.
unwrap_value({_, _, V}) -> V.
unwrap_token({T, _ ,_}) -> T.

index_access_exp({_, _, V}) -> {index_access, V}.
contains_exp({T, _, V}) -> {contains, {T, V}}.
