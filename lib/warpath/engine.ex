defmodule Warpath.Engine do
  @moduledoc false

  alias Warpath.Expression
  alias Warpath.Element.Path
  alias Warpath.Engine.EnumWalker
  alias Warpath.Engine.Filter
  alias Warpath.Engine.PathMarker
  alias Warpath.Engine.Scanner
  alias Warpath.UnsupportedOperationError

  @type document :: map | list

  @spec query(document, list(Expression.token()), any) :: {:error, RuntimeError.t()} | {:ok, any}
  def query(document, tokens, opts \\ []) when is_list(tokens) do
    try do
      terms =
        tokens
        |> Enum.reduce({document, []}, fn token, acc -> transform(acc, token) end)
        |> collect(Keyword.get(opts, :result_type))

      {:ok, terms}
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  defp collect(elements, opt) when is_list(elements) do
    Enum.map(elements, &collect(&1, opt))
  end

  defp collect({member, path}, :both) do
    {member, Path.bracketify(path)}
  end

  defp collect({_, path}, :path) do
    Path.bracketify(path)
  end

  defp collect({member, _}, _) do
    member
  end

  defp transform({member, path}, {:root, _} = token) do
    {member, Path.accumulate(token, path)}
  end

  defp transform({members, path}, {:dot, {:property, property} = token})
       when is_list(members) do
    message =
      "You are trying to traverse a list using dot " <>
        "notation '#{Path.accumulate(token, path) |> Path.dotify()}', " <>
        "that it's not allowed for list type. " <>
        "You can use something like '#{Path.dotify(path)}[*].#{property}' instead."

    raise RuntimeError, message
  end

  defp transform({member, path}, {:dot, {:property, property} = token}) do
    {member[property], Path.accumulate(token, path)}
  end

  defp transform({members, path}, {:index_access, index} = token)
       when is_list(members) do
    member = get_in(members, [Access.at(index)])

    {member, Path.accumulate(token, path)}
  end

  defp transform({_, _} = element, {:array_indexes, indexes}) do
    Enum.map(indexes, &transform(element, &1))
  end

  defp transform({members, _} = element, {:array_wildcard, _}) when is_list(members) do
    element
    |> PathMarker.stream(&Path.accumulate/2)
    |> Enum.to_list()
  end

  defp transform(element, {:filter, filter_expression}) do
    Filter.filter(element, filter_expression)
  end

  defp transform(element, {:scan, {:property, _} = property}) do
    Scanner.scan(element, property, &Path.accumulate/2)
  end

  defp transform(element, {:scan, {:wildcard, _} = wildcard}) do
    Scanner.scan(element, wildcard, &Path.accumulate/2)
  end

  defp transform(element, {:scan, {:filter, _} = filter}),
    do: do_scan_filter([element], filter)

  defp transform(element, {:scan, {{:wildcard, :*} = wildcard, {:filter, _} = filter}}) do
    element
    |> Scanner.scan(wildcard, &Path.accumulate/2)
    |> do_scan_filter(filter)
  end

  defp transform(element, {:scan, {:array_indexes, _} = indexes}) do
    reducer = container_reducer()

    [element]
    |> EnumWalker.reduce_while([], reducer, &Path.accumulate/2)
    |> Stream.filter(fn {members, _} -> is_list(members) end)
    |> Enum.flat_map(&transform(&1, indexes))
  end

  defp transform([element | []], token), do: transform(element, token)

  defp transform(members, token) when is_list(members) do
    Enum.map(members, fn member -> transform(member, token) end)
  end

  defp transform({member, path}, token) do
    raise UnsupportedOperationError,
          "token=#{inspect(token)}, path=#{inspect(path)}, member=#{inspect(member)}"
  end

  defp do_scan_filter(enumerable, filter) do
    enumerable
    |> EnumWalker.reduce_while([], container_reducer(), &Path.accumulate/2)
    |> Stream.filter(fn {member, _} -> is_list(member) end)
    |> Enum.flat_map(fn element -> transform(element, filter) end)
  end

  defguard has_itens(container)
           when (is_list(container) and container != []) or
                  (is_map(container) and map_size(container) > 0)

  defp container_reducer do
    fn {container, _} = element, acc ->
      case container do
        container when has_itens(container) ->
          {:walk, [element | acc]}

        _ ->
          {:skip, acc}
      end
    end
  end
end
