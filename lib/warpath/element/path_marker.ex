defmodule Warpath.Element.PathMarker do
  @moduledoc false

  alias Warpath.Element.Path

  @type acc :: list(Path.token())
  @type token :: Path.token()

  @spec stream({list | map, acc}, (token, acc -> acc)) :: Stream.t()
  def stream(element, path_fun \\ &Path.accumulate/2)

  def stream({members, path}, path_fun) when is_function(path_fun, 2) and is_list(members) do
    members
    |> Stream.with_index()
    |> Stream.map(fn {member, index} -> {member, path_fun.({:index_access, index}, path)} end)
  end

  def stream({member, path}, path_fun) when is_function(path_fun, 2) and is_map(member) do
    Stream.map(member, fn {k, v} -> {v, path_fun.({:property, k}, path)} end)
  end
end
