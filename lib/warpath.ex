defmodule Warpath do
  @moduledoc """
    A Elixir implementation of Jsonpath expression proposal by [Stefan Goessner](https://goessner.net/articles/JsonPath/)

    Warpath support dot–notation expression `$.store.book[0].author` or the bracket–notation `$['store']['book'][0]['author']`.

  ## Operators
    | Operator                  | Description                                                        |
    | :------------------------ | :----------------------------------------------------------------- |
    | `$`                       | The root element to query. This starts all path expressions.       |
    | `@`                       | The current node being processed by a filter predicate.            |
    | `*`                       | Wildcard. All objects/elements regardless their names.             |
    | `..`                      | Deep scan, recursive descent.                                      |
    | `.name`                   | Dot-notated child, it support string or atom as keys.              |
    | `['name']`                | Bracket-notated child, it support string or atom as keys.          |
    | `[int (,int>)]`           | Array index or indexes                                             |
    | `[start:end]`             | Array slice operator. **Will be supported soon**                   |
    | `[?(expression)]`         | Filter expression. Expression must evaluate to a boolean value.    |

  ## Filters operators
    Filter are expression that must be evaluated to a boolean value, Warpath will use then to retain data when filter a list,
    a filter expression have the syntax like this `[?( @.category == 'fiction' )]`.

    All filter operator supported by Warpath have the same behavior of Elixir lang,
    it means that it's possible to compare diferente data types.

    The down side of this approach is that filter a list with
    diferente data types could result e undesired output for exenple:
    ```
    iex> data = [:atom, "string", 11]
    ...> Warpath.query(data, "$[?(@ > 10)]")
    {:ok, [:atom, "string", 11]}
    ```

    The expression were evaluate and return the enterily input list has the output, this happen
    because the way elixir implement comparision, check the [Elixir getting started](https://elixir-lang.org/getting-started/basic-operators.html)
    page for more information.

    To cover this eddge case, Warpath support some functions to check the underline item data type that
    the filter is operate on, it could be combined with `and` operator to gain the strictness among comparision.

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
    | and                      | logical and operator `[?(@.price > 50 and @.price < 100)]`          |
    | or                       | logical or operator `[?(@.category == 'fiction' or @.price < 100)]` |
    | not                      | logical not operator `[?(not @.category == 'fiction')]`             |


    | Function            | Descrition                   |
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

      #key access
      iex>Warpath.query(%{"category" => "fiction", "price" => 12.99}, "$.category")
      {:ok, "fiction"}

      #quoted key
      iex>Warpath.query(%{"key with whitespace" => "some value"}, "$.['key with whitespace']")
      {:ok, "some value"}

      #atom based access
      iex>Warpath.query(%{atom_key: "some value"}, "$.:atom_key")
      {:ok, "some value"}

      #quoted atom
      iex>Warpath.query(%{"atom key": "some value"}, ~S{$.:"atom key"})
      {:ok, "some value"}

      #wildcard access
      iex>document = %{"store" => %{"car" => %{"price" => 100_000}, "bicyle" => %{"price" => 500}}}
      ...>Warpath.query(document, "$.store.*.price")
      {:ok, [500, 100_000]}

      #scan operator
      iex>document = %{"store" => %{"car" => %{"price" => 100_000}, "bicyle" => %{"price" => 500}}}
      ...>Warpath.query(document, "$..price")
      {:ok, [500, 100_000]}

      #filter operator
      iex>document = %{"store" => %{"car" => %{"price" => 100_000}, "bicyle" => %{"price" => 500}}}
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

      #wildcard as index access
      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[*]")
      {:ok, [100, 200, 300]}

      #options
      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[0, 1]", result_type: :path)
      {:ok, [ "$['integers'][0]", "$['integers'][1]" ]}

      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[0, 1]", result_type: :value_path)
      {:ok, [ {100, "$['integers'][0]"}, {200, "$['integers'][1]"} ]}
  """

  alias Warpath.Element.Path
  alias Warpath.Element.PathMarker
  alias Warpath.EnumWalker
  alias Warpath.Expression
  alias Warpath.Filter
  alias Warpath.Scanner
  alias Warpath.UnsupportedOperationError

  defguardp is_container(term) when is_list(term) or is_map(term)

  @doc """
  Query data for the given expression.

  ## Options:
    result_type:
    * `:path` - return the path of evaluated expression instead of it's value
    * `:value` -  return the value of evaluated expression - `default`
    * `:value_path` - return both path and values.
  """
  @spec query(any, String.t(), result_type: :value | :path | :value_path) :: any
  def query(data, string, opts \\ []) when is_binary(string) and is_list(opts) do
    with {:ok, expression} <- Expression.compile(string),
         {:ok, elements} <- do_query(data, expression) do
      {:ok, collect(elements, opts[:result_type])}
    else
      error ->
        error
    end
  end

  defp do_query(document, tokens) when is_list(tokens) do
    terms = Enum.reduce(tokens, {document, []}, fn item, acc -> transform(acc, item) end)
    {:ok, terms}
  rescue
    e in UnsupportedOperationError -> {:error, e}
  end

  defp transform({member, path}, {:root, _} = token),
    do: {member, Path.accumulate(token, path)}

  defp transform({members, path} = element, {:dot, {:property, name} = property} = token)
       when is_list(members) do
    if Keyword.keyword?(members) do
      access(element, token)
    else
      tips =
        "You are trying to traverse a list using dot " <>
          "notation '#{Path.accumulate(property, path) |> Path.dotify()}', " <>
          "that it's not allowed for list type. " <>
          "You can use something like '#{Path.dotify(path)}[*].#{name}' instead."

      raise UnsupportedOperationError, tips
    end
  end

  defp transform({member, _} = element, {:dot, _} = dot_token) when is_map(member),
    do: access(element, dot_token)

  defp transform({_, _} = element, {:array_indexes, indexes}),
    do: Enum.map(indexes, &transform(element, &1))

  defp transform({members, path}, {:index_access, index} = token) when is_list(members) do
    {Enum.at(members, index), Path.accumulate(token, path)}
  end

  defp transform({members, _} = element, {:wildcard, :*}) when is_container(members) do
    element
    |> PathMarker.stream()
    |> Enum.to_list()
  end

  defp transform(element, {:filter, filter_expression}),
    do: Filter.filter(element, filter_expression)

  defp transform(element, {:scan, {tag, _} = target}) when tag in [:property, :wildcard],
    do: Scanner.scan(element, target, &Path.accumulate/2)

  defp transform(element, {:scan, {:filter, _} = filter}),
    do: do_scan_filter([element], filter)

  defp transform(element, {:scan, {:array_indexes, _} = indexes}),
    do: do_scan_filter(element, indexes)

  defp transform(members, token) when is_list(members) do
    members
    |> List.flatten()
    |> Enum.map(&transform(&1, token))
  end

  defp transform({_member, path}, token) do
    raise UnsupportedOperationError,
          "token=#{inspect(token)}, path=#{inspect(path)}"
  end

  defp access({member, path}, {:dot, {:property, key} = token}) do
    {member[key], Path.accumulate(token, path)}
  end

  defp do_scan_filter(enumerable, filter) do
    enumerable
    |> EnumWalker.reduce_while([], container_reducer(), &Path.accumulate/2)
    |> Stream.filter(fn {member, _} -> is_list(member) end)
    |> Enum.flat_map(fn element -> transform(element, filter) end)
  end

  defguardp has_itens(container)
            when (is_list(container) and container != []) or
                   (is_map(container) and map_size(container) > 0)

  defp container_reducer do
    fn {container, _} = element, acc ->
      case container do
        container when has_itens(container) ->
          {:walk, [element | acc]}

        _ ->
          {:skip, acc}
      end
    end
  end

  defp collect(elements, opt) when is_list(elements), do: Enum.map(elements, &collect(&1, opt))
  defp collect({member, path}, :value_path), do: {member, Path.bracketify(path)}
  defp collect({_, path}, :path), do: Path.bracketify(path)
  defp collect({member, _}, _), do: member
end
