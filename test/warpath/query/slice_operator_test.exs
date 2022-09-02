defmodule Warpath.Query.SliceOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.SliceOperator

  defp env_for_slice(config \\ []) do
    Env.new({:slice, config})
  end

  defp element({term, index}), do: Element.new(term, [{:index_access, index}])

  property "slice any term other than list always produce a empty list" do
    check all(term <- term()) do
      assert is_list(term) or SliceOperator.evaluate(term, [], env_for_slice()) == []
    end
  end

  test "slice a empty list always produce a empty list" do
    assert SliceOperator.evaluate([], [], env_for_slice()) == []
  end

  property "slice without config result in all elements of input list" do
    check all(list <- list_of(term())) do
      elements =
        list
        |> Stream.with_index()
        |> Enum.map(&element/1)

      assert SliceOperator.evaluate(list, [], env_for_slice()) == elements
    end
  end

  describe "slice with start_index configured" do
    property "with index zero result in all elements of input list" do
      check all(list <- list_of(term(), min_length: 1)) do
        elements =
          list
          |> Stream.with_index()
          |> Enum.map(&element/1)

        assert SliceOperator.evaluate(list, [], env_for_slice(start_index: 0)) == elements
      end
    end

    property "with postive index" do
      check all(list <- list_of(term(), min_length: 1)) do
        elements =
          list
          |> Stream.with_index()
          |> Stream.filter(fn {_, index} -> index >= 1 end)
          |> Enum.map(&element/1)

        assert SliceOperator.evaluate(list, [], env_for_slice(start_index: 1)) == elements
      end
    end

    property "with negative index" do
      check all(list <- list_of(term(), min_length: 1)) do
        start = length(list) - 1

        elements =
          list
          |> Stream.with_index()
          |> Stream.filter(fn {_, index} -> index >= start end)
          |> Enum.map(&element/1)

        assert SliceOperator.evaluate(list, [], env_for_slice(start_index: -1)) == elements
      end
    end

    property "with out of bound positive index result in an empty list" do
      check all(list <- list_of(term(), min_length: 1)) do
        out_of_bound_index = length(list) + 1

        env = env_for_slice(start_index: out_of_bound_index)
        assert SliceOperator.evaluate(list, [], env) == []
      end
    end

    property "with out of bound negative index result in all elements of input list" do
      check all(list <- list_of(term(), min_length: 1)) do
        elements =
          list
          |> Stream.with_index()
          |> Enum.map(&element/1)

        out_of_bound_index = -(length(list) + 1)
        env = env_for_slice(start_index: out_of_bound_index)
        assert SliceOperator.evaluate(list, [], env) == elements
      end
    end
  end

  property "slice with missing start_index assume zero as default" do
    check all(list <- list_of(term(), min_length: 1)) do
      elements =
        list
        |> Stream.with_index()
        |> Enum.map(&element/1)

      assert SliceOperator.evaluate(list, [], env_for_slice([])) == elements
    end
  end

  describe "slice with exclusive end_index configured" do
    property "with postive index" do
      check all(list <- list_of(term(), min_length: 1)) do
        [h | _tail] = list
        elements = [element({h, 0})]

        assert SliceOperator.evaluate(list, [], env_for_slice(end_index: 1)) == elements
      end
    end

    property "with negative index" do
      check all(list <- list_of(term(), min_length: 1)) do
        end_index = length(list) - 1

        elements =
          list
          |> Stream.with_index()
          |> Stream.filter(fn {_, index} -> index < end_index end)
          |> Enum.map(&element/1)

        assert SliceOperator.evaluate(list, [], env_for_slice(end_index: -1)) == elements
      end
    end

    property "with out of bound positive index result in all elements of input list" do
      check all(list <- list_of(term(), min_length: 1)) do
        elements =
          list
          |> Stream.with_index()
          |> Enum.map(&element/1)

        out_of_bound_index = length(list) + 1
        env = env_for_slice(end_index: out_of_bound_index)

        assert SliceOperator.evaluate(list, [], env) == elements
      end
    end

    property "with out of bound negative index result in an empty list" do
      check all list <- list_of(term(), min_length: 1) do
        out_of_bound_index = -(length(list) + 1)
        env = env_for_slice(end_index: out_of_bound_index)

        assert SliceOperator.evaluate(list, [], env) == []
      end
    end
  end

  property "slice with missing end_index configuration the length of input list is used as a default" do
    check all(list <- list_of(term(), min_length: 1)) do
      elements =
        list
        |> Stream.with_index()
        |> Enum.map(&element/1)

      assert SliceOperator.evaluate(list, [], env_for_slice(start_index: 0)) == elements
    end
  end

  describe "configuration that result in empty range always produce an empty list" do
    property "start_index and end_index equals" do
      check all(list <- list_of(term(), min_length: 1)) do
        index = Enum.random(0..length(list))
        env = env_for_slice(start_index: index, end_index: index)

        assert SliceOperator.evaluate(list, [], env) == []
      end
    end

    test "negative start_index after normalize greater than end_index" do
      list = [1, 2, 3, 4, 5, 6]
      env = env_for_slice(start_index: -3, end_index: 2)
      assert SliceOperator.evaluate(list, [], env) == []
    end

    test "positve start_index greater than end_index" do
      list = [1, 2, 3, 4, 5, 6]
      env = env_for_slice(start_index: 4, end_index: 2)
      assert SliceOperator.evaluate(list, [], env) == []
    end
  end

  describe "slice step configuration" do
    property "missing, the value 1 is assumed as a default value" do
      check all(list <- list_of(term(), min_length: 1)) do
        elements =
          list
          |> Stream.with_index()
          |> Enum.map(&element/1)

        assert SliceOperator.evaluate(list, [], env_for_slice()) == elements
      end
    end

    test "should be used when supplied a positive step" do
      document = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

      assert [1, 3, 5] == Warpath.query!(document, "$[1:7:2]")
    end

    test "should be used when supplied a negative step" do
      document = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

      assert [5, 3, 1] == Warpath.query!(document, "$[7:1:-2]")
    end

    test "when negative, start less then end index result in empty list" do
      document = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

      assert [] == Warpath.query!(document, "$[1:2:-2]")
    end

    test "with negative step only" do
      document = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

      assert Enum.reverse(document) == Warpath.query!(document, "$[::-1]")
    end
  end

  test "evaluate/3 is nil safe traverse" do
    assert SliceOperator.evaluate(nil, [], env_for_slice()) == []
  end
end
