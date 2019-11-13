Nonterminals expression 
filter_exp filter
indexes array_indexes array_wildcard 
scan_rewrite scan_rwt_rhs
number boolean boolean_exp predicate predic_term
.

Terminals  
root property current_object comparator int float wildcard scan 
or_op and_op not_op
true false
'.' '[' ']' '?' '(' ')' '-' ','
.

Rootsymbol expression.

Left        100 or_op.       
Left        150 and_op.      
Left        200 comparator.     
Nonassoc    250 not_op.

%% Four shift/reduce conflicts coming from scan_rewrite
Expect 4.

expression     -> root                                      :   [extract('$1')].
expression     -> expression '.' property                   :   '$1' ++ [{dot, extract('$3')}].
expression     -> expression '.' wildcard                   :   '$1'.  
expression     -> expression '.' array_indexes              :   '$1' ++ ['$3'].
expression     -> expression filter_exp                     :   '$1' ++ ['$2'].
expression     -> expression array_wildcard                 :   '$1' ++ ['$2'].  
expression     -> expression array_indexes                  :   '$1' ++ ['$2'].

%Scan expression
expression     -> expression scan property                  :   '$1' ++ [build_scan(extract('$3'))].
expression     -> expression scan array_indexes             :   '$1' ++ [build_scan('$3')].
expression     -> expression scan array_wildcard            :   '$1' ++ [build_scan({wildcard, '*'})].
expression     -> expression scan filter_exp                :   '$1' ++ [build_scan('$3')].
expression     -> expression scan wildcard                  :   '$1' ++ [build_scan(extract('$3'))].
expression     -> expression scan scan_rewrite              :   '$1' ++ [build_scan('$3')].

scan_rewrite   -> wildcard filter_exp                       :   {{wildcard, '*'}, '$2'}.               
scan_rewrite   -> wildcard scan_rwt_rhs                     :   '$2'.
scan_rewrite   -> wildcard array_indexes                    :   '$2'.
scan_rewrite   -> array_wildcard filter_exp                 :   {{wildcard, '*'}, '$2'}.               
scan_rewrite   -> array_wildcard array_indexes              :   '$2'.
scan_rewrite   -> array_wildcard scan_rwt_rhs               :   '$2'.
                                                                          
scan_rwt_rhs   -> '.' property                              :   extract('$2').
scan_rwt_rhs   -> '.' array_indexes                         :   '$2'.
scan_rwt_rhs   -> '.' filter_exp                            :   {{wildcard, '*'}, '$2'}.

%Array access expression
array_indexes  -> '[' indexes ']'                           :   {array_indexes, '$2'}.
array_wildcard -> '[' wildcard ']'                          :   {array_wildcard, extract_value('$2')}.
indexes        -> int                                       :   [index_access('$1')].
indexes        -> indexes ',' int                           :   '$1' ++ [index_access('$3')].  

%Filter expression
filter_exp     -> '[' filter ']'                            :   {filter, '$2'}.
filter         -> '?' '(' boolean_exp ')'                   :   '$3'.

boolean_exp    -> boolean                                   :   '$1'.
boolean_exp    -> predicate                                 :   '$1'.     
boolean_exp    -> current_object '.' property               :   {contains, extract('$3')}.
boolean_exp    -> boolean_exp or_op boolean_exp             :   {'or',  ['$1', '$3']}.     
boolean_exp    -> boolean_exp and_op boolean_exp            :   {'and', ['$1', '$3']}.     
boolean_exp    -> not_op boolean_exp                        :   {'not', '$2'}.
boolean_exp    -> '(' boolean_exp ')'                       :   '$2'.     
        
predicate      -> predic_term comparator predic_term        :   {extract_value('$2'), ['$1', '$3']}.                    
predicate      -> property '(' predic_term ')'              :   function_call('$1', '$3').

predic_term    -> number                                    :   '$1'.
predic_term    -> boolean                                   :   '$1'.
predic_term    -> current_object '.' property               :   extract('$3').
predic_term    -> current_object                            :   current_object.
predic_term	   -> property									:	extract_value('$1').

boolean        -> true                                      :   true.
boolean        -> false                                     :   false.

number         -> int                                       :   extract_value('$1').
number         -> float                                     :   extract_value('$1').
number         -> '-' number                                :   -extract_value('$2').


Erlang code.

extract({T, _, V})       -> {T, V}.

extract_value({_, _, V}) -> V.

index_access({_, _, V}) -> {index_access, V}.

build_scan(Exp) -> {scan, Exp}.

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
