defprotocol IdentifierOperator do
  @spec evaluate(map, list(), Warpath.ExecutionEnv.t()) :: any
  def evaluate(data, path, env)

  @spec evaluate(Element.t(), Warpath.ExecutionEnv.t()) :: any
  def evaluate(element, env)
end

defimpl IdentifierOperator, for: Map do
  alias Warpath.Element.Path, as: Tracer
  alias Warpath.ExecutionEnv, as: Env

  @spec evaluate(map, list, Env.t()) :: Element.t()
  def evaluate(data, relative_path, %{instruction: {:dot, {:property, identifier} = token}}) do
    path = Tracer.accumulate(token, relative_path)

    data
    |> Access.get(identifier)
    |> Element.new(path)
  end

  @spec evaluate(Element.t(), Env.t()) :: Element.t()
  def evaluate(%Element{value: value, path: relative_path}, env) do
    evaluate(value, relative_path, env)
  end
end
