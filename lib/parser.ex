defmodule Warpath.Parser do
  @moduledoc false
  def parser(tokens) when is_list(tokens) do
    :parser.parse(tokens)
  end

  def parse(tokens) when is_list(tokens), do: :parser.parse(tokens)

  def parse!(tokens) when is_list(tokens) do
    {:ok, expression} = :parser.parse(tokens)
    expression
  end
end
