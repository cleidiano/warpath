Definitions.

Root                 = \$
CurrentNode          = @
Word                 = ([A-Za-z_]+-*[A-Za-z0-9]*-*)
SingleQuotedWord   = '([^\']*)'
Comparator           = (<|>|<=|>=|==|!=|===|!==)
Minus                = \-
Int                  = [0-9]+
OpenBracket          = \[
CloseBracket         = \]
OpenParenthese      = \(
CloseParenthese     = \)
Dot                  = \.
QuestionMark        = \?
Qildcard             = \*
Comma                = ,
Colon                = :
Whitespace           = [\s\t\n\r]

Rules.

(or|\|\|)               : {token, {or_op,           TokenLine}}.
(and|&&)                : {token, {and_op,          TokenLine}}.
not                     : {token, {not_op,          TokenLine}}.
true                    : {token, {true,            TokenLine}}.
false                   : {token, {false,           TokenLine}}.
in                      : {token, {in_op,           TokenLine}}.

{Colon}{Word}           : {token, {word,            TokenLine, to_atom(TokenChars)}}.
{Colon}".+"             : {token, {word,            TokenLine, to_atom(TokenChars)}}.
{Colon}'.+'             : {token, {word,            TokenLine, to_atom(TokenChars)}}.
{Root}                  : {token, {root,            TokenLine, list_to_binary(TokenChars)}}.
{Word}                  : {token, {word,            TokenLine, list_to_binary(TokenChars)}}.
{SingleQuotedWord}      : {token, {quoted_word,     TokenLine, single_quoted_word_to_binary(TokenChars)}}.
{CurrentNode}           : {token, {current_node,    TokenLine, list_to_binary(TokenChars)}}.
{Comparator}            : {token, {comparator,      TokenLine, list_to_atom(TokenChars)}}.
{Int}                   : {token, {int,             TokenLine, list_to_integer(TokenChars)}}.
{Int}{Dot}{Int}         : {token, {float,           TokenLine, list_to_float(TokenChars)}}.
-{Int}                  : {token, {negative_int,    TokenLine, list_to_integer(TokenChars)}}.
-{Int}{Dot}{Int}        : {token, {negative_flot,   TokenLine, list_to_float(TokenChars)}}.
{Dot}{Dot}              : {token, {scan,            TokenLine, list_to_atom(TokenChars)}}.
{Dot}                   : {token, {'.',             TokenLine}}.
{Minus}                 : {token, {'-',             TokenLine}}.
{Colon}                 : {token, {':',             TokenLine}}.
{Comma}                 : {token, {',',             TokenLine}}.  
{OpenBracket}           : {token, {'[',             TokenLine}}.
{CloseBracket}         : {token, {']',             TokenLine}}.
{QuestionMark}         : {token, {'?',             TokenLine}}.
{OpenParenthese}       : {token, {'(',             TokenLine}}.
{CloseParenthese}      : {token, {')',             TokenLine}}.
{Qildcard}              : {token, {wildcard,        TokenLine, list_to_atom(TokenChars)}}.
{Whitespace}+           : skip_token.

Erlang code.

single_quoted_word_to_binary([$', $']) -> <<>>;
single_quoted_word_to_binary([$' | Chars]) ->
    Char = lists:last(Chars),
    case Char of
      $' -> list_to_binary(lists:droplast(Chars));
      Other -> {error, Other}
    end.

to_atom([$: | Chars]) -> to_atom(Chars);
to_atom([$" | Chars]) ->
  Char = lists:last(Chars),
  case Char of
    $" -> to_atom(lists:droplast(Chars));
    Other -> {error, Other}
  end;
to_atom([$' | Chars]) ->
  Char = lists:last(Chars),
  case Char of
    $' -> to_atom(lists:droplast(Chars));
    Other -> {error, Other}
  end;
to_atom(Chars) -> list_to_atom(Chars).
