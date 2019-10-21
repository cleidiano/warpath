defmodule Warpath.Engine.Scanner do
  @moduledoc false

  def deep_scan(data, property, trace) when is_map(data) and is_list(trace) do
    data
    |> Enum.map(fn {key, value} -> match_and_search(property, key, value, trace) end)
    |> Enum.reverse()
    |> List.flatten()
    |> Enum.reject(&(&1 == {}))
  end

  def deep_scan(data, property, trace) when is_list(data) and is_list(trace) do
    Enum.map(data, &deep_scan(&1, property, trace))
  end

  defp match_and_search({:property, property_name} = property, current_key, current_value, trace)
       when property_name == current_key and (is_map(current_value) or is_list(current_value)) do
    new_trace = [property | trace]

    [
      {current_value, new_trace},
      deep_scan(current_value, property, new_trace)
    ]
  end

  defp match_and_search(property, current_key, current_value, trace)
       when is_map(current_value) do
    deep_scan(current_value, property, [{:property, current_key} | trace])
  end

  defp match_and_search({:property, _property_name} = property, current_key, current_value, trace)
       when is_list(current_value) do
    current_value
    |> Stream.map(fn term -> {term, [{:property, current_key} | trace]} end)
    |> Stream.with_index()
    |> Stream.map(fn {{term, term_trace}, i} -> {term, [{:index_access, i} | term_trace]} end)
    |> Enum.map(fn {item, term_trace} -> deep_scan(item, property, term_trace) end)
  end

  defp match_and_search({:property, property_name} = property, current_key, current_value, trace)
       when property_name == current_key do
    {current_value, [property | trace]}
  end

  defp match_and_search({:property, _}, _current_key, _current_value, _trace) do
    {}
  end
end
