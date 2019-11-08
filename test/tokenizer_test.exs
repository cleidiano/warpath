defmodule TokenizerTest do
  use ExUnit.Case, async: true

  alias Warpath.{Tokenizer, TokenizerError}

  describe "tokenize/1" do
    test "root" do
      assert {:ok, [{:root, 1, "$"}]} == Tokenizer.tokenize("$")
    end

    test "dot" do
      assert {:ok, [{:dot, 1, :.}]} == Tokenizer.tokenize(".")
    end

    test "access" do
      assert {:ok, [{:property, 1, "any"}]} == Tokenizer.tokenize("any")
    end

    test "current object" do
      assert {:ok, [{:current_object, 1, "@"}]} == Tokenizer.tokenize("@")
    end

    test "comparator >" do
      assert {:ok, [{:comparator, 1, :>}]} == Tokenizer.tokenize(">")
    end

    test "comparator <" do
      assert {:ok, [{:comparator, 1, :<}]} == Tokenizer.tokenize("<")
    end

    test "comparator ==" do
      assert {:ok, [{:comparator, 1, :==}]} == Tokenizer.tokenize("==")
    end

    test "int" do
      assert {:ok, [{:int, 1, 10}]} == Tokenizer.tokenize("10")
    end

    test "float" do
      assert {:ok, [{:float, 1, 1.1}]} == Tokenizer.tokenize("1.1")
    end

    test "open bracket" do
      assert {:ok, [{:open_bracket, 1, :"["}]} == Tokenizer.tokenize("[")
    end

    test "close bracket" do
      assert {:ok, [{:close_bracket, 1, :"]"}]} == Tokenizer.tokenize("]")
    end

    test "question mark" do
      assert {:ok, [{:question_mark, 1, :"?"}]} == Tokenizer.tokenize("?")
    end

    test "open parentheses" do
      assert {:ok, [{:open_parens, 1, :"("}]} == Tokenizer.tokenize("(")
    end

    test "close parentheses" do
      assert {:ok, [{:close_parens, 1, :")"}]} == Tokenizer.tokenize(")")
    end

    test "multiply" do
      assert {:ok, [{:wildcard, 1, :*}]} == Tokenizer.tokenize("*")
    end

    test "comma" do
      assert {:ok, [{:comma, 1, ","}]} == Tokenizer.tokenize(",")
    end

    test "minus" do
      assert {:ok, [{:minus, 1, "-"}]} == Tokenizer.tokenize("-")
    end

    test "should return {:error, reason} for invalid syntax" do
      message = "Invalid syntax on line 1, {:illegal, '#'}"
      assert {:error, %TokenizerError{message: message}} == Tokenizer.tokenize("$.name.#")
    end
  end

  describe "tokenize!/1 rise" do
    test "TokenizerError for invalid syntax" do
      assert_raise TokenizerError, fn ->
        Tokenizer.tokenize!("#.name")
      end
    end
  end
end
