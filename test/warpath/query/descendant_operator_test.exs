defmodule Warpath.Query.DescendantOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.DescendantOperator

  defp env_for(expr) do
    Env.new({:scan, expr})
  end

  defp filter_expression(filter) do
    {:ok, %Warpath.Expression{tokens: tokens}} = Warpath.Expression.compile("$[?( #{filter} )]")
    [_root, filter] = tokens
    filter
  end

  setup_all do
    document = %{
      "object" => %{
        "key" => "value",
        "array" => [
          %{"key" => "something"},
          %{"key" => %{"key" => "russian dolls"}}
        ]
      },
      "key" => "top"
    }

    [document: document]
  end

  describe "descendant property" do
    test "scan a existent one", %{document: document} do
      result = DescendantOperator.evaluate(document, [], env_for({:property, "key"}))

      assert result == [
               Element.new("top", property: "key"),
               Element.new("value", property: "key", property: "object"),
               Element.new("something",
                 property: "key",
                 index_access: 0,
                 property: "array",
                 property: "object"
               ),
               Element.new(%{"key" => "russian dolls"},
                 property: "key",
                 index_access: 1,
                 property: "array",
                 property: "object"
               ),
               Element.new("russian dolls",
                 property: "key",
                 property: "key",
                 index_access: 1,
                 property: "array",
                 property: "object"
               )
             ]
    end

    test "scan a inexistent one result in an empty list", %{document: document} do
      assert DescendantOperator.evaluate(document, [], env_for({:property, make_ref()})) == []
    end
  end

  test "descendant scan wildcard", %{document: document} do
    result = DescendantOperator.evaluate(document, [], env_for({:wildcard, :*}))

    assert result == [
             Element.new("top", property: "key"),
             Element.new(
               %{
                 "array" => [%{"key" => "something"}, %{"key" => %{"key" => "russian dolls"}}],
                 "key" => "value"
               },
               property: "object"
             ),
             Element.new([%{"key" => "something"}, %{"key" => %{"key" => "russian dolls"}}],
               property: "array",
               property: "object"
             ),
             Element.new("value", property: "key", property: "object"),
             Element.new(%{"key" => "something"},
               index_access: 0,
               property: "array",
               property: "object"
             ),
             Element.new(%{"key" => %{"key" => "russian dolls"}},
               index_access: 1,
               property: "array",
               property: "object"
             ),
             Element.new("something",
               property: "key",
               index_access: 0,
               property: "array",
               property: "object"
             ),
             Element.new(%{"key" => "russian dolls"},
               property: "key",
               index_access: 1,
               property: "array",
               property: "object"
             ),
             Element.new("russian dolls",
               property: "key",
               property: "key",
               index_access: 1,
               property: "array",
               property: "object"
             )
           ]
  end

  describe "descendant index" do
    test "scan for positive index when a document is a list" do
      env = env_for({:indexes, [index_access: 0, index_access: 2]})

      assert DescendantOperator.evaluate([:a, :b, :c], [], env) == [
               Element.new(:a, index_access: 0),
               Element.new(:c, index_access: 2)
             ]
    end

    test "scan for negative index when a document is a list" do
      env = env_for({:indexes, [index_access: -2, index_access: -1]})

      assert DescendantOperator.evaluate([:a, :b, :c], [], env) == [
               Element.new(:b, index_access: 1),
               Element.new(:c, index_access: 2)
             ]
    end

    test "scan a existent one", %{document: document} do
      env = env_for({:indexes, index_access: 0})

      assert DescendantOperator.evaluate(document, [], env) == [
               Element.new(%{"key" => "something"},
                 index_access: 0,
                 property: "array",
                 property: "object"
               )
             ]
    end

    test "scan a existent one using negative index", %{document: document} do
      env = env_for({:indexes, index_access: -1})

      assert DescendantOperator.evaluate(document, [], env) == [
               Element.new(%{"key" => %{"key" => "russian dolls"}},
                 index_access: 1,
                 property: "array",
                 property: "object"
               )
             ]
    end

    test "scan more than one index", %{document: document} do
      env = env_for({:indexes, index_access: 0, index_access: 1})

      assert DescendantOperator.evaluate(document, [], env) == [
               Element.new(%{"key" => "something"},
                 index_access: 0,
                 property: "array",
                 property: "object"
               ),
               Element.new(%{"key" => %{"key" => "russian dolls"}},
                 index_access: 1,
                 property: "array",
                 property: "object"
               )
             ]
    end

    test "scan a inexistent index result in an empty list", %{document: document} do
      env = env_for({:indexes, index_access: 99})
      assert DescendantOperator.evaluate(document, [], env) == []
    end

    test "scan on data type that isn't indexable result in an empty list" do
      env = env_for({:indexes, index_access: 0})
      assert DescendantOperator.evaluate(%{name: "warpath"}, [], env) == []
    end
  end

  describe "descendant filter" do
    test "scan that match a has_children? predicate" do
      document = %{
        "id" => 1,
        "more" => [
          %{"id" => 2},
          %{"more" => %{"id" => 3}},
          %{"id" => %{"id" => 4}},
          [%{"id" => 5}]
        ]
      }

      env =
        "@.id"
        |> filter_expression()
        |> env_for()

      expected = [
        Element.new(%{"id" => 2}, index_access: 0, property: "more"),
        Element.new(%{"id" => 5}, index_access: 0, index_access: 3, property: "more"),
        Element.new(%{"id" => 3}, property: "more", index_access: 1, property: "more"),
        Element.new(%{"id" => %{"id" => 4}}, index_access: 2, property: "more"),
        Element.new(%{"id" => 4}, property: "id", index_access: 2, property: "more")
      ]

      result = DescendantOperator.evaluate(document, [], env)
      assert Enum.sort(result) == Enum.sort(expected)
    end

    test "scan that match a comparision predicate" do
      document = %{
        "id" => 2,
        "more" => [
          %{"id" => 2},
          %{"more" => %{"id" => 2}},
          %{"id" => %{"id" => 2}},
          [%{"id" => 2}]
        ]
      }

      env =
        "@.id == 2"
        |> filter_expression()
        |> env_for()

      expected = [
        Element.new(%{"id" => 2}, index_access: 0, property: "more"),
        Element.new(%{"id" => 2}, property: "more", index_access: 1, property: "more"),
        Element.new(%{"id" => 2}, property: "id", index_access: 2, property: "more"),
        Element.new(%{"id" => 2}, index_access: 0, index_access: 3, property: "more")
      ]

      result = DescendantOperator.evaluate(document, [], env)
      assert Enum.sort(result) == Enum.sort(expected)
    end

    test "scan that match a guard predicate" do
      document = %{
        "id" => 2,
        "more" => [
          %{"id" => 2},
          %{"id" => [%{"id" => 2}]},
          %{"id" => %{"id" => 2}},
          [%{"id" => 2}]
        ]
      }

      env =
        "is_list(@.id) or is_map(@.id)"
        |> filter_expression()
        |> env_for()

      assert DescendantOperator.evaluate(document, [], env) == [
               Element.new(%{"id" => [%{"id" => 2}]}, index_access: 1, property: "more"),
               Element.new(%{"id" => %{"id" => 2}}, index_access: 2, property: "more")
             ]
    end

    test "scan that doesn't match a predicate", %{document: document} do
      env =
        env_for(
          {:filter,
           {:has_children?,
            {:subpath_expression, [{:current_node, "@"}, {:dot, {:property, make_ref()}}]}}}
        )

      assert DescendantOperator.evaluate(document, [], env) == []
    end
  end

  property "descendant filter that use a function on predicate" do
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

    check all terms <- list_of(term(), max_length: 20),
              function <- member_of(functions) do
      env =
        "#{function}(@)"
        |> filter_expression()
        |> env_for()

      result = DescendantOperator.evaluate(terms, [], env)
      assert Enum.all?(result, fn %Element{value: item} -> apply(Kernel, function, [item]) end)
    end
  end

  property "descendant operator on data type other then list or map always produce empty list" do
    check all term <- term() do
      container? = is_list(term) or is_map(term)
      assert container? or DescendantOperator.evaluate(term, [], env_for({:wildcard, :*})) == []
    end
  end

  test "evaluate/3 is nil safe" do
    env = env_for({:property, "any"})

    assert DescendantOperator.evaluate(nil, [], env) == []
  end
end
