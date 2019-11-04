defmodule Warpath.Engine do
  @moduledoc false

  import Warpath.Engine.Trace

  alias Warpath.Engine.{ItemPath, Trace, Scanner, Filter, EnumWalker}
  alias Warpath.Expression

  @spec query(any, list(Expression.token()), any) :: {:error, RuntimeError.t()} | {:ok, any}
  def query(data, tokens, opts \\ []) when is_list(tokens) do
    try do
      terms =
        tokens
        |> Enum.reduce({data, []}, fn token, acc -> transform(acc, token) end)
        |> collect(Keyword.get(opts, :result_type))

      {:ok, terms}
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  defp collect(term, opt) when is_list(term) do
    Enum.map(term, &collect(&1, opt))
  end

  defp collect({item, path}, :both) do
    {item, ItemPath.bracketify(path)}
  end

  defp collect({_, path}, :path) do
    ItemPath.bracketify(path)
  end

  defp collect({item, _}, _) do
    item
  end

  defp transform({data, trace}, {:root, _} = segment) do
    {data, Trace.append(trace, segment)}
  end

  defp transform({data, trace}, {:dot, {:property, property} = segment})
       when is_list(data) do
    message =
      "You are trying to traverse a list using dot " <>
        "notation '#{ItemPath.dotify(trace ++ [segment])}', " <>
        "that it's not allowed for list type. " <>
        "You can use something like '#{ItemPath.dotify(trace)}[*].#{property}' instead."

    raise RuntimeError, message
  end

  defp transform({data, trace}, {:dot, {:property, property} = segment}) do
    {data[property], Trace.append(trace, segment)}
  end

  defp transform({data, trace}, {:index_access, index} = segment)
       when is_list(data) do
    term = get_in(data, [Access.at(index)])

    {term, Trace.append(trace, segment)}
  end

  defp transform({_, _} = term, {:array_indexes, indexes}) do
    Enum.map(indexes, &transform(term, &1))
  end

  defp transform({data, _} = item, {:array_wildcard, _}) when is_list(data) do
    item
    |> stream(&Trace.append/2)
    |> Enum.to_list()
  end

  defp transform({_, _} = term, {:filter, filter_expression}) do
    Filter.filter(term, filter_expression)
  end

  defp transform({_, _} = term, {:scan, {:property, _} = property}) do
    Scanner.scan(term, property, &Trace.append/2)
  end

  defp transform({term, trace}, {:scan, {:wildcard, _} = wildcard}) do
    {term, trace}
    |> Scanner.scan(wildcard, &Trace.append/2)
  end

  defp transform(term, {:scan, {:filter, _} = filter}),
    do: do_scan_filter([term], filter)

  defp transform(term, {:scan, {{:wildcard, :*} = wildcard, {:filter, _} = filter}}) do
    term
    |> Scanner.scan(wildcard, &Trace.append/2)
    |> do_scan_filter(filter)
  end

  defp transform(term, {:scan, {:array_indexes, _} = indexes}) do
    reducer = container_reducer()

    [term]
    |> EnumWalker.reduce_while([], reducer, &Trace.append/2)
    |> Stream.filter(fn {item, _} -> is_list(item) end)
    |> Enum.flat_map(&transform(&1, indexes))
  end

  defp transform([term | []], segment), do: transform(term, segment)

  defp transform(data, segment) when is_list(data) do
    Enum.map(data, fn term -> transform(term, segment) end)
  end

  defp transform({data, trace}, syntax) do
    raise Warpath.NotImplementedError,
          "tokens=#{inspect(syntax)}, data=#{inspect(data)}, trace=#{inspect(trace)}"
  end

  defp do_scan_filter(enumerable, filter) do
    enumerable
    |> EnumWalker.reduce_while([], container_reducer(), &Trace.append/2)
    |> Stream.filter(fn {term, _} -> is_list(term) end)
    |> Enum.flat_map(fn term -> transform(term, filter) end)
  end

  defguard has_itens(term)
           when (is_list(term) and term != []) or (is_map(term) and map_size(term) > 0)

  defp container_reducer do
    fn {container, _} = term, acc ->
      case container do
        container when has_itens(container) ->
          {:walk, [term | acc]}

        _ ->
          {:skip, acc}
      end
    end
  end
end

defmodule Warpath.NotImplementedError do
  defexception [:message]
end
