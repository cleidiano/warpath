alias Warpath.Element
alias Warpath.Element.Path, as: ElementPath
alias Warpath.Element.PathMarker
alias Warpath.Execution.Env

defprotocol WildcardOperator do
  @fallback_to_any true

  @type document :: map() | list()
  @type relative_path :: [] | ElementPath.t()
  @type result :: [Element.t()]

  @spec evaluate(document(), relative_path, Env.t()) :: [Element.t()]
  def evaluate(document, relative_path, env)
end

defimpl WildcardOperator, for: Map do
  def evaluate(document, relative_path, _env) do
    document
    |> Element.new(relative_path)
    |> PathMarker.stream()
    |> Enum.to_list()
  end
end

defimpl WildcardOperator, for: List do
  def evaluate([%Element{} | _] = elements, [], env) do
    Enum.flat_map(elements, fn %Element{value: value, path: path} ->
      WildcardOperator.evaluate(value, path, env)
    end)
  end

  def evaluate(itens, relative_path, _env) do
    itens
    |> Element.new(relative_path)
    |> PathMarker.stream()
    |> Enum.to_list()
  end
end

defimpl WildcardOperator, for: Any do
  def evaluate(_element, _path, _), do: []
end
