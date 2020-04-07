defprotocol RootOperator do
  @fallback_to_any true

  @type document :: map() | list()
  @type relative_path :: Warpath.Element.Path.t()
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document(), relative_path(), Env.t()) :: result()
  def evaluate(data, path, env)

  @spec evaluate(Element.t(), Env.t()) :: result()
  def evaluate(element, env)
end

defimpl RootOperator, for: Any do
  @token {:root, "$"}
  def evaluate(data, path, _env), do: element_of(data, path)
  def evaluate(%Element{value: value, path: path}, _env), do: element_of(value, path)

  defp element_of(data, []) do
    Element.new(data, [@token])
  end
end
