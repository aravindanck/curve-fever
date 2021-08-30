# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :curve_fever, CurveFeverWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "eIWLhp0NYEbxw4pkAUQcNjgR+9H9aolIfw2c7VUF/Fz+aKfavo7IfJoEt0i6Gajz",
  render_errors: [view: CurveFeverWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: CurveFever.PubSub,
  live_view: [signing_salt: "I69gtL59"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
