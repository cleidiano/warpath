use Mix.Config

config :stream_data,
  max_runs:
    if(System.get_env("CI"),
      do: IO.inspect(200, label: "CI enabled max_runs:", syntax_colors: [number: :yellow]),
      else: 10
    )
