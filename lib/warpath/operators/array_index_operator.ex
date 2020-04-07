alias Warpath.ExecutionEnv, as: Env
alias Warpath.Element.Path, as: ElementPath

defprotocol ArrayIndexOperator do
  @type relative_path :: ElementPath.t()
  @type element :: %Element{value: list(), path: relative_path()}
  @type result :: Element.t() | [Element.t()]
  @type instruction :: {:array_indexes, list({:index, integer()})}
  @type env :: %Env{instruction: instruction()}

  @spec evaluate(list, relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)

  @spec evaluate(element(), Env.t()) :: result()
  def evaluate(element, env)
end

defimpl ArrayIndexOperator, for: List do
  def evaluate(_document, _relative_path, %Env{instruction: _instruction}) do
    []
  end

  def evaluate(%Element{value: document, path: relative_path}, env) do
    evaluate(document, relative_path, env)
  end
end
