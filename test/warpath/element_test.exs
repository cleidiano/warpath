defmodule Warpath.Element.ElementTest do
  use ExUnit.Case, async: true

  alias Warpath.Element

  doctest Element

  describe "elementify/3" do
    test "should generate index token for each item on list " do
      marked_paths = Element.elementify([2, 3], [])

      assert marked_paths == [
               Element.new(2, [{:index_access, 0}]),
               Element.new(3, [{:index_access, 1}])
             ]
    end

    test "should generate property token for each key on map" do
      marked_paths = Element.elementify(%{"name" => "Bumblebee", "group" => "Autobots"}, [])

      assert marked_paths == [
               Element.new("Autobots", [{:property, "group"}]),
               Element.new("Bumblebee", [{:property, "name"}])
             ]
    end

    test "should convert struct to map and then elementify it" do
      assert [Element.new("Warpath", property: :name)] ==
               Element.elementify(%Transformer{name: "Warpath"}, [])
    end
  end
end
