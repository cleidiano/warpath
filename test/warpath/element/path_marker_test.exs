defmodule Warpath.Element.PathMarkerTest do
  use ExUnit.Case, async: true

  alias Warpath.Element.PathMarker

  test "should generate index token for each item on list " do
    marked_paths =
      [2, 3]
      |> Element.new([])
      |> PathMarker.stream()
      |> Enum.to_list()

    assert marked_paths == [
             Element.new(2, [{:index_access, 0}]),
             Element.new(3, [{:index_access, 1}])
           ]
  end

  test "should generate property token for each key on map" do
    marked_paths =
      %{"name" => "Bumblebee", "group" => "Autobots"}
      |> Element.new([])
      |> PathMarker.stream()
      |> Enum.to_list()

    assert marked_paths == [
             Element.new("Autobots", [{:property, "group"}]),
             Element.new("Bumblebee", [{:property, "name"}])
           ]
  end
end
