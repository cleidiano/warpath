Nonterminals expression filter_exp boolean_exp predicate
number boolean item element elements indexes array_indexes
.

Terminals  
root word quoted_word current_node int float wildcard scan
true false or_op and_op not_op in_op comparator
'.' '[' ']' '?' '(' ')' '-' ','
.

Rootsymbol expression.

Left        100 or_op.       
Left        150 and_op.      
Left        200 comparator.     
Nonassoc    250 not_op.
Left        300 '.'.
Left        350 scan.

expression      -> root                                         :   [extract('$1')].
expression      -> expression '.' word                          :   '$1' ++ [{dot, property('$3')}].
expression      -> expression '.' wildcard                      :   '$1' ++ [extract('$3')].
expression      -> expression '.' array_indexes                 :   '$1' ++ ['$3'].
expression      -> expression '.' filter_exp                    :   '$1' ++ ['$3'].
expression      -> expression '.' '[' quoted_word ']'           :   '$1' ++ [{dot, property('$4')}].
expression      -> expression '.' '[' wildcard ']'              :   '$1' ++ [extract('$4')].

expression      -> expression '[' quoted_word ']'               :   '$1' ++ [{dot, property('$3')}].
expression      -> expression '[' wildcard ']'                  :   '$1' ++ [extract('$3')].
expression      -> expression filter_exp                        :   '$1' ++ ['$2'].
expression      -> expression array_indexes                     :   '$1' ++ ['$2'].

expression      -> expression scan word                         :   '$1' ++ [build_scan(property('$3'))].
expression      -> expression scan '[' quoted_word ']'          :   '$1' ++ [build_scan(property('$4'))].
expression      -> expression scan array_indexes                :   '$1' ++ [build_scan('$3')].
expression      -> expression scan filter_exp                   :   '$1' ++ [build_scan('$3')].
expression      -> expression scan wildcard                     :   '$1' ++ [build_scan(extract('$3'))].
expression      -> expression scan '[' wildcard ']'             :   '$1' ++ [build_scan(extract('$4'))].


%%Array
array_indexes	-> '[' indexes ']'                              :   {array_indexes, '$2'}.
indexes         -> int                                          :   [index_access('$1')].
indexes	        -> indexes ',' int                              :   '$1' ++ [index_access('$3')].

%%Filter
filter_exp      -> '[' '?' '(' boolean_exp ')' ']'              :   {filter, '$4'}.

boolean_exp     -> boolean                                      :   '$1'.
boolean_exp     -> predicate                                    :   '$1'.     
boolean_exp     -> current_node '.' word                        :   {'has_property?', property('$3')}.
boolean_exp     -> boolean_exp or_op boolean_exp                :   {'or',  ['$1', '$3']}.     
boolean_exp     -> boolean_exp and_op boolean_exp               :   {'and', ['$1', '$3']}.     
boolean_exp     -> not_op boolean_exp                           :   {'not', '$2'}.
boolean_exp     -> '(' boolean_exp ')'                          :   '$2'.     
        
predicate       -> item comparator item                         :   {extract_value('$2'), ['$1', '$3']}.                    
predicate       -> word '(' item ')'                            :   function_call('$1', '$3').
predicate       -> item in_op elements                          :   {in, ['$1', '$3']}.

item            -> number                                       :   '$1'.
item            -> boolean                                      :   '$1'.
item            -> current_node '.' word                        :   property('$3').
item            -> current_node                                 :   current_node.
item            -> word                                         :   extract_value('$1').
item            -> quoted_word                                  :   extract_value('$1').

elements        -> '[' element ']'                              : '$2'.
element         -> item                                         : ['$1'].
element         -> element ',' item                             : '$1' ++ ['$3']. 

boolean         -> true                                         :   true.
boolean         -> false                                        :   false.

number          -> int                                          :   extract_value('$1').
number          -> float                                        :   extract_value('$1').
number          -> '-' number                                   :   -extract_value('$2').

Erlang code.

build_scan(Exp) -> {scan, Exp}.

extract({Token, _, Value}) -> {Token, Value}.

extract_value({_, _, Value}) -> Value.

function_call({_, Line, FunctionName}, Arguments) ->
    Function = case FunctionName of
		 <<"is_atom">> -> is_atom;
		 <<"is_binary">> -> is_binary;
		 <<"is_boolean">> -> is_boolean;
		 <<"is_float">> -> is_float;
		 <<"is_integer">> -> is_integer;
		 <<"is_list">> -> is_list;
		 <<"is_map">> -> is_map;
		 <<"is_nil">> -> is_nil;
		 <<"is_number">> -> is_number;
		 <<"is_tuple">> -> is_tuple;
		 UnknownFunction ->
		     return_error(Line, ["'", UnknownFunction, "'"])
	       end,
    {Function, Arguments}.

index_access({_, _, Value}) -> {index_access, Value}.

property({_, _, Value}) -> {property, Value}.
