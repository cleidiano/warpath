defmodule WarpathTest do
  use ExUnit.Case, async: true

  doctest Warpath

  alias Warpath.ExpressionError
  alias Warpath.JsonDecodeError

  setup_all do
    %{data: Oracle.json_store()}
  end

  describe "query/3" do
    test "report {:error, ExpressionError.t()} when evaluate a invalid expression" do
      assert {:error, %ExpressionError{}} = Warpath.query(%{}, "$[]")
    end

    test "report {:error, JsonDecodeError} when evaluate a invalid expression" do
      assert {:error, %JsonDecodeError{}} = Warpath.query("invalid", "$")
    end

    test "successfully evaluate a valid expresssion" do
      assert {:ok, "Warpath"} =
               Warpath.query(%{"autobots" => ["Optimus Prime", "Warpath"]}, "$.autobots[1]")
    end

    test "successfully evaluate expression compiled" do
      {:ok, expression} = Warpath.Expression.compile("$.autobots[0]")

      assert {:ok, "Optimus Prime"} =
               Warpath.query(%{"autobots" => ["Optimus Prime", "Warpath"]}, expression)
    end

    test "can decode and evaluate a valid json string" do
      assert {:ok, "Warpath"} =
               Warpath.query(~S/{"autobots": ["Optimus Prime", "Warpath"]}/, "$.autobots[1]")
    end
  end

  describe "query!/3" do
    test "raise on evaluate a invalid expression" do
      assert_raise ExpressionError, fn ->
        Warpath.query!(%{}, "$[]")
      end
    end

    test "raise on decode a invalid json" do
      assert_raise JsonDecodeError, fn ->
        Warpath.query!("invalid", "$")
      end
    end

    test "successfully evaluate a valid expresssion" do
      assert "Warpath" =
               Warpath.query!(%{"autobots" => ["Optimus Prime", "Warpath"]}, "$.autobots[1]")
    end

    test "can decode and evaluate a valid json string" do
      assert "Warpath" =
               Warpath.query!(~S/{"autobots": ["Optimus Prime", "Warpath"]}/, "$.autobots[1]")
    end

    test "an empty list is returned for queries that filter out all possible matches", %{
      data: document
    } do
      assert Warpath.query!(document, "$.store.book[?(@.id == 0)].title") == []
    end
  end

  describe "query/3 handle options" do
    test "result_type: :path", %{data: document} do
      path = "$['store']['book'][0]"

      assert Warpath.query(document, "$.store.book[0]", result_type: :path) == {:ok, path}
    end

    test "result_type: :path_tokens", %{data: document} do
      path_tokens = [root: "$", property: "store", property: "book", index_access: 0]

      assert Warpath.query(document, "$.store.book[0]", result_type: :path_tokens) ==
               {:ok, path_tokens}
    end

    test "result_type: :value_path_tokens", %{data: document} do
      book = %{
        "author" => "Nigel Rees",
        "category" => "reference",
        "price" => 8.95,
        "title" => "Sayings of the Century"
      }

      path_tokens = [root: "$", property: "store", property: "book", index_access: 0]

      assert Warpath.query(document, "$.store.book[0]", result_type: :value_path_tokens) ==
               {:ok, {book, path_tokens}}
    end

    test "result_type: :value_path", %{data: document} do
      book = %{
        "author" => "Nigel Rees",
        "category" => "reference",
        "price" => 8.95,
        "title" => "Sayings of the Century"
      }

      path = "$['store']['book'][0]"

      assert Warpath.query(document, "$.store.book[0]", result_type: :value_path) ==
               {:ok, {book, path}}
    end

    test "default result_type is :value", %{data: document} do
      book = %{
        "author" => "Nigel Rees",
        "category" => "reference",
        "price" => 8.95,
        "title" => "Sayings of the Century"
      }

      assert Warpath.query(document, "$.store.book[0]") == {:ok, book}
    end
  end

  describe "delete/2" do
    test "remove items from children list" do
      numbers = %{"numbers" => [20, 3, 50, 6, 7]}
      assert {:ok, %{"numbers" => [20, 50]}} == Warpath.delete(numbers, "$.numbers[?(@ < 10)]")
    end

    test "remove item from map" do
      assert {:ok, %{"one" => 1}} == Warpath.delete(%{"one" => 1, "two" => 2}, "$.two")
    end

    test "return the input data structure when then selector doesn't match any item" do
      numbers = %{"numbers" => [20, 3, 50, 6, 7]}

      assert {:ok, numbers} == Warpath.delete(numbers, "$.numbers[?(@ > 100)]")
      assert {:ok, %{"numbers" => []}} == Warpath.delete(numbers, "$.numbers.*")
    end

    test "using bad selector" do
      assert {:error, _} = Warpath.delete(%{}, "$.")
    end

    test "request to remove an item that already have been removed should be ok", %{data: data} do
      assert {:ok, %{}} == Warpath.delete(data, "$..*")
    end

    test "delete root document result nil" do
      document = %{"value" => [20, 3, 50, 6, 7]}

      assert {:ok, nil} == Warpath.delete(document, "$")
    end

    test "when document is a json string" do
      document = ~S|{"numbers": [20, 3, 50, 6, 7]}|

      assert {:ok, %{"numbers" => [20, 50]}} == Warpath.delete(document, "$.numbers[?(@ < 10)]")
    end

    test "when document is a bad json string results decode error" do
      document = ~S|{"numbers": }|
      assert {:error, %JsonDecodeError{}} = Warpath.delete(document, "$.numbers[?(@ < 10)]")
    end
  end

  describe "update/3" do
    test "update a list" do
      numbers = %{"numbers" => [20, 3, 50, 6, 7]}

      assert {:ok, %{"numbers" => [20, 6, 50, 12, 14]}} ==
               Warpath.update(numbers, "$.numbers[?(@ < 10)]", &(&1 * 2))
    end

    test "update a map" do
      assert {:ok, %{"first" => 1, "second" => 12}} ==
               Warpath.update(%{"first" => 1, "second" => 2}, "$.second", &(&1 + 10))
    end

    test "return the input data structure when then selector doesn't match any item" do
      numbers = %{"numbers" => [20, 3, 50, 6, 7]}
      assert {:ok, numbers} == Warpath.update(numbers, "$.numbers[?(@ > 100)]", &(&1 * 2))
    end

    test "when document is a json string" do
      numbers = ~S|{"numbers" : [20, 3, 50, 6, 7]}|

      assert {:ok, %{"numbers" => [20, 6, 50, 12, 14]}} ==
               Warpath.update(numbers, "$.numbers[?(@ < 10)]", &(&1 * 2))
    end

    test "when document is a bad json string results decode error" do
      numbers = ~S|{"numbers": }|

      assert {:error, %JsonDecodeError{}} =
               Warpath.update(numbers, "$.numbers[?(@ < 10)]", &(&1 * 2))
    end

    test "update root document" do
      document = %{"value" => [20, 3, 50, 6, 7]}

      assert {:ok, ["Hello World"]} == Warpath.update(document, "$", fn _ -> ["Hello World"] end)
    end

    test "using bad selector" do
      assert {:error, _} = Warpath.update(%{}, "$.", &[&1])
    end
  end
end
