defmodule Warpath.Engine.PathMarkerTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine.PathMarker

  test "should generate index token for each item on list " do
    marked_paths =
      {[2, 3], []}
      |> PathMarker.stream(&(&2 ++ [&1]))
      |> Enum.to_list()

    assert marked_paths == [
             {2, [{:index_access, 0}]},
             {3, [{:index_access, 1}]}
           ]
  end

  test "should generate property token for each key on map" do
    marked_paths =
      {%{"name" => "Bumblebee", "group" => "Autobots"}, []}
      |> PathMarker.stream(&(&2 ++ [&1]))
      |> Enum.to_list()

    assert marked_paths == [
             {"Autobots", [{:property, "group"}]},
             {"Bumblebee", [{:property, "name"}]}
           ]
  end
end
