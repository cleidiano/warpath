defmodule Warpath.TokenizerTest do
  use ExUnit.Case, async: true

  alias Warpath.{Tokenizer, TokenizerError}

  describe "tokenize/1 generate tokens for" do
    test "root" do
      assert Tokenizer.tokenize("$") == {:ok, [{:"$", 1}]}
    end

    test "word" do
      assert Tokenizer.tokenize("any") == {:ok, [{:word, 1, "any"}]}
    end

    test "list of single quote word to double quote word when it's a IN expression" do
      assert Tokenizer.tokenize("in ['word one', other]") ==
               {:ok,
                [
                  {:in_op, 1},
                  {:"[", 1},
                  {:quoted_word, 1, "word one"},
                  {:",", 1},
                  {:word, 1, "other"},
                  {:"]", 1}
                ]}
    end

    test "single quoted word" do
      assert Tokenizer.tokenize("'single quoted word'") ==
               {:ok, [{:quoted_word, 1, "single quoted word"}]}
    end

    test "current node" do
      assert Tokenizer.tokenize("@") == {:ok, [{:@, 1}]}
    end

    test "operators" do
      operators = ["<", ">", "<=", ">=", "==", "!=", "===", "!=="]

      expected =
        Enum.map(operators, fn operator ->
          {:ok, [{:comparator, 1, String.to_atom(operator)}]}
        end)

      generated_tokens = Enum.map(operators, &Tokenizer.tokenize(&1))
      assert generated_tokens == expected
    end

    test "int" do
      assert Tokenizer.tokenize("10") == {:ok, [{:int, 1, 10}]}
    end

    test "float" do
      assert Tokenizer.tokenize("1.1") == {:ok, [{:float, 1, 1.1}]}
    end

    test "dot" do
      assert Tokenizer.tokenize(".") == {:ok, [{:., 1}]}
    end

    test "open bracket" do
      assert Tokenizer.tokenize("[") == {:ok, [{:"[", 1}]}
    end

    test "close bracket" do
      assert Tokenizer.tokenize("]") == {:ok, [{:"]", 1}]}
    end

    test "question mark" do
      assert Tokenizer.tokenize("?") == {:ok, [{:"?", 1}]}
    end

    test "open parentheses" do
      assert Tokenizer.tokenize("(") == {:ok, [{:"(", 1}]}
    end

    test "close parentheses" do
      assert Tokenizer.tokenize(")") == {:ok, [{:")", 1}]}
    end

    test "multiply" do
      assert Tokenizer.tokenize("*") == {:ok, [{:*, 1}]}
    end

    test "comma" do
      assert Tokenizer.tokenize(",") == {:ok, [{:",", 1}]}
    end

    test "colon" do
      assert Tokenizer.tokenize(":") == {:ok, [{:":", 1}]}
    end

    test "boolean" do
      assert Tokenizer.tokenize("true") == {:ok, [{:boolean, 1, true}]}
      assert Tokenizer.tokenize("false") == {:ok, [{:boolean, 1, false}]}
    end

    test "not" do
      assert Tokenizer.tokenize("not") == {:ok, [{:not_op, 1}]}
    end

    test "or" do
      assert Tokenizer.tokenize("or") == {:ok, [{:or_op, 1}]}
      assert Tokenizer.tokenize("||") == {:ok, [{:or_op, 1}]}
    end

    test "and" do
      assert Tokenizer.tokenize("and") == {:ok, [{:and_op, 1}]}
      assert Tokenizer.tokenize("&&") == {:ok, [{:and_op, 1}]}
    end

    test "atom" do
      assert Tokenizer.tokenize(":any") == {:ok, [{:word, 1, :any}]}
    end

    test "quoted atom" do
      assert Tokenizer.tokenize(~S{:"quoted atom"}) == {:ok, [{:word, 1, :"quoted atom"}]}
    end

    test "single quoted atom" do
      assert Tokenizer.tokenize(~S{:'quoted atom'}) == {:ok, [{:word, 1, :"quoted atom"}]}
    end

    test "special symbol" do
      assert Tokenizer.tokenize("#") == {:ok, [{:word, 1, "#"}]}
    end

    test "unicode symbol" do
      assert Tokenizer.tokenize("🌢") == {:ok, [{:word, 1, "🌢"}]}
    end
  end

  test "tokenize/1 should return {:error, reason} for nested single quote" do
    message = "Invalid syntax on line 1, {:illegal, '\\''}"

    assert Tokenizer.tokenize("'nested single ' quote'") ==
             {:error, %TokenizerError{message: message}}
  end

  test "brancket notation with quoted ponctuation as identifier" do
    assert Tokenizer.tokenize("['@']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "@"}, {:"]", 1}]}
    assert Tokenizer.tokenize("['$']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "$"}, {:"]", 1}]}
    assert Tokenizer.tokenize("['[']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "["}, {:"]", 1}]}
    assert Tokenizer.tokenize("[']']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "]"}, {:"]", 1}]}
    assert Tokenizer.tokenize("['(']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "("}, {:"]", 1}]}
    assert Tokenizer.tokenize("[')']") == {:ok, [{:"[", 1}, {:quoted_word, 1, ")"}, {:"]", 1}]}
    assert Tokenizer.tokenize("['.']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "."}, {:"]", 1}]}
    assert Tokenizer.tokenize("['?']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "?"}, {:"]", 1}]}
    assert Tokenizer.tokenize("['*']") == {:ok, [{:"[", 1}, {:quoted_word, 1, "*"}, {:"]", 1}]}
    assert Tokenizer.tokenize("[':']") == {:ok, [{:"[", 1}, {:quoted_word, 1, ":"}, {:"]", 1}]}
    assert Tokenizer.tokenize("[',']") == {:ok, [{:"[", 1}, {:quoted_word, 1, ","}, {:"]", 1}]}
  end
end
