alias Warpath.Element
alias Warpath.Element.Path, as: ElementPath
alias Warpath.Execution.Env
alias Warpath.Query.Accessible
alias Warpath.Query.IndexOperator
alias Warpath.Query.DescendantOperator
alias Warpath.Query.FilterOperator
alias Warpath.Query.IdentifierOperator
alias Warpath.Query.UnionOperator
alias Warpath.Query.WildcardOperator

defprotocol IdentifierOperator do
  @type document :: Element.t() | map | list
  @type relative_path :: ElementPath.t() | []
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document, relative_path, Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl IdentifierOperator, for: Map do
  def evaluate(document, relative_path, %Env{instruction: instruction}) do
    {:dot, {:property, identifier} = token} = instruction
    path = ElementPath.accumulate(token, relative_path)

    document
    |> Access.get(identifier)
    |> Element.new(path)
  end
end

defimpl IdentifierOperator, for: List do
  @previous_operators_allowed [
    IndexOperator,
    DescendantOperator,
    FilterOperator,
    UnionOperator,
    WildcardOperator
  ]

  def evaluate(elements, [], %Env{previous_operator: %Env{operator: previous_operator}} = env)
      when previous_operator in @previous_operators_allowed do
    {:dot, {:property, key}} = env.instruction

    elements
    |> Stream.filter(&accessible_with_key?(&1, key))
    |> Enum.map(fn %Element{value: document, path: path} ->
      IdentifierOperator.Map.evaluate(document, path, env)
    end)
  end

  def evaluate(elements, relative_path, %Env{instruction: instruction} = env) do
    unless Keyword.keyword?(elements) do
      {:dot, {:property, name} = token} = instruction

      wrong_query =
        token
        |> ElementPath.accumulate(relative_path)
        |> ElementPath.dotify()

      tips =
        "You are trying to traverse a list using dot " <>
          "notation '#{wrong_query}', that it's not allowed for list type. " <>
          "You can use something like '#{ElementPath.dotify(relative_path)}[*].#{name}' instead."

      raise Warpath.UnsupportedOperationError, tips
    end

    case elements do
      [] -> []
      keyword -> IdentifierOperator.Map.evaluate(keyword, relative_path, env)
    end
  end

  defp accessible_with_key?(%Element{value: value}, key), do: Accessible.has_key?(value, key)
end
