alias Warpath.Element
alias Warpath.Element.Path, as: ElementPath
alias Warpath.Execution.Env

defprotocol ArrayIndexOperator do
  @fallback_to_any true

  @type document :: list()
  @type relative_path :: ElementPath.t()
  @type result :: Element.t() | [Element.t()]
  @type instruction :: {:array_indexes, list({:index, integer()})}
  @type env :: %Env{instruction: instruction()}

  @spec evaluate(document(), relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl ArrayIndexOperator, for: List do
  def evaluate(elements, [], %Env{
        instruction: {:array_indexes, [index]},
        previous_operator: %Env{operator: WildcardOperator}
      }) do
    elements
    |> Stream.filter(&Element.value_list?/1)
    |> Enum.flat_map(fn %Element{value: list, path: path} ->
      value_for_indexes(list, path, [index])
    end)
  end

  def evaluate(document, path, %Env{instruction: {:array_indexes, [index]}}) do
    case value_for_indexes(document, path, [index]) do
      [] ->
        []

      [element] ->
        element
    end
  end

  def evaluate(document, path, %Env{instruction: {:array_indexes, indexes}}) do
    value_for_indexes(document, path, indexes)
  end

  defp value_for_indexes(list, path, indexes) do
    max_index = Enum.count(list) - 1

    indexes
    |> Stream.reject(fn {:index_access, index} -> index > max_index end)
    |> Enum.map(fn {:index_access, index} = token ->
      item_path = ElementPath.accumulate(token, path)

      list
      |> Enum.at(index)
      |> Element.new(item_path)
    end)
  end
end

defimpl ArrayIndexOperator, for: Any do
  def evaluate(_, _, _), do: []
end
