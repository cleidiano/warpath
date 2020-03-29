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

  def eval({action, _} = expression, context)
      when action == :has_property?
      when action in @operators
      when action in @functions do
    resolve(expression, context)
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

  defp resolve({:index_access, index}, context) when is_list(context) or is_map(context),
    do: Enum.at(context, index)

  defp resolve(:current_node, context),
    do: context

  defp resolve(term, context) when is_list(term) do
    Enum.map(term, &resolve(&1, context))
  end

  defp resolve(term, _context),
    do: term
end
