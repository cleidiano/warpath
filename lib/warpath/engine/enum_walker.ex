defmodule Warpath.Engine.EnumWalker do
  @moduledoc false

  alias Warpath.Element.Path
  alias Warpath.Element.PathMarker
  alias Warpath.Engine.EnumRecursiveDescent

  @type member :: any
  @type element :: {member, Path.t()}
  @type acc :: Enumerable.t()
  @type walk_reducer :: (element, acc -> {:skip, acc} | {:walk, acc} | {:halt, acc})
  @type path_fun :: (acc, Path.token() -> acc)
  @type t :: element | [element, ...]

  defguardp is_container(container)
            when is_list(container) or is_map(container)

  @spec recursive_descent(element, path_fun) :: element | [element, ...]
  defdelegate recursive_descent(term, path_fun \\ &Path.accumulate/2), to: EnumRecursiveDescent

  @spec reduce_while(t, acc, walk_reducer, path_fun) :: acc | {:error, any}
  def reduce_while(element, acc, walk_reducer, path_fun \\ &Path.accumulate/2)

  def reduce_while(elements, acc, walk_reducer, path_fun) when is_list(elements) do
    fun = fn ->
      Enum.reduce(elements, acc, &handle_accumulation(&1, &2, walk_reducer, path_fun))
    end

    capture_throw(fun)
  end

  def reduce_while({member, _} = element, acc, walk_reducer, path_fun)
      when is_container(member) do
    capture_throw(fn -> traverse(element, acc, walk_reducer, path_fun) end)
  end

  defp capture_throw(fun) when is_function(fun, 0) do
    fun.()
  rescue
    e in ArgumentError -> {:error, e}
  catch
    value -> value
  end

  defp traverse({member, _path} = element, accumulator, walk_reducer, path_fun)
       when is_container(member) do
    element
    |> PathMarker.stream(path_fun)
    |> Enum.reduce(accumulator, &handle_accumulation(&1, &2, walk_reducer, path_fun))
  end

  defp traverse(_element, accumulator, _fun, _), do: accumulator

  defp handle_accumulation(element, acc, walk_reducer, path_fun) do
    element
    |> walk_reducer.(acc)
    |> case do
      {:skip, new_acc} ->
        new_acc

      {:walk, new_acc} ->
        traverse(element, new_acc, walk_reducer, path_fun)

      {:halt, acc} ->
        throw(acc)

      fun_return ->
        raise ArgumentError,
              "Invalid return type got #{inspect(fun_return)}, allowed return types are " <>
                "{:skip, acc}, {:walk, acc} or {:halt, acc}"
    end
  end
end

defmodule Warpath.Engine.EnumRecursiveDescent do
  @moduledoc false

  alias Warpath.Element.Path
  alias Warpath.Element.PathMarker

  @type member :: any
  @type element :: {member, Path.t()}
  @type acc :: Enumerable.t()
  @type path_fun :: (acc, Path.token() -> acc)

  defguard is_container(container) when is_list(container) or is_map(container)

  @spec recursive_descent(element, path_fun) :: element | [element, ...]
  def recursive_descent({_, _} = element, path_fun) do
    get_members(element, path_fun)
  end

  def recursive_descent(elements, path_fun) when is_list(elements) do
    Enum.flat_map(elements, &recursive_descent(&1, path_fun))
  end

  defp get_members(term, path_fun)

  defp get_members({member, _} = element, path_fun) when is_container(member) do
    members = PathMarker.stream(element, path_fun)

    members
    |> Enum.reduce(Enum.reverse(members), &traverse(&1, &2, path_fun))
    |> Enum.reverse()
  end

  defp get_members({_, _} = element, _), do: element

  defp traverse({member, _} = element, acc, path_fun) when is_container(member) do
    element
    |> get_members(path_fun)
    |> Enum.reduce(acc, fn term, new_acc -> [term | new_acc] end)
  end

  defp traverse({_member, _path}, acc, _path_fun), do: acc
end
