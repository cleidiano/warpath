defprotocol WildcardOperator do
  @fallback_to_any true
  def evaluate(document, relative_path, env)
  def evaluate(element, env)
end

defimpl WildcardOperator, for: [Map, List] do
  alias Warpath.Element.PathMarker

  def evaluate(document, relative_path, _env) do
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
