defmodule Warpath.Expression.Parser do
  @moduledoc false

  alias Warpath.Expression.ParserError

  def parse(tokens) when is_list(tokens) do
    tokens
    |> :warpath_parser.parse()
    |> case do
      {:ok, _} = expression_tokens ->
        expression_tokens

      {:error, {line, _module, message}} ->
        error_message = "Parser error: Invalid token on line #{line}, #{List.to_string(message)}"
        {:error, ParserError.exception(error_message)}
    end
  end

  def parse!(tokens) when is_list(tokens) do
    tokens
    |> parse()
    |> case do
      {:ok, expression_tokens} ->
        expression_tokens

      {:error, exception} ->
        raise exception
    end
  end
end
