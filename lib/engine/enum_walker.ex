defmodule Warpath.Engine.EnumWalker do
  @moduledoc false

  import Warpath.Engine.Trace

  require Logger

  def recursive_descent({_, _} = term), do: elements(term)

  defp elements({terms, _} = item) when is_map(terms) do
    values = stream(item)

    values
    |> Enum.reduce(Enum.reverse(values), &traverse/2)
    |> Enum.reverse()
  end

  defp elements({terms, _} = item) when is_list(terms) do
    values = stream(item)

    values
    |> Enum.reduce(Enum.reverse(values), &traverse/2)
    |> Enum.reverse()
  end

  defp elements({_, _} = term), do: term

  defguard is_container(term) when is_list(term) or is_map(term)

  defp traverse({terms, _} = pair, acc) when is_container(terms) do
    pair
    |> elements()
    |> Enum.reduce(acc, fn term, new_acc -> [term | new_acc] end)
  end

  defp traverse({_term, _trace}, acc), do: acc

  @type path :: Warpath.Engine.ItemPath.t()
  @type item :: {any, [path]}
  @type acc :: Enum.t()
  @type reducer :: (item, acc -> {:skip, acc} | {:walk, acc} | {:halt, acc})

  @spec reduce_while([item], acc, reducer) :: acc | {:error, any}
  def reduce_while(enumerable, acc, fun) when is_list(enumerable) do
    enumerable |> Enum.reduce(acc, &handle_accumulation(&1, &2, fun))
  end

  @spec reduce_while({map, [path]}, acc, reducer) :: acc | {:error, any}
  def reduce_while({data, _} = term, acc, fun) when is_map(data) do
    try do
      traverse(term, fun, acc)
    rescue
      e in ArgumentError ->
        Logger.error(e.message)
        {:error, e}
    catch
      value -> value
    end
  end

  defp traverse({data, _trace} = term, fun, accumulator) when is_container(data) do
    term
    |> stream()
    |> Enum.reduce(accumulator, &handle_accumulation(&1, &2, fun))
  end

  defp traverse(_term, _fun, accumulator), do: accumulator

  defp handle_accumulation(item, acc, fun) do
    item
    |> fun.(acc)
    |> case do
      {:skip, fun_acc} ->
        fun_acc

      {:walk, fun_acc} ->
        traverse(item, fun, fun_acc)

      {:halt, acc} ->
        throw(acc)

      fun_return ->
        raise ArgumentError,
              "Invalid return type got #{inspect(fun_return)}, allowed return types are " <>
                "{:skip, acc}, {:walk, acc} or {:halt, acc}"
    end
  end
end
