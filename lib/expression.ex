defmodule Warpath.Expression do
  @moduledoc false
  alias Warpath.ExpressionError

  @typep root :: {:root, String.t()}
  @typep property :: {:property, String.t()}
  @typep dot_access :: {:dot, property}
  @typep index_access :: {:index_access, integer}
  @typep array_indexes :: {:array_indexes, list(index_access)}
  @typep array_wildcard :: {:array_wildcard, atom}
  @typep operator :: :> | :< | :==
  @typep filter :: {:filter, {property, operator, number}}
  @typep scan :: {:scan, property}

  @typep token ::
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
      {:error, {_, :tokenizer, _} = tokenizer_error, _} ->
        {:error, exception(tokenizer_error)}

      {:error, error} ->
        {:error, exception(error)}
    end
  end

  defp exception(error), do: inspect(error) |> ExpressionError.exception()
end

defmodule Warpath.ExpressionError do
  defexception [:message]
end
