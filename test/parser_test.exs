defmodule ParserTest do
  use ExUnit.Case, async: true

  alias Warpath.{Tokenizer, Parser}

  describe "parse/1" do
    test "root token expression" do
      tokens = Tokenizer.tokenize!("$")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}]}
    end

    test "dot property access" do
      tokens = Tokenizer.tokenize!("$.name")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}, {:dot, {:property, "name"}}]}
    end

    test "index based access" do
      tokens = Tokenizer.tokenize!("$[0]")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}, {:index_access, 0}]}
    end

    test "wildcard property access" do
      tokens = Tokenizer.tokenize!("$.persons.*")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}, {:dot, {:property, "persons"}}]}
    end

    test "array wildcard access" do
      tokens = Tokenizer.tokenize!("$.persons[*]")

      assert Parser.parser(tokens) ==
               {:ok, [{:root, "$"}, {:dot, {:property, "persons"}}, {:array_wildcard, :*}]}
    end

    test "filter expression @.age > 10" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age > 10)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {{:property, "age"}, :>, 10}}
                ]}
    end

    test "filter expression @.age < 10" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age < 10)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {{:property, "age"}, :<, 10}}
                ]}
    end

    test "filter expression @.age == 10" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age == 10)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {{:property, "age"}, :==, 10}}
                ]}
    end
  end
end
