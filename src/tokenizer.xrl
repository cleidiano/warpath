Definitions.

Root                 = \$
CurrentNode          = @
Word                 = ([A-Za-z_]+-*[A-Za-z0-9]*-*)
SingleQuotedWord     = '([^\']*)'
Comparator           = (<|>|<=|>=|==|!=|===|!==)
Boolean              = true|false


% Int Value
Digit               = [0-9]
NegativeSign        = -
IntegerPart         = {NegativeSign}?{Digit}+
IntValue            = {IntegerPart}

% Float Value
FractionalPart      = \.{Digit}+
Sign                = [+\-]
ExponentIndicator   = [eE]
ExponentPart        = {ExponentIndicator}{Sign}?{Digit}+
FloatValue          = ({IntegerPart}{FractionalPart}|{IntegerPart}{ExponentPart}|{IntegerPart}{FractionalPart}{ExponentPart})

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
in                      : {token, {in_op,           TokenLine}}.

{Boolean}               : {token, {boolean,         TokenLine, to_atom(TokenChars)}}.
{Colon}{Word}           : {token, {word,            TokenLine, to_atom(TokenChars)}}.
{Colon}".+"             : {token, {word,            TokenLine, to_atom(TokenChars)}}.
{Colon}'.+'             : {token, {word,            TokenLine, to_atom(TokenChars)}}.
{Root}                  : {token, {root,            TokenLine, list_to_binary(TokenChars)}}.
{Word}                  : {token, {word,            TokenLine, list_to_binary(TokenChars)}}.
{SingleQuotedWord}      : {token, {quoted_word,     TokenLine, single_quoted_word_to_binary(TokenChars)}}.
{CurrentNode}           : {token, {current_node,    TokenLine, list_to_binary(TokenChars)}}.
{Comparator}            : {token, {comparator,      TokenLine, list_to_atom(TokenChars)}}.
{FloatValue}            : {token, {float,           TokenLine, list_to_float(TokenChars)}}.
{IntValue}              : {token, {int,             TokenLine, list_to_integer(TokenChars)}}.
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
