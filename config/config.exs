# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :fiapx, Fiapx.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  ecto_repos: [Fiapx.Repo],
  grafana: [
    host: "http://grafana:3000",
    username: "admin",
    password: "admin",
    upload_dashboards_on_start: true
  ],
  metrics_server: :disabled

config :fiapx,
  ecto_repos: [Fiapx.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :fiapx, FiapxWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FiapxWeb.ErrorHTML, json: FiapxWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Fiapx.PubSub,
  live_view: [signing_salt: "L+7d6SxQ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :fiapx, Fiapx.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  fiapx: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  fiapx: [
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

hostname =
  case System.get_env("GITHUB_ACTIONS") do
    "true" -> [localhost: 29092]
    _ -> [kafka: 29092]
  end

config :kaffe,
  producer: [
    endpoints: hostname,
    topics: ["notifications"]
  ]

config :tesla, disable_deprecated_builder_warning: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
