alias Warpath.Element
alias Warpath.Expression
alias Warpath.Element.Path
alias Warpath.Element.PathMarker
alias Warpath.Execution.Env
alias Warpath.Filter.Predicate
alias Warpath.Query.FilterOperator

defprotocol FilterOperator do
  @moduledoc false

  @fallback_to_any true

  @type document :: map() | list()

  @type relative_path :: Path.acc()

  @type instruction :: Expression.filter()

  @type env :: %Env{instruction: instruction}

  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document, relative_path(), env) :: result()
  def evaluate(document, relative_path, env)
end

defimpl FilterOperator, for: List do
  def evaluate([%Element{} | _] = elements, [], %Env{} = env) do
    Enum.flat_map(
      elements,
      fn %Element{value: value, path: path} ->
        FilterOperator.evaluate(value, path, env)
      end
    )
  end

  def evaluate(document, relative_path, %Env{instruction: {:filter, filter_expression}}) do
    document
    |> Element.new(relative_path)
    |> PathMarker.stream()
    |> Enum.filter(fn %Element{value: value} -> Predicate.eval(filter_expression, value) end)
  end
end

defimpl FilterOperator, for: Map do
  def evaluate(document, relative_path, %Env{instruction: {:filter, filter_expression}}) do
    if Predicate.eval(filter_expression, document),
      do: [Element.new(document, relative_path)],
      else: []
  end
end

defimpl FilterOperator, for: Any do
  def evaluate(_, _, _), do: []
end
