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

      env = env_for(filter_expression("@.id"))

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
