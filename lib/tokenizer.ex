defmodule Tokenizer do
  def tokenize(term) do
    term
    |> String.to_charlist()
    |> :tokenizer.string()
  end

  def tokenize!(term) do
    term
    |> tokenize()
    |> case do
      {:ok, tokens, _} -> tokens
      error -> raise RuntimeError, "#{inspect(error)}"
    end
  end
end
