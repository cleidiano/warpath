defprotocol UnionOperator do
  @fallback_to_any true

  @type result :: Element.t()
  @type root_path :: []

  @spec evaluate(Element.t(), [root_path()], Env.t()) :: result()
  def evaluate(document, root_path, env)
end
