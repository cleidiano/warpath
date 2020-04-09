alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.PathMarker

defprotocol SliceOperator do
  @type relative_path :: Warpath.Element.Path.t()
  @type result :: [Element.t()]

  @spec evaluate(list(), relative_path(), Env.t()) :: [Element.t()]
  def evaluate(list, relative_path, env)
end

defimpl SliceOperator, for: List do
  def evaluate([%Element{} | _] = elements, [], %Env{instruction: {:array_slice, slice}}) do
    {step, range} = slice_config(elements, slice)
    do_slice(elements, range, step)
  end

  def evaluate(elements, relative_path, %Env{instruction: {:array_slice, slice}}) do
    {step, range} = slice_config(elements, slice)

    elements
    |> Element.new(relative_path)
    |> do_slice(range, step)
  end

  defp do_slice(elements, range, step) do
    empty_range? = Enum.count(range) - 1 <= 0

    unless empty_range? do
      elements
      |> PathMarker.stream()
      |> Stream.with_index()
      |> Enum.slice(range)
      |> Stream.reject(fn {_, index} -> rem(index, step) != 0 end)
      |> Enum.map(fn {element, _index} -> element end)
    else
      []
    end
  end

  defp slice_config(elements, slice_ops) do
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
