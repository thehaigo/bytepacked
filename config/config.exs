# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :bytepacked,
  ecto_repos: [Bytepacked.Repo]

# Configures the endpoint
config :bytepacked, BytepackedWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "lUjrBmviCcxANHj/2cSq82xHdx+YdzverdEBB+uvWxufXTiIS5sYaHAmVa2gxjIS",
  render_errors: [view: BytepackedWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Bytepacked.PubSub,
  live_view: [signing_salt: "7mb7poeP"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
