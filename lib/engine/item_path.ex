defmodule Warpath.Engine.ItemPath do
  @moduledoc false

  def bracketify(paths), do: make_path(paths, :bracketify)

  def dotify(paths), do: make_path(paths, :dotify)

  defp make_path([h | _] = data, option) when is_tuple(h) do
    join(data, option)
  end

  defp make_path([h | _] = data, option) when is_list(h) do
    data
    |> Enum.map(&make_path(&1, option))
    |> List.flatten()
  end

  defp join(data, opts) do
    data
    |> Enum.map(&path(&1, opts))
    |> Enum.join()
  end

  defp path({:root, root}, :bracketify), do: root
  defp path({:property, property}, :bracketify), do: "['#{property}']"
  defp path({:index_access, index}, _), do: "[#{index}]"
  defp path({:root, root}, :dotify), do: root
  defp path({:property, property}, :dotify), do: ".#{property}"
end
