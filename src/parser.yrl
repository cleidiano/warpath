Nonterminals expression filter_exp indexes array_indexes
number boolean boolean_exp predicate item list elements
.

Terminals  
root word current_object comparator int float wildcard scan
or_op and_op not_op in_op
true false
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
expression      -> expression '.' '[' word  ']'                 :   '$1' ++ [{dot, property('$4')}].
expression      -> expression '[' word ']'                      :   '$1' ++ [{dot, property('$3')}].

expression      -> expression '.' wildcard                      :   '$1' ++ [extract('$3')].
expression      -> expression '.' '[' wildcard ']'              :   '$1' ++ [extract('$4')].
expression      -> expression '[' wildcard ']'                  :   '$1' ++ [extract('$3')].

expression      -> expression '.' array_indexes                 :   '$1' ++ ['$3'].
expression      -> expression '.' filter_exp                    :   '$1' ++ ['$3'].

expression      -> expression scan word                         :   '$1' ++ [build_scan(property('$3'))].
expression      -> expression scan array_indexes                :   '$1' ++ [build_scan('$3')].
expression      -> expression scan filter_exp                   :   '$1' ++ [build_scan('$3')].
expression      -> expression scan wildcard                     :   '$1' ++ [build_scan(extract('$3'))].
expression      -> expression scan '[' wildcard ']'             :   '$1' ++ [build_scan(extract('$4'))].
expression      -> expression filter_exp                        :   '$1' ++ ['$2'].
expression      -> expression array_indexes                     :   '$1' ++ ['$2'].


%%Array
array_indexes	-> '[' indexes ']'                              :   {array_indexes, '$2'}.
indexes         -> int                                          :   [index_access('$1')].
indexes	        -> indexes ',' int                              :   '$1' ++ [index_access('$3')].

%%Filter
filter_exp      -> '[' '?' '(' boolean_exp ')' ']'              :   {filter, '$4'}.

boolean_exp     -> boolean                                      :   '$1'.
boolean_exp     -> predicate                                    :   '$1'.     
boolean_exp     -> current_object '.' word                      :   {contains, property('$3')}.
boolean_exp     -> boolean_exp or_op boolean_exp                :   {'or',  ['$1', '$3']}.     
boolean_exp     -> boolean_exp and_op boolean_exp               :   {'and', ['$1', '$3']}.     
boolean_exp     -> not_op boolean_exp                           :   {'not', '$2'}.
boolean_exp     -> '(' boolean_exp ')'                          :   '$2'.     
        
predicate       -> item comparator item                         :   {extract_value('$2'), ['$1', '$3']}.                    
predicate       -> word '(' item ')'                            :   function_call('$1', '$3').
predicate       -> item in_op list                              :   {in, ['$1', '$3']}.

item            -> number                                       :   '$1'.
item            -> boolean                                      :   '$1'.
item            -> current_object '.' word                      :   property('$3').
item            -> current_object                               :   current_object.
item            -> word                                         :   extract_value('$1').

list            -> '[' elements ']'                             : '$2'.
elements        -> item                                         : ['$1'].
elements        -> elements ',' item                            : '$1' ++ ['$3']. 

boolean         -> true                                         :   true.
boolean         -> false                                        :   false.

number          -> int                                          :   extract_value('$1').
number          -> float                                        :   extract_value('$1').
number          -> '-' number                                   :   -extract_value('$2').

Erlang code.

build_scan(Exp) -> {scan, Exp}.

extract({Token, _Line, Value}) -> {Token, Value}.

extract_value({_Token, _Line, Value}) -> Value.

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

index_access({_Token, _Line, Value}) -> {index_access, Value}.

property({_Token, _Line, Value}) -> {property, Value}.
