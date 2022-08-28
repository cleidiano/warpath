alias Warpath.Element
alias Warpath.Execution.Env
alias Warpath.Expression
alias Warpath.Query.SliceOperator

defprotocol SliceOperator do
  @moduledoc false

  @fallback_to_any true

  @type document :: list()

  @type relative_path :: Element.Path.acc()

  @type instruction :: Expression.slice()

  @type env :: %Env{instruction: instruction}

  @type result :: [Element.t()]

  @spec evaluate(document, relative_path(), env) :: [Element.t()]
  def evaluate(list, relative_path, env)
end

defimpl SliceOperator, for: List do
  def evaluate(elements, relative_path, %Env{instruction: {:slice, slice_args}}) do
    {first, last, step} = slice_config(elements, slice_args)

    case build_range(first, last) do
      {:range, range} ->
        elements
        |> Element.elementify(relative_path)
        |> Stream.with_index()
        |> Enum.slice(range)
        |> Enum.take_every(step)
        |> Enum.map(fn {element, _index} -> element end)

      _ ->
        []
    end
  end

  defp build_range(first, last) do
    if first > last do
      {:empty_range?, true}
    else
      {:range, Range.new(first, last)}
    end
  end

  defp slice_config(elements, slice_ops) when is_list(elements) do
    start = start_index(elements, slice_ops)
    end_index = end_index(elements, slice_ops)
    step = step(slice_ops)

    {start, end_index, step}
  end

  defp step(slice), do: Keyword.get(slice, :step, 1)

  defp start_index(elements, slice) do
    case Keyword.get(slice, :start_index, 0) do
      start when start >= 0 ->
        start

      start ->
        max(length(elements) + start, 0)
    end
  end

  defp end_index(elements, slice) do
    end_index =
      case Keyword.get_lazy(slice, :end_index, fn -> length(elements) end) do
        index when index >= 0 -> index
        index -> index + length(elements)
      end

    # end_index exclusive.
    end_index - 1
  end
end

defimpl SliceOperator, for: Any do
  def evaluate(_, _, _), do: []
end
