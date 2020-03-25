defmodule Warpath.ExpressionTest do
  use ExUnit.Case, async: true

  import Match

  alias Warpath.Expression
  alias Warpath.ExpressionError

  describe "compile/1 compile dot notation" do
    test "string property" do
      assert Expression.compile("$.name") == {:ok, [{:root, "$"}, {:dot, {:property, "name"}}]}
    end

    test "string that contains a dash" do
      assert Expression.compile("$.property-name") ==
               {:ok, [{:root, "$"}, {:dot, {:property, "property-name"}}]}
    end

    test "string that contains a underline" do
      assert Expression.compile("$.property_name") ==
               {:ok, [{:root, "$"}, {:dot, {:property, "property_name"}}]}
    end

    test "int property" do
      assert Expression.compile("$.1") == {:ok, [{:root, "$"}, {:dot, {:property, "1"}}]}
    end
  end

  describe "compile/1 compile" do
    test "root expression" do
      assert Expression.compile("$") == {:ok, [{:root, "$"}]}
    end

    test "index based access" do
      assert Expression.compile("$[0]") ==
               {:ok, [{:root, "$"}, {:array_indexes, [{:index_access, 0}]}]}
    end

    test "wildcard property access" do
      assert Expression.compile("$.persons.*") ==
               {:ok, [{:root, "$"}, {:dot, {:property, "persons"}}, {:wildcard, :*}]}
    end

    test "access many array index" do
      assert Expression.compile("$[0, 1, 2]") ==
               {:ok,
                [
                  {:root, "$"},
                  {:array_indexes, [{:index_access, 0}, {:index_access, 1}, {:index_access, 2}]}
                ]}
    end

    test "union properties" do
      assert Expression.compile("$['one', 'two']") ==
               {:ok,
                [{:root, "$"}, {:union, [{:dot, {:property, "one"}}, {:dot, {:property, "two"}}]}]}
    end

    test "atom based access" do
      assert Expression.compile(~S{$.:atom_key}) ==
               {:ok, [{:root, "$"}, {:dot, {:property, :atom_key}}]}
    end
  end

  describe "compile/1 compile scan" do
    test "property expression" do
      assert Expression.compile("$..name") == {:ok, [{:root, "$"}, {:scan, {:property, "name"}}]}
      assert Expression.compile("$..1") == {:ok, [{:root, "$"}, {:scan, {:property, "1"}}]}
    end

    test "array indexes access expression" do
      assert Expression.compile("$..[1]") ==
               {:ok, [{:root, "$"}, {:scan, {:array_indexes, [index_access: 1]}}]}
    end

    test "wildcard expression" do
      assert Expression.compile("$..*") == {:ok, [{:root, "$"}, {:scan, {:wildcard, :*}}]}
    end

    test "wildcard with comparator filter expression" do
      expression =
        {:ok,
         [
           {:root, "$"},
           {:scan, {:wildcard, :*}},
           {:filter, {:>, [{:property, "age"}, 18]}}
         ]}

      assert Expression.compile("$..*.[?(@.age > 18)]") == expression
      assert Expression.compile("$..*[?(@.age > 18)]") == expression
      assert Expression.compile("$..[*].[?(@.age > 18)]") == expression
      assert Expression.compile("$..[*][?(@.age > 18)]") == expression
    end

    test "wildcard with has_property? filter expression" do
      expression =
        {:ok,
         [
           {:root, "$"},
           {:scan, {:wildcard, :*}},
           {:filter, {:has_property?, {:property, "age"}}}
         ]}

      assert Expression.compile("$..*.[?(@.age)]") == expression
      assert Expression.compile("$..*[?(@.age)]") == expression
      assert Expression.compile("$..[*].[?(@.age)]") == expression
      assert Expression.compile("$..[*][?(@.age)]") == expression
    end

    test "with filter expression" do
      assert Expression.compile("$..[?(@.age > 18)]") ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:filter, {:>, [{:property, "age"}, 18]}}}
                ]}
    end

    test "with has_property? filter expression" do
      assert Expression.compile("$..[?(@.age)]") ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:filter, {:has_property?, {:property, "age"}}}}
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

      assert Expression.compile("$..*[1]") == expected
      assert Expression.compile("$..[*][1]") == expected
    end

    test "wildcard followed by dot call and array access expression" do
      expected =
        {:ok,
         [
           {:root, "$"},
           {:scan, {:wildcard, :*}},
           {:array_indexes, [index_access: 1]}
         ]}

      assert Expression.compile("$..*.[1]") == expected
      assert Expression.compile("$..[*].[1]") == expected
    end

    test "wildcard followed by dot property expression" do
      assert Expression.compile("$..*.name") ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:wildcard, :*}},
                  {:dot, {:property, "name"}}
                ]}
    end

    test "array wildcard followed by dot property expression" do
      assert Expression.compile("$..[*].name") ==
               {:ok,
                [
                  {:root, "$"},
                  {:scan, {:wildcard, :*}},
                  {:dot, {:property, "name"}}
                ]}
    end
  end

  describe "compile/1 compile array slice expression" do
    test "with all parameters supplied" do
      assert Expression.compile("$[0:1:1]") ==
               {:ok, [{:root, "$"}, {:array_slice, [start_index: 0, end_index: 1, step: 1]}]}
    end

    test "with only start index supplied" do
      assert Expression.compile("$[0:]") ==
               {:ok, [{:root, "$"}, {:array_slice, [start_index: 0]}]}
    end

    test "with only end index supplied" do
      assert Expression.compile("$[:1]") == {:ok, [{:root, "$"}, {:array_slice, [end_index: 1]}]}
    end

    test "with negative start index" do
      assert Expression.compile("$[-1:]") ==
               {:ok, [{:root, "$"}, {:array_slice, [start_index: -1]}]}
    end

    test "with negative end index" do
      assert Expression.compile("$[:-1]") ==
               {:ok, [{:root, "$"}, {:array_slice, [end_index: -1]}]}
    end

    test "with negative step argument" do
      message = "Parser error: Invalid token on line 1, slice step can't be negative"

      assert Expression.compile("$[1:1:-1]") == {:error, %ExpressionError{message: message}}
    end

    test "with one colon separator" do
      assert Expression.compile("$[:]") == {:ok, [{:root, "$"}, {:array_slice, []}]}
    end

    test "with two colon separator" do
      assert Expression.compile("$[::]") == {:ok, [{:root, "$"}, {:array_slice, []}]}
    end

    test "with to many arguments supplied" do
      message =
        "Parser error: Invalid token on line 1, " <>
          "to many params found for slice operation, " <>
          "the valid syntax is [start_index:end_index:step]"

      assert Expression.compile("$[1:3:2:1]") == {:error, %ExpressionError{message: message}}
    end
  end

  describe "compile/1 compile filter expression" do
    test "that have a AND operator" do
      assert Expression.compile("$[?(true and true)]") ==
               ok([
                 {:root, "$"},
                 {:filter, {:and, [true, true]}}
               ])
    end

    test "that have OR operator" do
      assert Expression.compile("$[?(true or true)]") ==
               ok([
                 {:root, "$"},
                 {:filter, {:or, [true, true]}}
               ])
    end

    test "that is a OR precedence" do
      assert Expression.compile("$[?(true and true or false)]") ==
               ok([
                 {:root, "$"},
                 {:filter, {:or, [{:and, [true, true]}, false]}}
               ])
    end

    test "that is a parenthesis precedence" do
      assert Expression.compile("$[?(true and (true or false))]") ==
               ok([
                 {:root, "$"},
                 {:filter, {:and, [true, {:or, [true, false]}]}}
               ])
    end

    test "that is a NOT operator" do
      assert Expression.compile("$[?(not true)]") ==
               ok([
                 {:root, "$"},
                 {:filter, {:not, true}}
               ])
    end

    test "that have a property on it" do
      assert Expression.compile("$[?(@.age > 10)]") ==
               {:ok,
                [
                  {:root, "$"},
                  {:filter, {:>, [{:property, "age"}, 10]}}
                ]}
    end

    test "that is a has_property? operator" do
      assert Expression.compile("$.persons[?(@.age)]") ==
               {:ok,
                [
                  {:root, "$"},
                  {:dot, {:property, "persons"}},
                  {:filter, {:has_property?, {:property, "age"}}}
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

      expression_tokens = Enum.map(operators, &Expression.compile("$[?(@.age #{&1} 1)]"))
      assert expression_tokens == expected
    end

    test "that is a IN operator with one element on list" do
      assert Expression.compile("$[?(@.name in ['Warpath'])]") ==
               {:ok,
                [
                  {:root, "$"},
                  {:filter, {:in, [{:property, "name"}, ["Warpath"]]}}
                ]}
    end

    test "that is a allowed function call of " do
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
        Enum.map(functions, &Expression.compile("$[?(#{Atom.to_string(&1)}(@.any))]"))

      assert expression_tokens == expected
    end

    test "that is a invalid function call" do
      assert {:error,
              %ExpressionError{
                message: "Parser error: Invalid token on line 1, 'function_name'"
              }} = Expression.compile("$[?(function_name(@.any))]")
    end

    test "that use a current node as a target" do
      assert Expression.compile("$[?(@ == 10)]") ==
               ok([
                 {:root, "$"},
                 {:filter, {:==, [:current_node, 10]}}
               ])
    end
  end
end
