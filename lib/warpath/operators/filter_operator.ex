defprotocol FilterOperator do
  @fallback_to_any true
  def evaluate(document, relative_path, env)
  def evaluate(element, env)
end

defimpl FilterOperator, for: [Map, List] do
  alias Warpath.Filter
  alias Warpath.ExecutionEnv, as: Env

  def evaluate(document, relative_path, %Env{instruction: filter_exp}) do
    Filter.filter({document, relative_path}, filter_exp)
  end

  def evaluate(%Element{value: document, path: relative_path}, env) do
    evaluate(document, relative_path, env)
  end
end

defimpl FilterOperator, for: Any do
  def evaluate(_, _, _), do: []
  def evaluate(_, _), do: []
end
