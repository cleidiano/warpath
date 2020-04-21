defmodule Warpath.Execution.Env do
  @moduledoc false

  @type t :: %__MODULE__{instruction: any()}

  defstruct operator: nil, instruction: nil, previous_operator: nil

  def new(instruction, previous_operator \\ nil) do
    %__MODULE__{
      operator: operator_for(instruction),
      instruction: instruction,
      previous_operator: previous_operator
    }
  end

  defp operator_for({:root, _}), do: Warpath.Query.RootOperator
  defp operator_for({:dot, _}), do: Warpath.Query.IdentifierOperator
  defp operator_for({:wildcard, _}), do: Warpath.Query.WildcardOperator
  defp operator_for({:scan, _}), do: Warpath.Query.DescendantOperator
  defp operator_for({:array_indexes, _}), do: Warpath.Query.ArrayIndexOperator
  defp operator_for({:filter, _}), do: Warpath.Query.FilterOperator
  defp operator_for({:array_slice, _}), do: Warpath.Query.SliceOperator
  defp operator_for({:union, _}), do: Warpath.Query.UnionOperator
end
