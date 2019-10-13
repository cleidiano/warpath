Definitions.

ROOT                 = \$
CURRENT_OBJECT       = @
PROPERTY             = [A-Za-z_][A-Za-z0-9]*
COMPARATOR           = (>|<|==)
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
COMMA                =  ,
WHITESPACE           = [\s\t\n\r]

Rules.

{ROOT}                  : {token, {root,            TokenLine, list_to_binary(TokenChars)}}.
{PROPERTY}              : {token, {property,        TokenLine, list_to_binary(TokenChars)}}.
{CURRENT_OBJECT}        : {token, {current_object,  TokenLine, list_to_binary(TokenChars)}}.
{COMPARATOR}            : {token, {comparator,      TokenLine, list_to_atom(TokenChars)}}.
{INT}                   : {token, {int,             TokenLine, list_to_integer(TokenChars)}}.
{INT}{DOT}{INT}         : {token, {float,           TokenLine, list_to_float(TokenChars)}}.
{DOT}                   : {token, {dot,             TokenLine, list_to_atom(TokenChars)}}.
{MINUS}                 : {token, {minus,           TokenLine, list_to_binary(TokenChars)}}.
{COMMA}                 : {token, {comma,           TokenLine, list_to_binary(TokenChars)}}.  
{OPEN_BRACKET}          : {token, {open_bracket,    TokenLine, list_to_atom(TokenChars)}}.
{CLOSE_BRACKET}         : {token, {close_bracket,   TokenLine, list_to_atom(TokenChars)}}.
{QUESTION_MARK}         : {token, {question_mark,   TokenLine, list_to_atom(TokenChars)}}.
{OPEN_PARENTHESE}       : {token, {open_parens,     TokenLine, list_to_atom(TokenChars)}}.
{CLOSE_PARENTHESE}      : {token, {close_parens,    TokenLine, list_to_atom(TokenChars)}}.
{WILDCARD}              : {token, {wildcard,        TokenLine, list_to_atom(TokenChars)}}.
{WHITESPACE}+           : skip_token.

Erlang code.
