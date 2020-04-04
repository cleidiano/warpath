defmodule Engine do
  alias Warpath.ExecutionEnv, as: Env
  alias Warpath.Expression
  alias Warpath.Element.Path

  def query(data, selector, opts \\ []) do
    acc = Element.new(data, [])

    query_result =
      selector
      |> compile()
      |> Enum.reduce(acc, &dispatch_reduce/2)
      |> collect(opts[:result_type] || :value)

    {:ok, query_result}
  end

  def query!(data, selector, opts \\ []) do
    {:ok, query_result} = query(data, selector, opts)
    query_result
  end

  defp compile(selector) do
    with {:ok, tokens} <- Expression.compile(selector),
         {:ok, operators} <- {:ok, Enum.map(tokens, &translate(&1))} do
      operators
    end
  end

  defp dispatch_reduce(%Env{operator: operator} = env, element),
    do: operator.evaluate(element, env)

  defp collect(elements, opt) when is_list(elements), do: Enum.map(elements, &collect(&1, opt))

  defp collect(%Element{value: member, path: path}, :value_path),
    do: {member, Path.bracketify(path)}

  defp collect(%Element{path: path}, :path), do: Path.bracketify(path)
  defp collect(%Element{value: member}, _), do: member

  defp translate({:root, _} = instr), do: Env.new(RootOperator, instr)
  defp translate({:dot, _} = instr), do: Env.new(IdentifierOperator, instr)
  defp translate({:wildcard, _} = instr), do: Env.new(WildcardOperator, instr)
  defp translate({:scan, _} = instr), do: Env.new(DescendantOperator, instr)
  defp translate({:array_indexes, _} = instr), do: Env.new(ArrayIndexOperator, instr)
  defp translate({:filter, _} = instr), do: Env.new(FilterOperator, instr)
  defp translate({:array_slice, _} = instr), do: Env.new(SliceOperator, instr)
end
