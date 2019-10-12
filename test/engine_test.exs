defmodule EngineTest do
  use ExUnit.Case, async: true
  alias Warpath.Engine

  setup do
    tour = %{
      "persons" => [
        %{"name" => "João", "surname" => "Bahia", "age" => 18},
        %{"name" => "Pedro", "surname" => "Brasil", "age" => 22}
      ],
      "city" => "Iraquara"
    }

    [data: tour]
  end

  describe "query/3 return value on" do
    test "evaluate root expression", context do
      assert Engine.query(context[:data], tokens("$")) == context[:data]
    end

    test "evaluate property expression ", context do
      assert Engine.query(context[:data], tokens("$.city")) == "Iraquara"
    end

    test "evaluate array index expression ", context do
      joao = context[:data]["persons"] |> List.first()

      assert Engine.query(context[:data], tokens("$.persons[0]")) == joao
    end

    test "evaluate wildcard array expression", context do
      expected = context[:data]["persons"]
      assert Engine.query(context[:data], tokens("$.persons[*]")) == expected
    end

    test "evaluate wildcard array expression with property after it", context do
      assert Engine.query(context[:data], tokens("$.persons[*].name")) == ["João", "Pedro"]
    end

    test "evaluate filter expression for relation >", context do
      pedro = context[:data]["persons"] |> List.last()
      assert Engine.query(context[:data], tokens("$.persons[?(@.age > 18)]")) == [pedro]
    end

    test "evaluate filter expression for relation <", context do
      joao = context[:data]["persons"] |> List.first()
      assert Engine.query(context[:data], tokens("$.persons[?(@.age < 22)]")) == [joao]
    end

    test "evaluate filter expression for relation ==", context do
      joao = context[:data]["persons"] |> List.first()
      assert Engine.query(context[:data], tokens("$.persons[?(@.age == 18)]")) == [joao]
    end
  end

  describe "query/3 return error when" do
    test "trying to traverse a list using dot notation", context do
      {:error, %{message: message}} = Engine.query(context[:data], tokens("$.persons.name"))
      assert message =~ "You are trying to traverse a list using dot notation"
    end
  end

  defp tokens(expression) do
    expression
    |> Warpath.Tokenizer.tokenize!()
    |> Warpath.Parser.parse()
    |> case do
      {:ok, tokens} -> tokens
      error -> raise RuntimeError, "#{inspect(error)}"
    end
  end
end
