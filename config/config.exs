import Config

# Configures the endpoint
config :curve_fever, CurveFeverWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "eIWLhp0NYEbxw4pkAUQcNjgR+9H9aolIfw2c7VUF/Fz+aKfavo7IfJoEt0i6Gajz",
  render_errors: [view: CurveFeverWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: CurveFever.PubSub,
  live_view: [signing_salt: "I69gtL59"]

config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
