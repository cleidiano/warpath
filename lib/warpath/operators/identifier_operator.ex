alias Warpath.Element.Path, as: ElementPath
alias Warpath.ExecutionEnv, as: Env

defprotocol IdentifierOperator do
  @type document :: map() | list()
  @type relative_path :: ElementPath.t()
  @type element :: %Element{value: document(), path: relative_path()}
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document(), relative_path(), Env.t()) :: result()
  def evaluate(data, path, env)

  @spec evaluate(Element.t(), Env.t()) :: result()
  def evaluate(element, env)
end

defimpl IdentifierOperator, for: [Map, Element] do
  def evaluate(data, relative_path, %{instruction: {:dot, {:property, identifier} = token}}) do
    path = ElementPath.accumulate(token, relative_path)

    data
    |> Access.get(identifier)
    |> Element.new(path)
  end

  def evaluate(%Element{value: value, path: relative_path}, env) do
    evaluate(value, relative_path, env)
  end
end
