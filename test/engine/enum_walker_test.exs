defmodule Warpath.Engine.EnumWalkerTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine.EnumWalker

  describe "reduce_while/4" do
    test "stop reduce a list of elements when encounter a {:halt, acc}" do
      path = []
      members = [{1, path}, {5, path}, {6, path}, {9, path}]

      walk_reducer = fn {member, _} = element, acc ->
        if rem(member, 2) != 0,
          do: {:walk, acc ++ [element]},
          else: {:halt, acc}
      end

      result = EnumWalker.reduce_while(members, [], walk_reducer)

      assert [{1, path}, {5, path}] == result
    end

    test "walk in nested strucutre" do
      members =
        {%{"detail" => %{"brand" => "Chevrolet", "color" => "Yellow"}, "name" => "Bumblebee"}, []}

      walk_reducer = fn {member, _} = element, acc ->
        case member do
          value when is_map(value) -> {:walk, acc}
          _ -> {:walk, acc ++ [element]}
        end
      end

      result = EnumWalker.reduce_while(members, [], walk_reducer)

      assert [
               {"Chevrolet", [{:property, "brand"}, {:property, "detail"}]},
               {"Yellow", [{:property, "color"}, {:property, "detail"}]},
               {"Bumblebee", [{:property, "name"}]}
             ] == result
    end
  end

  describe "recursive_descent/2" do
    test "should produce output that match with oracle result" do
      store = Oracle.json_store()

      result =
        {store, []}
        |> EnumWalker.recursive_descent(&[&1 | &2])
        |> Enum.map(fn {value, _path} -> value end)

      assert result == Oracle.scaned_elements()
    end
  end
end
