defmodule ParserTest do
  use ExUnit.Case, async: true

  alias Warpath.{Tokenizer, Parser}

  describe "parse/1 parse basic" do
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
  end

  describe "parse/1 parse a scan" do
    test "property expression" do
      tokens = Tokenizer.tokenize!("$..name")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}, {:scan, {:property, "name"}}]}
    end

    test "array indexes access expression" do
      tokens = Tokenizer.tokenize!("$..[1]")

      assert Parser.parser(tokens) ==
               {:ok, [{:root, "$"}, {:scan, {:array_indexes, [index_access: 1]}}]}
    end

    test "wildcard expression" do
      tokens = Tokenizer.tokenize!("$..*")

      assert Parser.parser(tokens) == {:ok, [{:root, "$"}, {:scan, {:wildcard, :*}}]}
    end

    test "wildcard followed by array access expression reduce to scan array index" do
      expected = {:ok, [{:root, "$"}, {:scan, {:array_indexes, [index_access: 1]}}]}

      assert Tokenizer.tokenize!("$..*[1]") |> Parser.parser() == expected
      assert Tokenizer.tokenize!("$..[*][1]") |> Parser.parser() == expected
    end

    test "wildcard followed by dot call and array access expression reduce to scan array index" do
      expected = {:ok, [{:root, "$"}, {:scan, {:array_indexes, [index_access: 1]}}]}

      assert Tokenizer.tokenize!("$..*.[1]") |> Parser.parse() == expected
      assert Tokenizer.tokenize!("$..[*].[1]") |> Parser.parse() == expected
    end

    test "wildcard with comparator filter expression" do
      expression =
        {:ok,
         [
           {:root, "$"},
           {:scan, {{:wildcard, :*}, {:filter, {{:property, "age"}, :>, 18}}}}
         ]}

      assert Tokenizer.tokenize!("$..*.[?(@.age > 18)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..*[?(@.age > 18)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..[*].[?(@.age > 18)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..[*][?(@.age > 18)]") |> Parser.parse() == expression
    end

    test "wildcard with contains filter expression" do
      expression =
        {:ok,
         [
           {:root, "$"},
           {:scan, {{:wildcard, :*}, {:filter, {:contains, {:property, "age"}}}}}
         ]}

      assert Tokenizer.tokenize!("$..*.[?(@.age)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..*[?(@.age)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..[*].[?(@.age)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..[*][?(@.age)]") |> Parser.parse() == expression
    end

    test "with filter expression" do
      tokens = Tokenizer.tokenize!("$..[?(@.age > 18)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:filter, {{:property, "age"}, :>, 18}}}
                ]}
    end

    test "with contains filter expression" do
      tokens = Tokenizer.tokenize!("$..[?(@.age)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:filter, {:contains, {:property, "age"}}}}
                ]}
    end
  end

  describe "parse/1 parse filter expression" do
    test "@.age > 10" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age > 10)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {{:property, "age"}, :>, 10}}
                ]}
    end

    test "@.age < 10" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age < 10)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {{:property, "age"}, :<, 10}}
                ]}
    end

    test "@.age == 10" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age == 10)]")

      assert Parser.parser(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {{:property, "age"}, :==, 10}}
                ]}
    end

    test "contains @.age" do
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
