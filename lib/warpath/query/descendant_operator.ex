alias Warpath.Element
alias Warpath.Execution.Env
alias Warpath.Query.ArrayIndexOperator
alias Warpath.Query.DescendantOperator
alias Warpath.Query.FilterOperator

defprotocol DescendantOperator do
  @fallback_to_any true

  @type document :: list() | map()
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document(), Element.Path.t(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl DescendantOperator, for: [Map, List] do
  alias Warpath.Element.PathMarker

  def evaluate(
        document,
        relative_path,
        %Env{
          instruction: {:scan, {:array_indexes, [{:index_access, index}]}},
          metadata: %{descendant_started: true}
        } = env
      ) do
    collect_by(
      document,
      relative_path,
      env,
      _acceptor = &list_with_index?(&1, index)
    )
  end

  def evaluate(document, path, %Env{instruction: {:scan, {:array_indexes, _}}} = env) do
    with {:scan, {:array_indexes, [index_access: index]} = index_expr} <- Env.instruction(env),
         indexes_env <- Env.new(index_expr),
         metadata <- %{descendant_started: true},
         env_started <- %{env | metadata: metadata},
         doc <- wrap_if_needed(document) do
      doc
      |> collect_by(path, env_started, _acceptor = &list_with_index?(&1, index))
      |> Enum.map(fn %Element{value: list, path: list_path} ->
        ArrayIndexOperator.evaluate(list, list_path, indexes_env)
      end)
    end
  end

  def evaluate(
        document,
        relative_path,
        %Env{instruction: {:scan, {:property, _} = token}} = env
      ) do
    collect_by(document, relative_path, env, _acceptor = &accept_key?(&1, token))
  end

  def evaluate(document, relative_path, %Env{instruction: {:scan, {:wildcard, _}}} = env) do
    collect_by(document, relative_path, env, _acceptor = fn _ -> true end)
  end

  def evaluate(document, relative_path, %Env{instruction: {:scan, {:filter, _} = filter}} = env) do
    # filter_scan(document, relative_path, env)

    filter_env = Env.new(filter)

    collect_by(
      document,
      relative_path,
      env,
      _acceptor = fn %Element{value: value, path: path} ->
        # List will be traversed by descedant algorithm
        not is_list(value) and FilterOperator.evaluate(value, path, filter_env) != []
      end
    )
  end

  defp wrap_if_needed(document) when is_list(document), do: [document]
  defp wrap_if_needed(document), do: document

  def collect_by(data, relative_path, env, acceptor, walker \\ &DescendantOperator.evaluate/3)
      when is_list(data) or is_map(data) do
    members =
      data
      |> Element.new(relative_path)
      |> PathMarker.stream()

    children =
      members
      |> Task.async_stream(fn %Element{value: value, path: path} ->
        walker.(value, path, env)
      end)
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

  defp list_with_index?(_, _), do: false

  # Property search
  defp accept_key?(%Element{value: _, path: path}, token_key), do: match?([^token_key | _], path)
  defp accept_key?(_, _), do: false
end

defimpl DescendantOperator, for: Any do
  def evaluate(_data, _relative_path, _), do: []
end
