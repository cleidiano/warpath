defmodule Warpath.AccessBuilder do
  @moduledoc false

  def build(paths) when is_list(paths) do
    paths
    |> maybe_wrap()
    |> Enum.map(fn tokens -> {tokens, to_accessor(tokens)} end)
  end

  defp maybe_wrap(paths) do
    case paths do
      [{:root, _} | _] -> [paths]
      _ -> paths
    end
  end

  defp to_accessor([{:root, _}]) do
    [
      fn _, data, next ->
        case next.(data) do
          :pop -> {data, nil}
          new_data -> new_data
        end
      end
    ]
  end

  defp to_accessor([{:root, _} | path_tokens]) do
    Enum.map(path_tokens, fn
      {:property, property} ->
        property

      {:index_access, index} ->
        Access.at(index)
    end)
  end
end
