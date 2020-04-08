defprotocol RootOperator do
  @fallback_to_any true

  @type result :: Element.t()
  @type root_path :: []

  @spec evaluate(Element.t(), [root_path()], Env.t()) :: result()
  def evaluate(document, root_path, env)
end

defimpl RootOperator, for: Any do
  @token {:root, "$"}

  def evaluate(document, _root_path, _env), do: Element.new(document, [@token])
end
