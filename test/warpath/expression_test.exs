defmodule Warpath.ExpressionTest do
  use ExUnit.Case, async: true

  alias Warpath.Expression
  alias Warpath.ExpressionError

  def assert_compile(query, output, type \\ :ok) do
    assert Expression.compile(query) == {type, output}
  end

  describe "children lookup" do
    test "with simple string as identifier using dot notation" do
      assert_compile "$.name", [
        {:root, "$"},
        {:dot, {:property, "name"}}
      ]
    end

    test "with simple atom as identifier" do
      assert_compile ~S{$.:atom_key}, [
        {:root, "$"},
        {:dot, {:property, :atom_key}}
      ]
    end

    test "with int as identifier using dot notation" do
      assert_compile "$.1", [
        {:root, "$"},
        {:dot, {:property, "1"}}
      ]
    end

    test "with wildcard using dot notation " do
      assert_compile "$.persons.*", [
        {:root, "$"},
        {:dot, {:property, "persons"}},
        {:wildcard, :*}
      ]
    end

    test "with index" do
      assert_compile "$[0]", [
        {:root, "$"},
        {:array_indexes, [{:index_access, 0}]}
      ]
    end

    test "with union of index" do
      assert_compile "$[0, 1, 2]", [
        {:root, "$"},
        {:array_indexes,
         [
           {:index_access, 0},
           {:index_access, 1},
           {:index_access, 2}
         ]}
      ]
    end

    test "with union of identifier" do
      assert_compile "$['one', 'two']", [
        {:root, "$"},
        {:union,
         [
           {:dot, {:property, "one"}},
           {:dot, {:property, "two"}}
         ]}
      ]
    end
  end

  describe "children lookup with slice" do
    test "when all parameters are supplied" do
      assert_compile "$[0:1:1]", [
        {:root, "$"},
        {:array_slice,
         [
           start_index: 0,
           end_index: 1,
           step: 1
         ]}
      ]
    end

    test "when only start_index is supplied" do
      assert_compile "$[0:]", [
        {:root, "$"},
        {:array_slice, [start_index: 0]}
      ]
    end

    test "when only end_index is supplied" do
      assert_compile "$[:1]", [
        {:root, "$"},
        {:array_slice, [end_index: 1]}
      ]
    end

    test "when negative start_index are supplied" do
      assert_compile "$[-1:]", [
        {:root, "$"},
        {:array_slice, [start_index: -1]}
      ]
    end

    test "when negative end_index are supplied" do
      assert_compile "$[:-1]", [
        {:root, "$"},
        {:array_slice, [end_index: -1]}
      ]
    end

    test "when only colon keyword are supplied" do
      expression = [{:root, "$"}, {:array_slice, []}]

      assert_compile "$[:]", expression
      assert_compile "$[::]", expression
    end

    test "when step argument supplied are less then 1" do
      message = "Parser error: Invalid token on line 1, slice step can't be negative"

      assert_compile "$[:1:-1]", %ExpressionError{message: message}, :error
      assert_compile "$[::-1]", %ExpressionError{message: message}, :error
      assert_compile "$[1:1:-1]", %ExpressionError{message: message}, :error
      assert_compile "$[::0]", %ExpressionError{message: message}, :error
    end

    test "when to many arguments are supplied" do
      message =
        "Parser error: Invalid token on line 1, " <>
          "to many params found for slice operation, " <>
          "the valid syntax is [start_index:end_index:step]"

      assert_compile "$[1:3:2:1]", %ExpressionError{message: message}, :error
    end
  end

  describe "children lookup filter" do
    test "combined with AND operator" do
      assert_compile "$[?(true and true)]", [
        {:root, "$"},
        {:filter, {:and, [true, true]}}
      ]
    end

    test "combined with OR operator" do
      assert_compile "$[?(true or true)]", [
        {:root, "$"},
        {:filter, {:or, [true, true]}}
      ]
    end

    test "that have a precedence OR operation" do
      assert_compile "$[?(true and true or false)]", [
        {:root, "$"},
        {:filter, {:or, [{:and, [true, true]}, false]}}
      ]
    end

    test "that have a precedence parenthesis defined" do
      assert_compile "$[?(true and (true or false))]", [
        {:root, "$"},
        {:filter, {:and, [true, {:or, [true, false]}]}}
      ]
    end

    test "that is a NOT operator" do
      assert_compile "$[?(not true)]", [
        {:root, "$"},
        {:filter, {:not, true}}
      ]
    end

    test "that have a children property lookup on it" do
      expression = [
        {:root, "$"},
        {:filter, {:>, [{:property, "age"}, 10]}}
      ]

      assert_compile "$[?(@.age > 10)]", expression
      assert_compile "$[?(@['age'] > 10)]", expression
    end

    test "that use a index access on it" do
      assert_compile "$[?(@[1] > 10)]", [
        {:root, "$"},
        {:filter, {:>, [{:index_access, 1}, 10]}}
      ]
    end

    test "that is a has_property? operator" do
      expression = [
        {:root, "$"},
        {:dot, {:property, "persons"}},
        {:filter, {:has_property?, {:property, "age"}}}
      ]

      assert_compile "$.persons[?(@.age)]", expression
      assert_compile "$.persons[?(@['age'])]", expression
    end

    test "that is any operator of [:<, :>, :<=, :>=, :==, :!=, :===, :!==]" do
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
      assert_compile "$[?(@.name in ['Warpath'])]", [
        {:root, "$"},
        {:filter, {:in, [{:property, "name"}, ["Warpath"]]}}
      ]
    end

    test "that use a current children as a target" do
      assert_compile "$[?(@ == 10)]", [
        {:root, "$"},
        {:filter, {:==, [:current_node, 10]}}
      ]
    end

    test "that is a allowed function call" do
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
      message = "Parser error: Invalid token on line 1, 'function_name'"

      assert_compile "$[?(function_name(@.any))]", %ExpressionError{message: message}, :error
    end
  end

  describe "recursive descent followed by" do
    test "a simple string as identifier" do
      assert_compile "$..name", [
        {:root, "$"},
        {:scan, {:property, "name"}}
      ]
    end

    test "a int as identifier" do
      assert_compile "$..1", [
        {:root, "$"},
        {:scan, {:property, "1"}}
      ]
    end

    test "a children index lookup" do
      assert_compile "$..[1]", [
        {:root, "$"},
        {:scan, {:array_indexes, [index_access: 1]}}
      ]
    end

    test "a children lookup filter" do
      assert_compile "$..[?(@.age > 18)]", [
        {:root, "$"},
        {:scan, {:filter, {:>, [{:property, "age"}, 18]}}}
      ]

      assert_compile "$..[?(@.age)]", [
        {:root, "$"},
        {:scan, {:filter, {:has_property?, {:property, "age"}}}}
      ]
    end

    test "a wildcard lookup" do
      assert_compile "$..*", [
        {:root, "$"},
        {:scan, {:wildcard, :*}}
      ]
    end

    test "a wildcard and then a children filter lookup" do
      comparator_filter = [
        {:root, "$"},
        {:scan, {:wildcard, :*}},
        {:filter, {:>, [{:property, "age"}, 18]}}
      ]

      assert_compile "$..*.[?(@.age > 18)]", comparator_filter
      assert_compile "$..*[?(@.age > 18)]", comparator_filter
      assert_compile "$..[*].[?(@.age > 18)]", comparator_filter
      assert_compile "$..[*][?(@.age > 18)]", comparator_filter

      has_property_filter = [
        {:root, "$"},
        {:scan, {:wildcard, :*}},
        {:filter, {:has_property?, {:property, "age"}}}
      ]

      assert_compile "$..*.[?(@.age)]", has_property_filter
      assert_compile "$..*[?(@.age)]", has_property_filter
      assert_compile "$..[*].[?(@.age)]", has_property_filter
      assert_compile "$..[*][?(@.age)]", has_property_filter
    end

    test "a wildcard and then a children index lookup" do
      expression = [
        {:root, "$"},
        {:scan, {:wildcard, :*}},
        {:array_indexes, [index_access: 1]}
      ]

      assert_compile "$..*[1]", expression
      assert_compile "$..*.[1]", expression
      assert_compile "$..[*][1]", expression
      assert_compile "$..[*].[1]", expression
    end

    test "a wildcard and then a identifier using dot notation" do
      expression = [
        {:root, "$"},
        {:scan, {:wildcard, :*}},
        {:dot, {:property, "name"}}
      ]

      assert_compile "$..*.name", expression
      assert_compile "$..[*].name", expression
    end
  end
end
