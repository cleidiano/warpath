defmodule Warpath.Query.Accessible do
  @moduledoc false

  def accessible?(term) do
    is_map(term) or Keyword.keyword?(term)
  end

  def has_key?(%{} = accessible, key), do: Map.has_key?(accessible, key)

  def has_key?(keywords, key) when is_list(keywords) and is_atom(key),
    do: Keyword.keyword?(keywords) and Keyword.has_key?(keywords, key)

  def has_key?(_, _), do: false
end
