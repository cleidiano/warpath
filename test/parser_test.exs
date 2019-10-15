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

      assert Parser.parser(tokens) ==
               {:ok, [{:root, "$"}, {:array_indexes, [{:index_access, 0}]}]}
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

    test "access many array index" do
      tokens = Tokenizer.tokenize!("$[0, 1, 2]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:array_indexes, [{:index_access, 0}, {:index_access, 1}, {:index_access, 2}]}
                ]}
    end

    test "scan property expression" do
      tokens = Tokenizer.tokenize!("$..name")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}, {:scan, {:property, "name"}}]}
    end

    test "scan wildcard expression" do
      tokens = Tokenizer.tokenize!("$..*")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}, {:scan, {:wildcard, :*}}]}
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

    test "filter expression contains @.age" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {:contains, {:property, "age"}}}
                ]}
    end
  end
end
