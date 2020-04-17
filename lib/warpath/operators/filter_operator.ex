alias Warpath.Element
alias Warpath.Element.Path
alias Warpath.Execution.Env
alias Warpath.FilterElement, as: Filter

defprotocol FilterOperator do
  @fallback_to_any true

  @type document :: map() | list()
  @type relative_path :: Path.t()
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document, relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl FilterOperator, for: [Map, List] do
  def evaluate(elements, [], %Env{instruction: {:filter, expression}}) when is_list(elements) do
    Filter.filter(elements, expression)
  end

  def evaluate(document, relative_path, %Env{instruction: {:filter, filter_exp}}) do
    document
    |> Element.new(relative_path)
    |> Filter.filter(filter_exp)
  end
end

defimpl FilterOperator, for: Any do
  def evaluate(_, _, _), do: []
end
