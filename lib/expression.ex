defmodule Warpath.Expression do
  def compile(expression) when is_binary(expression) do
    expression
    |> Warpath.Tokenizer.tokenize()
    |> case do
      {:ok, tokens, _} ->
        Warpath.Parser.parse(tokens)

      error ->
        error
    end
  end
end
