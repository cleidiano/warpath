defmodule Warpath.Engine.Scanner do
  @moduledoc false
  alias Warpath.Engine.{EnumWalker, Scanner.PropertySearch, Trace}

  def scan(term, criteria, trace_fun \\ &Trace.append/2)

  def scan(term, {:property, _} = criteria, trace_fun)
      when is_function(trace_fun, 2) do
    PropertySearch.search(term, criteria, trace_fun)
  end

  def scan(term, {:wildcard, :*}, trace_fun)
      when is_function(trace_fun, 2) do
    EnumWalker.recursive_descent(term, trace_fun)
  end

  defmodule PropertySearch do
    @moduledoc false

    def search({data, trace}, {:property, _} = property, trace_fun) when is_map(data) do
      data
      |> Enum.map(fn {key, value} -> walk(property, {key, value, trace}, trace_fun) end)
      |> Enum.reverse()
      |> List.flatten()
      |> Enum.reject(&(&1 == {}))
    end

    def search({data, trace}, {:property, _} = property, trace_fun) when is_list(data) do
      Enum.map(data, &search({&1, trace}, property, trace_fun))
    end

    defp walk({:property, property_name} = criteria, {key, value, trace}, trace_fun)
         when property_name == key do
      pair = {value, trace_fun.(trace, criteria)}

      if is_map(value) or is_list(value),
        do: [pair, search(pair, criteria, trace_fun)],
        else: pair
    end

    defp walk({:property, _} = criteria, {key, value, trace}, trace_fun)
         when is_map(value) do
      search({value, trace_fun.(trace, {:property, key})}, criteria, trace_fun)
    end

    defp walk({:property, _} = criteria, {key, value, trace}, trace_fun)
         when is_list(value) do
      value
      |> Stream.map(&{&1, trace_fun.(trace, {:property, key})})
      |> Stream.with_index()
      |> Stream.map(fn {{term, term_trace}, i} ->
        {term, trace_fun.(term_trace, {:index_access, i})}
      end)
      |> Enum.map(fn term -> search(term, criteria, trace_fun) end)
    end

    defp walk({:property, _}, {_, _, _}, _), do: {}
  end
end
