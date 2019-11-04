defmodule Warpath.Engine.Trace do
  @moduledoc false

  alias Warpath.Engine.ItemPath

  @type trace_acc :: list
  @type token :: ItemPath.token()
  @type trace_fun :: (trace_acc, token -> trace_acc)

  @spec append(trace_acc, token) :: trace_acc
  def append(acc, token) when is_list(acc), do: acc ++ [token]

  @spec stream({list | map, trace_acc}, trace_fun) :: Stream.t()
  def stream(data, trace_fun \\ &append/2)

  def stream({data, trace}, trace_fun) when is_function(trace_fun, 2) and is_list(data) do
    data
    |> Stream.with_index()
    |> Stream.map(fn {term, index} -> {term, trace_fun.(trace, {:index_access, index})} end)
  end

  def stream({data, trace}, trace_fun) when is_function(trace_fun, 2) and is_map(data) do
    Stream.map(data, fn {k, v} -> {v, trace_fun.(trace, {:property, k})} end)
  end
end
