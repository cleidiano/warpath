defmodule RegrationSuiteTest do
  use ExUnit.Case, async: true
  alias Warpath

  %{"queries" => errors} =
    __DIR__
    |> Path.join("/fixtures/json_comparision_regrassion_suite_errors.yaml")
    |> YamlElixir.read_from_file!()

  %{"queries" => queries} =
    __DIR__
    |> Path.join("/fixtures/json_comparision_regrassion_suite.yaml")
    |> YamlElixir.read_from_file!()

  queries =
    Enum.map(queries, fn query ->
      label =
        case Map.fetch(errors, query["id"]) do
          {:ok, "error"} ->
            :error

          {:ok, ["raise", exception]} ->
            {:raise, String.to_atom(exception)}

          _ ->
            :ok
        end

      Map.put(query, "test_type", label)
    end)

  for %{"id" => query_id, "document" => doc, "selector" => selector} = query <- queries do
    @query query
    test query_id <> " " <> selector do
      document = unquote(Macro.escape(doc))
      query_selector = unquote(selector)
      test_type = Map.get(@query, "test_type")

      consensus_value =
        Map.get_lazy(@query, "scalar-consensus", fn -> Map.get(@query, "consensus", :no_consensus) end)

      case {consensus_value, Map.get(@query, "ordered")} do
        {:no_consensus, _} ->
          case test_type do
            {:raise, exception} ->
              assert_raise exception, fn -> Warpath.query(document, query_selector) end

            type ->
              assert {^type, _} = Warpath.query(document, query_selector)
          end

        {"NOT_SUPPORTED", _} ->
          assert {:error, _} = Warpath.query(document, query_selector)

        {consensus, false} when is_list(consensus) ->
          result = Warpath.query!(document, query_selector)
          assert Enum.sort(consensus) == Enum.sort(result)

        {consensus, _} ->
          assert consensus == Warpath.query!(document, query_selector)
      end
    end
  end
end
