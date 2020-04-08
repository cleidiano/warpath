alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.Path, as: ElementPath

defprotocol ArrayIndexOperator do
  @type document  :: list()

  @type relative_path :: ElementPath.t()

  @type result :: Element.t() | [Element.t()]

  @type instruction :: {:array_indexes, list({:index, integer()})}

  @type env :: %Env{instruction: instruction()}

  @spec evaluate(document(), relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)

end

defimpl ArrayIndexOperator, for: List do
  def evaluate(_document, _relative_path, %Env{instruction: _instruction}) do
    raise "TODO"
  end
end
