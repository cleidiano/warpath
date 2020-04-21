defmodule Warpath.Query.RootOperator do
  @moduledoc false

  alias Warpath.Element
  alias Warpath.Execution.Env

  @token {:root, "$"}

  @type result :: Element.t()
  @type root_path :: []

  @spec evaluate(Element.t(), [root_path()], Env.t()) :: result()
  def evaluate(document, _root_path, _env), do: Element.new(document, [@token])
end
