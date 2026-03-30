import Config

config :credo,
  checks: %{
    disabled: [
      # requires Elixir < 1.8.0
      {Credo.Check.Refactor.MapInto, []},
      # requires Elixir < 1.7.0
      {Credo.Check.Warning.LazyLogging, []}
    ]
  }

config :stream_data,
  max_runs:
    if(System.get_env("CI"),
      do: IO.inspect(100, label: "CI enabled max_runs:", syntax_colors: [number: :yellow]),
      else: 10
    )
