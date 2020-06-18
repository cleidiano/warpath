defmodule Warpath.Query.CurrentNodeOperator do
  @moduledoc false

  alias Warpath.Element
  alias Warpath.Execution.Env


  @type document :: any()

  @type instruction :: {:at, String.t()}

  @type env :: %Env{instruction: instruction}

  @type result :: Element.t()

  @spec evaluate(document, [], env) :: result()
  def evaluate(document, [], _env), do: Element.new(document, [])
end
