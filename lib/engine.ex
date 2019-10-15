defmodule Warpath.Engine do
  alias Warpath.Engine.ItemPath

  @relation_fun [:>, :<, :==]

  def query(data, tokens, opts \\ []) when is_list(tokens) do
    try do
      [term, trace] = transform(tokens, data, [])

      case opts[:result_type] do
        :path -> ItemPath.bracketify(trace)
        _ -> term
      end
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  defp transform([segment = {:root, _} | rest], data, trace) do
    [term, terms_trace] = transform(rest, data, [segment | trace])
    [term, Enum.reverse(terms_trace)]
  end

  defp transform([{:dot, segment = {:property, property}} | _], data, trace)
       when is_list(data) do
    message =
      "You are trying to traverse a list using dot " <>
        "notation '#{ItemPath.dotify([segment | trace])}', " <>
        "that it's not allowed for list type. " <>
        "You can use something like this for " <>
        "exemple, '#{ItemPath.dotify(trace)}[*].#{property}'!"

    raise RuntimeError, message
  end

  defp transform([{:dot, segment = {:property, property}} | rest], data, trace) do
    transform(rest, data[property], [segment | trace])
  end

  defp transform([segment = {:index_access, index} | rest], data, trace)
       when is_list(data) or is_map(data) do
    term = get_in(data, [Access.at(index)])

    transform(rest, term, [segment | trace])
  end

  defp transform([{:array_indexes, indexes} | rest], data, trace) do
    [terms, terms_trace] =
      indexes
      |> Stream.map(&transform([&1], data, trace))
      |> consume_stream()

    transform(rest, terms, terms_trace)
  end

  defp transform([{:array_wildcard, _} | rest], data, trace)
       when is_list(data) and length(rest) > 0 do
    data
    |> Stream.with_index()
    |> Stream.map(fn {term, index} -> {term, [{:index_access, index} | trace]} end)
    |> Stream.map(fn {term, path} -> transform(rest, term, path) end)
    |> consume_stream()
  end

  defp transform([{:array_wildcard, _} | []], data, trace) do
    transform([], data, trace)
  end

  defp transform([{:filter, filter_expression} | rest], data, trace) do
    [terms, terms_trace] = filter(filter_expression, data, trace)
    transform(rest, terms, terms_trace)
  end

  defp transform([], data, trace) do
    [data, trace]
  end

  defp transform(syntax, data, trace) do
    raise Warpath.UnsupportedExpression,
          "tokens=#{inspect(syntax)}, data=#{inspect(data)}, trace=#{inspect(trace)}"
  end

  defp filter({{:property, property}, operator, operand}, data, trace)
       when is_list(data) and operator in @relation_fun do
    filter_fun = fn item -> apply(Kernel, operator, [item[property], operand]) end
    do_filter(data, filter_fun, trace)
  end

  defp filter({:contains, {:property, property}}, data, trace) when is_list(data) do
    do_filter(data, &Map.has_key?(&1, property), trace)
  end

  defp do_filter(data, filter_fun, trace) do
    data
    |> Stream.with_index()
    |> Stream.filter(fn {term, _index} -> filter_fun.(term) end)
    |> Stream.map(fn {term, index} -> [term, [{:index_access, index} | trace]] end)
    |> consume_stream()
  end

  defp consume_stream(%Stream{} = terms_trace_stream) do
    [terms, terms_trace] =
      terms_trace_stream
      |> Enum.reduce([[], []], fn [term | path], [terms_acc, trace_acc] ->
        [[term | terms_acc], [List.flatten(path) | trace_acc]]
      end)

    [Enum.reverse(terms), Enum.map(terms_trace, &Enum.reverse/1)]
  end
end

defmodule Warpath.UnsupportedExpression do
  defexception [:message]
end
