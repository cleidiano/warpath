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
      assert Predicate.eval(expression("10 >= 10"), %{})
    end

    test "<" do
      assert Predicate.eval(expression("5 < 10"), %{})
    end

    test "<=" do
      assert Predicate.eval(expression("10 <= 10"), %{})
    end

    test "== when left and right have the same type" do
      assert Predicate.eval(expression("10 == 10"), %{})
    end

    test "== when compare float point and integer" do
      assert Predicate.eval(expression("10 == 10.0"), %{})
    end

    test "!=" do
      assert Predicate.eval(expression("10 != 11"), %{})
    end

    test "!= when compare float point and integer" do
      refute Predicate.eval(expression("10 != 10.0"), %{})
    end

    test "=== when compare float point and integer" do
      refute Predicate.eval(expression("10 === 10.0"), %{})
    end

    test "=== when left and right have the same type" do
      assert Predicate.eval(expression("10.0 === 10.0"), %{})
    end

    test "!==" do
      assert Predicate.eval(expression("10 !== 10.0"), %{})
    end

    test "!== when compare float point and integer" do
      assert Predicate.eval(expression("10 !== 10.0"), %{})
    end

    test "AND operation when left and right side is true" do
      assert Predicate.eval(expression("101 > 100 and 2001 > 2000"), %{})
    end

    test "AND operation when left side is false" do
      refute Predicate.eval(expression(" 99 > 100 and 100 > 50"), %{})
    end

    test "AND operation when right side is false" do
      refute Predicate.eval(expression("101 > 100 and 200 > 300"), %{})
    end

    test "OR operation when left and right side is true" do
      assert Predicate.eval(expression("101 > 100 or 1000 > 500"), %{})
    end

    test "OR operation when left side is true and right is false" do
      assert Predicate.eval(expression("101 > 100 or 100 > 500"), %{})
    end

    test "OR operation when left side is false and right side is true" do
      assert Predicate.eval(expression("99 > 100 or 1000 > 500"), %{})
    end

    test "OR operation when left and right side is false" do
      refute Predicate.eval(expression("1 > 100 or 1 > 50"), %{})
    end

    test "NOT" do
      assert Predicate.eval(expression("not false"), %{})
      refute Predicate.eval(expression("not true"), %{})
    end

    test "IN" do
      assert Predicate.eval(expression("1 in [1, 2, 3]"), %{})
      refute Predicate.eval(expression("4 in [1, 2, 3]"), %{})
    end
  end

  describe "eval/2 can evaluate {:has_property?, property} expression" do
    test "when context is map" do
      assert Predicate.eval(expression("@.likes"), %{"likes" => 1})
      refute Predicate.eval(expression("@.likes"), %{"followers" => 10})
    end

    test "when context is a keyword list and property key is atom" do
      assert Predicate.eval(expression("@.:my_key"), my_key: :any)
    end

    test "when context is a keyword list and property key is string" do
      refute Predicate.eval(expression("@.my_key"), my_key: 1)
    end

    test "when context is a list and target is a positive index " do
      assert Predicate.eval(expression("@[0]"), [1, 2, 3, 4, 5])
      assert Predicate.eval(expression("@[4]"), [1, 2, 3, 4, 5])
      refute Predicate.eval(expression("@[5]"), [1, 2, 3, 4, 5])
    end

    test "when context is a keyword list and target is a negative index" do
      assert Predicate.eval(expression("@[-1]"), [1, 2, 3, 4, 5])
      assert Predicate.eval(expression("@[-5]"), [1, 2, 3, 4, 5])
      refute Predicate.eval(expression("@[-6]"), [1, 2, 3, 4, 5])
    end

    test "when expression is subpath expression using dot notation" do
      transformer = %{
        "transformer" => %{
          "name" => "Optmius Prime",
          "family" => "Autobot"
        }
      }

      assert Predicate.eval(expression("@.transformer.family"), transformer)
    end
  end

  describe "eval/2 handle function call" do
    test "is_atom" do
      assert Predicate.eval(expression("is_atom(@)"), :any_atom)
      refute Predicate.eval(expression("is_atom(@)"), "a string")
    end

    test "is_binary" do
      assert Predicate.eval(expression("is_binary(@)"), "a binary")
      refute Predicate.eval(expression("is_binary(@)"), nil)
    end

    test "is_boolean" do
      assert Predicate.eval(expression("is_boolean(@)"), true)
      assert Predicate.eval(expression("is_boolean(@)"), false)
      refute Predicate.eval(expression("is_boolean(@)"), 123)
    end

    test "is_float" do
      assert Predicate.eval(expression("is_float(@)"), 10.0)
      refute Predicate.eval(expression("is_float(@)"), 11)
    end

    test "is_integer" do
      assert Predicate.eval(expression("is_integer(@)"), 10)
      refute Predicate.eval(expression("is_integer(@)"), 11.0)
    end

    test "is_list" do
      assert Predicate.eval(expression("is_list(@)"), [])
      refute Predicate.eval(expression("is_list(@)"), %{})
    end

    test "is_map" do
      assert Predicate.eval(expression("is_map(@)"), %{})
      refute Predicate.eval(expression("is_map(@)"), [])
    end

    test "is_nil" do
      assert Predicate.eval(expression("is_nil(@)"), nil)
      refute Predicate.eval(expression("is_nil(@)"), "is not nil")
    end

    test "is_number" do
      assert Predicate.eval(expression("is_number(@)"), 10.0)
      assert Predicate.eval(expression("is_number(@)"), 10)
      refute Predicate.eval(expression("is_number(@)"), "10")
    end

    test "is_tuple" do
      assert Predicate.eval(expression("is_tuple(@)"), {})
      refute Predicate.eval(expression("is_tuple(@)"), nil)
    end
  end

  describe "eval/2 can evaluate {:dot, property} expression" do
    test "when action is a operator" do
      context = %{"likes" => 100}

      assert Predicate.eval(expression("@.likes > 10"), context)
      refute Predicate.eval(expression("@.likes > 1000"), context)
    end

    test "when action is a function call" do
      context = %{"likes" => 100}

      assert Predicate.eval(expression("is_integer(@.likes)"), context)
      refute Predicate.eval(expression("is_float(@.likes)"), context)
    end

    test "when acion is an IN operator" do
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

    test "when context is a keyword list and property key is atom" do
      assert Predicate.eval(expression("@.:my_key == false"), my_key: false)
    end

    test "when context is a keyword list and property key is string" do
      refute Predicate.eval(expression("@.my_key == 1"), my_key: 1)
    end

    test "when expression is subpath expression using dot notation" do
      transformer = %{
        "transformer" => %{
          "name" => "Optmius Prime",
          "family" => "Autobot"
        }
      }

      assert Predicate.eval(expression("@.transformer.family == 'Autobot'"), transformer)
    end

    test "when expression is subpath expression using index access" do
      transformer = %{
        "transformer" => %{
          "name" => "Optmius Prime",
          "family" => "Autobot",
          "accessories" => [
            "Roller",
            "Laser Blaster",
            "4 rockets"
          ]
        }
      }

      assert Predicate.eval(
               expression("@.transformer.accessories[1] == 'Laser Blaster'"),
               transformer
             )

      refute Predicate.eval(
               expression("@.transformer.accessories[0] == 'Laser Blaster'"),
               transformer
             )
    end
  end

  test "eval/2 can evaluate current node expression" do
    assert Predicate.eval(expression("is_map(@)"), %{})
    refute Predicate.eval(expression("is_map(@)"), [])
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

  test "eval/2 when expression is a boolean literal" do
    assert Predicate.eval(expression("true"), %{})
    refute Predicate.eval(expression("false"), %{})
  end
end
