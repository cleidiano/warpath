defmodule Warpath.Expression do
  @moduledoc false
  alias Warpath.ExpressionError

  @type root :: {:root, String.t()}
  @type property :: {:property, String.t()}
  @type dot_access :: {:dot, property}
  @type index_access :: {:index_access, integer}
  @type array_indexes :: {:array_indexes, list(index_access)}
  @type array_wildcard :: {:array_wildcard, atom}
  @type operator :: :> | :< | :==
  @type filter :: {:filter, {property, operator, number}}
  @type scan :: {:scan, property}

  @type token ::
          root
          | dot_access
          | array_indexes
          | array_wildcard
          | filter
          | scan

  @spec compile(String.t()) :: {:ok, list(token)} | {:error, ExpressionError.t()}
  def compile(expression) when is_binary(expression) do
    with {:ok, tokens, _} <- Warpath.Tokenizer.tokenize(expression),
         {:ok, _} = expression_tokens <- Warpath.Parser.parse(tokens) do
      expression_tokens
    else
      {:error, {line, _module, message}, _} ->
        exception("Invalid syntax on line #{line}, #{inspect(message)}")

      {:error, {line, _module, message}} ->
        exception("Parser error: Invalid token on line #{line}, #{List.to_string(message)}")

      {:error, error} ->
        {:error, inspect(error) |> exception()}
    end
  end

  defp exception(message), do: {:error, ExpressionError.exception(message)}
end

defmodule Warpath.ExpressionError do
  defexception [:message]
end
