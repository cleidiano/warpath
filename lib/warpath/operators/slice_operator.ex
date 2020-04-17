alias Warpath.Element
alias Warpath.Element.PathMarker
alias Warpath.Execution.Env

defprotocol SliceOperator do
  @fallback_to_any true

  @type relative_path :: Warpath.Element.Path.t()
  @type result :: [Element.t()]

  @spec evaluate(list(), relative_path(), Env.t()) :: [Element.t()]
  def evaluate(list, relative_path, env)
end

defimpl SliceOperator, for: List do
  def evaluate(elements, relative_path, %Env{instruction: {:array_slice, slice_args}}) do
    elements
    |> Element.new(relative_path)
    |> do_slice(slice_args, empty_range?(slice_args))
  end

  defp empty_range?(slice_args) do
    with {:ok, start_index} <- Keyword.fetch(slice_args, :start_index),
         {:ok, end_index} <- Keyword.fetch(slice_args, :end_index) do
      start_index == end_index
    else
      _ -> false
    end
  end

  defp do_slice(_elements, _slice_args, true), do: []

  defp do_slice(element, slice_args, false) do
    {step, range} = slice_config(element, slice_args)

    element
    |> PathMarker.stream()
    |> Stream.with_index()
    |> Enum.slice(range)
    |> Stream.reject(fn {_, index} -> rem(index, step) != 0 end)
    |> Enum.map(fn {element, _index} -> element end)
  end

  defp slice_config(%Element{value: elements}, slice_ops) do
    start_index = slice_start_index(elements, slice_ops)
    end_index = slice_end_index(elements, slice_ops)
    step = slice_step(slice_ops)

    {step, Range.new(start_index, end_index - 1)}
  end

  defp slice_step(slice), do: Keyword.get(slice, :step, 1)

  defp slice_start_index(elements, slice) do
    start = Keyword.get(slice, :start_index, 0)

    if start < 0, do: max(-length(elements), start), else: start
  end

  defp slice_end_index(element, slice) do
    Keyword.get_lazy(slice, :end_index, fn -> length(element) end)
  end
end

defimpl SliceOperator, for: Any do
  def evaluate(_, _, _), do: []
end
