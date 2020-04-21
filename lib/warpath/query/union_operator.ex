alias Warpath.Element
alias Warpath.Execution.Env
alias Warpath.Query.UnionOperator
alias Warpath.Query.IdentifierOperator

defprotocol UnionOperator do
  @type result :: [Element.t()]
  @type relative_path :: Warpath.Element.Path.t()

  @spec evaluate(Element.t(), relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl UnionOperator, for: Map do
  def evaluate(document, relative_path, %Env{instruction: {:union, properties}}) do
    properties
    |> Stream.filter(&has_property?(document, &1))
    |> Enum.map(fn property_query ->
      new_env = Env.new(property_query)
      IdentifierOperator.Map.evaluate(document, relative_path, new_env)
    end)
  end

  defp has_property?(map, {:dot, {:property, property}}),
    do: Map.has_key?(map, property)
end

defimpl UnionOperator, for: List do
  def evaluate(elements, [], env) do
    Enum.flat_map(
      elements,
      fn %Element{value: value, path: path} ->
        UnionOperator.evaluate(value, path, env)
      end
    )
  end
end
