defmodule WarpathTest do
  use ExUnit.Case, async: true

  doctest Warpath

  @value_path [result_type: :value_path]

  setup_all do
    %{data: Oracle.json_store()}
  end

  describe "query/3" do
    test "evaluate root expression", %{data: document} do
      assert Warpath.query(document, "$", @value_path) == {:ok, {document, "$"}}
    end

    test "evaluate property expression", %{data: document} do
      path = "$['store']['bicycle']"
      value = %{"color" => "red", "price" => 19.95}

      assert Warpath.query(document, "$.store.bicycle", @value_path) == {:ok, {value, path}}
    end

    test "evaluate atom expression" do
      value = %{"color" => "red", "price" => 19.95}
      path = "$['bicycle']"
      document = %{bicycle: value}

      assert Warpath.query(document, "$.:bicycle", @value_path) == {:ok, {value, path}}
      assert Warpath.query([bicycle: value], "$.:bicycle", @value_path) == {:ok, {value, path}}
    end

    test "result nil for property expression that not exists", %{data: document} do
      assert Warpath.query(document, "$.dont_exist", @value_path) ==
               {:ok, {nil, "$['dont_exist']"}}
    end

    test "evaluate wildcard expression like $.*", %{data: document} do
      values = Map.values(document)
      paths = ["$['expensive']", "$['store']"]

      assert Warpath.query(document, "$.*", @value_path) == {:ok, Enum.zip(values, paths)}
    end

    test "resolve a wildcard property" do
      document = %{
        "store" => %{
          "car" => %{"price" => 100_000},
          "bicyle" => %{"price" => 500}
        }
      }

      assert Warpath.query(document, "$.store.*.price", @value_path) ==
               {:ok,
                [
                  {500, "$['store']['bicyle']['price']"},
                  {100_000, "$['store']['car']['price']"}
                ]}
    end

    test "pass a compiled path expression", %{data: document} do
      path = "$['store']['bicycle']"
      value = %{"color" => "red", "price" => 19.95}
      {:ok, expression} = Warpath.Expression.compile(path)

      assert Warpath.query(document, expression, @value_path) == {:ok, {value, path}}
    end
  end

  describe "query/3 handle a scan expression" do
    test "that use a property and is terminal", %{data: document} do
      prices = [
        {19.95, "$['store']['bicycle']['price']"},
        {8.95, "$['store']['book'][0]['price']"},
        {12.99, "$['store']['book'][1]['price']"},
        {8.99, "$['store']['book'][2]['price']"},
        {22.99, "$['store']['book'][3]['price']"}
      ]

      assert Warpath.query(document, "$..price", @value_path) == {:ok, prices}
    end

    test "that use a property and is on middle", %{data: document} do
      prices = [
        {8.95, "$['store']['book'][0]['price']"},
        {12.99, "$['store']['book'][1]['price']"},
        {8.99, "$['store']['book'][2]['price']"},
        {22.99, "$['store']['book'][3]['price']"}
      ]

      assert Warpath.query(document, "$.store..book[*].price", @value_path) == {:ok, prices}
    end

    test "that use a array index access", %{data: document} do
      trace = "$['store']['book'][0]"

      book = %{
        "category" => "reference",
        "author" => "Nigel Rees",
        "title" => "Sayings of the Century",
        "price" => 8.95
      }

      assert Warpath.query(document, "$..[0]", @value_path) == {:ok, [{book, trace}]}
    end

    test "that use a wildcard as a scan operation", %{data: document} do
      expected = {:ok, Enum.zip(Oracle.scaned_elements(), Oracle.scaned_paths())}
      assert Warpath.query(document, "$..*", @value_path) == expected
    end

    test "that use a wildcard folowed by comparator filter", %{data: document} do
      values =
        Warpath.query(
          document,
          "$..*.[?(is_float(@.price) and @.price > 22)]",
          @value_path
        )

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

      assert values == {:ok, [expected, expected]}
    end

    test "that use a wildcard folowed by contains filter", %{data: document} do
      values = Warpath.query(document, "$..*.[?(@.isbn)]", @value_path)

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

      assert values == {:ok, books ++ books}
    end

    test "that use a filter", %{data: document} do
      values = Warpath.query(document, "$..[?(@.price > 22)]", @value_path)

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

      assert values == {:ok, [expected]}
    end
  end

  describe "query/3 handle filter expression" do
    test "that use a operator", %{data: document} do
      tolkien = %{
        "category" => "fiction",
        "author" => "J. R. R. Tolkien",
        "title" => "The Lord of the Rings",
        "isbn" => "0-395-19395-8",
        "price" => 22.99
      }

      assert Warpath.query(
               document,
               "$.store.book[?(@.price > 22)]",
               @value_path
             ) == {:ok, [{tolkien, "$['store']['book'][3]"}]}
    end

    test "that use a contains operation", %{data: document} do
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

      assert Warpath.query(document, "$.store.book[?(@.isbn)]", @value_path) == {:ok, books}
    end

    test "that use a function" do
      data = %{"list" => [1.0, 2, 3, "string"], "integer" => 1}

      assert Warpath.query(data, "$.list[?(is_integer(@))]") == {:ok, [2, 3]}
    end
  end

  describe "query/3 handle array" do
    test "index access expression", %{data: document} do
      path = "$['store']['book'][0]"

      book = %{
        "category" => "reference",
        "author" => "Nigel Rees",
        "title" => "Sayings of the Century",
        "price" => 8.95
      }

      assert Warpath.query(document, "$.store.book[0]", @value_path) == {:ok, {book, path}}
    end

    test "index access with many indexes", %{data: document} do
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

      assert Warpath.query(document, "$.store.book[1, 2]", @value_path) == {:ok, trace}
    end

    test "wildcard expression", %{data: document} do
      expected =
        document["store"]["book"]
        |> Stream.with_index()
        |> Enum.map(fn {item, index} -> {item, "$['store']['book'][#{index}]"} end)

      assert Warpath.query(document, "$.store.book[*]", @value_path) == {:ok, expected}
    end

    test "wildcard expression with property after it", %{data: document} do
      query_result = [
        {"Nigel Rees", "$['store']['book'][0]['author']"},
        {"Evelyn Waugh", "$['store']['book'][1]['author']"},
        {"Herman Melville", "$['store']['book'][2]['author']"},
        {"J. R. R. Tolkien", "$['store']['book'][3]['author']"}
      ]

      assert Warpath.query(document, "$.store.book[*].author", @value_path) == {:ok, query_result}
    end
  end

  describe "query/3 handle slice" do
    test "with only start index supplied" do
      list = [0, 1, 2, 3, 4, 5]

      assert Warpath.query(list, "$[1:]", @value_path) ==
               {:ok, [{1, "$[1]"}, {2, "$[2]"}, {3, "$[3]"}, {4, "$[4]"}, {5, "$[5]"}]}
    end

    test "with only negative start index supplied" do
      list = [0, 1, 2, 3, 4, 5]
      assert Warpath.query(list, "$[-2:]", @value_path) == {:ok, [{4, "$[4]"}, {5, "$[5]"}]}
    end

    test "with only end index supplied" do
      list = [0, 1, 2, 3, 4, 5]
      assert Warpath.query(list, "$[:2]", @value_path) == {:ok, [{0, "$[0]"}, {1, "$[1]"}]}
    end

    test "with only negative end index supplied" do
      list = [0, 1, 2, 3, 4, 5]

      assert Warpath.query(list, "$[:-2]", @value_path) ==
               {:ok, [{0, "$[0]"}, {1, "$[1]"}, {2, "$[2]"}, {3, "$[3]"}]}
    end

    test "with negative start index and negative end index supplied" do
      list = [0, 1, 2, 3, 4, 5]
      assert Warpath.query(list, "$[-3:-1]", @value_path) == {:ok, [{3, "$[3]"}, {4, "$[4]"}]}
    end

    test "with step, start and end index supplied" do
      list = [0, 1, 2, 3, 4, 5, 6, 7]

      assert Warpath.query(list, "$[0:6:2]", @value_path) ==
               {:ok, [{0, "$[0]"}, {2, "$[2]"}, {4, "$[4]"}]}
    end
  end

  describe "query/3 handle options" do
    test "result_type: :path", %{data: document} do
      path = "$['store']['book'][0]"

      assert Warpath.query(document, "$.store.book[0]", result_type: :path) == {:ok, path}
    end

    test "default result_type is value", %{data: document} do
      book = %{
        "author" => "Nigel Rees",
        "category" => "reference",
        "price" => 8.95,
        "title" => "Sayings of the Century"
      }

      assert Warpath.query(document, "$.store.book[0]") == {:ok, book}
    end
  end
end
