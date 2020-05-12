defmodule Warpath.Query.RootOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.RootOperator

  @relative_path [{:root, "$"}]

  defp env_for_root() do
    Env.new({:root, "$"})
  end

  property "create element for any term" do
    check all term <- term() do
      element = Element.new(term, @relative_path)

      assert RootOperator.evaluate(term, [], env_for_root()) == element
    end
  end
end
