defmodule Warpath.Engine.Scanner do
  @moduledoc false

  alias Warpath.Element.Path
  alias Warpath.Engine.EnumWalker

  def scan(element, criteria, path_fun \\ &Path.accumulate/2)

  def scan(element, {:property, _} = criteria, path_fun) when is_function(path_fun, 2) do
    walk_reducer = fn {_, path} = element, acc ->
      case path do
        [^criteria | _] ->
          {:walk, [element | acc]}

        _ ->
          {:walk, acc}
      end
    end

    element
    |> EnumWalker.reduce_while(_acc = [], walk_reducer)
    |> Enum.reverse()
  end

  def scan(element, {:wildcard, :*}, path_fun) when is_function(path_fun, 2) do
    EnumWalker.recursive_descent(element, path_fun)
  end
end
