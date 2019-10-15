defmodule Warpath.Engine do
  alias Warpath.Engine.ItemPath

  @relation_fun [:>, :<, :==]

  def query(data, tokens, opts \\ []) when is_list(tokens) do
    try do
      [term, trace] = transform(data, tokens, [])

      case opts[:result_type] do
        :trace -> trace
        _ -> term
      end
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  defp transform(data, [segment = {:root, _} | rest], trace) do
    [term, terms_trace] = transform(data, rest, [segment | trace])
    [term, Enum.reverse(terms_trace)]
  end

  defp transform(data, [{:dot, segment = {:property, property}} | _], trace)
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

  defp transform(data, [{:dot, segment = {:property, property}} | rest], trace) do
    transform(data[property], rest, [segment | trace])
  end

  defp transform(data, [segment = {:index_access, index} | rest], trace)
       when is_list(data) or is_map(data) do
    term = get_in(data, [Access.at(index)])

    transform(term, rest, [segment | trace])
  end

  defp transform(data, [{:array_indexes, indexes} | rest], trace) do
    [terms, terms_trace] =
      indexes
      |> Stream.map(&transform(data, [&1], trace))
      |> consume_stream()

    transform(terms, rest, terms_trace)
  end

  defp transform(data, [{:array_wildcard, _} | rest], trace)
       when is_list(data) and length(rest) > 0 do
    data
    |> Stream.with_index()
    |> Stream.map(fn {term, index} -> {term, [{:index_access, index} | trace]} end)
    |> Stream.map(fn {term, path} -> transform(term, rest, path) end)
    |> consume_stream()
  end

  defp transform(data, [{:array_wildcard, _} | []], trace) do
    transform(data, [], trace)
  end

  defp transform(data, [{:filter, filter_expression} | rest], trace) do
    [terms, terms_trace] = filter(data, filter_expression, trace)
    transform(terms, rest, terms_trace)
  end

  defp transform(data, [], trace) do
    [data, trace]
  end

  defp transform(data, [{:scan, {:property, _property}} = scan_expression | _rest], trace) do
    scan(data, scan_expression, trace)
  end

  defp transform(data, syntax, trace) do
    raise Warpath.UnsupportedExpression,
          "tokens=#{inspect(syntax)}, data=#{inspect(data)}, trace=#{inspect(trace)}"
  end

  def scan(term, {:scan, {:property, _} = property}, trace) do
    term
    |> deep_scan(property, trace)
    |> List.flatten()
    |> Stream.reject(&(&1 == {[], []}))
    |> Stream.map(&Tuple.to_list/1)
    |> consume_stream()
  end

  defp deep_scan(data, property, trace)
       when is_map(data) and is_list(trace) do
    data
    |> Enum.map(fn {key, value} -> match_and_search(property, key, value, trace) end)
    |> Enum.reverse()
  end

  defp deep_scan(data, property, trace)
       when is_list(data) and is_list(trace) do
    data |> Enum.map(&deep_scan(&1, property, trace))
  end

  defp match_and_search({:property, property_name} = property, current_key, current_value, trace)
       when property_name == current_key and (is_map(current_value) or is_list(current_value)) do
    new_trace = [property | trace]

    [
      {current_value, new_trace},
      deep_scan(current_value, property, new_trace)
    ]
  end

  defp match_and_search(property, current_key, current_value, trace)
       when is_map(current_value) do
    deep_scan(current_value, property, [{:property, current_key} | trace])
  end

  defp match_and_search({:property, _property_name} = property, current_key, current_value, trace)
       when is_list(current_value) do
    current_value
    |> Stream.map(fn term -> {term, [{:property, current_key} | trace]} end)
    |> Stream.with_index()
    |> Stream.map(fn {{term, term_trace}, i} -> {term, [{:index_access, i} | term_trace]} end)
    |> Enum.map(fn {item, term_trace} -> deep_scan(item, property, term_trace) end)
  end

  defp match_and_search({:property, property_name} = property, current_key, current_value, trace)
       when property_name == current_key do
    {current_value, [property | trace]}
  end

  defp match_and_search({:property, _}, _current_key, _current_value, _trace) do
    {[], []}
  end

  defp filter(data, {{:property, property}, operator, operand}, trace)
       when is_list(data) and operator in @relation_fun do
    filter_fun = fn item -> apply(Kernel, operator, [item[property], operand]) end
    do_filter(data, filter_fun, trace)
  end

  defp filter(data, {:contains, {:property, property}}, trace) when is_list(data) do
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
