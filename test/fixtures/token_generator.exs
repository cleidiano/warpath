defmodule TokenGenerator do
  def root(line \\ 1) do
    {:root, line, "$"}
  end

  def token_of(token, line \\ 1) do
    {String.to_atom(token), line, token}
  end

  def token_value(token, value, line \\ 1) do
    {String.to_atom(token), line, value}
  end

  def array_indexes(start, limit) do
    indexes =
      start..limit
      |> Enum.reduce([], fn int, acc ->
        new_acc = [token_value("int", int) | acc]
        [token_of(",") | new_acc]
      end)
      |> Enum.reverse()
      |> List.delete_at(-1)

    open_paren = token_of("[")
    close_paren = token_of("]")

    [open_paren | indexes] ++ [close_paren]
  end
end
