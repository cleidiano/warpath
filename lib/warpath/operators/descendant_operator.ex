defprotocol DescendantOperator do
  @fallback_to_any true
  def evaluate(data, relative_path, env)
  def evaluate(element, env)
end

defmodule DescendantUtils do
  alias Warpath.Element.PathMarker

  def evaluate(data, relative_path, %{instruction: {:scan, {:wildcard, _}}} = env) do
    members =
      {data, relative_path}
      |> PathMarker.stream()
      |> Enum.map(&Element.new/1)

    children = Enum.flat_map(members, fn element -> DescendantOperator.evaluate(element, env) end)
    members ++ children
  end
end

defimpl DescendantOperator, for: [Map, Element, List] do
  def evaluate(document, relative_path, env) do
    DescendantUtils.evaluate(document, relative_path, env)
  end

  def evaluate(%Element{value: value, path: path}, env) do
    DescendantOperator.evaluate(value, path, env)
  end
end

defimpl DescendantOperator, for: Any do
  def evaluate(_data, _relative_path, _), do: []
  def evaluate(_, _), do: []
end
