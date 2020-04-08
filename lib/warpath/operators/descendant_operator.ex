alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.Path, as: ElementPath

defprotocol DescendantOperator do
  @fallback_to_any true

  @type document :: list() | map()
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document(), ElementPath.t(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defmodule DescendantUtils do
  alias Warpath.Element.PathMarker

  def evaluate(data, relative_path, %{instruction: {:scan, {:wildcard, _}}} = env) do
    members =
      {data, relative_path}
      |> PathMarker.stream()
      |> Enum.map(&Element.new/1)

    children =
      Enum.flat_map(members, fn %Element{value: value, path: path} ->
        DescendantOperator.evaluate(value, path, env)
      end)

    members ++ children
  end
end

defimpl DescendantOperator, for: [Map, List] do
  def evaluate(document, relative_path, env) do
    DescendantUtils.evaluate(document, relative_path, env)
  end
end

defimpl DescendantOperator, for: Any do
  def evaluate(_data, _relative_path, _), do: []
end
