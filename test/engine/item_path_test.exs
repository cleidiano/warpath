defmodule Warpath.Engine.ItemPathTest do
  use ExUnit.Case, async: true

  alias Warpath.Engine.ItemPath

  describe "bracketify/1 create path for" do
    test "root expression" do
      assert ItemPath.bracketify([{:root, "$"}]) == "$"
    end

    test "property expression " do
      assert ItemPath.bracketify([{:root, "$"}, {:property, "city"}]) == "$['city']"
    end

    test "array index expression" do
      assert ItemPath.bracketify([{:root, "$"}, {:property, "persons"}, {:index_access, 0}]) ==
               "$['persons'][0]"
    end

    test "multiple array index expression" do
      assert ItemPath.bracketify([
               [{:root, "$"}, {:property, "persons"}, {:index_access, 0}],
               [{:root, "$"}, {:property, "persons"}, {:index_access, 1}]
             ]) == ["$['persons'][0]", "$['persons'][1]"]
    end

    test "array expression with property after it" do
      assert ItemPath.bracketify([
               [{:root, "$"}, {:property, "persons"}, {:index_access, 0}, {:property, "name"}],
               [{:root, "$"}, {:property, "persons"}, {:index_access, 1}, {:property, "name"}]
             ]) == ["$['persons'][0]['name']", "$['persons'][1]['name']"]
    end
  end

  describe "dotify/1 create path for" do
    test "root expression" do
      assert ItemPath.dotify([{:root, "$"}]) == "$"
    end

    test "property expression" do
      assert ItemPath.dotify([{:root, "$"}, {:property, "city"}]) == "$.city"
    end

    test "array index expression " do
      assert ItemPath.dotify([{:root, "$"}, {:property, "persons"}, {:index_access, 0}]) ==
               "$.persons[0]"
    end

    test "multiple array index expression" do
      assert ItemPath.dotify([
               [{:root, "$"}, {:property, "persons"}, {:index_access, 0}],
               [{:root, "$"}, {:property, "persons"}, {:index_access, 1}]
             ]) == ["$.persons[0]", "$.persons[1]"]
    end

    test "array expression with property after it" do
      assert ItemPath.dotify([
               [{:root, "$"}, {:property, "persons"}, {:index_access, 0}, {:property, "name"}],
               [{:root, "$"}, {:property, "persons"}, {:index_access, 1}, {:property, "name"}]
             ]) == ["$.persons[0].name", "$.persons[1].name"]
    end
  end
end
