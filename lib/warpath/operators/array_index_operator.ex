defprotocol ArrayIndexOperator do
  def evaluate(document, relative_path, env)
  def evaluate(element, env)
end

defimpl ArrayIndexOperator, for: List do
  alias Warpath.ExecutionEnv, as: Env

  def evaluate(document, relative_path, %Env{instruction: instruction}) do
    []
  end


  def evaluate(%Element{value: document, path: relative_path}, env) do
    evaluate(document, relative_path, env)
  end
end
