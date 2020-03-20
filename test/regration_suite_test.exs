defmodule RegrationSuiteTest do
  use ExUnit.Case, async: true
  @include_rules_pattern ["array_slice", "recursive_descent"]

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
    test String.replace(id, "_", " ") <> " selector = " <> selector do
      document = unquote(Macro.escape(document))
      selector = unquote(selector)

      consensus_value =
        Map.get_lazy(@rule, "scalar-consensus", fn -> Map.get(@rule, "consensus") end)

      ordered = Map.get(@rule, "ordered")

      case {consensus_value, ordered} do
        {nil, _} ->
          assert {:ok, _} = Warpath.query(document, selector)

        {consensus, false} when is_list(consensus) ->
          assert Enum.sort(consensus) ==
                   Warpath.query!(unquote(Macro.escape(document)), selector) |> Enum.sort()

        {consensus, _} ->
          assert consensus == Warpath.query!(document, selector)
      end
    end
  end
end
