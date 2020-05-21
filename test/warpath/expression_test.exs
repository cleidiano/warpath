defmodule Warpath.ExpressionTest do
  use ExUnit.Case, async: true

  import Warpath.Expression

  alias Warpath.Expression
  alias Warpath.ExpressionError

  doctest Expression

  describe "compile/1" do
    test "when tokenizer fail" do
      error = %ExpressionError{message: ~S(Invalid syntax on line 1, {:illegal, '"'})}
      assert {:error, error} == Expression.compile(~S("))
    end

    test "when parser fail" do
      error = %ExpressionError{
        message: ~S(Parser error: Invalid token on line 1, syntax error before: <<"name">>)
      }

      assert {:error, error} == Expression.compile(~S($.'name'))
    end

    test "compile successful" do
      assert {:ok, _} = Expression.compile("$.valid")
    end
  end

  describe "sigil_q/2" do
    test "rise when compilation fail" do
      assert_raise ExpressionError, fn ->
        defmodule InvalidExpression do
          @path ~q"["
        end
      end
    end

    test "compile successful" do
      assert %Expression{tokens: [{:root, "$"}, {:dot, {:property, "name"}}]} = ~q"$.name"
    end
  end
end
