defmodule Warpath.Tokenizer do
  @moduledoc false

  alias Warpath.TokenizerError

  def tokenize(term) when is_binary(term) do
    term
    |> String.to_charlist()
    |> :warpath_tokenizer.string()
    |> case do
      {:ok, tokens, _lines} ->
        {:ok, tokens}

      {:error, {line, _module, message}, _} ->
        {:error, TokenizerError.exception("Invalid syntax on line #{line}, #{inspect(message)}")}
    end
  end

  def tokenize!(term) do
    term
    |> tokenize()
    |> case do
      {:ok, tokens} -> tokens
      {:error, tokenizer_error} -> raise tokenizer_error
    end
  end
end
