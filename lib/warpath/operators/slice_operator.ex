defprotocol SliceOperator do
  @type element :: %Element{value: list(), path: relative_path()}
  @type relative_path :: Warpath.Element.Path.t()
  @type result :: [Element.t()]

  @spec evaluate(list(), relative_path(), Env.t()) :: [Element.t()]
  def evaluate(list, relative_path, env)

  @spec evaluate(element(), Env.t()) :: [Element.t()]
  def evaluate(element, env)
end

defimpl SliceOperator, for: Any do
  def evaluate(_list, _relative_path, _env), do: []
  def evaluate(_element, _env), do: []
end
