alias Warpath.Element
alias Warpath.Execution.Env
alias Warpath.Expression
alias Warpath.Query.Accessible
alias Warpath.Query.UnionOperator
alias Warpath.Query.IdentifierOperator

defprotocol UnionOperator do
  @moduledoc false

  @fallback_to_any true

  @type document :: map() | struct() | keyword() | list(Element.t()) | nil

  @type result :: [Element.t()]

  @type relative_path :: Element.Path.acc()

  @type instruction :: Expression.union_property()

  @type env :: %Env{instruction: instruction}

  @spec evaluate(document, relative_path(), env) :: result()
  def evaluate(document, relative_path, env)
end

defimpl UnionOperator, for: Map do
  def evaluate(document, relative_path, %Env{instruction: {:union, properties}}) do
    properties
    |> Stream.filter(&has_property?(document, &1))
    |> Enum.map(fn property_query ->
      new_env = Env.new(property_query)
      IdentifierOperator.evaluate(document, relative_path, new_env)
    end)
  end

  defp has_property?(document, {:dot, {:property, property}}),
    do: Accessible.has_key?(document, property)
end

defimpl UnionOperator, for: List do
  def evaluate([%Element{} | _] = elements, [], env) do
    Enum.flat_map(
      elements,
      fn %Element{value: value, path: path} ->
        UnionOperator.evaluate(value, path, env)
      end
    )
  end

  def evaluate(document, relative_path, env) do
    if Accessible.accessible?(document),
      do: UnionOperator.Map.evaluate(document, relative_path, env),
      else: []
  end
end

defimpl UnionOperator, for: Any do
  def evaluate(%_{} = struct, relative_path, env) do
    struct
    |> Map.from_struct()
    |> UnionOperator.Map.evaluate(relative_path, env)
  end

  def evaluate(_, _, _), do: []
end
