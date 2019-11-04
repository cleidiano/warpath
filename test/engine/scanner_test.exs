defmodule Warpath.Engine.ScannerTest do
  use ExUnit.Case, async: true

  alias Warpath.Engine.{Scanner, ItemPath}

  setup_all do
    [store: JayWayOracle.json_store()]
  end

  test "scan with wildcard get all elements like oracle", context do
    oracle_elements = JayWayOracle.scaned_elements()
    term = context[:store]
    trace = [{:root, "$"}]

    all_elements = Scanner.scan({term, trace}, {:wildcard, :*})
    assert oracle_elements == all_elements |> Enum.map(fn {element, _} -> element end)
  end

  test "deep_scan with wildcard get all paths like oracle", context do
    oracle_paths = JayWayOracle.scaned_paths()
    term = context[:store]
    trace = [{:root, "$"}]

    all_elements = Scanner.scan({term, trace}, {:wildcard, :*})

    assert oracle_paths ==
             all_elements
             |> Stream.map(fn {_term, path} -> path end)
             |> Stream.map(&ItemPath.bracketify(&1))
             |> Enum.to_list()
  end
end
