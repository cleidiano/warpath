defmodule Warpath.Engine.Trace do
  def stream({data, trace}) when is_list(data) do
    data
    |> Stream.with_index()
    |> Stream.map(fn {term, index} -> {term, [{:index_access, index} | trace]} end)
  end

  def stream({data, trace}) when is_map(data) do
    Stream.map(data, fn {k, v} -> {v, [{:property, k} | trace]} end)
  end
end
