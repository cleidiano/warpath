defmodule Warpath.ExecutionEnv do
  @type t :: %__MODULE__{instruction: any()}

  defstruct operator: nil, instruction: nil

  def new(operator, instr) do
    %__MODULE__{operator: operator, instruction: instr}
  end
end
