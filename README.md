# warpath

**TODO: Add description**

| Status |JsonPath | Result |
|:-- |:------- | :----- |
|Supported    | $.store.book[*].author                 | The authors of all books                                    |
|Supported    | $..author                              | All authors                                                 |
|Supported    | $.store.*                              | All things, both books and bicycles                         |
|Supported    | $.store..price                         | The price of everything                                     |
|Supported    | $..book[2]                             | The third book                                              |
|Unsupported  | $..book[-2]                            | The second to last book                                     |
|Supported    | $..book[0,1]                           | The first two books                                         |
|Unsupported  | $..book[:2]                            | All books from index 0 (inclusive) until index 2 (exclusive)|
|Unsupported  | $..book[1:2]                           | All books from index 1 (inclusive) until index 2 (exclusive)|
|Unsupported  | $..book[-2:]                           | Last two books                                              |
|Unsupported  | $..book[2:]                            | Book number two from tail                                   |
|Supported    | $..book[?(@.isbn)]                     | All books with an ISBN number                               |
|Supported    | $.store.book[?(@.price < 10)]          | All books in store cheaper than 10                          |
|Unsupported  | $..book[?(@.author =~ /.*REES/i)]      | All books matching regex (ignore case)                      |
|Supported  | $..*                                   | Give me every thing                                         | 
|Unsupported  | $..book.length()                       | The number of books                                         |


Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `warpath` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:warpath, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/warpath](https://hexdocs.pm/warpath).

