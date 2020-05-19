defmodule Warpath.Expression do
  @moduledoc false

  alias Warpath.Expression.Parser
  alias Warpath.Expression.Tokenizer
  alias Warpath.ExpressionError

  @type root :: {:root, String.t()}

  @type property :: {:property, String.t() | atom()}

  @type dot_access :: {:dot, property}

  @type has_property :: {:has_property?, property}

  @type index :: integer()

  @type indexes :: {:indexes, [{:index_access, index}, ...]}

  @type array_slice ::
          {:array_slice,
           [
             {:start_index, index},
             {:end_index, index},
             {:step, index}
           ]}

  @type wildcard :: {:wildcard, :*}

  @type union :: {:union, [dot_access, ...]}

  @type operator :: :< | :> | :<= | :>= | :== | :!= | :=== | :!== | :not | :and | :or | :in

  @type fun ::
          :is_atom
          | :is_binary
          | :is_boolean
          | :is_float
          | :is_integer
          | :is_list
          | :is_map
          | :is_nil
          | :is_number
          | :is_tuple

  @type filter :: {:filter, has_property | {operator | fun, term}}

  @type scan :: {:scan, property | wildcard | filter | indexes}

  @type token ::
          root()
          | indexes()
          | array_slice()
          | dot_access()
          | filter()
          | scan()
          | union()
          | wildcard()

  @spec compile(String.t()) :: {:ok, nonempty_list(token)} | {:error, ExpressionError.t()}
  def compile(expression) when is_binary(expression) do
    with {:ok, tokens} <- Tokenizer.tokenize(expression),
         {:ok, _} = expression_tokens <- Parser.parse(tokens) do
      expression_tokens
    else
      {:error, error} ->
        message = Exception.message(error)
        {:error, ExpressionError.exception(message)}
    end
  end
end
