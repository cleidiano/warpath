defmodule Warpath.Execution do
  @moduledoc false

  alias Warpath.Execution.Env
  alias Warpath.Expression

  @spec execution_plan(Expression.t()) :: list(Env.t())
  def execution_plan(%Expression{tokens: tokens}) do
    tokens
    |> Enum.reduce([], fn token, acc ->
      previous_operator = List.first(acc)
      env = Env.new(token, previous_operator)

      [env | acc]
    end)
    |> Enum.reverse()
  end
end
