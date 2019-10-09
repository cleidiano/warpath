defmodule Jexpa do
  def query(data, expression, opts \\ []) do
    {:ok, tokens, _} =
      expression
      |> String.to_charlist()
      |> :tokenizer.string()

    [value, paths] =
      tokens
      |> parse!()
      |> transform(data, _acc = [])

    case opts[:result_type] do
      :path -> paths
      _ -> value
    end
  end

  defp parse!(tokens) do
    tokens
    |> :parser.parse()
    |> case do
      {:ok, parsed_tokens} ->
        parsed_tokens

      _ ->
        raise RuntimeError
    end
  end

  defp transform([{:root, key} | t], data, path_acc) do
    transform(t, data, [key | path_acc])
  end

  defp transform([{:., {:property, property}} | t], data, path_acc) do
    transform(t, data[property], ["['#{property}']" | path_acc])
  end

  defp transform([{:index, index} | t], data, path_acc) when is_list(data) do
    value = get_in(data, [Access.at(index)])

    transform(t, value, ["[#{index}]" | path_acc])
  end

  defp transform([{:array_wildcard, _} | t], data, path_acc)
       when is_list(data)
       when is_list(data) and length(t) > 0 do
    {_, [itens, paths]} =
      data
      |> Stream.with_index()
      |> Enum.flat_map_reduce([[], []], fn {item, index}, [itens, paths] ->
        ## CABE USAR with {...} AQUI
        item_path = ["[#{index}]" | path_acc]
        transformed = transform(t, item, item_path)
        [h | t] = transformed
        {transformed, [[h | itens], [t | paths]]}
      end)

    [Enum.reverse(itens), Enum.reverse(paths) |> List.flatten()]
  end

  defp transform([], data, path_acc) do
    [data, Enum.reverse(path_acc) |> Enum.join()]
  end

  # definir catch all para transform
end
