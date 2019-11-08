defmodule Warpath.Expression do
  @moduledoc false
  alias Warpath.Tokenizer
  alias Warpath.Parser
  alias Warpath.ExpressionError

  @type root :: {:root, String.t()}
  @type property :: {:property, String.t()}
  @type dot_access :: {:dot, property}
  @type index_access :: {:index_access, integer}
  @type array_indexes :: {:array_indexes, [index_access, ...]}
  @type wildcard :: {:wildcard, :*}
  @type array_wildcard :: {:array_wildcard, :*}
  @type comparator :: :> | :< | :==
  @type contains :: {:contains, property}
  @type filter :: {:filter, contains | {property, comparator, any}}

  @type scan ::
          {:scan, property}
          | {:scan, wildcard}
          | {:scan, filter}
          | {:scan, array_indexes}
          | {:scan, {wildcard, filter}}

  @type token ::
          root
          | dot_access
          | array_indexes
          | array_wildcard
          | filter
          | scan

  @spec compile(String.t()) :: {:ok, [token, ...]} | {:error, ExpressionError.t()}
  def compile(expression) when is_binary(expression) do
    with {:ok, tokens} <- Tokenizer.tokenize(expression),
         {:ok, _} = expression_tokens <- Parser.parse(tokens) do
      expression_tokens
    else
      {:error, error} ->
        {:error, Exception.message(error) |> ExpressionError.exception()}
    end
  end
end
