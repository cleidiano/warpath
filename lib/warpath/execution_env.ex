defmodule Warpath.ExecutionEnv do
  @moduledoc false

  alias Warpath.ExecutionEnv, as: Env

  @type t :: %__MODULE__{instruction: any()}
  @type tokens :: [Warpath.Expression.token()]

  defstruct operator: nil, instruction: nil, previous_operator: nil

  def new(instr, previous_operator \\ nil) do
    %__MODULE__{
      operator: operator_for(instr),
      instruction: instr,
      previous_operator: previous_operator
    }
  end

  @spec execution_plan(tokens) :: list(Env.t())
  def execution_plan(tokens) when is_list(tokens) do
    tokens
    |> Enum.reduce([], fn token, acc ->
      previous_operator = List.first(acc)
      env = Env.new(token, previous_operator)
      [env | acc]
    end)
    |> Enum.reverse()
  end

  defp operator_for({:root, _}), do: RootOperator
  defp operator_for({:dot, _}), do: IdentifierOperator
  defp operator_for({:wildcard, _}), do: WildcardOperator
  defp operator_for({:scan, _}), do: DescendantOperator
  defp operator_for({:array_indexes, _}), do: ArrayIndexOperator
  defp operator_for({:filter, _}), do: FilterOperator
  defp operator_for({:array_slice, _}), do: SliceOperator
  defp operator_for({:union, _}), do: UnionOperator
end
