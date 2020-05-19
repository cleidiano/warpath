defmodule Warpath.Query.RootOperator do
  @moduledoc false

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Expression

  @token {:root, "$"}

  @type document :: any()

  @type instruction :: Expression.root()

  @type env :: %Env{instruction: instruction}

  @type result :: Element.t()

  @spec evaluate(document, [], env) :: result()
  def evaluate(document, [], _env), do: Element.new(document, [@token])
end
