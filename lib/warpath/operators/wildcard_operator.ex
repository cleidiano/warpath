alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.Path, as: ElementPath

defprotocol WildcardOperator do
  @fallback_to_any true

  @type document :: map() | list()
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document(), ElementPath.t(), Env.t()) :: result
  def evaluate(document, relative_path, env)

  @spec evaluate(Element.t(), Env.t()) :: Element.t() | [Element.t()]
  def evaluate(element, env)
end

defimpl WildcardOperator, for: [Map, Element, List] do
  alias Warpath.Element.PathMarker

  defguardp is_document(doc) when is_map(doc) or is_list(doc)

  def evaluate(document, relative_path, _env) when is_document(document) do
    {document, relative_path}
    |> PathMarker.stream()
    |> Enum.map(&Element.new/1)
  end

  def evaluate(%Element{value: document, path: relative_path}, env) do
    WildcardOperator.evaluate(document, relative_path, env)
  end
end

defimpl WildcardOperator, for: Any do
  def evaluate(_, _, _), do: []
  def evaluate(_, _), do: []
end
