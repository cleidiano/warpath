alias Warpath.Element
alias Warpath.Execution.Env
alias Warpath.Expression
alias Warpath.Query.WildcardOperator

defprotocol WildcardOperator do
  @moduledoc false

  @fallback_to_any true

  @type document :: map() | list()

  @type relative_path :: [] | Element.Path.t()

  @type instruction :: Expression.wildcard()

  @type env :: %Env{instruction: instruction}

  @type result :: [Element.t()]

  @spec evaluate(document(), relative_path, env) :: [Element.t()]
  def evaluate(document, relative_path, env)
end

defimpl WildcardOperator, for: Map do
  def evaluate(document, relative_path, _env) do
    Element.elementify(document, relative_path)
  end
end

defimpl WildcardOperator, for: List do
  def evaluate([%Element{} | _] = elements, [], env) do
    Enum.flat_map(elements, fn %Element{value: value, path: path} ->
      WildcardOperator.evaluate(value, path, env)
    end)
  end

  def evaluate(itens, relative_path, _env) do
    Element.elementify(itens, relative_path)
  end
end

defimpl WildcardOperator, for: Any do
  def evaluate(_element, _path, _), do: []
end
