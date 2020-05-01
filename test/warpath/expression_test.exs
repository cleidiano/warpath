defmodule Warpath.ExpressionTest do
  use ExUnit.Case, async: true

  alias Warpath.Expression
  alias Warpath.ExpressionError

  describe "expression" do
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
end
