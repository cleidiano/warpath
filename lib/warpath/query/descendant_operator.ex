alias Warpath.Element
alias Warpath.Expression
alias Warpath.Execution.Env
alias Warpath.Filter
alias Warpath.Query.IndexOperator
alias Warpath.Query.DescendantOperator

defprotocol DescendantOperator do
  @moduledoc false

  @fallback_to_any true

  @type document :: list() | map()

  @type relative_path :: Element.Path.acc()

  @type instruction :: Expression.scan()

  @type env :: %Env{instruction: instruction()}

  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document(), relative_path(), env) :: result()
  def evaluate(document, relative_path, env)
end

defimpl DescendantOperator, for: [Map, List] do
  def evaluate(
        document,
        relative_path,
        %Env{
          instruction: {:scan, {:indexes, indexes}},
          metadata: %{descendant_started: true}
        } = env
      ) do
    collect_by(document, relative_path, env, _acceptor = &at_least_one?(&1, indexes))
  end

  def evaluate(
        document,
        path,
        %Env{instruction: {:scan, {:indexes, indexes} = index_expr}} = env
      ) do
    indexes_env = Env.new(index_expr)
    env_started = %{env | metadata: Map.put(env.metadata, :descendant_started, true)}

    document
    |> wrap_if_needed()
    |> collect_by(path, env_started, _acceptor = &at_least_one?(&1, indexes))
    |> Enum.flat_map(fn %Element{value: list, path: list_path} ->
      case IndexOperator.evaluate(list, list_path, indexes_env) do
        %Element{} = element -> [element]
        result -> result
      end
    end)
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

  def evaluate(document, relative_path, %Env{instruction: {:scan, {:filter, filter}}} = env) do
    collect_by(
      document,
      relative_path,
      env,
      _acceptor = &Filter.Predicate.eval(filter, Element.value(&1))
    )
  end

  defp collect_by(data, relative_path, env, acceptor)
       when is_list(data) or is_map(data) do
    members = Element.elementify(data, relative_path)

    children =
      Enum.flat_map(
        members,
        fn %Element{value: value, path: path} ->
          DescendantOperator.evaluate(value, path, env)
        end
      )

    members
    |> Enum.concat(children)
    |> Enum.filter(acceptor)
  end

  # Index search
  defp wrap_if_needed(document) when is_list(document), do: [document]
  defp wrap_if_needed(document), do: document

  defp at_least_one?(%Element{value: []}, _indexes), do: false
  defp at_least_one?(%Element{value: value}, _indexes) when not is_list(value), do: false

  defp at_least_one?(%Element{value: list}, indexes) do
    count = length(list)
    Enum.any?(indexes, &in_bound?(&1, count))
  end

  defp in_bound?({:index_access, index}, list_length) when index >= 0, do: list_length > index
  defp in_bound?({:index_access, index}, list_length), do: list_length + index >= 0

  # Property search
  defp accept_key?(%Element{value: _, path: path}, token_key), do: match?([^token_key | _], path)
  defp accept_key?(_, _), do: false
end

defimpl DescendantOperator, for: Any do
  def evaluate(_data, _relative_path, _), do: []
end
