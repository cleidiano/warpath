defmodule Warpath.ParserTest do
  use ExUnit.Case, async: true

  import Match

  alias Warpath.Parser
  alias Warpath.ParserError
  alias Warpath.Tokenizer

  describe "parse/1 parse basic" do
    test "root token expression" do
      tokens = Tokenizer.tokenize!("$")

      assert Parser.parse(tokens) == {:ok, [{:root, "$"}]}
    end

    test "dot property access" do
      tokens = Tokenizer.tokenize!("$.name")

      assert Parser.parse(tokens) == {:ok, [{:root, "$"}, {:dot, {:property, "name"}}]}
    end

    test "index based access" do
      tokens = Tokenizer.tokenize!("$[0]")

      assert Parser.parse(tokens) ==
               {:ok, [{:root, "$"}, {:array_indexes, [{:index_access, 0}]}]}
    end

    test "wildcard property access" do
      tokens = Tokenizer.tokenize!("$.persons.*")

      assert Parser.parse(tokens) ==
               {:ok, [{:root, "$"}, {:dot, {:property, "persons"}}, {:wildcard, :*}]}
    end

    test "access many array index" do
      tokens = Tokenizer.tokenize!("$[0, 1, 2]")

      assert Parser.parse(tokens) ==
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

      assert Parser.parse(tokens) == {:ok, [{:root, "$"}, {:scan, {:property, "name"}}]}
    end

    test "array indexes access expression" do
      tokens = Tokenizer.tokenize!("$..[1]")

      assert Parser.parse(tokens) ==
               {:ok, [{:root, "$"}, {:scan, {:array_indexes, [index_access: 1]}}]}
    end

    test "wildcard expression" do
      tokens = Tokenizer.tokenize!("$..*")

      assert Parser.parse(tokens) == {:ok, [{:root, "$"}, {:scan, {:wildcard, :*}}]}
    end

    test "wildcard with comparator filter expression" do
      expression =
        {:ok,
         [
           {:root, "$"},
           {:scan, {:wildcard, :*}},
           {:filter, {:>, [{:property, "age"}, 18]}}
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
           {:scan, {:wildcard, :*}},
           {:filter, {:contains, {:property, "age"}}}
         ]}

      assert Tokenizer.tokenize!("$..*.[?(@.age)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..*[?(@.age)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..[*].[?(@.age)]") |> Parser.parse() == expression
      assert Tokenizer.tokenize!("$..[*][?(@.age)]") |> Parser.parse() == expression
    end

    test "with filter expression" do
      tokens = Tokenizer.tokenize!("$..[?(@.age > 18)]")

      assert Parser.parse(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:filter, {:>, [{:property, "age"}, 18]}}}
                ]}
    end

    test "with contains filter expression" do
      tokens = Tokenizer.tokenize!("$..[?(@.age)]")

      assert Parser.parse(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:filter, {:contains, {:property, "age"}}}}
                ]}
    end

    test "wildcard followed by array access expression" do
      expected =
        {:ok,
         [
           {:root, "$"},
           {:scan, {:wildcard, :*}},
           {:array_indexes, [index_access: 1]}
         ]}

      assert Tokenizer.tokenize!("$..*[1]") |> Parser.parse() == expected
      assert Tokenizer.tokenize!("$..[*][1]") |> Parser.parse() == expected
    end

    test "wildcard followed by dot call and array access expression" do
      expected =
        {:ok,
         [
           {:root, "$"},
           {:scan, {:wildcard, :*}},
           {:array_indexes, [index_access: 1]}
         ]}

      assert Tokenizer.tokenize!("$..*.[1]") |> Parser.parse() == expected
      assert Tokenizer.tokenize!("$..[*].[1]") |> Parser.parse() == expected
    end

    test "wildcard followed by dot property expression" do
      tokens = Tokenizer.tokenize!("$..*.name")

      assert Parser.parse(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:wildcard, :*}},
                  {:dot, {:property, "name"}}
                ]}
    end

    test "array wildcard followed by dot property expression" do
      tokens = Tokenizer.tokenize!("$..[*].name")

      assert Parser.parse(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:wildcard, :*}},
                  {:dot, {:property, "name"}}
                ]}
    end
  end

  describe "parse/1 parse filter expression" do
    test "that have a and operator" do
      tokens = Tokenizer.tokenize!("$[?(true and true)]")

      assert Parser.parse(tokens) ==
               ok([
                 {:root, "$"},
                 {:filter, {:and, [true, true]}}
               ])
    end

    test "that have or operator" do
      tokens = Tokenizer.tokenize!("$[?(true or true)]")

      assert Parser.parse(tokens) ==
               ok([
                 {:root, "$"},
                 {:filter, {:or, [true, true]}}
               ])
    end

    test "that is a or precedence" do
      tokens = Tokenizer.tokenize!("$[?(true and true or false)]")

      assert Parser.parse(tokens) ==
               ok([
                 {:root, "$"},
                 {:filter, {:or, [{:and, [true, true]}, false]}}
               ])
    end

    test "that is a parenthesis precedence" do
      tokens = Tokenizer.tokenize!("$[?(true and (true or false))]")

      assert Parser.parse(tokens) ==
               ok([
                 {:root, "$"},
                 {:filter, {:and, [true, {:or, [true, false]}]}}
               ])
    end

    test "that is a negation operator" do
      tokens = Tokenizer.tokenize!("$[?(not true)]")

      assert Parser.parse(tokens) ==
               ok([
                 {:root, "$"},
                 {:filter, {:not, true}}
               ])
    end

    test "that have a property on it" do
      tokens = Tokenizer.tokenize!("$[?(@.age > 10)]")

      assert Parser.parse(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:filter, {:>, [{:property, "age"}, 10]}}
                ]}
    end

    test "that is a contains operator" do
      tokens = Tokenizer.tokenize!("$.persons[?(@.age)]")

      assert Parser.parse(tokens) ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {:contains, {:property, "age"}}}
                ]}
    end

    test "that is any of [:<, :>, :<=, :>=, :==, :!=, :===, :!==]" do
      operators = [:<, :>, :<=, :>=, :==, :!=, :===, :!==]

      expected =
        Enum.map(operators, fn operator ->
          {:ok,
           [
             {:root, "$"},
             {:filter, {operator, [{:property, "age"}, 1]}}
           ]}
        end)

      expression_tokens =
        operators
        |> Enum.map(&Tokenizer.tokenize!("$[?(@.age #{&1} 1)]"))
        |> Enum.map(&Parser.parse/1)

      assert expression_tokens == expected
    end

    test "that is allowed function call of " do
      functions = [
        :is_atom,
        :is_binary,
        :is_boolean,
        :is_float,
        :is_integer,
        :is_list,
        :is_map,
        :is_nil,
        :is_number,
        :is_tuple
      ]

      expected =
        Enum.map(functions, fn function ->
          {:ok,
           [
             {:root, "$"},
             {:filter, {function, {:property, "any"}}}
           ]}
        end)

      expression_tokens =
        functions
        |> Enum.map(&Tokenizer.tokenize!("$[?(#{Atom.to_string(&1)}(@.any))]"))
        |> Enum.map(&Parser.parse/1)

      assert expression_tokens == expected
    end

    test "that is a invalid function call" do
      tokens = Tokenizer.tokenize!("$[?(function_name(@.any))]")

      assert {:error,
              %ParserError{
                message: "Parser error: Invalid token on line 1, 'function_name'"
              }} = Parser.parse(tokens)
    end

    test "that use current object as a target" do
      tokens = Tokenizer.tokenize!("$[?(@ == 10)]")

      assert Parser.parse(tokens) ==
               ok([
                 {:root, "$"},
                 {:filter, {:==, [:current_object, 10]}}
               ])
    end
  end

  describe "parse!/1 rise" do
    test "ParserError for invalid tokens" do
      assert_raise Warpath.ParserError, fn ->
        Parser.parse!([{:invalid, "token"}])
      end
    end
  end
end
