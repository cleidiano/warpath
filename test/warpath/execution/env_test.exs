defmodule Warpath.Execution.EnvTest do
  use ExUnit.Case, async: true

  alias Warpath.Execution.Env
  alias Warpath.Query.DescendantOperator
  alias Warpath.Query.FilterOperator
  alias Warpath.Query.IdentifierOperator
  alias Warpath.Query.IndexOperator
  alias Warpath.Query.RootOperator
  alias Warpath.Query.SliceOperator
  alias Warpath.Query.UnionOperator
  alias Warpath.Query.WildcardOperator

  defp assert_env(instruction, operator, previous_operator \\ nil, metadata \\ %{}) do
    env = Env.new(instruction, previous_operator, metadata)

    assert env.metadata == metadata
    assert env.operator == operator
    assert env.instruction == instruction
    assert env.previous_operator == previous_operator
  end

  describe "new/3 properly bind operator handler for" do
    test ":root instruction token" do
      assert_env {:root, "$"}, RootOperator
    end

    test ":dot instruction token" do
      assert_env {:dot, {:property, :name}}, IdentifierOperator
    end

    test ":wildcard instruction token" do
      assert_env {:wildcard, :*}, WildcardOperator
    end

    test ":scan instruction token" do
      assert_env {:scan, {:property, :name}}, DescendantOperator
    end

    test ":indexes instruction token" do
      assert_env {:indexes, [{:index_access, 0}]}, IndexOperator
    end

    test ":filter instruction token" do
      assert_env {:filter, {:has_children?, [{:subpath_expression, property: :name}]}},
                 FilterOperator
    end

    test ":slice instruction token" do
      assert_env {:slice,
                  [
                    {:start_index, 0},
                    {:end_index, 5},
                    {:step, 1}
                  ]},
                 SliceOperator
    end

    test ":union instruction token" do
      assert_env {:union, [{:property, :name}, {:property, :surname}]}, UnionOperator
    end
  end

  test "new/1" do
    assert Env.new({:root, "$"}) == %Env{
             operator: RootOperator,
             previous_operator: nil,
             metadata: %{},
             instruction: {:root, "$"}
           }
  end

  test "new/3" do
    assert_env {:wildcard, :*},
               _operator = WildcardOperator,
               _previous = RootOperator,
               _metadata = %{anything: :value}
  end
end
