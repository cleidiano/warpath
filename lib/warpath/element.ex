defmodule Element do
  @type t :: %Element{value: any, path: list()}

  defstruct value: nil, path: nil

  def new(value, path) when is_list(path) do
    %Element{value: value, path: path}
  end

  def new({value, path}), do: new(value, path)

  def value_list?(%Element{value: value}), do: is_list(value)
  def value_map?(%Element{value: value}), do: is_map(value)
end
