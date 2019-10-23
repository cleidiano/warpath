defmodule Warpath.Engine.Filter do
  @operators [:>, :<, :==]

  # TODO Join data and trace on tuple
  def filter(data, {{:property, property}, operator, operand}, trace)
      when operator in @operators do
    filter_fun = fn item ->
      apply(Kernel, operator, [item[property], operand])
    end

    do_filter(data, filter_fun, trace)
  end

  def filter(data, {:contains, {:property, property}}, trace),
    do: do_filter(data, &Map.has_key?(&1, property), trace)

  defp do_filter(data, filter_fun, trace) when is_map(data),
    do: if(filter_fun.(data), do: [{data, trace}], else: [])

  defp do_filter(data, filter_fun, trace) when is_list(data) do
    data
    |> Stream.with_index()
    |> Stream.filter(fn {term, _index} -> filter_fun.(term) end)
    |> Stream.map(fn {term, index} -> {term, [{:index_access, index} | trace]} end)
    |> Enum.to_list()
  end

  defp do_filter(_data, _, _), do: []
end
