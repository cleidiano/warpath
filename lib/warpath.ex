defmodule Warpath do
  @moduledoc """
    Public api for query elixir data strucutre as JsonPath proposal on https://goessner.net/articles/JsonPath/
  """
  alias Warpath.{Expression, Engine}

  def query(data, expression, opts \\ []) when is_binary(expression) do
    with {:ok, expression} <- Expression.compile(expression),
         {:ok, [itens | trace]} <- Engine.query(data, expression) do
      case opts[:result_type] do
        :trace -> Engine.ItemPath.bracketify(trace)
        _ -> itens
      end
    else
      error ->
        error
    end
  end
end
