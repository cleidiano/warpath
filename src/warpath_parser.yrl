Nonterminals grammar query_expression expression
children_expression
identifier_expression
identifier_query
array_index_expression
array_index_query
array_slice_expression
array_slice_query
index_elements 
index_element
slice_elements
slice_fragment
filter_expression
filter_query
filter
predicate
criteria
comparision_exp
item_exp
item_exp_lookup
item_resolver
boolean_exp
function_call

has_children_expression
has_children_query

union_expression
union_query
union_elements
union_element
union
wildcard_expression
wildcard_query

colon_separator
boolean_literal
int_literal
float_literal
.

Terminals '$' int float '[' ']' ',' '.' '*' ':' '(' ')' '?' '@'
identifier quoted_identifier atom_identifier
boolean comparator
and_op or_op not_op
.

Rootsymbol grammar.

Left        100 or_op.
Left        150 and_op.

% Query expression are in reverse order
grammar -> query_expression : reverse('$1').

query_expression -> '$' : [ build_root() ].
query_expression -> query_expression expression : ['$2' | '$1'].

expression -> children_expression : '$1'.
% expression -> descendant_expression : '$1'.

children_expression -> identifier_expression : '$1'.
children_expression -> array_index_expression : '$1'.
children_expression -> array_slice_expression : '$1'.
children_expression -> filter_expression : '$1'.
children_expression -> union_expression : '$1'.
children_expression -> wildcard_expression : '$1'.

% Identifier operations
identifier_expression -> identifier_query : build_identifier_lookup('$1').
identifier_query -> '.' identifier : '$2'.
identifier_query -> '.' atom_identifier : '$2'.

% Array index operations
array_index_expression -> array_index_query : build_array('$1').

array_index_query -> index_elements : '$1'.
array_index_query -> '.' index_elements : '$2'.

index_elements -> '[' index_element ']' : reverse('$2').
index_element -> int : [ '$1' ].
index_element -> index_element ',' int : [ '$3' | '$1' ] .

% Slice operations
colon_separator -> ':' : '$1'.

array_slice_expression -> array_slice_query : build_slice('$1').

array_slice_query -> slice_elements : '$1'.
array_slice_query -> '.' slice_elements : '$2'.

slice_elements -> '[' slice_fragment  ']' : reverse('$2').
slice_fragment -> colon_separator : ['$1'].
slice_fragment -> int colon_separator : ['$2', '$1'].
slice_fragment -> slice_fragment colon_separator : ['$2' | '$1'].
slice_fragment -> slice_fragment int : ['$2' | '$1'].

% Filter expression
int_literal -> int : value_of('$1').
float_literal -> float : value_of('$1').
boolean_literal -> boolean : value_of('$1').

filter_expression -> filter_query : build_filter('$1').
filter_query -> filter : '$1'.
filter_query -> '.' filter : '$2'.

filter -> '[' '?' '(' criteria ')' ']' : '$4'.
criteria -> boolean_exp : '$1'.

boolean_exp -> predicate : '$1'.
boolean_exp -> boolean_literal : '$1'.
boolean_exp -> boolean_exp and_op boolean_exp : {'and', ['$1', '$3']}.
boolean_exp -> boolean_exp or_op boolean_exp : {'or', ['$1', '$3']}.
boolean_exp -> not_op boolean_exp : {'not', '$2'}.
boolean_exp -> '(' boolean_exp ')' : '$2'.

predicate -> function_call : '$1'.
predicate -> comparision_exp : '$1'.
predicate -> has_children_expression : '$1'.

function_call -> identifier '(' item_exp ')' : build_function_call('$1', '$3').
comparision_exp -> item_exp comparator item_exp : build_comparision('$2', '$1', '$3').

item_exp -> int_literal : '$1'.
item_exp -> float_literal : '$1'.
item_exp -> boolean_literal : '$1'.
item_exp -> item_exp_lookup : '$1'.

item_exp_lookup -> '@' item_resolver : build_item_lookup('$1', '$2').
item_resolver -> union_expression : '$1'.
item_resolver -> identifier_expression : '$1'.
item_resolver -> array_index_expression : '$1'.

has_children_expression -> '@' has_children_query : build_has_children_lookup('$1', '$2').
has_children_query -> union_expression : '$1'.
has_children_query -> identifier_expression : '$1'.

% Union operations
union_expression -> union_query : build_union_lookup('$1').

union_query -> union : '$1'.
union_query -> '.' union : '$2'.

union -> '[' union_elements ']' : reverse('$2').
union_elements -> union_element : [ '$1' ].
union_elements -> union_elements ',' union_element : [ '$3' | '$1' ].

union_element -> atom_identifier : build_identifier_lookup('$1').
union_element -> quoted_identifier : build_identifier_lookup('$1').

% Wildcard operations
wildcard_expression -> wildcard_query : build_wildcard('$1').
wildcard_query -> '.' '*' : '$2'.


Erlang code.

-define(utf8_to_atom(Binary), binary_to_atom(Binary, utf8)).

-import(lists, [reverse/1, foldr/3]).

build_array(Indexes) ->
    IndexAccess = foldr(fun({int, _Line, Index}, Acc) -> [build_index(Index) | Acc] end, [], Indexes),
    {array_indexes, IndexAccess}.

build_index(Index) -> {index_access, Index}.

build_root() -> {root, <<"$">>}.

build_wildcard(Token) -> {wildcard, token_of(Token)}.

build_slice(Tokens) -> 
	Slice = compute_slice(_Line = start, _ColonCount = 0, _Acc = [], Tokens),
    {slice, reverse(Slice)}.

compute_slice(_, ColonCount, Acc, [{':', Line, _} | Rest]) ->
    compute_slice(Line, ColonCount + 1, Acc, Rest);

compute_slice(_, ColonCount, Acc, [Index | []]) ->
    [token_for(ColonCount, Index) | Acc];

compute_slice(_, ColonCount, Acc, [{_, Line, _} = Index | Rest]) ->
    Tokens = [token_for(ColonCount, Index) | Acc],
    compute_slice(Line, ColonCount, Tokens, Rest);

compute_slice(Line, ColonCount, Acc, []) -> 
    case ColonCount of
        Count when Count > 2  -> 
          ErrorMessage =
            "to many params found for slice operation, "
            "the valid syntax is [start_index:end_index:step]",
            return_error(Line, ErrorMessage);
        _ -> Acc
    end.

token_for(ColonCount, {int, Line, Int}) ->
    case ColonCount of
      2 when Int < 1 -> return_error(Line, "slice step should be greater than zero.");
      0 -> {start_index, Int};
      1 -> {end_index, Int};
      2 -> {step, Int}
    end.

build_union_lookup([Identifier]) -> Identifier;
build_union_lookup(Identifiers) -> {union, Identifiers}.

build_identifier_lookup(Token) -> {dot, identifier_lookup(Token)}.
identifier_lookup({_Token, _Line, Value}) when is_integer(Value) -> {property, integer_to_binary(Value)};
identifier_lookup({_Token, _Line, Value}) -> {property, Value}.

build_filter(FilterExpression) -> {filter, FilterExpression}.

build_comparision(Operator, Left, Right) -> {value_of(Operator), [Left, Right]}.

build_item_lookup(_AtOperator, {dot, Identifier}) -> Identifier;
build_item_lookup(_AtOperator,  {array_indexes, [IndexAccess]}) -> IndexAccess;
build_item_lookup(AtOperator,  Token) -> error_union_not_allowed(AtOperator, Token).

build_has_children_lookup(_AtOperator, {dot, Identifier}) -> {'has_property?', Identifier};
build_has_children_lookup(AtOperator, UnionToken) -> error_union_not_allowed(AtOperator, UnionToken) .

build_function_call({identifier, Line, Identifier}, Arguments) ->
    case safe_function_call(Identifier) of
        true -> {?utf8_to_atom(Identifier), Arguments};
		false -> return_error(Line, ["forbidden function '", Identifier, "'"])
    end.

safe_function_call(Function) -> 
    case binary_to_list(Function) of
		 "is_atom" -> true;
		 "is_binary" -> true;
		 "is_boolean" -> true;
		 "is_float" -> true;
		 "is_integer" -> true;
		 "is_list" -> true;
		 "is_map" -> true;
		 "is_nil" -> true;
		 "is_number" -> true;
		 "is_tuple" -> true;
		 _Forbidden -> false
    end.

value_of({_Token, _Line, Value}) -> Value.
token_of({Token, _Line, _Value}) -> Token.
% label_and_value_of({Token, _Line, Value}) -> {Token, Value}.

%%Errors
error_union_not_allowed({_, Line, _}, {Tag, [_ | _]}) when Tag == union; Tag == array_indexes ->
    return_error(Line, "union expression not supported in filter expression").
