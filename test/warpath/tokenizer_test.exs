defmodule Warpath.TokenizerTest do
  use ExUnit.Case, async: true

  alias Warpath.{Tokenizer, TokenizerError}

  def assert_tokens(input, tokens) do
    case :tokenizer.string(input) do
      {:ok, output, _} ->
        assert output == tokens

      {:error, {_, :tokenizer, output}, _} ->
        assert output == tokens
    end
  end

  # Ignored tokens
  test "WhiteSpace is ignored" do
    assert_tokens '\u0009', [] # horizontal tab
    assert_tokens '\u000B', [] # vertical tab
    assert_tokens '\u000C', [] # form feed
    assert_tokens '\u0020', [] # space
    assert_tokens '\u00A0', [] # non-breaking space
  end

  test "LineTerminator is ignored" do
    assert_tokens '\u000A', [] # new line
    assert_tokens '\u000D', [] # carriage return
    assert_tokens '\u2028', [] # line separator
    assert_tokens '\u2029', [] # paragraph separator
  end

  test "Punctuator" do
    assert_tokens '$',  [{ :"$", 1 }]
    assert_tokens '[',  [{ :"[", 1 }]
    assert_tokens ']',  [{ :"]", 1 }]
    assert_tokens '(',  [{ :"(", 1 }]
    assert_tokens ')',  [{ :")", 1 }]
    assert_tokens '?',  [{ :"?", 1 }]
    assert_tokens ':',  [{ :":", 1 }]
    assert_tokens ',',  [{ :",", 1 }]
    assert_tokens '.',  [{ :., 1 }]
    assert_tokens '*',  [{ :*, 1 }]
    assert_tokens '@',  [{ :@, 1 }]
    assert_tokens '..', [{ :.., 1 }]
  end

  test "Comparator" do
    assert_tokens '>',   [{ :comparator, 1, :> }]
    assert_tokens '<',   [{ :comparator, 1, :< }]
    assert_tokens '<=',  [{ :comparator, 1, :<= }]
    assert_tokens '>=',  [{ :comparator, 1, :>= }]
    assert_tokens '==',  [{ :comparator, 1, :== }]
    assert_tokens '!=',  [{ :comparator, 1, :!= }]
    assert_tokens '===', [{ :comparator, 1, :=== }]
    assert_tokens '!==', [{ :comparator, 1, :!== }]
  end

  test "Boolean" do
    assert_tokens 'true',  [{ :boolean, 1, true }]
    assert_tokens 'false', [{ :boolean, 1, false }]
  end

  test "IntValue" do
    assert_tokens '0',     [{ :int, 1, 0 }]
    assert_tokens '-0',    [{ :int, 1, -0 }]
    assert_tokens '-1',    [{ :int, 1, -1 }]
    assert_tokens '2340',  [{ :int, 1, 2340 }]
    assert_tokens '56789', [{ :int, 1, 56789 }]
  end

  test "FloatValue" do
    assert_tokens '0.0',      [{ :float, 1, 0.0 }]
    assert_tokens '-0.1',     [{ :float, 1, -0.1 }]
    assert_tokens '0.1',      [{ :float, 1, 0.1 }]
    assert_tokens '2.340',    [{ :float, 1, 2.340 }]
    assert_tokens '5678.9',   [{ :float, 1, 5678.9 }]
    assert_tokens '1.23e+45', [{ :float, 1, 1.23e+45 }]
    assert_tokens '1.23E-45', [{ :float, 1, 1.23e-45 }]
    assert_tokens '0.23E-45', [{ :float, 1, 0.23e-45 }]
  end

  test "Identifier" do
    assert_tokens '""',             [{ :quoted_word, 1, "" }]
    assert_tokens '"a"',            [{ :quoted_word, 1, "a" }]
    assert_tokens '"\u000f"',       [{ :quoted_word, 1, "\u000f"  }]
    assert_tokens '"\t"',           [{ :quoted_word, 1, "\t"  }]
    assert_tokens '"\\""',          [{ :quoted_word, 1, "\\\""  }]
    assert_tokens '"a\\n"',         [{ :quoted_word, 1, "a\\n"  }]

    assert_tokens ~c{''},           [{ :quoted_word, 1, "" }]
    assert_tokens ~c{'a'},          [{ :quoted_word, 1, "a" }]
    assert_tokens ~c{'\u000f'},     [{ :quoted_word, 1, "\u000f"  }]
    assert_tokens ~c{'\t'},         [{ :quoted_word, 1, "\t"  }]
    assert_tokens ~c{'\\''},        [{ :quoted_word, 1, "\\\'"  }]
    assert_tokens ~c{'a\\n'},       [{ :quoted_word, 1, "a\\n"  }]

    assert_tokens ~c{'a b'},        [{ :quoted_word, 1, "a b" }]
    assert_tokens ~c{"a b"},        [{ :quoted_word, 1, "a b" }]
    assert_tokens ~c{"'"},          [{ :quoted_word, 1, "'" }]
    assert_tokens ~c{'"'},          [{ :quoted_word, 1, "\"" }]

    assert_tokens 'identifier',     [{ :word, 1, "identifier" }]
    assert_tokens '_',              [{ :word, 1, "_" }]
    assert_tokens 'a',              [{ :word, 1, "a" }]
    assert_tokens 'Z',              [{ :word, 1, "Z" }]
    assert_tokens 'bar',            [{ :word, 1, "bar" }]
    assert_tokens 'Bar',            [{ :word, 1, "Bar" }]
    assert_tokens '_bar',           [{ :word, 1, "_bar" }]
    assert_tokens 'bar0',           [{ :word, 1, "bar0" }]
    assert_tokens '_xu_Da_QX_2',    [{ :word, 1, "_xu_Da_QX_2" }]
    assert_tokens '#',              [{ :word, 1, "#" }]
    assert_tokens '🌢',              [{ :word, 1, "🌢" }]
  end

  test "Atom" do
    assert_tokens ':""',             [{ :word, 1, :""}]
    assert_tokens ':"\u000f"',       [{ :word, 1, :"\u000f" }]
    assert_tokens ':"\t"',           [{ :word, 1, :"\t" }]
    assert_tokens ':"\\""',          [{ :word, 1, :"\\\"" }]
    assert_tokens ':"a\\n"',         [{ :word, 1, :"a\\n" }]

    assert_tokens ~c{:''},           [{ :word, 1, :""}]
    assert_tokens ~c{:'\u000f'},     [{ :word, 1, :"\u000f" }]
    assert_tokens ~c{:'\t'},         [{ :word, 1, :"\t" }]
    assert_tokens ~c{:'\\''},        [{ :word, 1, :"\\\'" }]
    assert_tokens ~c{:'a\\n'},       [{ :word, 1, :"a\\n" }]

    assert_tokens ~c{:'a b'},        [{ :word, 1, :"a b" }]
    assert_tokens ~c{:"a b"},        [{ :word, 1, :"a b" }]
    assert_tokens ~c{:"'"},          [{ :word, 1, :"'" }]
    assert_tokens ~c{:'"'},          [{ :word, 1, :"\"" }]
    assert_tokens ~c{:'#'},          [{ :word, 1, :"#" }]
    assert_tokens ~c{:'🌢'},          [{ :word, 1, :"🌢" }]

    assert_tokens ':identifier',     [{ :word, 1, :identifier }]
    assert_tokens ':_',              [{ :word, 1, :_ }]
    assert_tokens ':a',              [{ :word, 1, :a }]
    assert_tokens ':Z',              [{ :word, 1, :Z }]
    assert_tokens ':bar',            [{ :word, 1, :bar }]
    assert_tokens ':Bar',            [{ :word, 1, :Bar }]
    assert_tokens ':_bar',           [{ :word, 1, :_bar }]
    assert_tokens ':bar0',           [{ :word, 1, :bar0 }]
    assert_tokens ':_xu_Da_QX_2',    [{ :word, 1, :_xu_Da_QX_2 }]
  end

  test "Boolean Operators" do
    assert_tokens 'and', [{:and_op, 1}]
    assert_tokens '&&',  [{:and_op, 1}]
    assert_tokens 'or',  [{:or_op, 1}]
    assert_tokens '||',  [{:or_op, 1}]
    assert_tokens 'not', [{:not_op, 1}]
    assert_tokens 'in',  [{:in_op, 1}]
  end

  test "in expression" do
    assert_tokens ~c{in ['word one', other, :atom] }, [
      { :in_op, 1 },
      { :"[", 1 },
      { :quoted_word, 1, "word one" },
      { :",", 1 },
      { :word, 1, "other" },
      { :",", 1 },
      { :word, 1, :atom },
      { :"]", 1 }
    ]
  end

  test "tokenize/1 should return {:error, reason} for nested single quote" do
    message = "Invalid syntax on line 1, {:illegal, '\\''}"

    assert Tokenizer.tokenize("'nested single ' quote'") ==
             {:error, %TokenizerError{message: message}}
  end
end
