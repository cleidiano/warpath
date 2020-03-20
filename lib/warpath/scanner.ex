defmodule Warpath.Scanner do
  @moduledoc false

  alias Warpath.Element.Path
  alias Warpath.EnumWalker

  def scan(element, criteria, tracker \\ &Path.accumulate/2) when is_function(tracker, 2) do
    do_scan(element, criteria, tracker)
  end

  defp do_scan(element, {:property, _} = criteria, _tracker) do
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

  defp do_scan(element, {:wildcard, :*}, tracker) do
    EnumWalker.recursive_descent(element, tracker)
  end
end
