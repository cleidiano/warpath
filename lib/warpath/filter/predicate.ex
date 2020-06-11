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

  actions = [:has_property?] ++ @operators ++ @functions

  for action <- actions do
    def eval({unquote(action), _} = expression, context) do
      resolve(expression, context)
    catch
      :not_indexable_type -> false
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

  defp resolve({:has_property?, {:property, name}}, context),
    do: is_map(context) and Map.has_key?(context, name)

  defp resolve({:property, name}, context) when is_map(context),
    do: context[name]

  defp resolve({:index_access, index}, context) do
    case context do
      nil ->
        nil

      list when is_list(list) ->
        Enum.at(context, index)

      _ ->
        throw(:not_indexable_type)
    end
  end

  defp resolve(:current_node, context),
    do: context

  defp resolve(term, context) when is_list(term) do
    Enum.map(term, &resolve(&1, context))
  end

  defp resolve(term, _context),
    do: term
end
