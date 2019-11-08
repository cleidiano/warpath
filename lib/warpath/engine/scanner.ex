defmodule Warpath.Engine.Scanner do
  @moduledoc false
  alias Warpath.Engine.EnumWalker
  alias Warpath.Engine.Scanner.PropertySearch
  alias Warpath.Element.Path

  def scan(element, criteria, path_fun \\ &Path.accumulate/2)

  def scan(element, {:property, _} = criteria, path_fun)
      when is_function(path_fun, 2) do
    PropertySearch.search(element, criteria, path_fun)
  end

  def scan(element, {:wildcard, :*}, path_fun)
      when is_function(path_fun, 2) do
    EnumWalker.recursive_descent(element, path_fun)
  end

  defmodule PropertySearch do
    @moduledoc false

    def search({member, path}, {:property, _} = property, path_fun) when is_map(member) do
      member
      |> Enum.map(fn {key, value} -> walk(property, {key, value, path}, path_fun) end)
      |> Enum.reverse()
      |> List.flatten()
      |> Enum.reject(&(&1 == {}))
    end

    def search({member, path}, {:property, _} = property, path_fun) when is_list(member) do
      Enum.map(member, &search({&1, path}, property, path_fun))
    end

    defp walk({:property, name} = criteria, {key, value, path}, path_fun)
         when name == key do
      element = {value, path_fun.(criteria, path)}

      if is_map(value) or is_list(value),
        do: [element, search(element, criteria, path_fun)],
        else: element
    end

    defp walk({:property, _} = criteria, {key, value, path}, path_fun)
         when is_map(value) do
      search({value, path_fun.({:property, key}, path)}, criteria, path_fun)
    end

    defp walk({:property, _} = criteria, {key, value, path}, path_fun)
         when is_list(value) do
      value
      |> Stream.map(fn term -> {term, path_fun.({:property, key}, path)} end)
      |> Stream.with_index()
      |> Stream.map(fn {{member, path}, index} ->
        {member, path_fun.({:index_access, index}, path)}
      end)
      |> Enum.map(fn term -> search(term, criteria, path_fun) end)
    end

    defp walk({:property, _}, {_, _, _}, _), do: {}
  end
end
