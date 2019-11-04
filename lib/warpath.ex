defmodule Warpath do
  @moduledoc """
    Public api for query elixir data strucutre as JsonPath proposal on https://goessner.net/articles/JsonPath/
  """
  alias Warpath.{Expression, Engine}

  @spec query(any, String.t(), result_type: :value | :path | :both) :: any
  def query(data, expression, opts \\ []) when is_binary(expression) do
    with {:ok, expression} <- Expression.compile(expression),
         {:ok, query_result} <- Engine.query(data, expression, opts) do
      query_result
    else
      error ->
        error
    end
  end
end
