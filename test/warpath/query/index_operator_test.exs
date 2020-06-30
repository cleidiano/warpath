defmodule Warpath.Query.IndexOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import StreamData

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.IndexOperator

  @relative_path [{:root, "$"}]

  defp env_for_indexes(indexes, previous_operator \\ nil) do
    access = Enum.map(indexes, &{:index_access, &1})
    Env.new({:indexes, access}, previous_operator)
  end

  test "evaluate a empty list with union index operation always result in an empty list" do
    assert IndexOperator.evaluate([], @relative_path, env_for_indexes([1, 2, 3])) == []
  end

  describe "evaluate/3 on a single index operation" do
    property "always produce a scalar value for a existent index" do
      check all terms <- list_of(term(), min_length: 1),
                index = Enum.random(Range.new(0, length(terms) - 1)),
                item = Enum.at(terms, index) do
        result = IndexOperator.evaluate(terms, @relative_path, env_for_indexes([index]))
        assert result == Element.new(item, [{:index_access, index} | @relative_path])
      end
    end

    property "always produce a nil value for positive out of bound index" do
      check all terms <- list_of(term()),
                count = length(terms) do
        result = IndexOperator.evaluate(terms, @relative_path, env_for_indexes([count]))
        assert result == Element.new(nil, [{:index_access, count} | @relative_path])
      end
    end

    property "always produce a nil value for negative out of bound index" do
      check all terms <- list_of(term()),
                count = length(terms) do
        out_of_bound = -(count + 1)
        result = IndexOperator.evaluate(terms, @relative_path, env_for_indexes([out_of_bound]))
        assert result == Element.new(nil, [{:index_access, out_of_bound} | @relative_path])
      end
    end

    property "always produce nil for non list data type" do
      env = env_for_indexes([0])

      check all term <- term() do
        result = IndexOperator.evaluate(term, @relative_path, env)
        assert is_list(term) or result == Element.new(nil, [{:index_access, 0} | @relative_path])
      end
    end
  end

  describe "evaluate/3 on union index operation" do
    property "postive out of bound index are never evaluated" do
      check all terms <- list_of(term(), min_length: 1),
                count = length(terms) do
        env = env_for_indexes([count, count + 1])
        assert IndexOperator.evaluate(terms, @relative_path, env) == []
      end
    end

    property "negative out of bound index are never evaluated" do
      check all terms <- list_of(term(), min_length: 1),
                count = length(terms) do
        env = env_for_indexes([-(count + 1), -(count + 2)])
        assert IndexOperator.evaluate(terms, @relative_path, env) == []
      end
    end

    property "successfully evaluate positive index" do
      env = env_for_indexes([0, 1])

      check all terms <- list_of(term(), length: 2) do
        result = IndexOperator.evaluate(terms, [], env)

        [first, second | _] = terms

        assert result == [
                 Element.new(first, [{:index_access, 0}]),
                 Element.new(second, [{:index_access, 1}])
               ]
      end
    end

    property "successfully evaluate negative index" do
      check all terms <- list_of(term(), length: 2),
                count = length(terms) do
        env = env_for_indexes([-count, -(count - 1)])
        result = IndexOperator.evaluate(terms, [], env)

        [first, second | _] = terms

        assert result == [
                 Element.new(first, [{:index_access, 0}]),
                 Element.new(second, [{:index_access, 1}])
               ]
      end
    end

    property "flatten it's result on traverse a list of element after wildcard operator" do
      element = map(list_of(term(), length: 2), &Element.new(&1, []))
      env = env_for_indexes([0, 1])

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

    property "always produce empty list for non list data type" do
      env = env_for_indexes([0, 1])

      check all term <- term() do
        result = IndexOperator.evaluate(term, @relative_path, env)
        assert is_list(term) or result == []
      end
    end
  end

  property "evaluate/3 only evaluate %Element{} that it's value is a list data type" do
    env = env_for_indexes([0])

    check all term <- term(),
              element = Element.new(term, []) do
      result = IndexOperator.evaluate([element], [], env)
      assert is_list(term) or result == []
    end
  end

  test "evaluate/3 is nil safe" do
    assert IndexOperator.evaluate(nil, [], env_for_indexes([1, 2, 3])) == []
  end
end
