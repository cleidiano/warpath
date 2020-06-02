defmodule Warpath do
  @moduledoc """
    A implementation of Jsonpath expression proposal by [Stefan Goessner](https://goessner.net/articles/JsonPath/) for Elixir.

    Warpath support dot–notation expression `$.store.book[0].author` or the bracket–notation `$['store']['book'][0]['author']`.

  ## Operators
    | Operator                  | Description                                                        |
    | :------------------------ | :----------------------------------------------------------------- |
    | `$`                       | The root element to query. This starts all path expressions.       |
    | `@`                       | The current node being processed by a filter predicate.            |
    | `*`                       | Wildcard. All objects/elements regardless their names.             |
    | `..`                      | Deep scan, recursive descent.                                      |
    | `.name`                   | Dot-notated child, it support string or atom as keys.              |
    | `['name']`,`["name"]`     | Bracket-notated child, it support string or atom as keys.          |
    | `[int (,int>)]`           | Array index or indexes                                             |
    | `[start:end:step]`        | Array slice operator. Start index **inclusive**, end index **exclusive**. |
    | `[?(expression)]`         | Filter expression. Expression must evaluate to a boolean value.    |

  ## Filter operators
    Filter are expression that must be evaluated to a boolean value, Warpath will use then to retain data when filter a list,
    a filter expression have the syntax like this `[?( @.category == 'fiction' )]`.

    All filter operator supported by Warpath have the same behavior of Elixir lang,
    it means that it's possible to compare different data types.

    The down side of this approach is that filter a list with
    different data types could result in undesired output, for example:
    ```
    iex> data = [:atom, "string", 11]
    ...> Warpath.query(data, "$[?(@ > 10)]")
    {:ok, [:atom, "string", 11]}
    ```

    The expression were evaluate and return the entirely input list as the output, this happen
    because the way elixir implement comparison, check the [Elixir getting started](https://elixir-lang.org/getting-started/basic-operators.html)
    page for more information.

    To cover this case Warpath support some functions to check the underline data type that
    the filter is operate on, it could be combined with `and` operator to gain the strictness among comparison.

    The above expression could be rewrite to retain only integer values that is greater than 10 like this.
      iex> data = [:atom, "string", 11]
      ...> Warpath.query(data, "$[?(@ > 10 and is_integer(@))]")
      {:ok, [11]}

    | Operator                 | Description                                                         |
    | :----------------------- | :------------------------------------------------------------------ |
    | ==                       | left is equal to right                                              |
    | ===                      | left is equal to right in strict mode                               |
    | !=                       | left is not equal to right                                          |
    | !==                      | left is not equal to right in strict mode                           |
    | <                        | left is less than right                                             |
    | <=                       | left is less or equal to right                                      |
    | >                        | left is greater than right                                          |
    | >=                       | left is greater than or equal to right                              |
    | in                       | left exists in right `[?(@.price in [10, 20, 30])]`                 |
    | and,&&                   | logical and operator `[?(@.price > 50 and @.price < 100)]`          |
    | or,&#124;&#124;          | logical or operator `[?(@.category == 'fiction' or @.price < 100)]` |
    | not                      | logical not operator `[?(not @.category == 'fiction')]`             |


    | Function            | Description                   |
    | :------------------ | :--------------------------- |
    | is_atom/1           | check if the given expression argument is evaluate to atom       |
    | is_binary/1         | check if the given expression argument is evaluate to binary     |
    | is_boolean/1        | check if the given expression argument is evaluate to boolean    |
    | is_float/1          | check if the given expression argument is evaluate to float      |
    | is_integer/1        | check if the given expression argument is evaluate to integer    |
    | is_list/1           | check if the given expression argument is evaluate to list       |
    | is_map/1            | check if the given expression argument is evaluate to map        |
    | is_nil/1            | check if the given expression argument is evaluate to nil        |
    | is_number/1         | check if the given expression argument is evaluate to number     |
    | is_tuple/1          | check if the given expression argument is evaluate to tuple      |

  ## Examples

      #Dot-notated access
      iex>Warpath.query(%{"category" => "fiction", "price" => 12.99}, "$.category")
      {:ok, "fiction"}

      #Dot-notated using unicode as key
      iex>Warpath.query(%{"🌢" => "Elixir"}, "$.🌢")
      {:ok, "Elixir"}

      #Bracket-notated access
      iex>Warpath.query(%{"key with whitespace" => "some value"}, "$.['key with whitespace']")
      {:ok, "some value"}

      #atom based access
      iex>Warpath.query(%{atom_key: "some value"}, "$.:atom_key")
      {:ok, "some value"}

      #quoted atom
      iex>Warpath.query(%{"atom key": "some value"}, ~S{$.:"atom key"})
      {:ok, "some value"}

      #wildcard access
      iex>document = %{"store" => %{"car" => %{"price" => 100_000}, "bicycle" => %{"price" => 500}}}
      ...>Warpath.query(document, "$.store.*.price")
      {:ok, [500, 100_000]}

      #scan operator
      iex>document = %{"store" => %{"car" => %{"price" => 100_000}, "bicycle" => %{"price" => 500}}}
      ...>Warpath.query(document, "$..price")
      {:ok, [500, 100_000]}

      #filter operator
      iex>document = %{"store" => %{"car" => %{"price" => 100_000}, "bicycle" => %{"price" => 500}}}
      ...> Warpath.query(document, "$..*[?( @.price > 500 and is_integer(@.price) )]")
      {:ok, [%{"price" => 100000}]}

      #contains filter operator
      iex>document = %{"store" => %{"car" => %{"price" => 100_000}, "bicyle" => %{"price" => 500}}}
      ...> Warpath.query(document, "$..*[?(@.price)]")
      {:ok, [%{"price" => 500}, %{"price" => 100_000}]}

      #index access
      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[0, 1]")
      {:ok, [100, 200]}

      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[-1]")
      {:ok, 300}

      #wildcard as index access
      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[*]")
      {:ok, [100, 200, 300]}

      #union
      iex>document = %{"key" => "value", "another" => "entry"}
      ...> Warpath.query(document, "$['key', 'another']")
      {:ok, ["value", "entry"]}

      iex> document = [0, 1, 2, 3, 4]
      ...> Warpath.query(document, "$[0,3]")
      {:ok, [0, 3]}

      #slice operator
      iex> document = [0, 1, 2, 3, 4]
      ...> Warpath.query(document, "$[0:2:1]")
      {:ok, [0, 1]}

      #optional start and step
      iex> document = [0, 1, 2, 3, 4]
      ...> Warpath.query(document, "$[:2]")
      {:ok, [0, 1]}

      #Negative index
      iex> document = [0, 1, 2, 3, 4]
      ...> Warpath.query(document, "$[-2:]")
      {:ok, [3, 4]}

      #options
      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[0, 1]", result_type: :path)
      {:ok, ["$['integers'][0]", "$['integers'][1]"]}

      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[0]", result_type: :path_tokens)
      {:ok, [{:root, "$"}, {:property, "integers"}, {:index_access, 0}]}

      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[0, 1]", result_type: :value_path)
      {:ok, [{100, "$['integers'][0]"}, {200, "$['integers'][1]"}]}

      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[0]", result_type: :value_path_tokens)
      {:ok, {100, [{:root, "$"}, {:property, "integers"}, {:index_access, 0}]}}
  """
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
    * `:value` -  return the value of evaluated expression - `default`
    * `:path` - return the path of evaluated expression instead of it's value
    * `:value_path` - return both value and path.
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
    |> Jason.decode!()
    |> query(selector, opts)
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
  @spec query!(document, String.t(), opts) :: any
  def query!(data, selector, opts \\ []) do
    case query(data, selector, opts) do
      {:ok, query_result} -> query_result
      {:error, error} -> raise error
    end
  end

  defp dispatch(%Env{operator: operator} = env, elements) when is_list(elements) do
    output = operator.evaluate(elements, [], env)
    {label_of(output), output}
  end

  defp dispatch(%Env{operator: operator} = env, %Element{value: document, path: path}) do
    output = operator.evaluate(document, path, env)
    {label_of(output), output}
  end

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
