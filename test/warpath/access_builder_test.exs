defmodule Warpath.AccessBuilderTest do
  use ExUnit.Case, async: true

  alias Warpath.AccessBuilder

  test "create access path to modify a list" do
    path = [root: "$", index_access: 0]
    [{^path, accessor}] = AccessBuilder.build(path)

    assert pop_in([1, 2, 3], accessor) == {1, [2, 3]}
    assert update_in([1, 2, 3], accessor, fn value -> value + 10 end) == [11, 2, 3]
  end

  test "create access path to modify a map" do
    path = [root: "$", property: :key]
    [{^path, accessor}] = AccessBuilder.build(path)

    assert pop_in(%{key: "ABC"}, accessor) == {"ABC", %{}}

    assert update_in(%{key: "ABC"}, accessor, fn value -> String.reverse(value) end) == %{
             key: "CBA"
           }
  end

  test "create access path to modify a nested data structure" do
    path = [root: "$", property: :list, index_access: 0, property: :map, property: :key]
    [{^path, accessor}] = AccessBuilder.build(path)

    data = %{list: [%{map: %{key: "ABC"}}]}

    assert pop_in(data, accessor) == {"ABC", %{list: [%{map: %{}}]}}

    assert update_in(data, accessor, fn value -> String.reverse(value) end) == %{
             list: [%{map: %{key: "CBA"}}]
           }
  end

  test "create a path to pop root data structure" do
    [{_, accessor}] = AccessBuilder.build(root: "$")

    assert pop_in([1], accessor) == {[1], nil}
    assert pop_in(%{key: :a}, accessor) == {%{key: :a}, nil}
  end
end
