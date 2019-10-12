defmodule Warpath.Engine do
  alias Warpath.Engine.ItemPath

  @relation_fun [:>, :<, :==]

  def query(data, tokens, opts \\ []) when is_list(tokens) do
    try do
      [value, paths] = transform(tokens, data, _acc = [])

      case opts[:result_type] do
        :path -> ItemPath.bracketify(paths)
        _ -> value
      end
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  defp transform([segment = {:root, _} | t], data, item_path) do
    [value, paths] = transform(t, data, [segment | item_path])
    [value, Enum.reverse(paths)]
  end

  defp transform([{:dot, segment = {:property, property}} | _], data, item_path)
       when is_list(data) do
    message =
      "You are trying to traverse a list using dot " <>
        "notation '#{ItemPath.dotify([segment | item_path])}', " <>
        "that it's not allowed for list type. " <>
        "You can use something like this for " <>
        "exemple, '#{ItemPath.dotify(item_path)}[*].#{property}'!"

    raise RuntimeError, message
  end

  defp transform([{:dot, segment = {:property, property}} | t], data, item_path) do
    transform(t, data[property], [segment | item_path])
  end

  defp transform([segment = {:index_access, index} | t], data, item_path)
       when is_list(data) or is_map(data) do
    value = get_in(data, [Access.at(index)])

    transform(t, value, [segment | item_path])
  end

  defp transform([{:array_wildcard, _} | t], data, item_path)
       when is_list(data) and length(t) > 0 do
    [itens, paths] =
      data
      |> Stream.with_index()
      |> Stream.map(fn {item, index} -> {item, [{:index_access, index} | item_path]} end)
      |> Stream.map(fn {item, path} -> transform(t, item, path) end)
      |> Enum.reduce([_item_acc = [], _path_acc = []], fn [item | path], [acc_itens, trace] ->
        [[item | acc_itens], [List.flatten(path) | trace]]
      end)

    [Enum.reverse(itens), Enum.map(paths, &Enum.reverse/1)]
  end

  defp transform([{:array_wildcard, _} | []], data, item_path) do
    transform([], data, item_path)
  end

  defp transform([{:filter, filter_expression} | t], data, item_path) do
    [result, itens_path] = filter(filter_expression, data, item_path)
    transform(t, result, itens_path)
  end

  defp transform([], data, item_path) do
    [data, item_path]
  end

  defp transform(syntax, data, paths) do
    raise Warpath.SyntaxError,
          "tokens=#{inspect(syntax)}, data=#{inspect(data)}, paths=#{inspect(paths)}"
  end

  defp filter({{:property, property}, operator, operand}, data, item_path)
       when is_list(data) and operator in @relation_fun do
    do_filter(data, property, operator, operand, item_path)
  end

  defp do_filter(data, property, operator, operand, item_path) do
    filter_fun = fn item -> apply(Kernel, operator, [item, operand]) end

    [itens, paths] =
      data
      |> Stream.with_index()
      |> Stream.filter(fn {item, _index} -> filter_fun.(item[property]) end)
      |> Stream.map(fn {item, index} -> {item, [{:index_access, index} | item_path]} end)
      |> Enum.reduce([_itens_acc = [], _path_acc = []], fn {item, path}, [itens, paths] ->
        [[item | itens], [List.flatten(path) | paths]]
      end)

    [Enum.reverse(itens), Enum.map(paths, &Enum.reverse/1)]
  end

  # TODO Define a catch all for transform function
end

defmodule Warpath.SyntaxError do
  defexception [:message]
end
