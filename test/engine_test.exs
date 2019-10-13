defmodule EngineTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine

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

      assert Engine.query(context[:data], tokens("$.store.book[0]")) == nigel_rees
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
