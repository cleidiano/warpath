defmodule Warpath.Element.PathMarker do
  @moduledoc false

  alias Warpath.Element
  alias Warpath.Element.Path

  @type path :: Path.t()
  @type token :: Path.token()
  @type elements :: Element.t()

  @spec stream(elements(), (token, path -> path)) :: Stream.t()
  def stream(element, path_fun \\ &Path.accumulate/2)

  def stream(%Element{value: list, path: path}, path_fun) when is_list(list) do
    list
    |> Stream.with_index()
    |> Stream.map(fn {item, index} ->
      Element.new(item, path_fun.({:index_access, index}, path))
    end)
  end

  def stream(%Element{value: map, path: path}, path_fun) when is_map(map) do
    Stream.map(
      map,
      fn {k, v} ->
        key_path = path_fun.({:property, k}, path)
        Element.new(v, key_path)
      end
    )
  end
end
