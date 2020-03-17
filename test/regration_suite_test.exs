defmodule RegrationSuiteTest do
  use ExUnit.Case, async: true
  @include_rules_pattern ["array_slice"]

  %{"queries" => queries} =
    __DIR__
    |> Path.join("/fixtures/json_comparision_regration_suite.yaml")
    |> YamlElixir.read_from_file!()

  queries = Enum.filter(queries, fn rule -> Map.has_key?(rule, "consensus") end)

  for %{"id" => id, "document" => document, "selector" => selector} = rule <- queries do
    tag =
      @include_rules_pattern
      |> Enum.filter(fn pattern -> String.contains?(id, pattern) end)
      |> case do
        [] -> :skip
        [tag | _] -> String.to_atom(tag)
      end

    @rule rule
    @tag tag
    test String.replace(id, "_", " ") do
      @rule
      |> Map.get_lazy("scalar-consensus", fn -> Map.get(@rule, "consensus") end)
      |> case do
        nil ->
          assert {:ok, _} = Warpath.query(unquote(Macro.escape(document)), unquote(selector))

        consensus_value ->
          assert {:ok, quote(do: unquote(consensus_value))} ==
                   Warpath.query(unquote(Macro.escape(document)), unquote(selector))
      end
    end
  end
end
