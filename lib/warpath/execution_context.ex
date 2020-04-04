defmodule Warpath.ExecutionContext do
  alias __MODULE__

  @typep token :: Warpath.Expression.token()
  @type t :: %ExecutionContext{current_token: token(), previous_token: token()}

  defstruct [:current_token, :previous_token]

  def new(current_token, previous_token \\ nil) do
    %ExecutionContext{current_token: current_token, previous_token: previous_token}
  end

  def put_current_token(%ExecutionContext{current_token: current_token} = context, next_token) do
    context
    |> Map.put(:current_token, next_token)
    |> Map.put(:previous_token, current_token)
  end

  def current_token(%ExecutionContext{current_token: token}) do
    token
  end

  def previous_token(%ExecutionContext{previous_token: token}) do
    token
  end
end
