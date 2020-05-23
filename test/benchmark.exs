json =
  __DIR__
  |> Path.join("/fixtures/json_sample.json")
  |> Path.expand()
  |> File.read!()

Benchee.run(
  %{
    "Warpath.query/3" => fn {selector, document} -> Warpath.query(document, selector) end
  },
  inputs: %{
    "$..name" => {"$..name", json},
    "$..*" => {"$..*", json},
    "$.items[0]" => {"$.items[0]", json},
    "$.items[*].name" => {"$.items[*].name", json},
    "$.items[?(is_integer(@.integer) and @.integer > 5)]" =>
      {"$.items[?(is_integer(@.integer) and @.integer > 5)]", json},
    "$.items[0:]" => {"$.items[0:]", json}
  },
  memory_time: 2
)
