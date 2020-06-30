alias Warpath.Element
alias Warpath.Expression
alias Warpath.Execution.Env
alias Warpath.Query.IndexOperator

defprotocol IndexOperator do
  @moduledoc false

  @fallback_to_any true

  @type document :: list()

  @type relative_path :: Element.Path.acc()

  @type result :: Element.t() | [Element.t()]

  @type instruction :: Expression.indexes()

  @type env :: %Env{instruction: instruction()}

  @spec evaluate(document(), relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl IndexOperator, for: List do
  def evaluate([%Element{} | _] = elements, [], %Env{instruction: {:indexes, indexes}}) do
    elements
    |> Stream.filter(&Element.value_list?/1)
    |> Enum.flat_map(fn %Element{value: list, path: path} ->
      value_for_indexes(list, path, indexes)
    end)
  end

  def evaluate(document, path, %Env{instruction: {:indexes, [index]}}) do
    if out_of_bound?(index, document) do
      Element.new(nil, Element.Path.accumulate(index, path))
    else
      [element] = value_for_indexes(document, path, [index])
      element
    end
  end

  def evaluate(document, path, %Env{instruction: {:indexes, indexes}}) do
    value_for_indexes(document, path, indexes)
  end

  defp value_for_indexes(list, path, indexes) do
    indexes
    |> Stream.reject(&out_of_bound?(&1, list))
    |> Enum.map(fn {:index_access, index} ->
      {term, item_index} =
        list
        |> Stream.with_index()
        |> Enum.at(index)

      Element.new(term, Element.Path.accumulate({:index_access, item_index}, path))
    end)
  end

  defp out_of_bound?({:index_access, _}, []), do: true
  defp out_of_bound?({:index_access, index}, list) when index >= 0, do: index >= length(list)

  defp out_of_bound?({:index_access, index}, list) do
    count = length(list)
    computed_index = count + index
    computed_index < 0
  end
end

defimpl IndexOperator, for: Any do
  def evaluate(_, path, %Env{instruction: {:indexes, [index]}}) do
    Element.new(nil, Element.Path.accumulate(index, path))
  end

  def evaluate(_, _, _), do: []
end
