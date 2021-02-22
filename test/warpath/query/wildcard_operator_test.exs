defmodule Warpath.Query.WildcardOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.WildcardOperator

  defp env do
    Env.new({:wildcard, :*})
  end

  defmodule MyStruct do
    defstruct [:a, :b, :c]
  end

  describe "wildcard operator" do
    test "nil safe traverse" do
      assert WildcardOperator.evaluate(nil, [], env()) == []
    end

    property "always return empty list for data type other then list and map" do
      check all term <- term() do
        unless is_list(term) or is_map(term) do
          assert WildcardOperator.evaluate(term, [], env()) == []
        end
      end
    end

    property "should have each path of element composed by a relative path input" do
      check all list <- StreamData.list_of(term()) do
        relative_path = {:property, "initial_path"}
        elements = WildcardOperator.evaluate(list, [relative_path], env())

        paths = Enum.map(elements, fn %Element{path: path} -> Enum.reverse(path) end)

        refute Enum.any?(paths, &(length(&1) < 2))
        assert Enum.all?(paths, &match?([^relative_path | _], &1))
      end
    end

    property "produce a list of element with value from input list" do
      check all list <- StreamData.list_of(term()) do
        elements = WildcardOperator.evaluate(list, [], env())
        values = Enum.map(elements, fn %Element{value: value} -> value end)

        assert list == values
      end
    end

    test "flatten it result when operate on list of elements" do
      first = Element.new(["one", "two"], property: "first")
      second = Element.new(["three", "four"], property: "second")

      assert WildcardOperator.evaluate([first, second], [], env()) == [
               Element.new("one", index_access: 0, property: "first"),
               Element.new("two", index_access: 1, property: "first"),
               Element.new("three", index_access: 0, property: "second"),
               Element.new("four", index_access: 1, property: "second")
             ]
    end

    property "produce a list of element where it path and value is extracted from input map" do
      check all map <- map_of(term(), term()) do
        result = WildcardOperator.evaluate(map, [], env())

        keys_as_properties =
          map
          |> Map.keys()
          |> Enum.map(&{:property, &1})
          |> Enum.sort()

        assert Enum.sort(Enum.flat_map(result, &Element.path/1)) == keys_as_properties
        assert Enum.sort(Enum.map(result, &Element.value/1)) == Enum.sort(Map.values(map))
      end
    end

    test "support struct data type" do
      document = %MyStruct{a: 1, b: 2, c: 3}

      expected = [
        Element.new(1, property: :a),
        Element.new(2, property: :b),
        Element.new(3, property: :c)
      ]

      assert WildcardOperator.evaluate(document, [], env()) == expected
    end
  end
end
