defmodule Warpath.Engine.Scanner do
  @moduledoc false
  alias Warpath.Engine.{EnumWalker, Scanner.PropertySearch}

  def scan(term, {:property, _} = search_criteria),
    do: PropertySearch.search(term, search_criteria)

  def scan(term, {:wildcard, :*}), do: EnumWalker.recursive_descent(term)

  defmodule PropertySearch do
    def search({data, trace}, {:property, _} = property) when is_map(data) do
      data
      |> Enum.map(fn {key, value} -> walk(property, {key, value, trace}) end)
      |> Enum.reverse()
      |> List.flatten()
      |> Enum.reject(&(&1 == {}))
    end

    def search({data, trace}, {:property, _} = property) when is_list(data) do
      Enum.map(data, &search({&1, trace}, property))
    end

    defp walk({:property, property_name} = search_criteria, {key, value, trace})
         when property_name == key do
      pair = {value, [search_criteria | trace]}

      if is_map(value) or is_list(value),
        do: [pair, search(pair, search_criteria)],
        else: pair
    end

    defp walk({:property, _} = search_criteria, {key, value, trace}) when is_map(value) do
      search({value, [{:property, key} | trace]}, search_criteria)
    end

    defp walk({:property, _} = search_criteria, {key, value, trace}) when is_list(value) do
      value
      |> Stream.map(fn term -> {term, [{:property, key} | trace]} end)
      |> Stream.with_index()
      |> Stream.map(fn {{term, term_trace}, i} -> {term, [{:index_access, i} | term_trace]} end)
      |> Enum.map(fn term -> search(term, search_criteria) end)
    end

    defp walk({:property, _}, {_, _, _}), do: {}
  end
end
