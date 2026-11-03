# IssuesPhoenix

A Phoenix LiveView-based issue tracker for your Phoenix applications. Track and manage issues directly from your development or production environment with rich route integration.

## Features

- 📋 Issue tracking with priorities and statuses
- 🗺️ Route integration - associate issues with specific Phoenix routes
- 🏷️ Tags for organization
- 🔍 Route scanner - automatically discover routes in your application
- 📊 Route management and categorization
- 🎨 UI with Pico CSS
- 🎯 Scoped CSS - no style conflicts with your app

## Installation

### 1. Add Dependency

Add `issues_phoenix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:issues_phoenix, github: "oscarolbe/issues_phoenix", branch: "master"}
  ]
end
```

Then run:

```bash
mix deps.get
```

### 2. Configure Repository

In your `config/config.exs`:

```elixir
config :issues_phoenix,
  repo: MyApp.Repo  # Your application's Ecto repository
```

IssuesPhoenix does not start a repo or any other process of its own. Every query goes through
your repo, so it shares your connection pool, your sandbox in tests, and your migrations.

### 3. Run Migrations

Create a new migration and use the provided migration helper:

```bash
mix ecto.gen.migration add_issues_phoenix_tables
```

Then in your migration file:

```elixir
defmodule MyApp.Repo.Migrations.AddIssuesPhoenixTables do
  use Ecto.Migration

  def up do
    IssuesPhoenix.Migration.up()
  end

  def down do
    IssuesPhoenix.Migration.down()
  end
end
```

If your app already has tables called `issues`, `tags` or `categories`, keep IssuesPhoenix in its own
Postgres schema instead:

```elixir
def up, do: IssuesPhoenix.Migration.up(prefix: "issues_phoenix")
def down, do: IssuesPhoenix.Migration.down(prefix: "issues_phoenix")
```

```elixir
# config/config.exs
config :issues_phoenix, repo: MyApp.Repo, prefix: "issues_phoenix"
```

Run the migration:

```bash
mix ecto.migrate
```

### 4. Configure Static Assets

To serve the Issues Phoenix stylesheet, add this to your `lib/my_app_web/endpoint.ex` **before** your existing `Plug.Static`:

```elixir
# Serve issues_phoenix assets
plug Plug.Static,
  at: "/issues_phoenix",
  from: {:issues_phoenix, "priv/static"},
  only: ~w(pico.min.css)

# Your existing Plug.Static
plug Plug.Static,
  at: "/",
  from: :my_app,
  gzip: false,
  only: MyAppWeb.static_paths()
```

### 5. Mount Routes

In your `lib/my_app_web/router.ex`:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use IssuesPhoenixWeb, :router  # Import IssuesPhoenix router macros

  # ... existing pipelines ...

  # Mount the issues tracker
  scope "/" do
    pipe_through :browser
    issues_phoenix_routes "/dev/issues"
  end
end
```

`use IssuesPhoenixWeb, :router` only imports `issues_phoenix_routes/2`. Your router's own
`use Phoenix.Router` stays the only one.

The pages work under any path or nested scope. For example, `scope "/admin"` with
`issues_phoenix_routes "/issues"` serves them at `/admin/issues`. They always render with
IssuesPhoenix's own root layout, whatever `put_root_layout` your pipeline sets.

To protect the pages, use a pipeline (e.g. with basic auth) or pass your own LiveView hooks:

```elixir
scope "/admin" do
  pipe_through [:browser, :require_admin]
  issues_phoenix_routes "/issues", on_mount: [{MyAppWeb.UserAuth, :ensure_admin}]
end
```

To expose the tracker only in development, wrap the mount in
`if Application.compile_env(:my_app, :dev_routes) do ... end`.

## Usage

Visit `/dev/issues` (or your configured path) to start tracking issues.

### Getting Started

1. **Manage Routes** - Click "Manage Routes" to scan and select which routes to track
2. **Create Issues** - Click "New Issue" to report bugs or tasks for specific routes
3. **Track Progress** - Update status and priority directly from the issues list
4. **Organize** - Use tags to categorize and filter issues

## Configuration Options

```elixir
config :issues_phoenix,
  repo: MyApp.Repo,                # Required: your Ecto repository
  prefix: "issues_phoenix",        # Optional: Postgres schema for the tables (default: repo default)
  router: MyAppWeb.Router,         # Optional: router scanned by "Manage Routes"
                                   #   (default: the router the pages are mounted in)
  assets_path: "/issues_phoenix"   # Optional: where you serve pico.min.css
```

## Database Schema

The Migration module creates these tables:

- `tracked_routes` - Routes available for issue tracking
- `issues` - Issue records with status, priority, and descriptions
- `tags` - User-defined tags for organizing issues
- `categories` - Predefined categories (currently unused)
- `issues_tags` - Join table for issue-tag associations
- `issues_categories` - Join table for issue-category associations

## Development

`lib/` is the library. `dev/` holds a standalone harness (`IssuesPhoenix.Repo`, endpoint, router)
for working on this project by itself. It is only compiled in this project's `:dev` and `:test`
environments, so host apps never get it.

The tests in `test/issues_phoenix_web/host/` mount the library inside a simulated host app
(`test/support/test_host`), at `/admin/tracker` with its own repo. Only the host repo gets a
sandbox connection there, so any query that bypasses the configured repo fails the test.

To work on this library:

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Start the development server
mix phx.server
```

Visit `http://localhost:4000/dev/issues` to see the library in action.

## License

MIT
