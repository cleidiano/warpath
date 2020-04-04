defmodule Element do
  @type t :: %Element{value: any, path: list()}

  defstruct value: nil, path: nil

  def new(value, path) when is_list(path) do
    %Element{value: value, path: path}
  end

  def new({value, path}), do: new(value, path)
end
