defmodule Warpath do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Warpath.AccessBuilder
  alias Warpath.Element
  alias Warpath.Element.Path
  alias Warpath.Execution
  alias Warpath.Execution.Env
  alias Warpath.Expression

  @type json :: String.t()

  @type container :: map | struct | list

  @type document :: container | json

  @type selector :: Expression.t() | String.t()

  @type updated_value :: any()

  @type update_fun :: (term() -> updated_value) | (Path.acc(), term() -> updated_value)

  @type opts :: [result_type: :value | :path | :value_path | :path_tokens | :value_path_tokens]

  @doc """
  Remove an item(s) from a nested data structure via the given `selector`.

  If the selector does not evaluate anything, it returns the data structure unchanged.
  > This function rely on `Access` behaviour, that means structs must implement that behaviour to got support.

  ## Examples

      iex> users = %{"john" => %{"age" => 27, "country" => "Brasil"}, "meg" => %{"age" => 23, "country" => "U.K"}}
      ...> Warpath.delete(users, "$..age")
      {:ok, %{"john" => %{"country" => "Brasil"}, "meg" => %{"country" => "U.K"}}}

      iex> numbers = %{"numbers" => [20, 3, 50, 6, 7]}
      ...> Warpath.delete(numbers, "$.numbers[?(@ < 10)]")
      {:ok, %{"numbers" => [20, 50]}}

      iex> numbers = %{"numbers" => [20, 3, 50, 6, 7]}
      ...> Warpath.delete(numbers, "$")
      {:ok, nil}

      iex> users = %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}
      ...> Warpath.delete(users, "$..city")
      {:ok, %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}} # Unchanged
  """
  @spec delete(document(), selector()) :: {:ok, container() | nil} | {:error, any}
  def delete(document, selector) do
    decode_run(
      document,
      &execute_change(
        &1,
        selector,
        fn {_tokens, path}, acc -> elem(pop_in(acc, path), 1) end
      )
    )
  end

  @doc """
  Query data for the given expression.

  ## Example
      iex> data_structure = %{"name" => "Warpath"}
      ...> Warpath.query(data_structure, "$.name")
      {:ok, "Warpath"}

      iex> raw_json = ~s/{"name": "Warpath"}/
      ...> Warpath.query(raw_json, "$.name")
      {:ok, "Warpath"}

      iex> #Pass a compiled expression as selector
      ...> {:ok, expression} = Warpath.Expression.compile("$.autobots[0]")
      ...> Warpath.query(%{"autobots" => ["Optimus Prime", "Warpath"]}, expression)
      {:ok, "Optimus Prime"}

  ## Options:
    result_type:
    * `:value` - return the value of evaluated expression - `default`
    * `:path` - return the bracketfiy path string representation of evaluated expression instead of it's value
    * `:value_path` - return both value and bracketify path string.
    * `:path_tokens` - return the path tokens instead of it string representation, see `Warpath.Element.Path`.
    * `:value_path_tokens` - return both value and path tokens.
  """
  @spec query(document, selector(), opts) :: {:ok, any} | {:error, any}
  def query(document, selector, opts \\ [])

  def query(document, selector, opts) when is_binary(document) do
    decode_run(document, &query(&1, selector, opts))
  end

  def query(document, selector, opts) when is_binary(selector) do
    case Expression.compile(selector) do
      {:ok, expression} ->
        query(document, expression, opts)

      {:error, _} = error ->
        error
    end
  end

  def query(document, %Expression{} = expression, opts) do
    result =
      expression
      |> Execution.execution_plan()
      |> Enum.reduce_while(Element.new(document, []), &dispatch/2)

    {:ok, collect(result, opts[:result_type] || :value)}
  end

  @doc """
    The same as query/3, but rise exception if it fail.
  """
  @spec query!(document, selector(), opts) :: any
  def query!(data, selector, opts \\ []) do
    case query(data, selector, opts) do
      {:ok, query_result} -> query_result
      {:error, error} -> raise error
    end
  end

  defp decode_run(json, fun) when is_binary(json) do
    json
    |> Jason.decode()
    |> case do
      {:ok, decoded} ->
        fun.(decoded)

      {:error, exception} ->
        {:error, Warpath.JsonDecodeError.from(exception)}
    end
  end

  defp decode_run(document, fun), do: fun.(document)

  defp dispatch(%Env{operator: operator} = env, elements) when is_list(elements) do
    output = operator.evaluate(elements, [], env)
    {label_of(output), output}
  end

  defp dispatch(%Env{operator: operator} = env, %Element{value: document, path: path}) do
    output = operator.evaluate(document, path, env)
    {label_of(output), output}
  end

  defp label_of([]), do: :halt
  defp label_of(_), do: :cont

  defp collect(elements, opt) when is_list(elements), do: Enum.map(elements, &collect(&1, opt))

  defp collect(%Element{path: path}, :path), do: Path.bracketify(path)
  defp collect(%Element{path: path}, :path_tokens), do: Enum.reverse(path)

  defp collect(%Element{value: member, path: path}, :value_path),
    do: {member, Path.bracketify(path)}

  defp collect(%Element{value: member, path: path}, :value_path_tokens),
    do: {member, Enum.reverse(path)}

  defp collect(%Element{value: member}, _), do: member

  @doc """
    Updates a nested data structure via the given `selector`.

    The `fun` will be called for each item discovered under the given `selector`, the `fun` result will be used to update the data structure.

    If the selector does not evaluate anything, it returns the data structure unchanged.
    > This function rely on `Access` behaviour, that means structs must implement that behaviour to got support.

  ## Examples
      iex> users = %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}
      ...> Warpath.update(users, "$.john.age", &(&1 + 1))
      {:ok, %{"john" => %{"age" => 28}, "meg" => %{"age" => 23}}}

      iex> numbers = %{"numbers" => [20, 3, 50, 6, 7]}
      ...> Warpath.update(numbers, "$.numbers[?(@ < 10)]", &(&1 * 2))
      {:ok, %{"numbers" => [20, 6, 50, 12, 14]}}

      iex> users = %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}
      ...> Warpath.update(users, "$.theo.age", &(&1 + 1))
      {:ok, %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}} # Unchanaged
  """

  @spec update(document(), selector(), update_fun()) ::
          {:ok, container() | updated_value()} | {:error, any}
  def update(document, selector, fun) when is_function(fun, 2) do
    decode_run(
      document,
      &execute_change(
        &1,
        selector,
        fn {tokens, path}, acc ->
          update_in(acc, path, fn node -> fun.(tokens, node) end)
        end
      )
    )
  end

  def update(document, selector, fun) when is_function(fun, 1) do
    update(document, selector, fn _tokens, node -> fun.(node) end)
  end

  defp execute_change(document, selector, reducer) do
    case query(document, selector, result_type: :path_tokens) do
      {:ok, [head | _] = paths} ->
        longest_paths_first =
          if is_list(head) do
            paths
            |> Enum.uniq()
            |> Enum.sort(&>=/2)
          else
            paths
          end

        {:ok,
         longest_paths_first
         |> AccessBuilder.build()
         |> Enum.reduce(document, reducer)}

      {:ok, []} ->
        {:ok, document}

      error ->
        error
    end
  end
end
