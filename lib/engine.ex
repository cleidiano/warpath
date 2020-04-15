defmodule Engine do
  alias Warpath.ExecutionEnv, as: Env
  alias Warpath.Expression
  alias Warpath.Element.Path

  def query(document, selector, opts \\ [])

  def query(document, selector, opts) when is_binary(document) do
    document
    |> Jason.decode!()
    |> query(selector, opts)
  end

  def query(data, selector, opts) do
    start = Element.new(data, [])

    query_result =
      selector
      |> compile()
      # |> IO.inspect(label: :execution_plan)
      |> Enum.reduce(start, fn item, acc ->
        # IO.inspect(item.operator)

        dispatch_reduce(item, acc)
        # |> IO.inspect(label: :output)
      end)
      |> collect(opts[:result_type] || :value)

    {:ok, query_result}
  end

  def query!(data, selector, opts \\ []) do
    {:ok, query_result} = query(data, selector, opts)
    query_result
  end

  def compile(selector) do
    with {:ok, tokens} <- Expression.compile(selector) do
      tokens
      |> Enum.reduce([], fn token, acc ->
        env = translate(token, List.first(acc))
        [env | acc]
      end)
      |> Enum.reverse()
    end
  end

  defp dispatch_reduce(%Env{operator: operator} = env, elements) when is_list(elements) do
    operator.evaluate(elements, [], env)
  end

  defp dispatch_reduce(%Env{operator: operator} = env, %Element{value: document, path: path}) do
    operator.evaluate(document, path, env)
    # |> IO.inspect(label: :dispatch)
  end

  defp collect(elements, opt) when is_list(elements), do: Enum.map(elements, &collect(&1, opt))

  defp collect(%Element{value: member, path: path}, :value_path),
    do: {member, Path.bracketify(path)}

  defp collect(%Element{path: path}, :path), do: Path.bracketify(path)
  defp collect(%Element{value: member}, _), do: member

  defp translate({:root, _} = instr, nil), do: Env.new(RootOperator, instr)
  defp translate({:dot, _} = instr, previous), do: Env.new(IdentifierOperator, instr, previous)
  defp translate({:wildcard, _} = instr, previous), do: Env.new(WildcardOperator, instr, previous)
  defp translate({:scan, _} = instr, previous), do: Env.new(DescendantOperator, instr, previous)

  defp translate({:array_indexes, _} = instr, previous),
    do: Env.new(ArrayIndexOperator, instr, previous)

  defp translate({:filter, instr}, previous), do: Env.new(FilterOperator, instr, previous)
  defp translate({:array_slice, _} = instr, previous), do: Env.new(SliceOperator, instr, previous)
  defp translate({:union, _} = instr, previous), do: Env.new(UnionOperator, instr, previous)
end
