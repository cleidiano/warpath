defprotocol RootOperator do
  @fallback_to_any true
  def evaluate(data, path, env)
end

defimpl RootOperator, for: Any  do

  def evaluate(data, path, _env), do: Element.new(data, [{:root, "$"} | path])
end
