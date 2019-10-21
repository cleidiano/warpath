defmodule Warpath.Engine do
  alias Warpath.Engine.ItemPath
  alias Warpath.Engine.Scanner
  alias Warpath.Engine.Filter

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
        "You can use something like this for " <>
        "exemple, '#{ItemPath.dotify(base_trace)}[*].#{property}'!"

    raise RuntimeError, message
  end

  defp transform({data, trace}, [{:dot, segment = {:property, property}} | rest]) do
    transform({data[property], [segment | trace]}, rest)
  end

  defp transform({data, trace}, [segment = {:index_access, index} | rest])
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

  defp transform({data, trace}, [{:array_wildcard, _} | rest])
       when is_list(data) and length(rest) > 0 do
    data
    |> Stream.with_index()
    |> Stream.map(fn {term, index} -> {term, [{:index_access, index} | trace]} end)
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
    term
    |> Scanner.deep_scan(property, trace)
    |> Stream.map(fn item -> transform(item, rest) end)
    |> Enum.to_list()
    |> List.flatten()
  end

  defp transform({data, trace}, []) do
    {data, List.flatten(trace) |> Enum.reverse()}
  end

  defp transform(term, []) when is_list(term) do
    term
    |> Enum.map(fn {item, trace} -> {item, List.flatten(trace) |> Enum.reverse()} end)
  end

  defp transform({data, trace}, syntax) do
    raise Warpath.NotImplementedError,
          "tokens=#{inspect(syntax)}, data=#{inspect(data)}, trace=#{inspect(trace)}"
  end
end

defmodule Warpath.NotImplementedError do
  defexception [:message]
end
