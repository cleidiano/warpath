defmodule Warpath.Engine.Filter do
  @moduledoc false

  alias Warpath.Engine.PathMarker
  alias Warpath.Expression

  @comparators [:>, :<, :==]

  @type member :: any
  @type filter_exp ::
          Expression.contains() | {Expression.property(), Expression.comparator(), any}

  @spec filter({member, ItemPath.t()}, filter_exp) :: [{member, ItemPath.t()}, ...]
  def filter(member, filter_exp)

  def filter({_, _} = element, {{:property, property}, comparator, operand})
      when comparator in @comparators do
    filter_fun = fn member ->
      apply(Kernel, comparator, [member[property], operand])
    end

    do_filter(element, filter_fun)
  end

  def filter({_, _} = element, {:contains, {:property, property}}) do
    do_filter(element, &Map.has_key?(&1, property))
  end

  defp do_filter({member, path}, filter_fun) when is_map(member) do
    if filter_fun.(member), do: [{member, path}], else: []
  end

  defp do_filter({members, _} = element, filter_fun) when is_list(members) do
    element
    |> PathMarker.stream()
    |> Enum.filter(fn {member, _} -> filter_fun.(member) end)
  end

  defp do_filter(_, _), do: []
end
