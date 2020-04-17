defmodule Warpath.ExecutionEnv do
  alias Warpath.ExecutionEnv, as: Env

  @type t :: %__MODULE__{instruction: any()}

  defstruct operator: nil, instruction: nil, previous_operator: nil

  # TODO Resolver operator dado a instrução
  def new(operator, instr, previous_operator \\ nil) do
    %__MODULE__{
      operator: operator,
      instruction: instr,
      previous_operator: previous_operator
    }
  end

  @type tokens :: [Warpath.Expression.token()]

  @spec execution_plan(tokens) :: list(Env.t())
  def execution_plan(tokens) when is_list(tokens) do
    tokens
    |> Enum.reduce([], fn token, acc ->
      env = translate(token, List.first(acc))
      [env | acc]
    end)
    |> Enum.reverse()
  end

  defp translate({:root, _} = instr, nil), do: Env.new(RootOperator, instr)
  defp translate({:dot, _} = instr, previous), do: Env.new(IdentifierOperator, instr, previous)
  defp translate({:wildcard, _} = instr, previous), do: Env.new(WildcardOperator, instr, previous)
  defp translate({:scan, _} = instr, previous), do: Env.new(DescendantOperator, instr, previous)

  defp translate({:array_indexes, _} = instr, previous),
    do: Env.new(ArrayIndexOperator, instr, previous)

  defp translate({:filter, instr}, previous), do: Env.new(FilterOperator, instr, previous)
  defp translate({:array_slice, _} = instr, previous), do: Env.new(SliceOperator, instr, previous)
  defp translate({:union, _} = instr, previous), do: Env.new(UnionOperator, instr, previous)
end
