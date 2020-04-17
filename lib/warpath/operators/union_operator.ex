alias Warpath.Element
alias Warpath.ExecutionEnv, as: Env

defprotocol UnionOperator do
  @type result :: [Element.t()]
  @type relative_path :: Warpath.Element.Path.t()

  @spec evaluate(Element.t(), relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl UnionOperator, for: Map do
  def evaluate(document, relative_path, %Env{instruction: {:union, properties}}) do
    properties
    |> Enum.flat_map(fn {:dot, {:property, property}} = inst ->
      if Map.has_key?(document, property) do
        new_env = Env.new(IdentifierOperator, inst)
        [IdentifierOperator.Map.evaluate(document, relative_path, new_env)]
      else
        []
      end
    end)
  end
end

defimpl UnionOperator, for: List do
  def evaluate(elements, [], env) do
    elements
    |> Enum.flat_map(fn %Element{value: value, path: path} ->
      UnionOperator.evaluate(value, path, env)
    end)
  end
end
