defmodule EngineTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine

  @trace [result_type: :trace]

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

  describe "query/3 return value on" do
    test "evaluate root expression", context do
      assert Engine.query(context[:data], tokens("$")) == context[:data]
    end

    test "evaluate property expression ", context do
      assert Engine.query(context[:data], tokens("$.store.bicycle")) == %{
               "color" => "red",
               "price" => 19.95
             }
    end

    test "evaluate array index expression ", context do
      nigel_rees = %{
        "category" => "reference",
        "author" => "Nigel Rees",
        "title" => "Sayings of the Century",
        "price" => 8.95
      }

      assert Engine.query(context[:data], tokens("$.store.book[0]")) == [nigel_rees]
    end

    test "evaluate scan property expression ", context do
      prices = [8.95, 12.99, 8.99, 22.99, 19.95]
      assert Engine.query(context[:data], tokens("$..price")) == prices
    end

    test "evaluate many array indexes expression", context do
      books = [
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
        }
      ]

      assert Engine.query(context[:data], tokens("$.store.book[1, 2]")) == books
    end

    test "evaluate wildcard array expression", context do
      expected = context[:data]["store"]["book"]
      assert Engine.query(context[:data], tokens("$.store.book[*]")) == expected
    end

    test "evaluate wildcard array expression with property after it", context do
      assert Engine.query(context[:data], tokens("$.store.book[*].author")) == [
               "Nigel Rees",
               "Evelyn Waugh",
               "Herman Melville",
               "J. R. R. Tolkien"
             ]
    end

    test "evaluate filter expression for relation >", context do
      tolkien = %{
        "category" => "fiction",
        "author" => "J. R. R. Tolkien",
        "title" => "The Lord of the Rings",
        "isbn" => "0-395-19395-8",
        "price" => 22.99
      }

      assert Engine.query(context[:data], tokens("$.store.book[?(@.price > 22)]")) == [tolkien]
    end

    test "evaluate filter expression for relation <", context do
      books = [
        %{
          "category" => "reference",
          "author" => "Nigel Rees",
          "title" => "Sayings of the Century",
          "price" => 8.95
        },
        %{
          "category" => "fiction",
          "author" => "Herman Melville",
          "title" => "Moby Dick",
          "isbn" => "0-553-21311-3",
          "price" => 8.99
        }
      ]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.price < 9)]")) == books
    end

    test "evaluate filter expression for relation ==", context do
      tolkien = [
        %{
          "category" => "fiction",
          "author" => "J. R. R. Tolkien",
          "title" => "The Lord of the Rings",
          "isbn" => "0-395-19395-8",
          "price" => 22.99
        }
      ]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.price == 22.99)]")) == tolkien
    end

    test "evaluate filter expression for contains operation", context do
      books = [
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
      ]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.isbn)]")) == books
    end
  end

  describe "query/3 return trace on" do
    test "evaluate root expression", context do
      trace = [root: "$"]
      assert Engine.query(context[:data], tokens("$"), @trace) == trace
    end

    test "evaluate property expression ", context do
      trace = [root: "$", property: "store", property: "bicycle"]
      assert Engine.query(context[:data], tokens("$.store.bicycle"), @trace) == trace
    end

    test "evaluate array index expression ", context do
      trace = [[root: "$", property: "store", property: "book", index_access: 0]]

      assert Engine.query(context[:data], tokens("$.store.book[0]"), @trace) == trace
    end

    test "evaluate scan property expression ", context do
      prices = [
        [root: "$", property: "store", property: "book", index_access: 0, property: "price"],
        [root: "$", property: "store", property: "book", index_access: 1, property: "price"],
        [root: "$", property: "store", property: "book", index_access: 2, property: "price"],
        [root: "$", property: "store", property: "book", index_access: 3, property: "price"],
        [root: "$", property: "store", property: "bicycle", property: "price"]
      ]

      assert Engine.query(context[:data], tokens("$..price"), @trace) == prices
    end

    test "evaluate many array indexes expression", context do
      trace = [
        [root: "$", property: "store", property: "book", index_access: 1],
        [root: "$", property: "store", property: "book", index_access: 2]
      ]

      assert Engine.query(context[:data], tokens("$.store.book[1, 2]"), @trace) ==
               trace
    end

    test "evaluate wildcard array expression", context do
      trace = [root: "$", property: "store", property: "book"]
      assert Engine.query(context[:data], tokens("$.store.book[*]"), @trace) == trace
    end

    test "evaluate wildcard array expression with property after it", context do
      trace = [
        [root: "$", property: "store", property: "book", index_access: 0, property: "author"],
        [root: "$", property: "store", property: "book", index_access: 1, property: "author"],
        [root: "$", property: "store", property: "book", index_access: 2, property: "author"],
        [root: "$", property: "store", property: "book", index_access: 3, property: "author"]
      ]

      assert Engine.query(context[:data], tokens("$.store.book[*].author"), @trace) == trace
    end

    test "evaluate filter expression for relation >", context do
      trace = [root: "$", property: "store", property: "book", index_access: 3]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.price > 22)]"), @trace) ==
               [trace]
    end

    test "evaluate filter expression for relation <", context do
      trace = [
        [root: "$", property: "store", property: "book", index_access: 0],
        [root: "$", property: "store", property: "book", index_access: 2]
      ]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.price < 9)]"), @trace) == trace
    end

    test "evaluate filter expression for relation ==", context do
      trace = [root: "$", property: "store", property: "book", index_access: 3]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.price == 22.99)]"), @trace) ==
               [trace]
    end

    test "evaluate filter expression for contains operation", context do
      trace = [
        [root: "$", property: "store", property: "book", index_access: 2],
        [root: "$", property: "store", property: "book", index_access: 3]
      ]

      assert Engine.query(context[:data], tokens("$.store.book[?(@.isbn)]"), @trace) == trace
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
end
