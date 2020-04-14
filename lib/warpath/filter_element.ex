defmodule Warpath.FilterElement do
  @moduledoc false

  alias Warpath.Element.PathMarker
  alias Warpath.Expression
  alias Warpath.Filter.Predicate

  @type has_property :: Expression.has_property()
  @type operator :: Expression.operator()
  @type element :: Element.t() | [Element.t()]
  @type args :: [any, ...]
  @type filter_exp :: has_property() | {operator(), args}

  @spec filter(element(), filter_exp) :: element()
  def filter(member, filter_exp)

  def filter(elements, filter_exp) when is_list(elements) do
    Enum.flat_map(elements, &filter(&1, filter_exp))
  end

  def filter(%Element{} = element, filter_exp) do
    do_filter(element, fn value -> Predicate.eval(filter_exp, value) end)
  end

  defp do_filter(%Element{value: member} = element, filter_fun) when is_map(member) do
    if filter_fun.(member),
      do: [element],
      else: []
  end

  defp do_filter(%Element{value: members} = element, filter_fun) when is_list(members) do
    element
    |> PathMarker.stream()
    |> Enum.filter(fn %Element{value: member} -> filter_fun.(member) end)
  end

  defp do_filter(_, _), do: []
end
