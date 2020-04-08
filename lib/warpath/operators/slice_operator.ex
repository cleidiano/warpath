defprotocol SliceOperator do
  @type relative_path :: Warpath.Element.Path.t()
  @type result :: [Element.t()]

  @spec evaluate(list(), relative_path(), Env.t()) :: [Element.t()]
  def evaluate(list, relative_path, env)
end

defimpl SliceOperator, for: Any do
  def evaluate(_list, _relative_path, _env), do: []
end
