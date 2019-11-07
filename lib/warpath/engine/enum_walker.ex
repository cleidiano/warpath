defmodule Warpath.Engine.EnumWalker do
  @moduledoc false
  import Warpath.Engine.Trace

  defdelegate recursive_descent(term, trace_fun \\ &append/2), to: RecursiveDescentImpl

  defdelegate reduce_while(term, acc, reducer, trace_fun \\ &append/2), to: Reducer
end

defmodule RecursiveDescentImpl do
  @moduledoc false

  alias Warpath.Engine.{Trace, ItemPath}

  @type item :: {any, ItemPath.t()}
  @type acc :: Enum.t()
  @type trace_fun :: (acc, ItemPath.token() -> acc)

  @spec recursive_descent(item, trace_fun) :: [item] | item
  def recursive_descent({_, _} = term, trace_fun) when is_function(trace_fun, 2) do
    elements(term, trace_fun)
  end

  defp elements(term, trace_fun)

  defp elements({terms, _} = item, trace_fun) when is_map(terms) do
    values = Trace.stream(item, trace_fun)

    values
    |> Enum.reduce(Enum.reverse(values), fn item, acc -> traverse(item, acc, trace_fun) end)
    |> Enum.reverse()
  end

  defp elements({terms, _} = item, trace_fun) when is_list(terms) do
    values = Trace.stream(item, trace_fun)

    values
    |> Enum.reduce(Enum.reverse(values), fn item, acc -> traverse(item, acc, trace_fun) end)
    |> Enum.reverse()
  end

  defp elements({_, _} = term, _), do: term

  defp traverse({terms, _} = pair, acc, trace_fun)
       when is_map(terms)
       when is_list(terms) do
    pair
    |> elements(trace_fun)
    |> Enum.reduce(acc, fn term, new_acc -> [term | new_acc] end)
  end

  defp traverse({_term, _trace}, acc, _), do: acc
end

defmodule Reducer do
  @moduledoc false

  require Logger

  alias Warpath.Engine.Trace
  alias Warpath.Engine.ItemPath

  @type item :: {any, ItemPath.t()}
  @type acc :: Enumerable.t
  @type reducer :: (item, acc -> {:skip, acc} | {:walk, acc} | {:halt, acc})
  @type trace_fun :: (acc, ItemPath.token() -> acc)
  @type t :: item | [item, ...]

  @spec reduce_while(t, acc, reducer, trace_fun) :: acc | {:error, any}
  def reduce_while(term, acc, reducer, trace_fun)

  def reduce_while(enumerable, acc, fun, trace_fun)
      when is_function(trace_fun, 2) and is_list(enumerable) do
    enumerable
    |> Enum.reduce(acc, &handle_accumulation(&1, &2, fun, trace_fun))
  end

  def reduce_while({data, _} = term, acc, reducer, trace_fun)
      when is_function(trace_fun, 2) and is_map(data) do
    try do
      traverse(term, reducer, acc, trace_fun)
    rescue
      e in ArgumentError ->
        Logger.error(e.message)
        {:error, e}
    catch
      value -> value
    end
  end

  defp traverse({data, _trace} = term, fun, accumulator, trace_fun)
       when is_map(data)
       when is_list(data) do
    term
    |> Trace.stream(trace_fun)
    |> Enum.reduce(accumulator, &handle_accumulation(&1, &2, fun, trace_fun))
  end

  defp traverse(_term, _fun, accumulator, _), do: accumulator

  defp handle_accumulation(item, acc, fun, trace_fun) do
    item
    |> fun.(acc)
    |> case do
      {:skip, fun_acc} ->
        fun_acc

      {:walk, fun_acc} ->
        traverse(item, fun, fun_acc, trace_fun)

      {:halt, acc} ->
        throw(acc)

      fun_return ->
        raise ArgumentError,
              "Invalid return type got #{inspect(fun_return)}, allowed return types are " <>
                "{:skip, acc}, {:walk, acc} or {:halt, acc}"
    end
  end
end
