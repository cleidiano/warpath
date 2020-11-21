[![Actions Status](https://github.com/cleidiano/warpath/workflows/build/badge.svg?branch=master)](https://github.com/cleidiano/warpath/actions)
[![Warpath version](https://img.shields.io/hexpm/v/warpath.svg)](https://hex.pm/packages/warpath)

# Warpath
<!-- MDOC !-->
A implementation of Jsonpath expression proposal by [Stefan Goessner](https://goessner.net/articles/JsonPath/) for Elixir.

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
  All filter operator supported by Warpath have the same behavior of Elixir lang,
  it means that it's possible to compare different data types, check the [Elixir getting started](https://elixir-lang.org/getting-started/basic-operators.html)
  page for more information about cross comparision on data types.

  Filter are expression that must be result on a boolean value, Warpath will use then to retain data when filter a data structure;
  a filter expression have it syntax like this `[?( @.category == 'fiction' )]`.

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
  | or,\|\|                  | logical or operator `[?(@.category == 'fiction' or @.price < 100)]` |
  | not                      | logical not operator `[?(not @.category == 'fiction')]`             |

### Functions allowed in filter expression
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
### All children
```elixir
    #wildcard using bracket-notation
    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[*]")
    {:ok, [:a, :b, :c]}

    #wildcard using dot-notation
    iex> document = %{"integers" => [100, 200, 300]}
    ...> Warpath.query(document, "$.integers.*")
    {:ok, [100, 200, 300]}
```

### Children lookup by name
```elixir
    #Simple string
    iex> Warpath.query(%{"category" => "fiction", "price" => 12.99}, "$.category")
    {:ok, "fiction"}

    #Quoted string
    iex> Warpath.query(%{"key with whitespace" => "some value"}, "$.['key with whitespace']")
    {:ok, "some value"}

    #Simple atom
    iex> Warpath.query(%{atom_key: "some value"}, "$.:atom_key")
    {:ok, "some value"}

    #Quoted atom
    iex> Warpath.query(%{"atom key": "some value"}, ~S{$.:'atom key'})
    {:ok, "some value"}

    #Unicode support
    iex> Warpath.query(%{"🌢" => "Elixir"}, "$.🌢")
    {:ok, "Elixir"}

    #Union
    iex> document = %{"key" => "value", "another" => "entry"}
    ...> Warpath.query(document, "$['key', 'another']")
    {:ok, ["value", "entry"]}
```

### Children lookup by index
```elixir
    #Positive index
    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[0]")
    {:ok, :a}

    #Negative index
    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[-1]")
    {:ok, :c}

    #Union
    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[0, 1]")
    {:ok, [:a, :b]}
```

### Slice
```elixir
    iex> document = [0, 1, 2, 3, 4]
    ...> Warpath.query(document, "$[0:2:1]")
    {:ok, [0, 1]}

    #optional start and step param.
    iex> document = [0, 1, 2, 3, 4]
    ...> Warpath.query(document, "$[:2]")
    {:ok, [0, 1]}

    #Negative start index
    iex> document = [0, 1, 2, 3, 4]
    ...> Warpath.query(document, "$[-2:]")
    {:ok, [3, 4]}
```

### Filter
```elixir
    # Using logical and operator with is_integer function guard to gain strictness
    iex> document = %{"store" => %{"car" => %{"price" => 100_000}, "bicycle" => %{"price" => 500}}}
    ...> Warpath.query(document, "$..*[?( @.price > 500 and is_integer(@.price) )]")
    {:ok, [%{"price" => 100_000}]}

    # Deep path matching
    iex> addresses = [%{"address" => %{"state" => "Bahia"}}, %{"address" => %{"state" => "São Paulo"}}]
    ...> Warpath.query(addresses, "$[?(@.address.state=='Bahia')]")
    {:ok, [%{ "address" => %{ "state" => "Bahia"}}]}

    #has children using named key
    iex> document = %{"store" => %{"car" => %{"price" => 100_000}, "bicycle" => %{"price" => 500}}}
    ...> Warpath.query(document, "$..*[?(@.price)]")
    {:ok, [%{"price" => 500}, %{"price" => 100_000}]}

    #has children using index
    iex> document = [ [1, 2, 3], [0, 5], [], [1], 9, [9, 8, 7] ]
    ...> Warpath.query(document, "$[?( @[2] )]") # That means give me all list that have index 2.
    {:ok, [ [1, 2, 3], [9, 8, 7]] }
```

### Recursive descendant
```elixir
    #Collect key
    iex> document = %{"store" => %{"car" => %{"price" => 100_000}, "bicycle" => %{"price" => 500}}}
    ...> Warpath.query(document, "$..price")
    {:ok, [500, 100_000]}

    #Collect index
    iex> document = [ [1, 2, 3], [], :item, [0, 5], [1], 9, [9, 8, 7] ]
    ...> Warpath.query(document, "$..[2]")
    {:ok, [:item, 3, 7]}

    #Using filter criteria to scan
    iex> document = [ [1, 2], [], :item, 9, [9, 8], 1.1, "string" ]
    ...> Warpath.query(document, "$..[?( is_list(@) )]")
    {:ok, [ [1, 2], [], [9, 8]]}
```

### Options

```elixir
    
    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements")
    {:ok, [:a, :b, :c]}

    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[0, 1]", result_type: :path)
    {:ok, ["$['elements'][0]", "$['elements'][1]"]}

    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[0]", result_type: :path_tokens)
    {:ok, [{:root, "$"}, {:property, "elements"}, {:index_access, 0}]}

    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[0, 1]", result_type: :value_path)
    {:ok, [{:a, "$['elements'][0]"}, {:b, "$['elements'][1]"}]}

    iex> document = %{"elements" => [:a, :b, :c]}
    ...> Warpath.query(document, "$.elements[0]", result_type: :value_path_tokens)
    {:ok, {:a, [{:root, "$"}, {:property, "elements"}, {:index_access, 0}]}}

```
<!-- MDOC !-->


**Installation:**

The package can be installed by adding `warpath` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:warpath, "~> 0.4.1"}
  ]
end
```

See documentation at [https://hexdocs.pm](https://hexdocs.pm/warpath/Warpath.html).

To see a comparisions between warpath and others json path libraries, visit [json-path-comparison](https://cburgmer.github.io/json-path-comparison/) and see the great job done by `Christoph Burgmer`.
