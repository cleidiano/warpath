defmodule Warpath.Query.CurrentNodeOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.CurrentNodeOperator

  defp current_node do
    Env.new({:current_node, "@"})
  end

  property "create element for any term" do
    check all term <- term() do
      element = Element.new(term, [])

      assert CurrentNodeOperator.evaluate(term, [], current_node()) == element
    end
  end

  test "evaluate/3 is nil safe" do
    assert CurrentNodeOperator.evaluate(nil, [], current_node()) == Element.new(nil, [])
  end
end
