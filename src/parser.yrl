Nonterminals expression filter_exp boolean_exp predicate
number item element elements indexes array_indexes array_slice slice_parts
integer_arg union union_prop property wildcard
.

Terminals  
'$' word quoted_word int float negative_float negative_int '..'
boolean or_op and_op not_op in_op comparator
'.' '[' ']' '?' '(' ')' ',' ':' '*' '@'
.

Rootsymbol expression.

Left        100 or_op.       
Left        150 and_op.      
Left        200 comparator.     
Nonassoc    250 not_op.
Left        300 '.'.
Left        350 '..'.

expression      -> '$'                                          :   [{root, <<"$">>}].
expression      -> expression '.' property                      :   '$1' ++ [{dot, property('$3')}].
expression      -> expression '.' wildcard                      :   '$1' ++ ['$3'].
expression      -> expression '.' array_indexes                 :   '$1' ++ ['$3'].
expression      -> expression '.' filter_exp                    :   '$1' ++ ['$3'].
expression      -> expression '.' union                         :   '$1' ++ resolv_operation_for('$3').
expression      -> expression '.' '[' wildcard ']'              :   '$1' ++ ['$4'].

expression      -> expression union                             :   '$1' ++ resolv_operation_for('$2').
expression      -> expression '[' wildcard ']'                  :   '$1' ++ ['$3'].
expression      -> expression filter_exp                        :   '$1' ++ ['$2'].
expression      -> expression array_indexes                     :   '$1' ++ ['$2'].
expression      -> expression array_slice                       :   '$1' ++ ['$2'].

expression      -> expression '..' property                     :   '$1' ++ [build_scan(property('$3'))].
expression      -> expression '..' '[' quoted_word ']'          :   '$1' ++ [build_scan(property('$4'))].
expression      -> expression '..' array_indexes                :   '$1' ++ [build_scan('$3')].
expression      -> expression '..' filter_exp                   :   '$1' ++ [build_scan('$3')].
expression      -> expression '..' wildcard                     :   '$1' ++ [build_scan('$3')].
expression      -> expression '..' '[' wildcard ']'             :   '$1' ++ [build_scan('$4')].

%%Key collector
union           -> '[' union_prop ']'                           :   '$2'.
union_prop      -> quoted_word                                  :   [{dot, property('$1')}].
union_prop      -> union_prop ',' quoted_word                   :   '$1' ++ [{dot, property('$3')}].

%%Property
property        -> word                                         :   '$1'.
property        -> quoted_word                                  :   '$1'.
property        -> int                                          :   '$1'.

%%Wildcard
wildcard        -> '*'                                          :   {wildcard, '*'}.

%%Array
array_indexes	-> '[' indexes ']'                              :   {array_indexes, '$2'}.
indexes         -> integer_arg                                  :   [index_access('$1')].
indexes         -> indexes ',' integer_arg                      :   '$1' ++ [index_access('$3')].

array_slice     -> '[' slice_parts ']'                          :   {array_slice, slice_op(line('$1'), '$2')}.
slice_parts     -> ':'                                          :   [colon].
slice_parts     -> integer_arg ':'                              :   ['$1', colon].
slice_parts     -> slice_parts ':'                              :   '$1' ++ [colon].
slice_parts     -> slice_parts integer_arg                      :   '$1' ++ ['$2'].

integer_arg     -> int                                          :   extract_value('$1').
integer_arg     -> negative_int                                 :   extract_value('$1').

%%Filter
filter_exp      -> '[' '?' '(' boolean_exp ')' ']'              :   {filter, '$4'}.

boolean_exp     -> boolean                                      :   extract_value('$1').
boolean_exp     -> predicate                                    :   '$1'.     
boolean_exp     -> '@' '.' property                             :   {'has_property?', property('$3')}.
boolean_exp     -> boolean_exp or_op boolean_exp                :   {'or',  ['$1', '$3']}.     
boolean_exp     -> boolean_exp and_op boolean_exp               :   {'and', ['$1', '$3']}.     
boolean_exp     -> not_op boolean_exp                           :   {'not', '$2'}.
boolean_exp     -> '(' boolean_exp ')'                          :   '$2'.     
        
predicate       -> item comparator item                         :   {extract_value('$2'), ['$1', '$3']}.                    
predicate       -> word '(' item ')'                            :   function_call('$1', '$3').
predicate       -> item in_op elements                          :   {in, ['$1', '$3']}.

item            -> number                                       :   '$1'.
item            -> boolean                                      :   extract_value('$1').
item            -> '@' '.' property                             :   property('$3').
item            -> '@'                                          :   current_node.
item            -> word                                         :   extract_value('$1').
item            -> quoted_word                                  :   extract_value('$1').

elements        -> '[' element ']'                              :   '$2'.
element         -> item                                         :   ['$1'].
element         -> element ',' item                             :   '$1' ++ ['$3'].

number          -> int                                          :   extract_value('$1').
number          -> float                                        :   extract_value('$1').
number          -> negative_float                               :   extract_value('$1').
number          -> negative_int                                 :   extract_value('$1').

Erlang code.

build_scan(Exp) -> {scan, Exp}.

extract_value({_, _, Value}) -> Value.

line({_, Line}) -> Line.

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

index_access(Value) -> {index_access, Value}.

property({_, _, Value}) when is_integer(Value) -> {property, integer_to_binary(Value)};
property({_, _, Value}) -> {property, Value}.

% Unwrap whent it's only one key access.
% Ex:
% ['some_key'] should be unwrapped to {:dot, {:property, "some_key"}
% ['one', 'two'] should be translated to {:union, [{:dot, {:property, "one"}, {:dot, {:property, "two"}]}
resolv_operation_for([{dot, {property, _}}] = Property) -> Property;
resolv_operation_for(Union) -> [{union, Union}].

slice_op(Line, Tokens) -> 
	Params = slice_params(0, [], Tokens),
	check_slice_params(Line, Params).

slice_params(Position, SliceTokens, [colon | Rest]) ->
    slice_params(Position + 1, SliceTokens, Rest);

slice_params(Position, SliceTokens, [Index | []]) ->
    SliceTokens ++ [{label_of(Position), Index}];

slice_params(Position, SliceTokens, [Index | Rest])
    when length(Rest) > 0 ->
    [colon | R] = Rest,
    Tokens = SliceTokens ++ [{label_of(Position), Index}],
    slice_params(Position + 1, Tokens, R);

slice_params(_, Tokens, _) -> Tokens.

label_of(Position) ->
    case Position of
      0 -> start_index;
      1 -> end_index;
      2 -> step;
      _ -> unknow
    end.

check_slice_params(Line, Tokens) when length(Tokens) > 3 -> 
  ErrorMessage =
	"to many params found for slice operation, "
	"the valid syntax is [start_index:end_index:step]",
	return_error(Line, ErrorMessage);

check_slice_params(Line, Tokens) when length(Tokens) == 3 ->
	case lists:last(Tokens) of
	 {step, Step} when Step < 0 ->
		return_error(Line, "slice step can't be negative");
	_ -> Tokens
	end;

check_slice_params(_StartLine, Tokens) -> Tokens.

