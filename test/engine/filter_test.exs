defmodule Warpath.Engine.FilterTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine.Filter

  setup_all do
    data = %{
      "store" => %{
        "book" => [
          %{
            "category" => "fiction",
            "author" => "Herman Melville",
            "title" => "Moby Dick",
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
      },
      "expensive" => 10
    }

    [data: data]
  end

  describe "filter/3" do
    test "filter a list of map by property", context do
      books = context[:data]["store"]["book"]
      trace = [{:index_access, 0}]

      assert [{List.first(books), trace}] ==
               Filter.filter({books, []}, {{:property, "price"}, :<, 10})
    end

    test "filter a list of map by contains property", context do
      books = context[:data]["store"]["book"]
      trace = [{:index_access, 1}]

      assert [{List.last(books), trace}] ==
               Filter.filter({books, []}, {:contains, {:property, "isbn"}})
    end

    test "filter map by property", context do
      bicycle = context[:data]["store"]["bicycle"]
      trace = [{:property, "bicycle"}, {:store, "store"}]

      assert [{bicycle, trace}] ==
               Filter.filter({bicycle, trace}, {{:property, "price"}, :>, 10})
    end

    test "filter a map by contains property", context do
      book = context[:data]["store"]["book"] |> List.last()
      trace = [{:index_access, 1}, {:property, "book"}, {:store, "store"}]

      assert [{book, trace}] ==
               Filter.filter({book, trace}, {:contains, {:property, "isbn"}})
    end

    test "empty list for data type that doesn't support Access behaviour" do
      invalid_types = [10, "Test", {:some, 10}]

      for type <- invalid_types do
        assert [] == Filter.filter({type, []}, {:contains, {:property, "any"}})
      end
    end
  end
end
