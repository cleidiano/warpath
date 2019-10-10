defmodule Warpath do
  @moduledoc """
    Public api for query elixir data strucutre as JsonPath proposal on https://goessner.net/articles/JsonPath/
  """
  alias Warpath.{Expression, Engine}

  def query(data, expression, opts \\ []) when is_binary(expression) do
    expression
    |> Expression.compile()
    |> case do
      {:ok, expression} ->
        Engine.query(data, expression, opts)

      error ->
        error
    end
  end
end
