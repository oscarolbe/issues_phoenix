import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :issues_phoenix, IssuesPhoenix.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "issues_phoenix_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :issues_phoenix, start_endpoint: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :issues_phoenix, IssuesPhoenixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "jQapWcehRNvAm8ouEiQA1XxKeSU5lRGnd1sORTETXEd06pa11MrdbEsunwjwQ4ZY",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Enable dev routes for testing
config :issues_phoenix, dev_routes: true, enabled: true
