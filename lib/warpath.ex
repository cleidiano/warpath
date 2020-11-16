defmodule Warpath do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Warpath.Element
  alias Warpath.Element.Path
  alias Warpath.Execution
  alias Warpath.Execution.Env
  alias Warpath.Expression

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
  @type json :: String.t()
  @type document :: map | list | json
  @type selector :: Expression.t() | String.t()
  @type opts :: [result_type: :value | :path | :value_path | :path_tokens | :value_path_tokens]

  @spec query(document, selector(), opts) :: {:ok, any} | {:error, any}
  def query(document, selector, opts \\ [])

  def query(document, selector, opts) when is_binary(document) do
    document
    |> Jason.decode()
    |> case do
      {:ok, decoded_document} ->
        query(decoded_document, selector, opts)

      {:error, exception} ->
        {:error, Warpath.JsonDecodeError.from(exception)}
    end
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
    expression
    |> Execution.execution_plan()
    |> Enum.reduce_while(Element.new(document, []), &dispatch/2)
    |> case do
      {:error, _} = error ->
        error

      result ->
        {:ok, collect(result, opts[:result_type] || :value)}
    end
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

  @doc """
    Remove an item(s) from a nested data structure via the given `selector`.

  ## Examples
      iex> users = %{"john" => %{"age" => 27, "country" => "Brasil"}, "meg" => %{"age" => 23}}
      ...> Warpath.delete(users, "$.john.country")
      {:ok, %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}}

      iex> users = %{"john" => %{"age" => 27, "country" => "Brasil"}, "meg" => %{"age" => 23, "country" => "U.K"}}
      ...> Warpath.delete(users, "$..age")
      {:ok, %{"john" => %{"country" => "Brasil"}, "meg" => %{"country" => "U.K"}}}
  """
  @spec delete(document(), selector()) :: {:ok, data} | {:error, any}
        when data: map | list()
  def delete(document, expression) do
    with {:ok, paths} <- query(document, expression, result_type: :path_tokens) do
      data =
        paths
        |> maybe_wrap()
        |> do_delete(document)

      {:ok, data}
    else
      error ->
        error
    end
  end

  @doc """
    Updates a nested data structure via the given `selector`.

    The `fun` will be called for each item discovered under the given `selector`, the `fun` result will be used to update the data structure.

  ## Examples
      iex> users = %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}
      ...> Warpath.update(users, "$.john.age", &(&1 + 1))
      {:ok, %{"john" => %{"age" => 28}, "meg" => %{"age" => 23}}}

      iex> users = %{"john" => %{"age" => 27}, "meg" => %{"age" => 23}}
      ...> Warpath.update(users, "$..[?(@.age < 27)].age", &(&1 + 1))
      {:ok, %{"john" => %{"age" => 27}, "meg" => %{"age" => 24}}}
  """
  @spec update(document(), selector(), (term() -> term())) :: {:ok, data} | {:error, any}
        when data: map | list()
  def update(document, selector, fun) do
    with {:ok, paths} <- query(document, selector, result_type: :path_tokens) do
      data =
        paths
        |> maybe_wrap()
        |> do_get_and_update_in(document, fn value -> {value, fun.(value)} end)

      {:ok, data}
    else
      error ->
        error
    end
  end

  defp maybe_wrap(paths) do
    case paths do
      [{:root, _} | _] -> [paths]
      _ -> paths
    end
  end

  defp do_delete([], data), do: data

  defp do_delete([h | _] = paths, data) do
    patched_paths =
      if match?([{:index_access, _} | _], :lists.reverse(h)) do
        paths
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.with_index()
        |> Enum.map(fn {path, delete_count} ->
          [{:index_access, index} | tail] = :lists.reverse(path)
          :lists.reverse([{:index_access, index - delete_count} | tail])
        end)
      else
        paths
      end

    do_get_and_update_in(patched_paths, data, fn _ -> :pop end)
  end

  defp do_get_and_update_in(paths, data, fun) do
    Enum.reduce(
      paths,
      data,
      fn exp, container ->
        container
        |> get_and_update_in(to_accessor(exp), fun)
        |> elem(1)
      end
    )
  end

  defp to_accessor([{:root, _} | _] = path_tokens) do
    path_tokens
    |> Keyword.delete(:root)
    |> Enum.map(fn
      {:property, property} ->
        property

      {:index_access, index} ->
        Access.at(index)
    end)
  end

  # query
  defp dispatch(%Env{operator: operator} = env, elements) when is_list(elements) do
    output = operator.evaluate(elements, [], env)
    {label_of(output), output}
  end

  defp dispatch(%Env{operator: operator} = env, %Element{value: document, path: path}) do
    output = operator.evaluate(document, path, env)
    {label_of(output), output}
  end

  defp label_of([]), do: :halt
  defp label_of({:error, _}), do: :halt
  defp label_of(_), do: :cont

  defp collect(elements, opt) when is_list(elements), do: Enum.map(elements, &collect(&1, opt))

  defp collect(%Element{path: path}, :path), do: Path.bracketify(path)
  defp collect(%Element{path: path}, :path_tokens), do: Enum.reverse(path)

  defp collect(%Element{value: member, path: path}, :value_path),
    do: {member, Path.bracketify(path)}

  defp collect(%Element{value: member, path: path}, :value_path_tokens),
    do: {member, Enum.reverse(path)}

  defp collect(%Element{value: member}, _), do: member
end
