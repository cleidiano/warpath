alias Warpath.Element.Path, as: ElementPath
alias Warpath.ExecutionEnv, as: Env

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
    ArrayIndexOperator,
    FilterOperator,
    UnionOperator,
    WildcardOperator
  ]

  def evaluate(elements, [], %Env{previous_operator: %Env{operator: previous_operator}} = env)
      when previous_operator in @previous_operators_allowed do
    {:dot, {:property, key}} = env.instruction

    Enum.flat_map(elements, fn %Element{value: document, path: path} ->
      if Map.has_key?(document, key),
        do: [IdentifierOperator.Map.evaluate(document, path, env)],
        else: []
    end)
  end

  def evaluate(keyword, relative_path, %Env{instruction: instruction} = env) do
    unless Keyword.keyword?(keyword) do
      {:dot, {:property, name} = token} = instruction

      tips =
        "You are trying to traverse a list using dot " <>
          "notation '#{ElementPath.accumulate(token, relative_path) |> ElementPath.dotify()}', " <>
          "that it's not allowed for list type. " <>
          "You can use something like '#{ElementPath.dotify(relative_path)}[*].#{name}' instead."

      raise Warpath.UnsupportedOperationError, tips
    end

    IdentifierOperator.Map.evaluate(keyword, relative_path, env)
  end
end

defimpl IdentifierOperator, for: Element do
  def evaluate(%Element{value: value, path: path}, _empty, env) do
    IdentifierOperator.evaluate(value, path, env)
  end
end
