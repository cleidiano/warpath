defmodule Warpath.Query.AccessibleTest do
  use ExUnit.Case, async: true
  alias Warpath.Query.Accessible

  test "accessible?/1" do
    refute Accessible.accessible?(:atom)
    refute Accessible.accessible?("")
    refute Accessible.accessible?(1)
    refute Accessible.accessible?(1.0)
    refute Accessible.accessible?({:a, 1})
    refute Accessible.accessible?([1])
    refute Accessible.accessible?(make_ref())

    assert Accessible.accessible?([])
    assert Accessible.accessible?(a: 1)
    assert Accessible.accessible?(%{})
  end

  test "has_key?/2" do
    assert Accessible.has_key?([a: 1], :a)
    assert Accessible.has_key?(%{a: 1}, :a)
    assert Accessible.has_key?(%{"a" => 1}, "a")

    refute Accessible.has_key?([a: 1], :b)
    refute Accessible.has_key?(%{a: 1}, :b)
    refute Accessible.has_key?(%{"a" => 1}, "b")

    refute Accessible.has_key?([], :b)
    refute Accessible.has_key?(%{}, "b")
    refute Accessible.has_key?([], "b")

    refute Accessible.has_key?(:atom, :a)
    refute Accessible.has_key?("", :a)
    refute Accessible.has_key?(1, :a)
    refute Accessible.has_key?(1.0, :a)
    refute Accessible.has_key?({:a, 1}, :a)
    refute Accessible.has_key?([:a], :a)
    refute Accessible.has_key?(make_ref(), :a)
  end
end
