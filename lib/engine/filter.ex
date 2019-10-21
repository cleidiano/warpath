defmodule Warpath.Engine.Filter do
  @relation_fun [:>, :<, :==]

  def filter(data, {{:property, property}, operator, operand}, trace)
      when is_list(data) and operator in @relation_fun do
    filter_fun = fn item -> apply(Kernel, operator, [item[property], operand]) end
    do_filter(data, filter_fun, trace)
  end

  def filter(data, {:contains, {:property, property}}, trace) when is_list(data) do
    do_filter(data, &Map.has_key?(&1, property), trace)
  end

  defp do_filter(data, filter_fun, trace) do
    data
    |> Stream.with_index()
    |> Stream.filter(fn {term, _index} -> filter_fun.(term) end)
    |> Stream.map(fn {term, index} -> {term, [{:index_access, index} | trace]} end)
    |> Enum.to_list()
  end
end
