defmodule Warpath.ExecutionEnv do
  @type t :: %__MODULE__{instruction: any()}

  defstruct operator: nil, instruction: nil, previous_operator: nil

  def new(operator, instr, previous_operator \\ nil) do
    %__MODULE__{
      operator: operator,
      instruction: instr,
      previous_operator: previous_operator
    }
  end
end
