defmodule Warpath.Filter.Predicate do
  @moduledoc false

  @operators [
    :<,
    :>,
    :<=,
    :>=,
    :==,
    :!=,
    :===,
    :!==,
    :and,
    :or,
    :in
  ]

  @functions [
    :is_atom,
    :is_binary,
    :is_boolean,
    :is_float,
    :is_integer,
    :is_list,
    :is_map,
    :is_nil,
    :is_number,
    :is_tuple,
    :not
  ]

  @current_node {:current_node, "@"}

  @type expression ::
          {:property, atom() | String.t()}
          | {:index_access, integer()}
          | {:current_node, String.t()}

  @spec eval(boolean | {atom, expression}, any) :: boolean()
  def eval({:literal, false}, _), do: false
  def eval({:literal, true}, _), do: true

  for action <- [:has_property?] ++ @operators ++ @functions do
    def eval({unquote(action), _} = expression, context) do
      resolve(expression, context)
    catch
      error when error in [:not_indexable_type, :not_container_type] -> false
    end
  end

  for operator <- @operators do
    defp resolve({unquote(operator), [left, right]}, context) do
      unquote(operator)(resolve(left, context), resolve(right, context))
    end
  end

  for function <- @functions do
    defp resolve({unquote(function), expression}, context) do
      unquote(function)(resolve(expression, context))
    end
  end

  defp resolve(@current_node, context), do: context

  defp resolve({:literal, value}, _context), do: value

  defp resolve({:subpath_expression, tokens}, context) do
    Enum.reduce(tokens, context, fn token, acc -> resolve(token, acc) end)
  end

  defp resolve({:has_property?, {:subpath_expression, tokens}}, context) do
    {last_token, rest} = List.pop_at(tokens, -1)
    result = resolve({:subpath_expression, rest}, context)

    case {result, last_token} do
      {map, {:dot, {:property, key}}} when is_map(map) ->
        Map.has_key?(map, key)

      {list, {:dot, {:property, key}}} when is_list(list) and is_atom(key) ->
        Keyword.has_key?(list, key)

      {list, {:indexes, [index_access: index]}} when is_list(list) and index >= 0 ->
        length(list) > index

      {list, {:indexes, [index_access: index]}} when is_list(list) ->
        count = length(list)
        count + index >= 0

      _ ->
        false
    end
  end

  defp resolve({:dot, {:property, name}}, context) do
    case {context, name} do
      {map = %{}, key} ->
        Map.get(map, key)

      {list, key} when is_list(list) and is_atom(key) ->
        Access.get(list, key)

      _ ->
        throw(:not_container_type)
    end
  end

  defp resolve({:indexes, [index_access: index]}, context) do
    case context do
      nil ->
        nil

      indexable when is_list(indexable) ->
        Enum.at(indexable, index)

      _ ->
        throw(:not_indexable_type)
    end
  end

  false

  defp resolve(term, context) when is_list(term) do
    Enum.map(term, &resolve(&1, context))
  end
end
