alias Warpath.ExecutionEnv, as: Env

defprotocol FilterOperator do
  @fallback_to_any true

  @type document :: map() | list()
  @type relative_path :: Warpath.Element.Path.t()
  @type result :: Element.t() | [Element.t()]

  @spec evaluate(document, relative_path(), Env.t()) :: result()
  def evaluate(document, relative_path, env)
end

defimpl FilterOperator, for: [Map, List] do
  alias Warpath.Filter

  def evaluate(document, relative_path, %Env{instruction: filter_exp}) do
    #TODO Handle this it's return legacy type
    Filter.filter({document, relative_path}, filter_exp)
  end
end

defimpl FilterOperator, for: Any do
  def evaluate(_, _, _), do: []
end
