defmodule Warpath.Element.PathTest do
  use ExUnit.Case, async: true

  alias Warpath.Element.Path

  describe "bracketify/1 create path for" do
    test "root expression" do
      assert Path.bracketify([{:root, "$"}]) == "$"
    end

    test "property expression " do
      tokens = accumulate_tokens([{:root, "$"}, {:property, "city"}])

      assert Path.bracketify(tokens) == "$['city']"
    end

    test "array index expression" do
      tokens = accumulate_tokens([{:root, "$"}, {:property, "persons"}, {:index_access, 0}])

      assert Path.bracketify(tokens) == "$['persons'][0]"
    end

    test "multiple array index expression" do
      nested_tokens = [
        [{:root, "$"}, {:property, "persons"}, {:index_access, 0}],
        [{:root, "$"}, {:property, "persons"}, {:index_access, 1}]
      ]

      tokens = Enum.map(nested_tokens, &accumulate_tokens(&1))
      assert Path.bracketify(tokens) == ["$['persons'][0]", "$['persons'][1]"]
    end

    test "array expression with property after it" do
      nested_tokens = [
        [{:root, "$"}, {:property, "persons"}, {:index_access, 0}, {:property, "name"}],
        [{:root, "$"}, {:property, "persons"}, {:index_access, 1}, {:property, "name"}]
      ]

      tokens = Enum.map(nested_tokens, &accumulate_tokens(&1))
      assert Path.bracketify(tokens) == ["$['persons'][0]['name']", "$['persons'][1]['name']"]
    end
  end

  describe "dotify/1 create path for" do
    test "root expression" do
      assert Path.dotify([{:root, "$"}]) == "$"
    end

    test "property expression" do
      tokens = accumulate_tokens([{:root, "$"}, {:property, "city"}])

      assert Path.dotify(tokens) == "$.city"
    end

    test "array index expression " do
      tokens = accumulate_tokens([{:root, "$"}, {:property, "persons"}, {:index_access, 0}])

      assert Path.dotify(tokens) == "$.persons[0]"
    end

    test "multiple array index expression" do
      nested_tokens = [
        [{:root, "$"}, {:property, "persons"}, {:index_access, 0}],
        [{:root, "$"}, {:property, "persons"}, {:index_access, 1}]
      ]

      tokens = Enum.map(nested_tokens, &accumulate_tokens(&1))
      assert Path.dotify(tokens) == ["$.persons[0]", "$.persons[1]"]
    end

    test "array expression with property after it" do
      nested_tokens = [
        [{:root, "$"}, {:property, "persons"}, {:index_access, 0}, {:property, "name"}],
        [{:root, "$"}, {:property, "persons"}, {:index_access, 1}, {:property, "name"}]
      ]

      tokens = Enum.map(nested_tokens, &accumulate_tokens(&1))
      assert Path.dotify(tokens) == ["$.persons[0].name", "$.persons[1].name"]
    end
  end

  defp accumulate_tokens(tokens) do
    Enum.reduce(tokens, [], &Path.accumulate/2)
  end
end
