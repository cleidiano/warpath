defmodule Warpath.Execution do
  @moduledoc false

  alias Warpath.Execution.Env

  @type tokens :: [Warpath.Expression.token()]

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
end
