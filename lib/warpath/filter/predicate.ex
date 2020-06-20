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
          | {:at, String.t()}

  @spec eval(boolean | {atom, expression}, any) :: boolean()
  def eval({:literal, false}, _), do: false
  def eval({:literal, true}, _), do: true

  for action <- [:has_property?] ++ @operators ++ @functions do
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

  defp resolve({:subpath_expression, [@current_node, dot: {:property, name}]}, %{} = context),
    do: context[name]

  defp resolve({:subpath_expression, [@current_node, indexes: _]}, nil), do: nil

  defp resolve({:subpath_expression, [@current_node, indexes: [index_access: index]]}, context)
       when is_list(context),
       do: Enum.at(context, index)

  defp resolve({:subpath_expression, [@current_node, indexes: _]}, _),
    do: throw(:not_indexable_type)

  defp resolve({:subpath_expression, tokens}, context) do
    expression = %Warpath.Expression{tokens: tokens}
    {:ok, value} = Warpath.query(context, expression)
    value
  end

  defp resolve(@current_node, context), do: context

  defp resolve(term, context) when is_list(term) do
    Enum.map(term, &resolve(&1, context))
  end

  defp resolve({:literal, value}, _context), do: value
end
