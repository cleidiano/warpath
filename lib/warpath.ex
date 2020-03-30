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

      #wildcard as index access
      iex>document = %{"integers" => [100, 200, 300]}
      ...> Warpath.query(document, "$.integers[*]")
      {:ok, [100, 200, 300]}

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
      ...> Warpath.query(document, "$.integers[0, 1]", result_type: :value_path)
      {:ok, [{100, "$['integers'][0]"}, {200, "$['integers'][1]"}]}
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

  ```
    #data structure
    iex> term = %{"name" => "Warpath"}
    ...> Warpath.query(term, "$.name")
    {:ok, "Warpath"}

  ```
  ```
    #raw json
    iex> term = ~s/{"name": "Warpath"}/
    ...> Warpath.query(term, "$.name")
    {:ok, "Warpath"}

  ```
  ## Options:
    result_type:
    * `:path` - return the path of evaluated expression instead of it's value
    * `:value` -  return the value of evaluated expression - `default`
    * `:value_path` - return both path and value.
  """
  @spec query(term, String.t(), result_type: :value | :path | :value_path) :: any
  def query(term, expression, opts \\ [])

  def query(term, expression, opts) when is_binary(term) do
    term
    |> Jason.decode!()
    |> query(expression, opts)
  end

  def query(term, expression, opts) when is_binary(expression) and is_list(opts) do
    with {:ok, tokens} <- Expression.compile(expression),
         {:ok, elements} <- do_query(term, tokens) do
      {:ok, collect(elements, opts[:result_type])}
    else
      error ->
        error
    end
  end

  @doc """
    The same as query/3, but rise exception if it fail.
  """
  def query!(term, expression, opts \\ []) do
    case query(term, expression, opts) do
      {:ok, result} -> result
      {:error, exception} -> raise exception
    end
  end

  defp do_query(document, tokens) when is_list(tokens) do
    last_token = length(tokens) - 1

    terms =
      tokens
      |> Stream.with_index()
      |> Enum.reduce(
        _acc = {document, []},
        _transformer = fn {item, index}, acc ->
          result = transform(acc, item)

          case {index, item} do
            {^last_token, {:wildcard, _}} ->
              List.flatten(result)

            _ ->
              result
          end
        end
      )

    {:ok, terms}
  rescue
    e in UnsupportedOperationError -> {:error, e}
    e in Enum.OutOfBoundsError -> {:error, e}
  end

  @typep member :: any()
  @typep members :: [member, ...]
  @typep element :: {member | members, Path.token()}
  @typep token :: Expression.token()

  @spec transform(element, token) :: element | [element, ...]
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

  defp transform({member, _} = element, {:union, tokens}) when is_map(member) do
    tokens
    |> Enum.reduce([], fn dot_property_token, acc ->
      case access(element, dot_property_token, :not_found) do
        {:not_found, _} -> acc
        result -> [result | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp transform({members, _} = element, {:array_indexes, target} = indexes) do
    case target do
      [{_, index} | []] = _should_unwrap? ->
        if index > Enum.count(members) - 1 do
          message =
            "The query should be resolved to scalar value " <>
              "but the index #{index} is out of bounds for emum #{inspect(members)}."

          raise Enum.OutOfBoundsError, message
        else
          [head | []] = value_for_indexes(element, indexes)
          head
        end

      _ ->
        value_for_indexes(element, indexes)
    end
  end

  defp transform({members, _} = element, {:wildcard, :*}) when is_container(members) do
    element
    |> PathMarker.stream()
    |> Enum.to_list()
  end

  defp transform(element, {:filter, filter_expression}) do
    Filter.filter(element, filter_expression)
  end

  defp transform(element, {:scan, {tag, _} = target}) when tag in [:property, :wildcard] do
    Scanner.scan(element, target, &Path.accumulate/2)
  end

  defp transform(element, {:scan, {:filter, _} = filter}) do
    self_included = [element]

    self_included
    |> search_for_lists()
    |> Enum.flat_map(&transform(&1, filter))
  end

  defp transform(element, {:scan, {:array_indexes, _} = indexes}) do
    self_included = [element]

    self_included
    |> search_for_lists()
    |> Enum.flat_map(&value_for_indexes(&1, indexes))
  end

  defp transform({members, _} = element, {:array_slice, slice}) do
    case members do
      data when is_list(data) ->
        {start_index, end_index, step, range} = create_slice_range(members, slice)

        if start_index != end_index do
          element
          |> PathMarker.stream()
          |> Stream.with_index()
          |> Enum.slice(range)
          |> Stream.reject(fn {_, index} -> rem(index, step) != 0 end)
          |> Enum.map(fn {member_path, _} -> member_path end)
        else
          []
        end

      _ ->
        []
    end
  end

  defp transform(members, token) when is_list(members) do
    members
    |> List.flatten()
    |> Enum.reduce([], fn element, acc ->
      case transform(element, token) do
        {nil, _path} -> acc
        result -> [result | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp transform({_member, path}, token) do
    raise UnsupportedOperationError,
          "token=#{inspect(token)}, path=#{inspect(path)}"
  end

  defp value_for_indexes({members, path}, {:array_indexes, indexes}) do
    max_index = Enum.count(members) - 1

    indexes
    |> Enum.reject(fn {:index_access, index} -> index > max_index end)
    |> Enum.map(fn {:index_access, index} = token ->
      {Enum.at(members, index), Path.accumulate(token, path)}
    end)
  end

  defp search_for_lists(enumerable) do
    enumerable
    |> EnumWalker.reduce_while([], container_reducer())
    |> Stream.filter(fn {member, _} -> is_list(member) end)
  end

  defp access({member, path}, {:dot, {:property, key} = token}, default \\ nil) do
    {Access.get(member, key, default), Path.accumulate(token, path)}
  end

  defp create_slice_range(elements, slice_ops) do
    start_index = slice_start_index(elements, slice_ops)
    end_index = slice_end_index(elements, slice_ops)
    step = slice_step(slice_ops)

    {start_index, end_index, step, Range.new(start_index, end_index - 1)}
  end

  defp slice_step(slice), do: Keyword.get(slice, :step, 1)

  defp slice_start_index(elements, slice) do
    start = Keyword.get(slice, :start_index, 0)

    if start < 0, do: max(-length(elements), start), else: start
  end

  defp slice_end_index(element, slice) do
    Keyword.get_lazy(slice, :end_index, fn -> length(element) end)
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
          {:skip, [element | acc]}
      end
    end
  end

  defp collect(elements, opt) when is_list(elements), do: Enum.map(elements, &collect(&1, opt))
  defp collect({member, path}, :value_path), do: {member, Path.bracketify(path)}
  defp collect({_, path}, :path), do: Path.bracketify(path)
  defp collect({member, _}, _), do: member
end
