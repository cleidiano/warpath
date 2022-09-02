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
    length = length(elements)
    {start_index, end_index, step} = arguments_or_defaults(slice_args, length)

    {lower, upper} = bounds(start_index, end_index, step, length)

    slice(elements, relative_path, {lower, upper, step})
  end

  defp arguments_or_defaults(args, length) do
    step = Keyword.get(args, :step, 1)

    {default_start, default_end} =
      if step >= 0 do
        {0, length}
      else
        {length, 0}
      end

    start_index = Keyword.get(args, :start_index, default_start)
    end_index = Keyword.get(args, :end_index, default_end)

    {start_index, end_index, step}
  end

  defp slice(_, _, {_, _, 0}), do: []

  defp slice(elements, relative_path, {lower, upper, step}) do
    itens =
      elements
      |> Element.elementify(relative_path)
      |> Stream.with_index()
      |> Stream.drop(lower)
      |> Stream.transform([], fn {element, index}, acc ->
        case select?(index, lower, upper) do
          {:cont, true} -> {[element], nil}
          {:cont, false} -> {[], nil}
          {:halt, _} -> {:halt, acc}
        end
      end)
      |> Enum.take_every(abs(step))

    if step > 0, do: itens, else: Enum.reverse(itens)
  end

  defp bounds(start_index, end_index, step, length) do
    normalized_start = normalize_index(start_index, length)
    normalized_end = normalize_index(end_index, length)

    if step >= 0 do
      lower = min(max(normalized_start, 0), length)
      upper = min(max(normalized_end, 0), length)
      {lower, upper}
    else
      upper = min(max(normalized_start, -1), length)
      lower = min(max(normalized_end, -1), length - 1)

      {lower, upper}
    end
  end

  defp normalize_index(i, len) do
    if i >= 0, do: i, else: len + i
  end

  defp select?(index, lower, upper) when index >= lower and index < upper, do: {:cont, true}
  defp select?(index, lower, _upper) when index < lower, do: {:cont, false}
  defp select?(_, _, _), do: {:halt, false}
end

defimpl SliceOperator, for: Any do
  def evaluate(_, _, _), do: []
end
