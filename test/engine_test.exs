defmodule EngineTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine

  @value_and_path [result_type: :value_and_path]

  setup do
    store = %{
      "store" => %{
        "book" => [
          %{
            "category" => "reference",
            "author" => "Nigel Rees",
            "title" => "Sayings of the Century",
            "price" => 8.95
          },
          %{
            "category" => "fiction",
            "author" => "Evelyn Waugh",
            "title" => "Sword of Honour",
            "price" => 12.99
          },
          %{
            "category" => "fiction",
            "author" => "Herman Melville",
            "title" => "Moby Dick",
            "isbn" => "0-553-21311-3",
            "price" => 8.99
          },
          %{
            "category" => "fiction",
            "author" => "J. R. R. Tolkien",
            "title" => "The Lord of the Rings",
            "isbn" => "0-395-19395-8",
            "price" => 22.99
          }
        ],
        "bicycle" => %{
          "color" => "red",
          "price" => 19.95
        }
      }
    }

    [data: store]
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
  end

  describe "query/3 evaluate a scan expression" do
    test "that is terminal", context do
      prices = [
        {8.95, "$['store']['book'][0]['price']"},
        {12.99, "$['store']['book'][1]['price']"},
        {8.99, "$['store']['book'][2]['price']"},
        {22.99, "$['store']['book'][3]['price']"},
        {19.95, "$['store']['bicycle']['price']"}
      ]

      assert Engine.query(context[:data], tokens("$..price"), @value_and_path) == ok(prices)
    end

    test "that is on middle", context do
      prices = [
        {8.95, "$['store']['book'][0]['price']"},
        {12.99, "$['store']['book'][1]['price']"},
        {8.99, "$['store']['book'][2]['price']"},
        {22.99, "$['store']['book'][3]['price']"}
      ]

      assert Engine.query(context[:data], tokens("$.store..book[*].price"), @value_and_path) ==
               ok(prices)
    end
  end

  describe "query/3 handle filter expression" do
    test "evaluate filter expression for relation >", context do
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

    test "evaluate filter expression for relation <", context do
      books = [
        {%{
           "category" => "reference",
           "author" => "Nigel Rees",
           "title" => "Sayings of the Century",
           "price" => 8.95
         }, "$['store']['book'][0]"},
        {%{
           "category" => "fiction",
           "author" => "Herman Melville",
           "title" => "Moby Dick",
           "isbn" => "0-553-21311-3",
           "price" => 8.99
         }, "$['store']['book'][2]"}
      ]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.price < 9)]"), @value_and_path) ==
               ok(books)
    end

    test "evaluate filter expression for relation ==", context do
      book = [
        {%{
           "category" => "fiction",
           "author" => "J. R. R. Tolkien",
           "title" => "The Lord of the Rings",
           "isbn" => "0-395-19395-8",
           "price" => 22.99
         }, "$['store']['book'][3]"}
      ]

      assert Engine.query(
               context[:data],
               tokens("$.store.book[?(@.price == 22.99)]"),
               @value_and_path
             ) == ok(book)
    end

    test "evaluate filter expression for contains operation", context do
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

    test "evaluate wildcard array expression", context do
      expected = context[:data]["store"]["book"]
      trace = "$['store']['book']"

      assert Engine.query(context[:data], tokens("$.store.book[*]"), @value_and_path) ==
               ok({expected, trace})
    end

    test "evaluate wildcard array expression with property after it", context do
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
      assert message =~ "You are trying to traverse a list using dot notation"
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
