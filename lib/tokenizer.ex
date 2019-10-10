defmodule Warpath.Tokenizer do
  @moduledoc false
  def tokenize(term) when is_binary(term) do
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
