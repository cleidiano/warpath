defmodule Warpath.Element.Path do
  @moduledoc """
    This module contains functions to accumulate and transform item path tokens.

    The path are built during a expression evaluation by `Warpath.query/3`.
  """

  @type token ::
          {:root, String.t()}
          | {:property, String.t() | atom()}
          | {:index_access, integer}

  @type acc :: [token, ...] | []

  @doc """
  Accumulate a path token into a path acc.

  ## Example
      iex> acc = [{:root, "$"}]
      ...> Warpath.Element.Path.accumulate({:property, "name"}, acc)
      [{:property, "name"}, {:root, "$"}]
  """
  @spec accumulate(token, acc) :: acc
  def accumulate({tag, _} = token, acc)
      when is_list(acc) and tag in [:root, :property, :index_access],
      do: [token | acc]

  @doc """
  Transform path tokens into a jsonpath bracket-notation representation.

  ## Example
      iex> acc = [{:property, "name"}, {:root, "$"}]
      ...> Warpath.Element.Path.bracketify(acc)
      "$['name']"

  """
  @spec bracketify(acc) :: binary
  def bracketify(paths), do: make_path(paths, :bracketify)

  @doc """
  Transform path tokens into a jsonpath dot-notation representation.

  ## Example
      iex> acc = [{:property, "name"}, {:root, "$"}]
      ...> Warpath.Element.Path.dotify(acc)
      "$.name"

  """
  @spec dotify(acc) :: binary
  def dotify(paths), do: make_path(paths, :dotify)

  defp make_path([h | _] = tokens, option) when is_tuple(h) do
    to_string(tokens, option)
  end

  defp make_path([h | _] = tokens, option) when is_list(h) do
    Enum.map(tokens, &make_path(&1, option))
  end

  defp make_path([], _), do: ""

  defp to_string(tokens, opts) do
    tokens
    |> Enum.reverse()
    |> Enum.map(&path(&1, opts))
    |> Enum.join()
  end

  defp path({:root, root}, :bracketify), do: root
  defp path({:root, root}, :dotify), do: root
  defp path({:property, property}, :bracketify), do: "['#{property}']"
  defp path({:property, property}, :dotify), do: ".#{property}"
  defp path({:index_access, index}, _), do: "[#{index}]"
end
