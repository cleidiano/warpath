Nonterminals grammar query_expression expression
children_expression identifier_expression identifier_query bracket_notation_identifier dot_notation_identifier special_identifier
array_index_expression array_index_query
array_slice_expression array_slice_query index indexes slice_fragment slice_fragments
filter_expression filter_query filter boolean_exp comparision_exp current_node_op element elements
identifier_value boolean_value int_value float_value function_call has_children_expression has_children_query
in_expression item children_item item_resolver predicate
union_expression union_query union union_element union_elements
wildcard_expression wildcard_query bracket_wildcard
descendant_expression descendant_query descendant_identifier_expression descendant_wildcard_expression
root_op dot_op at_op colon_op descendant_op wildcard_op
open_bracket close_bracket
.

Terminals '$' '[' ']' ',' '.' '..' '*' ':' '(' ')' '?' '@'
identifier quoted_identifier atom_identifier boolean comparator
and_op or_op not_op in_op
int float 
.

Rootsymbol grammar.

Left 100 or_op.
Left 150 and_op.
Left 200 dot_op.

% Query expression are in reverse order
grammar -> query_expression : reverse('$1').

query_expression -> root_op : [ build_root() ].
query_expression -> query_expression expression : ['$2' | '$1'].

expression -> children_expression : '$1'.
expression -> descendant_expression : '$1'.

children_expression -> identifier_expression : '$1'.
children_expression -> array_index_expression : '$1'.
children_expression -> array_slice_expression : '$1'.
children_expression -> filter_expression : '$1'.
children_expression -> union_expression : '$1'.
children_expression -> wildcard_expression : '$1'.

% Identifier expression
identifier_expression -> identifier_query : build_identifier_lookup('$1').
identifier_query -> dot_notation_identifier : '$1'.
identifier_query -> bracket_notation_identifier : '$1'.
identifier_query -> dot_op bracket_notation_identifier : '$2'.

dot_notation_identifier -> dot_op identifier : '$2'.
dot_notation_identifier -> dot_op atom_identifier : '$2'.
dot_notation_identifier -> dot_op special_identifier : convert_to_identifier('$2').

bracket_notation_identifier -> open_bracket atom_identifier close_bracket: '$2'.
bracket_notation_identifier -> open_bracket quoted_identifier close_bracket: '$2'.

%%Special case allowed in dot notation operator and descendant operator
special_identifier -> in_op : '$1'.
special_identifier -> not_op : '$1'.
special_identifier -> and_op : '$1'.
special_identifier -> or_op : '$1'.
special_identifier -> boolean : '$1'.
special_identifier -> int : '$1'.

% Array index expression
array_index_expression -> array_index_query : build_array('$1').

array_index_query -> indexes : '$1'.
array_index_query -> dot_op indexes : '$2'.

indexes -> open_bracket index close_bracket : reverse('$2').
index -> int : ['$1'].
index -> index ',' int : ['$3' | '$1'] .

% Slice expression
array_slice_expression -> array_slice_query : build_slice('$1').

array_slice_query -> slice_fragments : '$1'.
array_slice_query -> dot_op slice_fragments : '$2'.

slice_fragments -> open_bracket slice_fragment close_bracket : reverse('$2').
slice_fragment -> colon_op : ['$1'].
slice_fragment -> int colon_op : ['$2', '$1'].
slice_fragment -> slice_fragment colon_op : ['$2' | '$1'].
slice_fragment -> slice_fragment int : ['$2' | '$1'].

% Filter expression
filter_expression -> filter_query : build_filter('$1').
filter_query -> filter : '$1'.
filter_query -> dot_op filter : '$2'.

filter -> open_bracket '?' '(' boolean_exp ')' close_bracket : '$4'.

boolean_exp -> predicate : '$1'.
boolean_exp -> boolean_value : '$1'.
boolean_exp -> boolean_exp and_op boolean_exp : {'and', ['$1', '$3']}.
boolean_exp -> boolean_exp or_op boolean_exp : {'or', ['$1', '$3']}.
boolean_exp -> not_op boolean_exp : {'not', '$2'}.
boolean_exp -> '(' boolean_exp ')' : '$2'.

predicate -> has_children_expression : '$1'.
predicate -> function_call : '$1'.
predicate -> in_expression : '$1'.
predicate -> comparision_exp : '$1'.

has_children_expression -> at_op has_children_query : build_has_children_lookup('$1', '$2').
has_children_query -> identifier_expression : '$1'.

function_call -> identifier '(' item ')' : build_function_call('$1', '$3').

item -> int_value : '$1'.
item -> float_value : '$1'.
item -> boolean_value : '$1'.
item -> identifier_value : '$1'.
item -> current_node_op : '$1'.
item -> children_item : '$1'.

children_item -> at_op item_resolver : build_children_item('$1', '$2').
item_resolver -> identifier_expression : '$1'.
item_resolver -> array_index_expression : '$1'.

comparision_exp -> item comparator item : build_comparision('$2', '$1', '$3').

in_expression -> item in_op elements : {in, ['$1', '$3']}. 
elements -> open_bracket element close_bracket : reverse('$2').
element -> item : ['$1'].
element -> element ',' item : ['$3' | '$1'].

int_value -> int : value_of('$1').
float_value -> float : value_of('$1').
boolean_value -> boolean : value_of('$1').
current_node_op -> at_op : current_node.

identifier_value -> identifier : identifier_value('$1').
identifier_value -> atom_identifier : identifier_value('$1').
identifier_value -> quoted_identifier : identifier_value('$1').

% Union expression
union_expression -> union_query : build_union_lookup('$1').
union_query -> union : '$1'.
union_query -> dot_op union : '$2'.

union -> open_bracket union_elements close_bracket : reverse('$2').
union_elements -> union_element ',' union_element  : ['$3', '$1'].
union_elements -> union_elements ',' union_element : ['$3' | '$1'].

union_element -> atom_identifier : build_identifier_lookup('$1').
union_element -> quoted_identifier : build_identifier_lookup('$1').

% Wildcard expression
wildcard_expression -> wildcard_query : build_wildcard('$1').

wildcard_query -> dot_op wildcard_op : '$2'.
wildcard_query -> bracket_wildcard : '$1'.
wildcard_query -> dot_op bracket_wildcard : '$2'.

bracket_wildcard -> open_bracket wildcard_op close_bracket : '$2'.

% Descendant expression
descendant_expression -> descendant_op descendant_query : build_descendant_lookup('$1', '$2').

descendant_query -> filter_expression : '$1'.
descendant_query -> array_index_expression : '$1'.
descendant_query -> descendant_wildcard_expression : build_wildcard('$1').
descendant_query -> descendant_identifier_expression : build_identifier_lookup('$1').

descendant_wildcard_expression -> wildcard_op : '$1'.
descendant_wildcard_expression -> bracket_wildcard : '$1'.

descendant_identifier_expression -> identifier : '$1'.
descendant_identifier_expression -> atom_identifier : '$1'.
descendant_identifier_expression -> bracket_notation_identifier : '$1'.
descendant_identifier_expression -> special_identifier : convert_to_identifier('$1').

%Operators
at_op -> '@' : '$1'.
dot_op -> '.' : '$1'.
root_op -> '$' : '$1'.
colon_op -> ':' : '$1'.
wildcard_op -> '*' : '$1'.
descendant_op -> '..' : '$1'.
descendant_op -> '..' dot_op : error_dot_op_after_descendant_op('$2') .

%helpers
open_bracket -> '[' : '$1'.
close_bracket -> ']' : '$1'.

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
    {array_slice, reverse(Slice)}.

compute_slice(_, ColonCount, Acc, [{':', Line, _} | Rest]) ->
    compute_slice(Line, ColonCount + 1, Acc, Rest);

compute_slice(Line, ColonCount, Acc, [Index | []]) ->
    Tokens = [token_for(ColonCount, Index) | Acc],
    compute_slice(Line, ColonCount, Tokens, []);

compute_slice(_, ColonCount, Acc, [{_, Line, _} = Index | Rest]) ->
    Tokens = [token_for(ColonCount, Index) | Acc],
    compute_slice(Line, ColonCount, Tokens, Rest);

compute_slice(Line, ColonCount, Acc, []) -> 
    case ColonCount of
        Count when Count > 2  -> error_slice_with_many_params(Line);
        _ -> Acc
    end.

token_for(ColonCount, {int, Line, Int}) ->
    case ColonCount of
      2 when Int < 1 -> error_slice_step_less_then_one(Line);
      0 -> {start_index, Int};
      1 -> {end_index, Int};
      2 -> {step, Int};
      _ -> {unknown, unknown}
    end.

build_union_lookup(Identifiers) -> {union, Identifiers}.

build_identifier_lookup(Token) -> {dot, {property, identifier_value(Token)}}.
identifier_value({_Token, _Line, Value}) -> Value.

convert_to_identifier({_, Line, V}) when is_atom(V) -> to_identifier(Line, atom_to_binary(V, utf8));
convert_to_identifier({_, Line, V}) when is_integer(V) -> to_identifier(Line, integer_to_binary(V)).
to_identifier(Line, Value) -> {identifier, Line, Value}.

build_filter(FilterExpression) -> {filter, FilterExpression}.

build_comparision(Operator, Left, Right) -> {value_of(Operator), [Left, Right]}.

build_children_item(_AtOperator, {dot, Identifier}) -> Identifier;
build_children_item(_AtOperator, {array_indexes, [IndexAccess]}) -> IndexAccess;
build_children_item(AtOperator, Token) -> error_union_not_allowed("filter", AtOperator, Token).

build_has_children_lookup(_AtOperator, {dot, Identifier}) -> {'has_property?', Identifier}.

build_function_call({identifier, _, Identifier} = Token, Arguments) ->
    Fun = binary_to_list(Identifier),
    case safe_function_call(Fun) of
        true -> {?utf8_to_atom(Identifier), Arguments};
		false -> error_forbidden_function(Token)
    end.

safe_function_call(Function) when is_list(Function) -> lists:member(Function, whitelist_functions()).
whitelist_functions() -> [
    "is_atom",
    "is_binary",
    "is_boolean",
    "is_float",
    "is_integer",
    "is_list",
    "is_map",
    "is_nil",
    "is_number",
    "is_tuple"
].

build_descendant_lookup(_, {dot, Expression}) -> {scan, Expression};
build_descendant_lookup(_, {filter, _} = Expression) -> {scan, Expression};
build_descendant_lookup(_, {wildcard, _} = Expression) -> {scan, Expression};
build_descendant_lookup(_, {array_indexes, [_]} = Expression) -> {scan, Expression};
build_descendant_lookup(Op, {array_indexes, _} = Expression) ->
    error_union_not_allowed("descendant", Op, Expression).

value_of({_Token, _Line, Value}) -> Value.
token_of({Token, _Line, _Value}) -> Token.
% label_and_value_of({Token, _Line, Value}) -> {Token, Value}.

%%Errors
error_slice_step_less_then_one(Line) ->
    return_error(Line, "slice step should be greater than zero.").

error_slice_with_many_params(Line) ->
    return_error(Line,
    "to many params found for slice operation, "
    "the valid syntax is [start_index:end_index:step]"
).

error_forbidden_function({identifier, Line, Identifier}) ->
    return_error(Line, io_lib:format(
        "forbidden function '~s', it's only allowed to call whitelist functions: [~s]",
        [Identifier, string:join(whitelist_functions(), ", ")]
    )
).

error_dot_op_after_descendant_op({_, Line, _}) ->
    return_error(Line, io_lib:format("~s", [
            "operator dot ('.') is not allowed after descendant operator ('..'),\n"
            "it must be contracted in a operator (..),\n"
            "For example: instead of '$...name' you must write '$..name', that is the right syntax!"
        ]
    )
).

error_union_not_allowed(ExpressionType, {_, Line, _}, {array_indexes, Indexes}) when length(Indexes) > 1 ->
    return_error(Line, io_lib:format(
        "union index expression not supported in ~s expression",
        [ExpressionType]
    )
).
