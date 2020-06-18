defmodule Warpath.Filter.PredicateTest do
  use ExUnit.Case, async: true

  alias Warpath.Filter.Predicate

  defp expression(filter) do
    {:ok, %Warpath.Expression{tokens: tokens}} = Warpath.Expression.compile("$[?( #{filter} )]")
    [_root | [{:filter, expression}]] = tokens
    expression
  end

  describe "eval/2 ensure dispatch call for operator" do
    test ">" do
      assert Predicate.eval(expression("5 > 1"), %{})
    end

    test ">=" do
      assert Predicate.eval({:>=, [10, 10]}, %{})
    end

    test "<" do
      assert Predicate.eval({:<, [5, 10]}, %{})
    end

    test "<=" do
      assert Predicate.eval({:<=, [10, 10]}, %{})
    end

    test "== when left and right have the same type" do
      assert Predicate.eval({:==, [10, 10]}, %{})
    end

    test "== when compare float point and integer" do
      assert Predicate.eval({:==, [10, 10.0]}, %{})
    end

    test "!=" do
      assert Predicate.eval({:!=, ["10", 10]}, %{})
    end

    test "!= when compare float point and integer" do
      refute Predicate.eval({:!=, [10, 10.0]}, %{})
    end

    test "=== when compare float point and integer" do
      refute Predicate.eval({:===, [10, 10.0]}, %{})
    end

    test "=== when left and right have the same type" do
      assert Predicate.eval({:===, [10.0, 10.0]}, %{})
    end

    test "!==" do
      assert Predicate.eval({:!=, ["10", 10]}, %{})
    end

    test "!== when compare float point and integer" do
      assert Predicate.eval({:!==, [10, 10.0]}, %{})
    end

    test "AND operation when left and right side is true" do
      assert Predicate.eval({:and, [>: [101, 100], >: [2001, 2000]]}, %{})
    end

    test "AND operation when left side is false" do
      refute Predicate.eval({:and, [>: [99, 100], <: [100, 50]]}, %{})
    end

    test "AND operation when right side is false" do
      refute Predicate.eval({:and, [>: [101, 100], >: [200, 300]]}, %{})
    end

    test "OR operation when left and right side is true" do
      assert Predicate.eval({:or, [>: [101, 100], >: [1000, 500]]}, %{})
    end

    test "OR operation when left side is true and right is false" do
      assert Predicate.eval({:or, [>: [101, 100], >: [100, 500]]}, %{})
    end

    test "OR operation when left side is false and right side is true" do
      assert Predicate.eval({:or, [>: [99, 100], >: [1000, 500]]}, %{})
    end

    test "OR operation when left and right side is false" do
      refute Predicate.eval({:or, [>: [1, 100], >: [1, 500]]}, %{})
    end

    test "NOT" do
      refute Predicate.eval({:not, true}, %{})
      assert Predicate.eval({:not, false}, %{})
    end

    test "IN" do
      assert Predicate.eval({:in, [1, [1, 2, 3]]}, %{})
      refute Predicate.eval({:in, [4, [1, 2, 3]]}, %{})
    end
  end

  describe "eval/2 handle a has_property? operation" do
    test "that return true" do
      assert Predicate.eval({:has_property?, {:property, "likes"}}, %{"likes" => 1})
    end

    test "that return false" do
      refute Predicate.eval({:has_property?, {:property, "likes"}}, %{"followers" => 10})
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

  describe "eval/2 can discovery" do
    test "a property value from context on eval operators" do
      context = %{"likes" => 100}

      assert Predicate.eval(expression("@.likes > 10"), context)
      refute Predicate.eval(expression("@.likes > 1000"), context)
    end

    test "a property value from context on eval function call" do
      context = %{"likes" => 100}

      assert Predicate.eval(expression("is_integer(@.likes)"), context)
      refute Predicate.eval(expression("is_float(@.likes)"), context)
    end

    test "a value from context for each property on list on eval IN operator" do
      left_is_value = expression(" 'Warpath' in [@.affiliation, @.name] ")
      left_is_expression = expression(" @.name in [Warpath, Bumblebee] ")

      assert Predicate.eval(left_is_value, %{"affiliation" => "Autobots", "name" => "Warpath"})

      refute Predicate.eval(left_is_value, %{
               "affiliation" => "Decepticon",
               "name" => "Megatronus"
             })

      assert Predicate.eval(left_is_expression, %{
               "affiliation" => "Autobots",
               "name" => "Warpath"
             })

      refute Predicate.eval(left_is_expression, %{
               "affiliation" => "Autobots",
               "name" => "Optimus"
             })
    end

    test "a value for the current node that is context it self" do
      assert Predicate.eval(expression("is_map(@)"), %{})
    end
  end

  describe "eval/2 evaluate index access from context " do
    test "when it exists" do
      context = [1, 2, 3, 4]

      assert Predicate.eval(expression("1 == @[0]"), context)
    end

    test "when it doesn't exists" do
      context = [1, 2, 3, 4]

      refute Predicate.eval(expression("1 == @[5]"), context)
    end

    test "when the context is not a list" do
      context = :atom

      refute Predicate.eval(expression("@[0] == @[0]"), context)
    end

    test "when the context is nil, nil will be returned" do
      assert Predicate.eval(expression("is_nil(@[1])"), nil)
    end
  end

  describe "eval/2 evaluate sub path expression" do
    test "simple filter using dot notation" do
      transformer = %{
        "transformer" => %{
          "name" => "Optmius Prime",
          "family" => "Autobot"
        }
      }

      assert Predicate.eval(expression("@.transformer.family == 'Autobot'"), transformer)
    end

    test "simple filter using index access" do
      transformer = %{
        "transformer" => %{
          "name" => "Optmius Prime",
          "family" => "Autobot",
          "accessories" => [
            "Laser Blaster",
            "2 fists (left & right)",
            "Trailer/Combat Deck",
            "Roller",
            "4 rockets",
            "hose",
            "nozzle",
            "fuel pump"
          ]
        }
      }

      assert Predicate.eval(
               expression("@.transformer.accessories[0] == 'Laser Blaster'"),
               transformer
             )

      refute Predicate.eval(
               expression("@.transformer.accessories[1] == 'Laser Blaster'"),
               transformer
             )
    end
  end

  test "eval/2 when expression is a boolean literal" do
    assert Predicate.eval(true, %{})
    refute Predicate.eval(false, %{})
  end
end
