defmodule Warpath.Engine.ScannerTest do
  use ExUnit.Case, async: true

  alias Warpath.Element.Path
  alias Warpath.Engine.Scanner

  setup_all do
    [store: Oracle.json_store()]
  end

  test "scan with wildcard get all elements like oracle", context do
    oracle_elements = Oracle.scaned_elements()
    term = context[:store]
    trace = [{:root, "$"}]

    all_elements = Scanner.scan({term, trace}, {:wildcard, :*})
    assert oracle_elements == all_elements |> Enum.map(fn {element, _} -> element end)
  end

  test "deep_scan with wildcard get all paths like oracle", context do
    oracle_paths = Oracle.scaned_paths()
    term = context[:store]
    trace = [{:root, "$"}]

    all_elements = Scanner.scan({term, trace}, {:wildcard, :*})

    assert oracle_paths ==
             all_elements
             |> Stream.map(fn {_term, path} -> path end)
             |> Stream.map(&Path.bracketify(&1))
             |> Enum.to_list()
  end

  test "should get empty list when property not found" do
    element = {%{"id" => 9, "tags" => ["one", "two", "three"]}, []}

    assert Scanner.scan(element, {:property, "name"}) == []
  end
end
