defmodule Warpath.Engine.FilterTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine.Filter
  alias Warpath.Engine.PathMarker

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

  describe "filter/3 filter a element member" do
    test "with a list of map by comparison property expression",
         context do
      books = context[:data]["store"]["book"]
      path = [{:index_access, 0}]

      assert [{List.first(books), path}] ==
               Filter.filter({books, []}, {{:property, "price"}, :<, 10})
    end

    test "with a list of map by contains property expression", context do
      books = context[:data]["store"]["book"]
      path = [{:index_access, 1}]

      assert [{List.last(books), path}] ==
               Filter.filter({books, []}, {:contains, {:property, "isbn"}})
    end

    test "that is map by property comparison expression", context do
      bicycle = context[:data]["store"]["bicycle"]
      path = [{:property, "bicycle"}, {:store, "store"}]

      assert [{bicycle, path}] ==
               Filter.filter({bicycle, path}, {{:property, "price"}, :>, 10})
    end

    test "that is map by contains property expression", context do
      book = context[:data]["store"]["book"] |> List.last()
      path = [{:index_access, 1}, {:property, "book"}, {:store, "store"}]

      assert [{book, path}] ==
               Filter.filter({book, path}, {:contains, {:property, "isbn"}})
    end
  end

  describe "filter/3 filter a list of elements" do
    test "by contains property expression", context do
      path = [{:index_access, 1}]
      books = context[:data]["store"]["book"]

      elements =
        {books, []}
        |> PathMarker.stream()
        |> Enum.to_list()

      assert [{List.last(books), path}] ==
               Filter.filter(elements, {:contains, {:property, "isbn"}})
    end

    test "by comparison property expression", context do
      path = [{:index_access, 0}]
      books = context[:data]["store"]["book"]

      elements =
        {books, []}
        |> PathMarker.stream()
        |> Enum.to_list()

      assert [{List.first(books), path}] ==
               Filter.filter(elements, {{:property, "price"}, :<, 10})
    end
  end

  test "empty list for data type that doesn't support Access behaviour" do
    invalid_types = [10, "Test", {:some, 10}]

    for type <- invalid_types do
      assert [] == Filter.filter({type, []}, {:contains, {:property, "any"}})
    end
  end
end
