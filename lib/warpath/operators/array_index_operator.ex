alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.Path, as: ElementPath

defprotocol ArrayIndexOperator do
  @type document :: list()

  @type relative_path :: ElementPath.t()

  @type result :: Element.t() | [Element.t()]

  @type instruction :: {:array_indexes, list({:index, integer()})}

  @type env :: %Env{instruction: instruction()}

  @spec evaluate(document(), relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl ArrayIndexOperator, for: List do
  alias Warpath.Element.Path

  def evaluate(document, path, %Env{instruction: {:array_indexes, [index]}}) do
    result = value_for_indexes(document, path, [index])

    case result do
      [element] ->
        element

      [] ->
        message =
          "The query should be resolved to scalar value " <>
            "but the index #{inspect(index)} is out of bounds for emum #{inspect(document)}."

        raise Enum.OutOfBoundsError, message
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
      item_path = Path.accumulate(token, path)

      list
      |> Enum.at(index)
      |> Element.new(item_path)
    end)
  end
end
