defmodule Warpath.Filter.PredicateTest do
  use ExUnit.Case, async: true

  alias Warpath.Filter.Predicate

  describe "eval/2 handle operator" do
    test ">" do
      assert Predicate.eval({:>, [{:property, "likes"}, 1]}, %{"likes" => 5})
    end

    test ">=" do
      assert Predicate.eval({:>=, [{:property, "likes"}, 10]}, %{"likes" => 10})
    end

    test "<" do
      assert Predicate.eval({:<, [{:property, "likes"}, 10]}, %{"likes" => 5})
    end

    test "<=" do
      assert Predicate.eval({:<=, [{:property, "likes"}, 10]}, %{"likes" => 10})
    end

    test "== when left and right have the same type" do
      assert Predicate.eval({:==, [{:property, "likes"}, 10]}, %{"likes" => 10})
    end

    test "== when compare float point and integer" do
      assert Predicate.eval({:==, [{:property, "likes"}, 10.0]}, %{"likes" => 10})
    end

    test "!=" do
      assert Predicate.eval({:!=, [{:property, "likes"}, 10]}, %{"likes" => "10"})
    end

    test "!= when compare float point and integer" do
      refute Predicate.eval({:!=, [{:property, "likes"}, 10.0]}, %{"likes" => 10})
    end

    test "=== when compare float point and integer" do
      refute Predicate.eval({:===, [{:property, "likes"}, 10.0]}, %{"likes" => 10})
    end

    test "=== when left and right have the same type" do
      assert Predicate.eval({:===, [{:property, "likes"}, 10.0]}, %{"likes" => 10.0})
    end

    test "!==" do
      assert Predicate.eval({:!=, [{:property, "likes"}, 10]}, %{"likes" => "10"})
    end

    test "!== when compare float point and integer" do
      assert Predicate.eval({:!==, [{:property, "likes"}, 10.0]}, %{"likes" => 10})
    end

    test "and operation when left and right side is true" do
      expression = {:and, [>: [{:property, "likes"}, 100], >: [{:property, "follwers"}, 2000]]}

      assert Predicate.eval(expression, %{"likes" => 101, "follwers" => 2001})
    end

    test "and operation when left side is false" do
      expression = {:and, [>: [{:property, "likes"}, 100], <: [{:property, "follwers"}, 50]]}

      refute Predicate.eval(expression, %{"likes" => 99, "follwers" => 100})
    end

    test "and operation when right side is false" do
      expression = {:and, [>: [{:property, "likes"}, 100], >: [{:property, "follwers"}, 300]]}

      refute Predicate.eval(expression, %{"likes" => 101, "follwers" => 200})
    end

    test "or operation when left and right side is true" do
      expression = {:or, [>: [{:property, "likes"}, 100], >: [{:property, "follwers"}, 500]]}

      assert Predicate.eval(expression, %{"likes" => 101, "follwers" => 1000})
    end

    test "or operation when left side is true and right is false" do
      expression = {:or, [>: [{:property, "likes"}, 100], >: [{:property, "follwers"}, 500]]}

      assert Predicate.eval(expression, %{"likes" => 101, "follwers" => 100})
    end

    test "or operation when left side is false and right side is true" do
      expression = {:or, [>: [{:property, "likes"}, 100], >: [{:property, "follwers"}, 500]]}

      assert Predicate.eval(expression, %{"likes" => 99, "follwers" => 1000})
    end

    test "or operation when left and right side is false" do
      expression = {:or, [>: [{:property, "likes"}, 100], >: [{:property, "follwers"}, 500]]}

      refute Predicate.eval(expression, %{"likes" => 1, "follwers" => 1})
    end
  end

  describe "eval/2 handle a contains operation" do
    test "that return true" do
      assert Predicate.eval({:contains, {:property, "likes"}}, %{"likes" => 1})
    end

    test "that return false" do
      refute Predicate.eval({:contains, {:property, "likes"}}, %{"followers" => 10})
    end
  end

  describe "eval/2 handle function call" do
    test "is_atom" do
      assert Predicate.eval({:is_atom, :any_atom}, nil)
      refute Predicate.eval({:is_atom, "not a atom"}, nil)
    end

    test "is_binary" do
      assert Predicate.eval({:is_binary, "a binary"}, nil)
      refute Predicate.eval({:is_binary, []}, nil)
    end

    test "is_boolean" do
      assert Predicate.eval({:is_boolean, true}, nil)
      refute Predicate.eval({:is_boolean, ""}, nil)
    end

    test "is_float" do
      assert Predicate.eval({:is_float, 10.1}, nil)
      refute Predicate.eval({:is_float, 10}, nil)
    end

    test "is_integer" do
      assert Predicate.eval({:is_integer, 100}, nil)
      refute Predicate.eval({:is_integer, 10.0}, nil)
    end

    test "is_list" do
      assert Predicate.eval({:is_list, []}, nil)
      refute Predicate.eval({:is_list, ""}, nil)
    end

    test "is_map" do
      assert Predicate.eval({:is_map, %{}}, nil)
      refute Predicate.eval({:is_map, []}, nil)
    end

    test "is_nil" do
      assert Predicate.eval({:is_nil, nil}, nil)
      refute Predicate.eval({:is_nil, ""}, nil)
    end

    test "is_number" do
      assert Predicate.eval({:is_number, 10.0}, nil)
      assert Predicate.eval({:is_number, 10}, nil)
      refute Predicate.eval({:is_number, "10"}, nil)
    end

    test "is_tuple" do
      assert Predicate.eval({:is_tuple, {}}, nil)
      refute Predicate.eval({:is_tuple, "10"}, nil)
    end
  end
end
