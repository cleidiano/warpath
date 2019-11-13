defmodule Warpath.EngineTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine

  @value_and_path [result_type: :both]

  setup_all do
    [data: Oracle.json_store()]
  end

  describe "query/3" do
    test "evaluate root expression", context do
      assert Engine.query(context[:data], tokens("$"), @value_and_path) ==
               ok({context[:data], "$"})
    end

    test "evaluate property expression", context do
      path = "$['store']['bicycle']"
      value = %{"color" => "red", "price" => 19.95}

      assert Engine.query(context[:data], tokens("$.store.bicycle"), @value_and_path) ==
               ok({value, path})
    end

    test "result nil for property expression that not exists", context do
      document = context[:data]

      assert Engine.query(document, tokens("$.dont_exist"), @value_and_path) ==
               ok({nil, "$['dont_exist']"})
    end
  end

  describe "query/3 handle a scan expression" do
    test "that use a property and is terminal", context do
      prices = [
        {19.95, "$['store']['bicycle']['price']"},
        {8.95, "$['store']['book'][0]['price']"},
        {12.99, "$['store']['book'][1]['price']"},
        {8.99, "$['store']['book'][2]['price']"},
        {22.99, "$['store']['book'][3]['price']"}
      ]

      assert Engine.query(context[:data], tokens("$..price"), @value_and_path) == ok(prices)
    end

    test "that use a property and is on middle", context do
      prices = [
        {8.95, "$['store']['book'][0]['price']"},
        {12.99, "$['store']['book'][1]['price']"},
        {8.99, "$['store']['book'][2]['price']"},
        {22.99, "$['store']['book'][3]['price']"}
      ]

      assert Engine.query(context[:data], tokens("$.store..book[*].price"), @value_and_path) ==
               ok(prices)
    end

    test "that use a array index access", context do
      trace = "$['store']['book'][0]"

      book = %{
        "category" => "reference",
        "author" => "Nigel Rees",
        "title" => "Sayings of the Century",
        "price" => 8.95
      }

      assert Engine.query(context[:data], tokens("$..[0]"), @value_and_path) ==
               ok([{book, trace}])
    end

    test "that use a wildcard as a scan operation", context do
      values = Engine.query(context[:data], tokens("$..*"), @value_and_path)

      assert values ==
               Enum.zip(Oracle.scaned_elements(), Oracle.scaned_paths()) |> ok()
    end

    test "that use a wildcard folowed by comparator filter", context do
      values = Engine.query(context[:data], tokens("$..*.[?(@.price > 22)]"), @value_and_path)

      expected = {
        %{
          "category" => "fiction",
          "author" => "J. R. R. Tolkien",
          "title" => "The Lord of the Rings",
          "isbn" => "0-395-19395-8",
          "price" => 22.99
        },
        "$['store']['book'][3]"
      }

      assert values == ok([expected, expected])
    end

    test "that use a wildcard folowed by contains filter", context do
      values = Engine.query(context[:data], tokens("$..*.[?(@.isbn)]"), @value_and_path)

      books = [
        {%{
           "category" => "fiction",
           "author" => "Herman Melville",
           "title" => "Moby Dick",
           "isbn" => "0-553-21311-3",
           "price" => 8.99
         }, "$['store']['book'][2]"},
        {%{
           "category" => "fiction",
           "author" => "J. R. R. Tolkien",
           "title" => "The Lord of the Rings",
           "isbn" => "0-395-19395-8",
           "price" => 22.99
         }, "$['store']['book'][3]"}
      ]

      assert values == ok(books ++ books)
    end

    test "that use a filter", context do
      values = Engine.query(context[:data], tokens("$..[?(@.price > 22)]"), @value_and_path)

      expected = {
        %{
          "category" => "fiction",
          "author" => "J. R. R. Tolkien",
          "title" => "The Lord of the Rings",
          "isbn" => "0-395-19395-8",
          "price" => 22.99
        },
        "$['store']['book'][3]"
      }

      assert values == ok([expected])
    end
  end

  describe "query/3 handle filter expression" do
    test "that use a operator", context do
      tolkien = %{
        "category" => "fiction",
        "author" => "J. R. R. Tolkien",
        "title" => "The Lord of the Rings",
        "isbn" => "0-395-19395-8",
        "price" => 22.99
      }

      assert Engine.query(
               context[:data],
               tokens("$.store.book[?(@.price > 22)]"),
               @value_and_path
             ) == ok([{tolkien, "$['store']['book'][3]"}])
    end

    test "that use a contains operation", context do
      books = [
        {%{
           "category" => "fiction",
           "author" => "Herman Melville",
           "title" => "Moby Dick",
           "isbn" => "0-553-21311-3",
           "price" => 8.99
         }, "$['store']['book'][2]"},
        {%{
           "category" => "fiction",
           "author" => "J. R. R. Tolkien",
           "title" => "The Lord of the Rings",
           "isbn" => "0-395-19395-8",
           "price" => 22.99
         }, "$['store']['book'][3]"}
      ]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.isbn)]"), @value_and_path) ==
               ok(books)
    end

    test "that use a guard function" do
      data = %{"list" => [1.0, 2, 3, "string"], "integer" => 1}

      assert Engine.query(data, tokens("$.list[?(is_integer(@))]")) ==
               ok([2, 3])
    end
  end

  describe "query/3 handle array" do
    test "index access expression", context do
      trace = "$['store']['book'][0]"

      book = %{
        "category" => "reference",
        "author" => "Nigel Rees",
        "title" => "Sayings of the Century",
        "price" => 8.95
      }

      assert Engine.query(context[:data], tokens("$.store.book[0]"), @value_and_path) ==
               ok([{book, trace}])
    end

    test "index access with many indexes", context do
      trace = [
        {
          %{
            "category" => "fiction",
            "author" => "Evelyn Waugh",
            "title" => "Sword of Honour",
            "price" => 12.99
          },
          "$['store']['book'][1]"
        },
        {
          %{
            "category" => "fiction",
            "author" => "Herman Melville",
            "title" => "Moby Dick",
            "isbn" => "0-553-21311-3",
            "price" => 8.99
          },
          "$['store']['book'][2]"
        }
      ]

      assert Engine.query(context[:data], tokens("$.store.book[1, 2]"), @value_and_path) ==
               ok(trace)
    end

    test "wildcard expression", context do
      expected =
        context[:data]["store"]["book"]
        |> Stream.with_index()
        |> Enum.map(fn {item, index} -> {item, "$['store']['book'][#{index}]"} end)

      assert Engine.query(context[:data], tokens("$.store.book[*]"), @value_and_path) ==
               ok(expected)
    end

    test "wildcard expression with property after it", context do
      query_result = [
        {"Nigel Rees", "$['store']['book'][0]['author']"},
        {"Evelyn Waugh", "$['store']['book'][1]['author']"},
        {"Herman Melville", "$['store']['book'][2]['author']"},
        {"J. R. R. Tolkien", "$['store']['book'][3]['author']"}
      ]

      assert Engine.query(context[:data], tokens("$.store.book[*].author"), @value_and_path) ==
               ok(query_result)
    end
  end

  describe "query/3 handle options" do
    test "result_type: :path", context do
      trace = "$['store']['book'][0]"

      assert Engine.query(context[:data], tokens("$.store.book[0]"), result_type: :path) ==
               ok([trace])
    end

    test "default result_type is value", context do
      book = %{
        "author" => "Nigel Rees",
        "category" => "reference",
        "price" => 8.95,
        "title" => "Sayings of the Century"
      }

      assert Engine.query(context[:data], tokens("$.store.book[0]")) == ok([book])
    end
  end

  describe "query/3 return error when" do
    test "trying to traverse a list using dot notation", context do
      {:error, %{message: message}} = Engine.query(context[:data], tokens("$.store.book.price"))

      assert message =~
               "You are trying to traverse a list using dot notation '$.store.book.price'"
    end
  end

  defp tokens(expression) do
    expression
    |> Warpath.Tokenizer.tokenize!()
    |> Warpath.Parser.parse()
    |> case do
      {:ok, tokens} -> tokens
      error -> raise RuntimeError, "#{inspect(error)}"
    end
  end

  defp ok(term), do: {:ok, term}
end
