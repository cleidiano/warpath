defmodule Warpath.Element.PathMarker do
  @moduledoc false

  alias Warpath.Element.Path

  @type path :: list(Path.token())
  @type token :: Path.token()

  @type elements :: {list | map, path} | Element.t() | [Element.t()]

  @spec stream(elements(), (token, path -> path)) :: Stream.t()
  def stream(element, path_fun \\ &Path.accumulate/2)

  def stream({members, path}, path_fun) when is_list(members) do
    members
    |> Stream.with_index()
    |> Stream.map(fn {member, index} -> {member, path_fun.({:index_access, index}, path)} end)
  end

  def stream({member, path}, path_fun) when is_function(path_fun, 2) and is_map(member) do
    Stream.map(member, fn {k, v} -> {v, path_fun.({:property, k}, path)} end)
  end

  def stream([%Element{} | _] = elements, path_fun) do
    elements
    |> Stream.with_index()
    |> Stream.map(fn {%Element{value: value, path: path}, index} ->
      Element.new(value, path_fun.({:index_access, index}, path))
    end)
  end

  def stream(%Element{value: list, path: path}, path_fun) when is_list(list) do
    list
    |> Stream.with_index()
    |> Stream.map(fn {item, index} ->
      Element.new(item, path_fun.({:index_access, index}, path))
    end)
  end

  def stream(%Element{value: map, path: path}, path_fun) when is_map(map) do
    map
    |> Stream.map(fn {k, v} ->
      key_path = path_fun.({:property, k}, path)
      Element.new(v, key_path)
    end)
  end
end
