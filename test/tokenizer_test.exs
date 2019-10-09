defmodule TokenizerTest do
  use ExUnit.Case, async: true

  describe "tokenize/1" do
    test "root" do
      assert {:ok, [{:root, 1, "$"}], 1} == Tokenizer.tokenize("$")
    end

    test "dot" do
      assert {:ok, [{:dot, 1, :.}], 1} == Tokenizer.tokenize(".")
    end

    test "access" do
      assert {:ok, [{:property, 1, "any"}], 1} == Tokenizer.tokenize("any")
    end

    test "current object" do
      assert {:ok, [{:current_object, 1, "@"}], 1} == Tokenizer.tokenize("@")
    end

    test "comparator >" do
      assert {:ok, [{:comparator, 1, :>}], 1} == Tokenizer.tokenize(">")
    end

    test "comparator <" do
      assert {:ok, [{:comparator, 1, :<}], 1} == Tokenizer.tokenize("<")
    end

    test "comparator ==" do
      assert {:ok, [{:comparator, 1, :==}], 1} == Tokenizer.tokenize("==")
    end

    test "int" do
      assert {:ok, [{:int, 1, 10}], 1} == Tokenizer.tokenize("10")
    end

    test "[" do
      assert {:ok, [{:open_bracket, 1, :"["}], 1} == Tokenizer.tokenize("[")
    end

    test "]" do
      assert {:ok, [{:close_bracket, 1, :"]"}], 1} == Tokenizer.tokenize("]")
    end

    test "?" do
      assert {:ok, [{:question_mark, 1, :"?"}], 1} == Tokenizer.tokenize("?")
    end

    test "(" do
      assert {:ok, [{:open_parens, 1, :"("}], 1} == Tokenizer.tokenize("(")
    end

    test ")" do
      assert {:ok, [{:close_parens, 1, :")"}], 1} == Tokenizer.tokenize(")")
    end

    test "*" do
      assert {:ok, [{:wildcard, 1, :*}], 1} == Tokenizer.tokenize("*")
    end
  end
end
