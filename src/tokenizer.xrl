Definitions.

ROOT                 = \$
CURRENT_OBJECT       = @
WORD                 = ([A-Za-z_]+[A-Za-z0-9]*)
SINGLE_QUOTED_WORD   = '([^\']*)'
COMPARATOR           = (<|>|<=|>=|==|!=|===|!==)
PLUS                 = \+
MINUS                = \-
INT                  = [0-9]+
OPEN_BRACKET         = \[
CLOSE_BRACKET        = \]
OPEN_PARENTHESE      = \(
CLOSE_PARENTHESE     = \)
DOT                  = \.
QUESTION_MARK        = \?
WILDCARD             = \*
COMMA                = ,
WHITESPACE           = [\s\t\n\r]

Rules.

(or|\|\|)               : {token, {or_op,           TokenLine}}.
(and|&&)                : {token, {and_op,          TokenLine}}.
not                     : {token, {not_op,          TokenLine}}.
true                    : {token, {true,            TokenLine}}.
false                   : {token, {false,           TokenLine}}.
in                      : {token, {in_op,           TokenLine}}.

{ROOT}                  : {token, {root,            TokenLine, list_to_binary(TokenChars)}}.
{WORD}                  : {token, {word,            TokenLine, list_to_binary(TokenChars)}}.
{SINGLE_QUOTED_WORD}    : {token, {quoted_word,     TokenLine, single_quoted_word_to_binary(TokenChars)}}.
{CURRENT_OBJECT}        : {token, {current_node,    TokenLine, list_to_binary(TokenChars)}}.
{COMPARATOR}            : {token, {comparator,      TokenLine, list_to_atom(TokenChars)}}.
{INT}                   : {token, {int,             TokenLine, list_to_integer(TokenChars)}}.
{INT}{DOT}{INT}         : {token, {float,           TokenLine, list_to_float(TokenChars)}}.
{DOT}{DOT}              : {token, {scan,            TokenLine, list_to_atom(TokenChars)}}.
{DOT}                   : {token, {'.',             TokenLine}}.
{MINUS}                 : {token, {'-',             TokenLine}}.
{COMMA}                 : {token, {',',             TokenLine}}.  
{OPEN_BRACKET}          : {token, {'[',             TokenLine}}.
{CLOSE_BRACKET}         : {token, {']',             TokenLine}}.
{QUESTION_MARK}         : {token, {'?',             TokenLine}}.
{OPEN_PARENTHESE}       : {token, {'(',             TokenLine}}.
{CLOSE_PARENTHESE}      : {token, {')',             TokenLine}}.
{WILDCARD}              : {token, {wildcard,        TokenLine, list_to_atom(TokenChars)}}.
{WHITESPACE}+           : skip_token.

Erlang code.

single_quoted_word_to_binary("''") -> <<>>;
single_quoted_word_to_binary("'" ++ TokenChars) ->
    Caracter = lists:last(TokenChars),
    case Caracter of
      39 -> list_to_binary(lists:droplast(TokenChars));
      Other -> {error, Other}
    end.
