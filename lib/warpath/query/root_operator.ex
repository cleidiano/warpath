defmodule Warpath.Query.RootOperator do
  @moduledoc false

  alias Warpath.Element
  alias Warpath.Execution.Env

  @token {:root, "$"}

  @type result :: Element.t()
  @type root_path :: [{:root, String.t()}]

  @spec evaluate(Element.t(), [], Env.t()) :: result()
  def evaluate(document, [], _env), do: Element.new(document, [@token])
end
