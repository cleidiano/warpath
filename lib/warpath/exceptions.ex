defmodule Warpath.ExpressionError do
  defexception [:message]

  @type t :: %__MODULE__{}
end
