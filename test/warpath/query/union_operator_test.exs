defmodule Warpath.Query.UnionOperatorOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.UnionOperator

  @relative_path [{:root, "$"}]

  defp env_evaluation_for(keys, previous \\ nil) do
    properties = Enum.map(keys, &{:dot, {:property, &1}})
    Env.new({:union, properties}, previous)
  end

  describe "UnionOperator.Map" do
    property "evaluate a existent properties always create a element" do
      check all map <- map_of(term(), term(), min_length: 1),
                {key1, value1} = Enum.random(map),
                {key2, value2} = Enum.random(map) do
        elements = [
          Element.new(value1, [{:property, key1} | @relative_path]),
          Element.new(value2, [{:property, key2} | @relative_path])
        ]

        union_result =
          UnionOperator.evaluate(map, @relative_path, env_evaluation_for([key1, key2]))

        assert union_result == elements
      end
    end

    property "evaluate a non existent property a element isn't created" do
      unique = make_ref()

      check all map <- map_of(term(), term(), min_length: 1),
                {key, value} = Enum.random(map) do
        element = Element.new(value, [{:property, key} | @relative_path])

        union_result =
          UnionOperator.evaluate(map, @relative_path, env_evaluation_for([unique, key]))

        assert union_result == [element]
      end
    end

    test "evaluate a property on empty map result in empty list" do
      assert UnionOperator.evaluate(%{}, @relative_path, env_evaluation_for(["any"])) == []
    end
  end

  describe "UnionOperator.List" do
    property "evaluate a keyword as document dispatch to UnionOperator.Map" do
      check all keyword <-
                  uniq_list_of(
                    {atom(:alphanumeric), term()},
                    min_length: 1,
                    uniq_fun: fn {key, _value} -> key end
                  ),
                {key1, value1} = Enum.random(keyword),
                {key2, value2} = Enum.random(keyword) do
        elements = [
          Element.new(value1, [{:property, key1} | @relative_path]),
          Element.new(value2, [{:property, key2} | @relative_path])
        ]

        env = env_evaluation_for([key1, key2])
        assert elements == UnionOperator.evaluate(keyword, @relative_path, env)
      end
    end

    test "traverse it's elements and query it value when it's a map" do
      elements_with_map = [
        Element.new(%{"b" => 1}, @relative_path),
        Element.new(%{"a" => 2, "child" => "2"}, @relative_path),
        Element.new(%{"c" => 3, "child" => "3"}, @relative_path),
        Element.new(%{"b" => "other", "c" => 4, "child" => "4"}, @relative_path)
      ]

      elements = [
        Element.new(1, [{:property, "b"} | @relative_path]),
        Element.new("2", [{:property, "child"} | @relative_path]),
        Element.new("3", [{:property, "child"} | @relative_path]),
        Element.new("4", [{:property, "child"} | @relative_path]),
        Element.new("other", [{:property, "b"} | @relative_path])
      ]

      env = env_evaluation_for(["b", "child"])
      result = UnionOperator.evaluate(elements_with_map, [], env)

      assert Enum.sort(elements) == Enum.sort(result)
    end

    test "traverse it's elements and query it value when it's a keyword list" do
      elements_with_keyword_list = [
        Element.new([b: 1], @relative_path),
        Element.new([a: 2, child: "2"], @relative_path),
        Element.new([c: 3, child: "3"], @relative_path),
        Element.new([c: 4, child: "4"], @relative_path),
        Element.new(%{c: 5, child: "from map"}, @relative_path)
      ]

      expected = [
        Element.new(1, [{:property, :b} | @relative_path]),
        Element.new("2", [{:property, :child} | @relative_path]),
        Element.new("3", [{:property, :child} | @relative_path]),
        Element.new("4", [{:property, :child} | @relative_path]),
        Element.new("from map", [{:property, :child} | @relative_path])
      ]

      env = env_evaluation_for([:b, :child])
      assert UnionOperator.evaluate(elements_with_keyword_list, [], env) == expected
    end

    test "evaluate a empty list always result in empty list" do
      assert UnionOperator.evaluate([], @relative_path, env_evaluation_for([:any])) == []
    end
  end

  test "evaluate/3 is nil safe traverse" do
    assert UnionOperator.evaluate(nil, [], env_evaluation_for([:first, :second])) == []
  end
end
