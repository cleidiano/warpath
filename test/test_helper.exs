Path.wildcard("#{__DIR__}/fixtures/*.exs")
|> Enum.each(fn path -> Code.require_file(path) end)

ExUnit.start()
