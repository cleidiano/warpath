% JsonPath Lexer
%
% Acknowledgments
% Some piece of this lexer were extract from https://github.com/graphql-elixir/graphql/blob/master/src/graphql_lexer.xrl

Definitions.

% Ignored tokens
WhiteSpace          = \x{0009}\x{000B}\x{000C}\x{0020}\x{00A0}
_LineTerminator     = \x{000A}\x{000D}\x{2028}\x{2029}
LineTerminator      = [{_LineTerminator}]
Ignored             = [{WhiteSpace}]|{LineTerminator}

%Especial Symbols
At                  = \@
Dollar              = \$
OpenBracket         = \[
CloseBracket        = \]
OpenParens          = \(
CloseParens         = \)
Dot                 = \.
QuestionMark        = \?
Start               = \*
Colon               = \:
Comma               = \,
RecursiveDescent    = {Dot}{Dot}
Comparator          = (<|>|<=|>=|==|!=|===|!==)
Boolean             = true|false

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


% Punctuator
_Punctuator         = {At}{Dollar}{OpenBracket}{CloseBracket}{OpenParens}{CloseParens}{Dot}{QuestionMark}{Start}{Colon}{Comma}
Punctuator          = [{_Punctuator}]|{RecursiveDescent}


% Identifier Value
HexDigit            = [0-9A-Fa-f]
EscapedUnicode      = u{HexDigit}{HexDigit}{HexDigit}{HexDigit}
OperatorsSymbol     = ><=!
EscapedCharacter    = ['"\\\/bfnrt]
AllowedIdentifier   = [^"'{_LineTerminator}{_Punctuator}{WhiteSpace}{OperatorsSymbol}]
EscapedSequence     = \\{EscapedUnicode}|\\{EscapedCharacter}|\\{_Punctuator}

IdentifierCharacter = ({AllowedIdentifier}|{EscapedSequence})
ToQuoteIdentifier   = ([^''{_LineTerminator}]|{EscapedSequence})
Identifier          = {IdentifierCharacter}+
QuotedIdentifier    = '({Identifier}|{ToQuoteIdentifier})*'


%%%Atom
AllowedUnicode      = [^'"'{_LineTerminator}]
ToQuoteAtom         = ({AllowedUnicode}|{EscapedSequence})
UnquotedAtom        = ([a-zA-Z_][0-9a-zA-Z_?!]*)
DoubleQuotedAtom    = "({UnquotedAtom}|{ToQuoteAtom})*"
SingleQuotedAtom    = '({UnquotedAtom}|{ToQuoteAtom})*'
Atom                = :({UnquotedAtom}|{DoubleQuotedAtom}|{SingleQuotedAtom})


%%Operators
OrOp                = or|\|\|
AndOp               = and|&&
NotOp               = not
InOp                = in



Rules.

{OrOp}                  : {token, {or_op,           TokenLine}}.
{AndOp}                 : {token, {and_op,          TokenLine}}.
{NotOp}                 : {token, {not_op,          TokenLine}}.
{InOp}                  : {token, {in_op,           TokenLine}}.

{Punctuator}            : {token, {list_to_atom(TokenChars), TokenLine}}.
{Boolean}               : {token, {boolean,         TokenLine, list_to_atom(TokenChars)}}.
{Atom}                  : {token, {word,            TokenLine, to_atom(TokenChars)}}.

{Comparator}            : {token, {comparator,      TokenLine, list_to_atom(TokenChars)}}.
{FloatValue}            : {token, {float,           TokenLine, list_to_float(TokenChars)}}.
{IntValue}              : {token, {int,             TokenLine, list_to_integer(TokenChars)}}.
{Identifier}            : {token, {word,            TokenLine, unicode:characters_to_binary(TokenChars)}}.
{QuotedIdentifier}      : {token, {quoted_word,     TokenLine, single_quoted_word_to_binary(TokenChars)}}.
{Ignored}               : skip_token.



Erlang code.

single_quoted_word_to_binary([$', $']) -> <<>>;
single_quoted_word_to_binary([$' | Chars]) ->
    Char = lists:last(Chars),
    case Char of
      $' -> unicode:characters_to_binary(lists:droplast(Chars));
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
