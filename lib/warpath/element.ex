defmodule Element do
  alias Warpath.Element.Path

  @type t :: %Element{value: any, path: Path.t()}

  defstruct value: nil, path: nil

  def new(value, path) when is_list(path) do
    %Element{value: value, path: path}
  end

  def value_list?(%Element{value: value}), do: is_list(value)
  def value_map?(%Element{value: value}), do: is_map(value)
end
