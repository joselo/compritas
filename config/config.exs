# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :billing, :scopes,
  user: [
    default: true,
    module: Billing.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Billing.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :billing, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10],
  repo: Billing.Repo

# plugins: [
#   # It runs every 5 minutes
#   {Oban.Plugins.Cron, crontab: [{"*/5 * * * *", Billing.AuthInvoiceWorkerWorker}]}
# ]

config :billing,
  ecto_repos: [Billing.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :billing, BillingWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BillingWeb.ErrorHTML, json: BillingWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Billing.PubSub,
  live_view: [signing_salt: "GEW1Q50K"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :billing, Billing.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  billing: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  billing: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mime, :types, %{
  "application/x-pkcs12" => ["p12"]
}

config :billing,
  crypto_key_base: "Ek/ZCeyFk1/yXXsEtjunrVHBHxqLPndOMgIIaoQEqW0qntrhBXoHtYS/RqA4bcdN"

config :billing,
       BillingWeb.Gettext,
       default_locale: "es",
       locales: ~w(en es)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
