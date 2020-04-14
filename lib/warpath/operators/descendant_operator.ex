alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.Path, as: ElementPath
alias DescendantUtils, as: Utils

defprotocol DescendantOperator do
  @fallback_to_any true

  @type document :: list() | map()
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document(), ElementPath.t(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
  def collect(document, relative_path, env)
end

defmodule DescendantUtils do
  alias Warpath.Element.PathMarker

  defguardp is_dictionary(enum) when is_list(enum) or is_map(enum)

  def property_scan(document, relative_path, %Env{instruction: instruction} = env) do
    {:scan, {:property, _} = token} = instruction
    extract_all(document, relative_path, env, &accept_key?(&1, token))
  end

  def wildcard_scan(document, relative_path, env) do
    extract_all(document, relative_path, env, fn _ -> true end)
  end

  def search_for_list(
        document,
        relative_path,
        %Env{instruction: {:scan, {_, [{:index_access, index}]}}} = env
      ) do
    extract_all(
      document,
      relative_path,
      env,
      &list_with_index?(&1, index),
      &DescendantOperator.collect/3
    )
  end

  def search_for_list(
        document,
        relative_path,
        %Env{instruction: {:scan, {:filter, _}}} = env
      ) do
    extract_all(
      document,
      relative_path,
      env,
      &list_with_index?(&1, 0),
      &DescendantOperator.collect/3
    )
  end

  defp extract_all(data, relative_path, env, acceptor, walker \\ &DescendantOperator.evaluate/3)
       when is_dictionary(data) do
    members =
      data
      |> Element.new(relative_path)
      |> PathMarker.stream()

    children =
      members
      |> Task.async_stream(fn %Element{value: value, path: path} -> walker.(value, path, env) end)
      |> Stream.flat_map(fn {:ok, enum} -> enum end)

    members
    |> Stream.concat(children)
    |> Enum.filter(acceptor)
  end

  defp list_with_index?(%Element{value: []}, _index), do: false

  defp list_with_index?(%Element{value: value}, index) when is_list(value) and index >= 0,
    do: length(value) > index

  defp list_with_index?(%Element{value: value}, index) when is_list(value) do
    count = length(value)
    computed_index = count + index
    computed_index >= 0 and computed_index <= count
  end

  defp list_with_index?(_d, _), do: false
  defp accept_key?(%Element{value: _, path: path}, token_key), do: match?([^token_key | _], path)
  defp accept_key?(_, _), do: false
end

defimpl DescendantOperator, for: [Map, List] do
  def evaluate(document, relative_path, %Env{instruction: {:scan, {:property, _}}} = env) do
    Utils.property_scan(document, relative_path, env)
  end

  def evaluate(document, relative_path, %Env{instruction: {:scan, {:wildcard, _}}} = env) do
    Utils.wildcard_scan(document, relative_path, env)
  end

  def evaluate(
        document,
        relative_path,
        %Env{instruction: {:scan, {:filter, filter}}} = env
      ) do
    filter_env = Env.new(FilterOperator, filter)

    document
    |> find_all_list(relative_path, env)
    |> Enum.flat_map(fn %Element{value: value, path: path} ->
      FilterOperator.evaluate(value, path, filter_env)
    end)
  end

  def evaluate(document, path, %Env{instruction: {:scan, {:array_indexes, _} = indexes}} = env) do
    # Entry point called only once

    indexes_env = Env.new(ArrayIndexOperator, indexes)

    document
    |> find_all_list(path, env)
    |> Enum.map(fn %Element{value: list, path: list_path} ->
      ArrayIndexOperator.evaluate(list, list_path, indexes_env)
    end)
  end

  def collect(document, relative_path, env) do
    Utils.search_for_list(document, relative_path, env)
  end

  defp find_all_list(document, relative_path, env) do
    document =
      if is_list(document) do
        # Self include list by wrap it
        [document]
      else
        document
      end

    Utils.search_for_list(document, relative_path, env)
  end
end

defimpl DescendantOperator, for: Any do
  def evaluate(_data, _relative_path, _), do: []
  def collect(_data, _relative_path, _), do: []
end
