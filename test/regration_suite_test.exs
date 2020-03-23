defmodule RegrationSuiteTest do
  use ExUnit.Case, async: true

  %{"queries" => queries} =
    __DIR__
    |> Path.join("/fixtures/json_comparision_regration_suite.yaml")
    |> YamlElixir.read_from_file!()

  for %{"id" => rule_id, "document" => document, "selector" => selector} = rule <- queries do
    tag =
      rule
      |> Map.get("warpath")
      |> String.to_atom()

    @rule rule
    @tag tag
    test rule_id <> " " <> selector do
      consensus_value =
        Map.get_lazy(@rule, "scalar-consensus", fn -> Map.get(@rule, "consensus") end)

      document = unquote(Macro.escape(document))
      selector = unquote(selector)
      ordered = Map.get(@rule, "ordered")

      case {consensus_value, ordered} do
        {nil, _} ->
          assert {:ok, _} = Warpath.query(document, selector)

        {consensus, false} when is_list(consensus) ->
          assert Enum.sort(consensus) ==
                   Warpath.query!(unquote(Macro.escape(document)), selector) |> Enum.sort()

        {consensus, _} ->
          assert consensus == Warpath.query!(unquote(Macro.escape(document)), selector)
      end
    end
  end
end
