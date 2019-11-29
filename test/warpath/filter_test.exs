defmodule Warpath.FilterTest do
  use ExUnit.Case, async: true

  alias Warpath.Element.PathMarker
  alias Warpath.Filter

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
    test "when the target member is a tuple of {map, path}", context do
      bicycle = context[:data]["store"]["bicycle"]
      path = [{:property, "bicycle"}, {:store, "store"}]

      assert [{bicycle, path}] ==
               Filter.filter({bicycle, path}, {:>, [{:property, "price"}, 10]})
    end

    test "when the target member is tuple of {list, path}", context do
      path = [{:index_access, 1}]
      books = context[:data]["store"]["book"]

      assert [{List.last(books), path}] ==
               Filter.filter({books, []}, {:has_property?, {:property, "isbn"}})
    end

    test "when the target member is a list of [{member, path}]", context do
      path = [{:index_access, 0}]
      books = [%{"price" => 11} | context[:data]["store"]["book"]]

      elements =
        {books, []}
        |> PathMarker.stream()
        |> Enum.to_list()

      assert [{%{"price" => 11}, path}] ==
               Filter.filter(elements, {:is_integer, {:property, "price"}})
    end
  end

  test "empty list for data type that doesn't support Access behaviour" do
    invalid_types = [10, "Test", {:some, 10}]

    for type <- invalid_types do
      assert [] == Filter.filter({type, []}, {:has_property?, {:property, "any"}})
    end
  end
end
