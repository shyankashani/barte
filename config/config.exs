# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :barte,
  ecto_repos: [Barte.Repo]

# Configures the endpoint
config :barte, BarteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "FBWW6VjrVSeiS1i8cJG6aNtm5sPOdCwdq1LHfI7Hk2/A6ND43Jixcg80Xan7WoWG",
  render_errors: [view: BarteWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Barte.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "MsNz6CbN"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
