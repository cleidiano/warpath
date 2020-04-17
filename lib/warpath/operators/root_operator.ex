alias Warpath.Element

defmodule RootOperator do
  @moduledoc false

  @token {:root, "$"}

  @type result :: Element.t()
  @type root_path :: []

  @spec evaluate(Element.t(), [root_path()], Env.t()) :: result()
  def evaluate(document, _root_path, _env), do: Element.new(document, [@token])
end
