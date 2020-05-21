alias Warpath.Element
alias Warpath.Element.PathMarker
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
  def evaluate(elements, relative_path, %Env{instruction: {:array_slice, slice_args}}) do
    with {:empty_range?, false} <- {:empty_range?, empty_range?(slice_args)},
         {:config, {step, %Range{} = range}} <- {:config, slice_config(elements, slice_args)} do
      elements
      |> Element.new(relative_path)
      |> do_slice(range, step)
    else
      {:empty_range?, true} ->
        []
    end
  end

  defp empty_range?(slice_args) do
    with {:ok, start_index} <- Keyword.fetch(slice_args, :start_index),
         {:ok, end_index} <- Keyword.fetch(slice_args, :end_index) do
      start_index == end_index
    else
      _ -> false
    end
  end

  defp slice_config(elements, slice_ops) when is_list(elements) do
    start = start_index(elements, slice_ops)
    end_index = end_index(elements, slice_ops)
    step = step(slice_ops)

    {step, Range.new(start, end_index - 1)}
  end

  defp step(slice), do: Keyword.get(slice, :step, 1)

  defp start_index(elements, slice) do
    case Keyword.get(slice, :start_index, 0) do
      start when start >= 0 ->
        start

      start ->
        max(-length(elements), start)
    end
  end

  defp end_index(element, slice) do
    Keyword.get_lazy(slice, :end_index, fn -> length(element) end)
  end

  defp do_slice(element, range, step) do
    element
    |> PathMarker.stream()
    |> Stream.with_index()
    |> Enum.slice(range)
    |> Stream.reject(fn {_, index} -> rem(index, step) != 0 end)
    |> Enum.map(fn {element, _index} -> element end)
  end
end

defimpl SliceOperator, for: Any do
  def evaluate(_, _, _), do: []
end
