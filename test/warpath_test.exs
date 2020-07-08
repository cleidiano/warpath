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
end
