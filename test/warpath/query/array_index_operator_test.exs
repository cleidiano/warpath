defmodule Warpath.Query.ArrayIndexOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import StreamData

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.IndexOperator

  @relative_path [{:root, "$"}]

  defp env_for_array_index(indexes, previous_operator \\ nil) do
    access = Enum.map(indexes, &{:index_access, &1})
    Env.new({:indexes, access}, previous_operator)
  end

  test "evaluate a empty list always result in an element with empty list" do
    IndexOperator.evaluate([], @relative_path, env_for_array_index([1, 2, 3]))
  end

  property "always unwrap element when evaluate a single existent index" do
    check all terms <- list_of(term(), min_length: 1),
              index = Enum.random(Range.new(0, length(terms) - 1)),
              item = Enum.at(terms, index) do
      result = IndexOperator.evaluate(terms, @relative_path, env_for_array_index([index]))
      assert result == Element.new(item, [{:index_access, index} | @relative_path])
    end
  end

  property "postive out of bound index are never evaluated" do
    check all terms <- list_of(term(), min_length: 1),
              count = length(terms) do
      env = env_for_array_index([count, count + 1])
      assert IndexOperator.evaluate(terms, @relative_path, env) == []
    end
  end

  property "negative out of bound index are never evaluated" do
    check all terms <- list_of(term(), min_length: 1),
              count = length(terms) do
      env = env_for_array_index([-(count + 1), -(count + 2)])
      assert IndexOperator.evaluate(terms, @relative_path, env) == []
    end
  end

  property "flatten it's result on traverse a list of element after wildcard operator" do
    element = map(list_of(term(), length: 2), &Element.new(&1, []))
    env = env_for_array_index([0, 1])

    check all elements <- list_of(element) do
      result = IndexOperator.evaluate(elements, [], env)

      expected_elements =
        elements
        |> Stream.map(&Element.value/1)
        |> Enum.flat_map(fn [first, second | _] ->
          [
            Element.new(first, [{:index_access, 0}]),
            Element.new(second, [{:index_access, 1}])
          ]
        end)

      assert result == expected_elements
    end
  end

  property "index query are only evaluated on list data type" do
    env = env_for_array_index([0])

    check all term <- term(),
              element = Element.new(term, []) do
      result = IndexOperator.evaluate([element], [], env)
      assert result == [] or is_list(term)
    end
  end

  property "evaluate multipe index" do
    env = env_for_array_index([0, 1])

    check all terms <- list_of(term(), length: 2) do
      result = IndexOperator.evaluate(terms, [], env)

      [first, second | _] = terms

      assert result == [
               Element.new(first, [{:index_access, 0}]),
               Element.new(second, [{:index_access, 1}])
             ]
    end
  end

  property "can evaluate negative index" do
    check all terms <- list_of(term(), length: 2),
              count = length(terms) do
      env = env_for_array_index([-count, -(count - 1)])
      result = IndexOperator.evaluate(terms, [], env)

      [first, second | _] = terms

      assert result == [
               Element.new(first, [{:index_access, 0}]),
               Element.new(second, [{:index_access, 1}])
             ]
    end
  end
end
