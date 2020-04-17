"#{__DIR__}/fixtures/*.exs"
|> Path.wildcard()
|> Enum.each(fn path -> Code.require_file(path) end)

ExUnit.start(exclude: [:skip])
