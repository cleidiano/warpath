alias Warpath.Element
alias Warpath.Execution.Env
alias Warpath.Expression
alias Warpath.Query.Accessible
alias Warpath.Query.IdentifierOperator

defprotocol IdentifierOperator do
  @moduledoc false

  @fallback_to_any true

  @type document :: map() | struct() | keyword() | list(Element.t()) | nil

  @type relative_path :: Element.Path.acc() | []

  @type instruction :: Expression.dot_access()

  @type env :: %Env{instruction: instruction}

  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document, relative_path, env) :: result()
  def evaluate(document, relative_path, env)
end

defimpl IdentifierOperator, for: Map do
  def evaluate(document, relative_path, %Env{instruction: instruction}) do
    {:dot, {:property, identifier} = token} = instruction

    if Accessible.has_key?(document, identifier) do
      path = Element.Path.accumulate(token, relative_path)

      document
      |> Map.get(identifier)
      |> Element.new(path)
    else
      Element.new(nil, [])
    end
  end
end

defimpl IdentifierOperator, for: List do
  def evaluate([%Element{} | _] = elements, [], env) do
    {:dot, {:property, key}} = env.instruction

    elements
    |> Stream.filter(&accessible_with_key?(&1, key))
    |> Enum.map(fn %Element{value: document, path: path} ->
      IdentifierOperator.evaluate(document, path, env)
    end)
  end

  def evaluate(elements, relative_path, env) do
    case {elements, Keyword.keyword?(elements)} do
      {_, false} ->
        Element.new(nil, [])

      {keyword, true} ->
        keyword
        |> Map.new()
        |> IdentifierOperator.Map.evaluate(relative_path, env)
    end
  end

  defp accessible_with_key?(%Element{value: value}, key), do: Accessible.has_key?(value, key)
end

defimpl IdentifierOperator, for: Any do
  def evaluate(%_{} = struct, relative_path, env) do
    struct
    |> Map.from_struct()
    |> IdentifierOperator.Map.evaluate(relative_path, env)
  end

  def evaluate(_struct, _path, _env) do
    Element.new(nil, [])
  end
end
