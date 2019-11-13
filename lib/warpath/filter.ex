defmodule Warpath.Filter do
  @moduledoc false

  alias Warpath.Element
  alias Warpath.Element.PathMarker
  alias Warpath.Expression
  alias Warpath.Filter.Predicate

  @type contains :: Expression.contains()
  @type operator :: Expression.operator()
  @type member :: any
  @type filter_exp :: contains() | {operator(), maybe_improper_list(any, any)}

  @spec filter({member, Element.Path.t()}, filter_exp) :: [{member, Element.Path.t()}, ...]
  def filter(member, filter_exp)

  def filter(elements, filter_exp) when is_list(elements) do
    Enum.flat_map(elements, &filter(&1, filter_exp))
  end

  def filter({_, _} = element, filter_exp) do
    do_filter(element, &Predicate.eval(filter_exp, &1))
  end

  defp do_filter({member, path}, filter_fun) when is_map(member) do
    if filter_fun.(member),
      do: [{member, path}],
      else: []
  end

  defp do_filter({members, _} = element, filter_fun) when is_list(members) do
    element
    |> PathMarker.stream()
    |> Enum.filter(fn {member, _} -> filter_fun.(member) end)
  end

  defp do_filter(_, _), do: []
end
