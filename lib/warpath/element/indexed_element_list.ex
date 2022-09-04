defmodule Warpath.Element.IndexedElementList do
  defstruct indexed_elements: []

  def new([]), do: %__MODULE__{}

  def new([{_, index} | _] = indexed_elements) when is_integer(index) do
      %__MODULE__{indexed_elements: indexed_elements}
  end
end
