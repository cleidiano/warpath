defmodule Warpath.Execution.Env do
  @moduledoc false

  alias Warpath.Query.DescendantOperator
  alias Warpath.Query.FilterOperator
  alias Warpath.Query.IdentifierOperator
  alias Warpath.Query.IndexOperator
  alias Warpath.Query.RootOperator
  alias Warpath.Query.SliceOperator
  alias Warpath.Query.UnionOperator
  alias Warpath.Query.WildcardOperator

  @type operator :: module()
  @type instruction :: Warpath.Expression.token()
  @type metadata :: map()

  @type t :: %__MODULE__{
          instruction: instruction(),
          operator: operator(),
          previous_operator: operator(),
          metadata: metadata()
        }

  defstruct operator: nil, instruction: nil, previous_operator: nil, metadata: nil

  @spec new(instruction(), operator() | nil, map()) :: Warpath.Execution.Env.t()
  def new(instruction, previous_operator \\ nil, metadata \\ %{}) do
    %__MODULE__{
      operator: operator_for(instruction),
      instruction: instruction,
      previous_operator: previous_operator,
      metadata: metadata
    }
  end

  defp operator_for({:root, _}), do: RootOperator
  defp operator_for({:dot, _}), do: IdentifierOperator
  defp operator_for({:wildcard, _}), do: WildcardOperator
  defp operator_for({:scan, _}), do: DescendantOperator
  defp operator_for({:indexes, _}), do: IndexOperator
  defp operator_for({:filter, _}), do: FilterOperator
  defp operator_for({:slice, _}), do: SliceOperator
  defp operator_for({:union, _}), do: UnionOperator
end
