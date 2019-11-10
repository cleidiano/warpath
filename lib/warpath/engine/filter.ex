defmodule Warpath.Engine.Filter do
  @moduledoc false

  alias Warpath.Engine.PathMarker
  alias Warpath.Expression
  alias Warpath.Element
  @comparators [:>, :<, :==]

  @type member :: any
  @type filter_exp ::
          Expression.contains() | {Expression.property(), Expression.comparator(), any}

  @spec filter({member, Element.Path.t()}, filter_exp) :: [{member, Element.Path.t()}, ...]
  def filter(member, filter_exp)

  def filter({_, _} = element, {{:property, name}, comparator, operand})
      when comparator in @comparators do
    filter_fun = fn member ->
      is_map(member) and
        Map.has_key?(member, name) and
        apply(Kernel, comparator, [member[name], operand])
    end

    do_filter(element, filter_fun)
  end

  def filter({_, _} = element, {:contains, {:property, property}}) do
    do_filter(element, fn term -> is_map(term) and Map.has_key?(term, property) end)
  end

  def filter(elements, filter_exp) when is_list(elements) do
    Enum.flat_map(elements, &filter(&1, filter_exp))
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
