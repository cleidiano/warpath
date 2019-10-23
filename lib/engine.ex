defmodule Warpath.Engine do
  import Warpath.Engine.Trace

  alias Warpath.Engine.ItemPath
  alias Warpath.Engine.Scanner
  alias Warpath.Engine.Filter
  alias Warpath.Engine.EnumWalker

  @spec query(any, maybe_improper_list, any) :: {:error, RuntimeError.t()} | {:ok, any}
  def query(data, tokens, opts \\ []) when is_list(tokens) do
    try do
      terms =
        {data, []}
        |> transform(tokens)
        |> collect(Keyword.get(opts, :result_type))

      {:ok, terms}
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  defp collect({item, path}, :value_and_path), do: {item, ItemPath.bracketify(path)}
  defp collect({_, path}, :path), do: ItemPath.bracketify(path)
  defp collect({item, _}, _), do: item

  defp collect(query_result, opt) when is_list(query_result),
    do: Enum.map(query_result, &collect(&1, opt))

  defguard no_empty_container(term)
           when (is_list(term) and length(term) > 0) or (is_map(term) and map_size(term) > 0)

  defp transform({data, trace}, [segment = {:root, _} | rest]) do
    transform({data, [segment | trace]}, rest)
  end

  defp transform({data, trace}, [{:dot, segment = {:property, property}} | _])
       when is_list(data) do
    base_trace = Enum.reverse(trace)

    message =
      "You are trying to traverse a list using dot " <>
        "notation '#{ItemPath.dotify(base_trace ++ [segment])}', " <>
        "that it's not allowed for list type. " <>
        "You can use something like '#{ItemPath.dotify(base_trace)}[*].#{property}' instead."

    raise RuntimeError, message
  end

  defp transform(data, [{:dot, {:property, property} = segment} | rest])
       when is_list(data) do
    Enum.map(data, fn {term, trace} -> transform({term[property], [segment | trace]}, rest) end)
  end

  defp transform({data, trace}, [{:dot, {:property, property} = segment} | rest]) do
    transform({data[property], [segment | trace]}, rest)
  end

  defp transform({data, trace}, [{:index_access, index} = segment | rest])
       when is_list(data) or is_map(data) do
    term = get_in(data, [Access.at(index)])

    transform({term, [segment | trace]}, rest)
  end

  defp transform({data, trace}, [{:array_indexes, indexes} | rest]) do
    terms_indexes =
      indexes
      |> Stream.map(&transform({data, trace}, [&1]))
      |> Stream.map(fn {item, item_trace} -> {item, Enum.reverse(item_trace)} end)
      |> Enum.to_list()

    transform(terms_indexes, rest)
  end

  defp transform({data, _} = item, [{:array_wildcard, _} | rest])
       when is_list(data) and length(rest) > 0 do
    item
    |> stream()
    |> Stream.map(fn term -> transform(term, rest) end)
    |> Enum.to_list()
  end

  defp transform({term, trace}, [{:array_wildcard, _} | []]) do
    transform({term, trace}, [])
  end

  defp transform({data, trace}, [{:filter, filter_expression} | rest]) do
    data
    |> Filter.filter(filter_expression, trace)
    |> transform(rest)
  end

  defp transform({term, trace}, [{:scan, {:property, _} = property} | rest]) do
    {term, trace}
    |> Scanner.scan(property)
    |> Enum.map(fn item -> transform(item, rest) end)
    |> List.flatten()
  end

  defp transform({term, trace}, [{:scan, {:wildcard, _} = wildcard} | []]) do
    {term, trace}
    |> Scanner.scan(wildcard)
    |> Enum.map(&transform(&1, []))
  end

  defp transform(term, [{:scan, {:filter, _} = filter} | rest]),
    do: do_scan_filter([term], filter, rest)

  defp transform(term, [
         {:scan, {{:wildcard, :*} = wildcard, {:filter, _} = filter}} | rest
       ]) do
    term
    |> Scanner.scan(wildcard)
    |> do_scan_filter(filter, rest)
  end

  defp transform(term, [{:scan, {:array_indexes, _} = indexes} | rest]) do
    reducer = container_reducer()

    [term]
    |> EnumWalker.reduce_while([], reducer)
    |> Stream.filter(fn {item, _} -> is_list(item) end)
    |> Stream.flat_map(&transform(&1, [indexes]))
    |> Stream.map(fn {item, trace} -> {item, Enum.reverse(trace)} end)
    |> Enum.map(&transform(&1, rest))
  end

  defp transform({data, trace}, []) do
    {data, List.flatten(trace) |> Enum.reverse()}
  end

  defp transform(term, []) when is_list(term) do
    Enum.map(term, fn {item, trace} -> {item, List.flatten(trace) |> Enum.reverse()} end)
  end

  defp transform({data, trace}, syntax) do
    raise Warpath.NotImplementedError,
          "tokens=#{inspect(syntax)}, data=#{inspect(data)}, trace=#{inspect(trace)}"
  end

  defp do_scan_filter(enumerable, filter, rest) do
    enumerable
    |> EnumWalker.reduce_while([], container_reducer())
    |> Stream.filter(fn {term, _} -> is_list(term) end)
    |> Stream.flat_map(fn term -> transform(term, [filter | rest]) end)
    |> Enum.to_list()
  end

  defp container_reducer do
    fn {container, _} = term, acc ->
      case container do
        container when no_empty_container(container) -> {:walk, [term | acc]}
        _ -> {:skip, acc}
      end
    end
  end
end

defmodule Warpath.NotImplementedError do
  defexception [:message]
end
