defprotocol SliceOperator do
  def evaluate(document, relative_path, env)
  def evaluate(element, env)
end

defimpl SliceOperator, for: Any  do
  def evaluate(_document, _relative_path, _env), do: []
  def evaluate(_element, _env), do: []
end

