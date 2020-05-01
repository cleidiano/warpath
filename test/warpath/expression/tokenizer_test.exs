defmodule Warpath.TokenizerTest do
  use ExUnit.Case, async: true

  alias Warpath.Expression.{Tokenizer, TokenizerError}

  def assert_tokens(input, tokens) do
    case :warpath_tokenizer.string(input) do
      {:ok, output, _} ->
        assert output == tokens

      {:error, {_, :tokenizer, output}, _} ->
        assert output == tokens
    end
  end

  # Ignored tokens
  test "WhiteSpace is ignored" do
    # horizontal tab
    assert_tokens '\u0009', []
    # vertical tab
    assert_tokens '\u000B', []
    # form feed
    assert_tokens '\u000C', []
    # space
    assert_tokens '\u0020', []
    # non-breaking space
    assert_tokens '\u00A0', []
  end

  test "LineTerminator is ignored" do
    # new line
    assert_tokens '\u000A', []
    # carriage return
    assert_tokens '\u000D', []
    # line separator
    assert_tokens '\u2028', []
    # paragraph separator
    assert_tokens '\u2029', []
  end

  test "Punctuator" do
    assert_tokens '$', [{:"$", 1, "$"}]
    assert_tokens '[', [{:"[", 1, "["}]
    assert_tokens ']', [{:"]", 1, "]"}]
    assert_tokens '(', [{:"(", 1, "("}]
    assert_tokens ')', [{:")", 1, ")"}]
    assert_tokens '?', [{:"?", 1, "?"}]
    assert_tokens ':', [{:":", 1, ":"}]
    assert_tokens ',', [{:",", 1, ","}]
    assert_tokens '.', [{:., 1, "."}]
    assert_tokens '*', [{:*, 1, "*"}]
    assert_tokens '@', [{:@, 1, "@"}]
    assert_tokens '..', [{:.., 1, ".."}]
  end

  test "Comparator" do
    assert_tokens '>', [{:comparator, 1, :>}]
    assert_tokens '<', [{:comparator, 1, :<}]
    assert_tokens '<=', [{:comparator, 1, :<=}]
    assert_tokens '>=', [{:comparator, 1, :>=}]
    assert_tokens '==', [{:comparator, 1, :==}]
    assert_tokens '!=', [{:comparator, 1, :!=}]
    assert_tokens '===', [{:comparator, 1, :===}]
    assert_tokens '!==', [{:comparator, 1, :!==}]
  end

  test "Boolean" do
    assert_tokens 'true', [{:boolean, 1, true}]
    assert_tokens 'false', [{:boolean, 1, false}]
  end

  test "IntValue" do
    assert_tokens '0', [{:int, 1, 0}]
    assert_tokens '-0', [{:int, 1, -0}]
    assert_tokens '-1', [{:int, 1, -1}]
    assert_tokens '2340', [{:int, 1, 2340}]
    assert_tokens '56789', [{:int, 1, 56789}]
  end

  test "FloatValue" do
    assert_tokens '0.0', [{:float, 1, 0.0}]
    assert_tokens '-0.1', [{:float, 1, -0.1}]
    assert_tokens '0.1', [{:float, 1, 0.1}]
    assert_tokens '2.340', [{:float, 1, 2.340}]
    assert_tokens '5678.9', [{:float, 1, 5678.9}]
    assert_tokens '1.23e+45', [{:float, 1, 1.23e+45}]
    assert_tokens '1.23E-45', [{:float, 1, 1.23e-45}]
    assert_tokens '0.23E-45', [{:float, 1, 0.23e-45}]
  end

  test "Identifier" do
    assert_tokens '""', [{:quoted_identifier, 1, ""}]
    assert_tokens '"a"', [{:quoted_identifier, 1, "a"}]
    assert_tokens '"\u000f"', [{:quoted_identifier, 1, "\u000f"}]
    assert_tokens '"\t"', [{:quoted_identifier, 1, "\t"}]
    assert_tokens '"\\""', [{:quoted_identifier, 1, "\\\""}]
    assert_tokens '"a\\n"', [{:quoted_identifier, 1, "a\\n"}]

    assert_tokens ~c{''}, [{:quoted_identifier, 1, ""}]
    assert_tokens ~c{'a'}, [{:quoted_identifier, 1, "a"}]
    assert_tokens ~c{'\u000f'}, [{:quoted_identifier, 1, "\u000f"}]
    assert_tokens ~c{'\t'}, [{:quoted_identifier, 1, "\t"}]
    assert_tokens ~c{'\\''}, [{:quoted_identifier, 1, "\\\'"}]
    assert_tokens ~c{'a\\n'}, [{:quoted_identifier, 1, "a\\n"}]

    assert_tokens ~c{'a b'}, [{:quoted_identifier, 1, "a b"}]
    assert_tokens ~c{"a b"}, [{:quoted_identifier, 1, "a b"}]
    assert_tokens ~c{"'"}, [{:quoted_identifier, 1, "'"}]
    assert_tokens ~c{'"'}, [{:quoted_identifier, 1, "\""}]

    assert_tokens 'identifier', [{:identifier, 1, "identifier"}]
    assert_tokens '_', [{:identifier, 1, "_"}]
    assert_tokens 'a', [{:identifier, 1, "a"}]
    assert_tokens 'Z', [{:identifier, 1, "Z"}]
    assert_tokens 'bar', [{:identifier, 1, "bar"}]
    assert_tokens 'Bar', [{:identifier, 1, "Bar"}]
    assert_tokens '_bar', [{:identifier, 1, "_bar"}]
    assert_tokens 'bar0', [{:identifier, 1, "bar0"}]
    assert_tokens 'bar-bar', [{:identifier, 1, "bar-bar"}]
    assert_tokens '_xu_Da_QX_2', [{:identifier, 1, "_xu_Da_QX_2"}]
    assert_tokens '#', [{:identifier, 1, "#"}]
    assert_tokens '🌢', [{:identifier, 1, "🌢"}]
  end

  test "Atom" do
    assert_tokens ':""', [{:atom_identifier, 1, :""}]
    assert_tokens ':"\u000f"', [{:atom_identifier, 1, :"\u000f"}]
    assert_tokens ':"\t"', [{:atom_identifier, 1, :"\t"}]
    assert_tokens ':"\\""', [{:atom_identifier, 1, :"\\\""}]
    assert_tokens ':"a\\n"', [{:atom_identifier, 1, :"a\\n"}]

    assert_tokens ~c{:''}, [{:atom_identifier, 1, :""}]
    assert_tokens ~c{:'\u000f'}, [{:atom_identifier, 1, :"\u000f"}]
    assert_tokens ~c{:'\t'}, [{:atom_identifier, 1, :"\t"}]
    assert_tokens ~c{:'\\''}, [{:atom_identifier, 1, :"\\\'"}]
    assert_tokens ~c{:'a\\n'}, [{:atom_identifier, 1, :"a\\n"}]

    assert_tokens ~c{:'a b'}, [{:atom_identifier, 1, :"a b"}]
    assert_tokens ~c{:'a-b'}, [{:atom_identifier, 1, :"a-b"}]
    assert_tokens ~c{:"a b"}, [{:atom_identifier, 1, :"a b"}]
    assert_tokens ~c{:"a-b"}, [{:atom_identifier, 1, :"a-b"}]
    assert_tokens ~c{:"'"}, [{:atom_identifier, 1, :"'"}]
    assert_tokens ~c{:'"'}, [{:atom_identifier, 1, :"\""}]
    assert_tokens ~c{:'#'}, [{:atom_identifier, 1, :"#"}]
    assert_tokens ~c{:'🌢'}, [{:atom_identifier, 1, :"🌢"}]

    assert_tokens ':identifier', [{:atom_identifier, 1, :identifier}]
    assert_tokens ':_', [{:atom_identifier, 1, :_}]
    assert_tokens ':a', [{:atom_identifier, 1, :a}]
    assert_tokens ':Z', [{:atom_identifier, 1, :Z}]
    assert_tokens ':bar', [{:atom_identifier, 1, :bar}]
    assert_tokens ':Bar', [{:atom_identifier, 1, :Bar}]
    assert_tokens ':_bar', [{:atom_identifier, 1, :_bar}]
    assert_tokens ':bar0', [{:atom_identifier, 1, :bar0}]
    assert_tokens ':_xu_Da_QX_2', [{:atom_identifier, 1, :_xu_Da_QX_2}]
  end

  test "Boolean Operators" do
    assert_tokens 'and', [{:and_op, 1, :and}]
    assert_tokens '&&', [{:and_op, 1, :&&}]
    assert_tokens 'or', [{:or_op, 1, :or}]
    assert_tokens '||', [{:or_op, 1, :||}]
    assert_tokens 'not', [{:not_op, 1, :not}]
    assert_tokens 'in', [{:in_op, 1, :in}]
  end

  test "in expression" do
    assert_tokens 'in', [
      {:in_op, 1, :in}
    ]
  end

  describe "tokenize/1" do
    test "should return {:error, reason} for nested single quote" do
      message = "Invalid syntax on line 1, {:illegal, '\\''}"

      assert Tokenizer.tokenize("'nested single ' quote'") ==
               {:error, %TokenizerError{message: message}}
    end

    test "sucsessfull tokenize" do
      assert {:ok, [{:identifier, 1, "🌢"}]} == Tokenizer.tokenize("🌢")
    end
  end

  describe "tokenize!" do
    test "rise when tokenize/1 fail" do
      assert_raise TokenizerError, fn -> Tokenizer.tokenize!("'''") end
    end

    test "sucsessfull tokenize" do
      assert [{:identifier, 1, "🌢"}] == Tokenizer.tokenize!("🌢")
    end
  end
end
