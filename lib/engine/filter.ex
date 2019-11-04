defmodule Warpath.Engine.Filter do
  @moduledoc false

  alias Warpath.Engine.Trace
  alias Warpath.Engine.ItemPath
  alias Warpath.Expression

  @comparators [:>, :<, :==]

  @type filter_exp ::
          Expression.contains() | {Expression.property(), Expression.comparator(), any}

  @spec filter({any, ItemPath.t()}, filter_exp) :: [{any, ItemPath.t()}, ...]
  def filter(any, filter_exp)

  def filter({_, _} = term, {{:property, property}, comparator, operand})
      when comparator in @comparators do
    filter_fun = fn item ->
      apply(Kernel, comparator, [item[property], operand])
    end

    do_filter(term, filter_fun)
  end

  def filter({_, _} = term, {:contains, {:property, property}}) do
    do_filter(term, &Map.has_key?(&1, property))
  end

  defp do_filter({data, trace}, filter_fun) when is_map(data) do
    if(filter_fun.(data), do: [{data, trace}], else: [])
  end

  defp do_filter({data, _} = term, filter_fun) when is_list(data) do
    term
    |> Trace.stream()
    |> Enum.filter(fn {item, _} -> filter_fun.(item) end)
  end

  defp do_filter(_, _), do: []
end
