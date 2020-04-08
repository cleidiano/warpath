alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.Path, as: ElementPath

defprotocol WildcardOperator do
  @fallback_to_any true

  @type document :: map() | list()
  @type relative_path :: ElementPath.t()
  @type result :: [Element.t()]

  @spec evaluate(document(), relative_path, Env.t()) :: [Element.t()]
  def evaluate(document, relative_path, env)
end

defimpl WildcardOperator, for: [Map, List] do
  alias Warpath.Element.PathMarker

  def evaluate(document, relative_path, _env) do
    {document, relative_path}
    |> PathMarker.stream()
    |> Enum.map(&Element.new/1)
  end
end

defimpl WildcardOperator, for: Any do
  def evaluate(_, _, _), do: []
end
