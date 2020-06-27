defmodule Warpath.ExpressionError do
  defexception [:message]

  @type t :: %__MODULE__{}
end

defmodule Warpath.JsonDecodeError do
  defexception [:position, :data]

  @type t :: %__MODULE__{position: integer, data: String.t()}

  @spec from(Jason.DecodeError.t()) :: Warpath.JsonDecodeError.t()
  def from(%Jason.DecodeError{data: data, position: position}) do
    %Warpath.JsonDecodeError{data: data, position: position}
  end

  @impl true
  defdelegate message(exp), to: Jason.DecodeError
end
