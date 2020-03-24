defmodule RegrationSuiteTest do
  use ExUnit.Case, async: true

  %{"queries" => queries} =
    __DIR__
    |> Path.join("/fixtures/json_comparision_regration_suite.yaml")
    |> YamlElixir.read_from_file!()

  for %{"id" => rule_id, "document" => doc, "selector" => selector} = rule <- queries do
    tag =
      rule
      |> Map.get("warpath")
      |> String.to_atom()

    @rule rule
    @tag tag
    @consensus ["scalar-consensus", "consensus", "warpath_output"]
    test rule_id <> " " <> selector do
      consensus_value =
        Enum.reduce_while(@consensus, nil, fn key, acc ->
          if Map.has_key?(@rule, key), do: {:halt, Map.get(@rule, key)}, else: {:cont, acc}
        end)

      document = unquote(Macro.escape(doc))
      query_selector = unquote(selector)
      ordered = Map.get(@rule, "ordered")

      case {consensus_value, ordered} do
        {nil, _} ->
          assert {:ok, _} = Warpath.query(document, query_selector)

        {consensus, false} when is_list(consensus) ->
          assert Enum.sort(consensus) ==
                   Warpath.query!(document, query_selector) |> Enum.sort()

        {consensus, _} ->
          assert consensus == Warpath.query!(document, query_selector)
      end
    end
  end
end
