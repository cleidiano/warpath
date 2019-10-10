defmodule Warpath.Engine do
  alias Warpath.Engine.ItemPath

  @relation_fun [:>, :<, :==]

  def query(data, tokens, opts \\ []) when is_list(tokens) do
    try do
      [value, paths] = transform(tokens, data, _acc = [])

      case opts[:result_type] do
        :path -> ItemPath.create(paths)
        _ -> value
      end
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  defp transform([{:root, key} | t], data, item_path) do
    transform(t, data, [key | item_path])
  end

  defp transform([{:dot, {:property, property}} | _], data, item_path) when is_list(data) do
    #TODO ADICIONAR TEST APRA ESTE CASO
    base_path =
      item_path
      |> ItemPath.create()
      |> String.replace("['", ".")
      |> String.replace("']", "")

    property_path = "#{base_path}.#{property}"
    index_path = "#{base_path}[*].#{property}"

    raise RuntimeError,
          "You are trying to traverse a list using dot notation #{property_path} " <>
            "that it's not allowed for list type, you can use something like this for exemple, #{
              index_path
            } instead!"
  end

  defp transform([{:dot, {:property, property}} | t], data, item_path) do
    transform(t, data[property], [ItemPath.segment(:property, property) | item_path])
  end

  defp transform([{:index_access, index} | t], data, item_path)
       when is_list(data) or is_map(data) do
    value = get_in(data, [Access.at(index)])

    transform(t, value, [ItemPath.segment(:index, index) | item_path])
  end

  defp transform([{:array_wildcard, _} | t], data, item_path)
       when is_list(data) and length(t) > 0 do
    [itens, paths] =
      data
      |> Stream.with_index()
      |> Stream.map(fn {item, index} -> {item, [ItemPath.segment(:index, index) | item_path]} end)
      |> Stream.map(fn {item, path} -> transform(t, item, path) end)
      |> Enum.reduce([_item_acc = [], _path_acc = []], fn [item | path], [acc_itens, trace] ->
        [[item | acc_itens], [path | trace]]
      end)

    [Enum.reverse(itens), Enum.reverse(paths)]
  end

  defp transform([{:array_wildcard, _} | []], data, item_path) do
    transform([], data, item_path)
  end

  defp transform([{:filter, filter_expression} | t], data, item_path) do
    # TODO How will path look like??
    [result, itens_path] = filter(filter_expression, data, item_path)
    transform(t, result, itens_path)
  end

  defp transform([], data, item_path) do
    [data, item_path]
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
      |> Stream.map(fn {item, index} -> {item, [ItemPath.segment(:index, index) | item_path]} end)
      |> Enum.reduce([_itens_acc = [], _path_acc = []], fn {item, path}, [itens, paths] ->
        [[item | itens], [path | paths]]
      end)

    [itens, Enum.reverse(paths)]
  end

  # TODO Define a catch all for transform function
end

defmodule Warpath.Engine.ItemPath do
  @moduledoc false

  def create(data) when is_list(data) do
    join(data)
  end

  def segment(:property, term) when is_binary(term), do: "['#{term}']"
  def segment(:index, index), do: "[#{index}]"

  defp join([h | _] = data) when is_list(h) do
    data
    |> Enum.map(fn path -> join(path) end)
    |> List.flatten()
  end

  defp join([h | _] = data) when is_binary(h) do
    data |> Enum.reverse() |> Enum.join()
  end
end
