defmodule Warpath.Query.IdentifierOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Query.IdentifierOperator
  alias Warpath.Execution.Env
  alias Warpath.Element

  import StreamData

  @length_config [min_length: 1, max_length: 10]
  @relative_path [{:root, "$"}]

  defp env_evaluation_for(propery_name, previous \\ nil) do
    Env.new({:dot, {:property, propery_name}}, previous)
  end

  describe "IdentifierOperator.Map" do
    property "evaluate a existent property always create a element" do
      check all map <- map_of(term(), term(), @length_config),
                {key, value} = Enum.random(map) do
        element = Element.new(value, [{:property, key} | @relative_path])

        assert IdentifierOperator.evaluate(map, @relative_path, env_evaluation_for(key)) ==
                 element
      end
    end

    property "evaluate a non existent property always create a element with value nil" do
      unique = make_ref()

      check all map <- map_of(term(), term(), @length_config) do
        element = Element.new(nil, [{:property, unique} | @relative_path])

        assert IdentifierOperator.evaluate(map, @relative_path, env_evaluation_for(unique)) ==
                 element
      end
    end

    test "evaluate a selector on empty map" do
      result = IdentifierOperator.evaluate(%{}, @relative_path, env_evaluation_for("any"))

      assert result == Element.new(nil, [{:property, "any"} | @relative_path])
    end
  end

  describe "IdentifierOperator.List" do
    property "evaluate a keyword as document dispatch to Map" do
      check all keyword <- list_of({atom(:alphanumeric), term()}, @length_config),
                {key, value} = Enum.random(keyword) do
        element = Element.new(value, [{:property, key} | @relative_path])
        result = IdentifierOperator.evaluate(keyword, @relative_path, env_evaluation_for(key))

        assert result == element
      end
    end

    test "traverse it's elements and query it value when it's a map" do
      elements_with_map = [
        Element.new(%{"b" => 1}, @relative_path),
        Element.new(%{"a" => 2, "child" => "2"}, @relative_path),
        Element.new(%{"c" => 3, "child" => "3"}, @relative_path),
        Element.new(%{"c" => 4, "child" => "4"}, @relative_path)
      ]

      previous_operation = Env.new({:wildcard, :*})
      env = env_evaluation_for("child", previous_operation)

      expected = [
        Element.new("2", [{:property, "child"} | @relative_path]),
        Element.new("3", [{:property, "child"} | @relative_path]),
        Element.new("4", [{:property, "child"} | @relative_path])
      ]

      assert IdentifierOperator.evaluate(elements_with_map, [], env) == expected
    end

    test "traverse it's elements and query it value when it's a keyword list" do
      elements_with_keyword_list = [
        Element.new([b: 1], @relative_path),
        Element.new([a: 2, child: "2"], @relative_path),
        Element.new([c: 3, child: "3"], @relative_path),
        Element.new([c: 4, child: "4"], @relative_path),
        Element.new(%{c: 5, child: "from map"}, @relative_path)
      ]

      previous_operation = Env.new({:wildcard, :*})
      env = env_evaluation_for(:child, previous_operation)

      expected = [
        Element.new("2", [{:property, :child} | @relative_path]),
        Element.new("3", [{:property, :child} | @relative_path]),
        Element.new("4", [{:property, :child} | @relative_path]),
        Element.new("from map", [{:property, :child} | @relative_path])
      ]

      assert IdentifierOperator.evaluate(elements_with_keyword_list, [], env) == expected
    end

    test "evaluate a empty list always result in empty list" do
      assert IdentifierOperator.evaluate([], @relative_path, env_evaluation_for(:any)) == []
    end

    test "raise for non keyword list" do
      tips =
        "You are trying to traverse a list using dot notation '.a_property_name', " <>
          "that it's not allowed for list type. " <>
          "You can use something like '[*].a_property_name' instead."

      assert_raise Warpath.UnsupportedOperationError, tips, fn ->
        IdentifierOperator.evaluate(["abc"], [], env_evaluation_for("a_property_name"))
      end
    end
  end
end
