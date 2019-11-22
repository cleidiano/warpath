defmodule Warpath.TokenizerTest do
  use ExUnit.Case, async: true

  alias Warpath.{Tokenizer, TokenizerError}

  describe "tokenize/1 generate tokens for" do
    test "root" do
      assert Tokenizer.tokenize("$") == {:ok, [{:root, 1, "$"}]}
    end

    test "word" do
      assert Tokenizer.tokenize("any") == {:ok, [{:word, 1, "any"}]}
    end

    test "bracket access should rewrite to dot access" do
      assert Tokenizer.tokenize("['transformed in dot call']") ==
               {:ok, [{:., 1}, {:word, 1, "transformed in dot call"}]}
    end

    test "single quoted word" do
      assert Tokenizer.tokenize("'single quoted word'") ==
               {:ok, [{:word, 1, "single quoted word"}]}
    end

    test "current object" do
      assert Tokenizer.tokenize("@") == {:ok, [{:current_object, 1, "@"}]}
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
      assert Tokenizer.tokenize("*") == {:ok, [{:wildcard, 1, :*}]}
    end

    test "comma" do
      assert Tokenizer.tokenize(",") == {:ok, [{:",", 1}]}
    end

    test "minus" do
      assert Tokenizer.tokenize("-") == {:ok, [{:-, 1}]}
    end

    test "boolean" do
      assert Tokenizer.tokenize("true") == {:ok, [{true, 1}]}
      assert Tokenizer.tokenize("false") == {:ok, [{false, 1}]}
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
  end

  test "tokenize/1 should return {:error, reason} for invalid syntax" do
    message = "Invalid syntax on line 1, {:illegal, '#'}"
    assert Tokenizer.tokenize("$.name.#") == {:error, %TokenizerError{message: message}}
  end

  test "tokenize/1 should return {:error, reason} for nested single quote" do
    message = "Invalid syntax on line 1, {:illegal, '\\''}"

    assert Tokenizer.tokenize("'nested single ' quote'") ==
             {:error, %TokenizerError{message: message}}
  end

  describe "tokenize!/1 rise" do
    test "rise TokenizerError for invalid syntax" do
      assert_raise TokenizerError, fn ->
        Tokenizer.tokenize!("#.name")
      end
    end
  end
end
