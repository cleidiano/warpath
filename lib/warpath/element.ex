defmodule Warpath.Element do
  @moduledoc false

  alias __MODULE__
  alias Warpath.Element.Path

  @type t :: %Element{value: any, path: Path.t()}

  defstruct value: nil, path: nil

  def new(value, path) when is_list(path) do
    %Element{value: value, path: path}
  end

  @spec path(t) :: Path.t()
  def path(%Element{path: path}), do: path

  @spec value(t) :: any()
  def value(%Element{value: value}), do: value

  @spec value_list?(t) :: boolean()
  def value_list?(%Element{value: value}), do: is_list(value)

  @spec value_map?(t) :: boolean()
  def value_map?(%Element{value: value}), do: is_map(value)
end
