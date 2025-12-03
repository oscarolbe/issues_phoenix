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
    {:issues_phoenix, github: "oscarolbe/issues_phoenix"}
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

Run the migration:

```bash
mix ecto.migrate
```

### 4. Configure Static Assets

To serve the Issues Phoenix CSS and assets, add this to your `lib/my_app_web/endpoint.ex` **before** your existing `Plug.Static`:

```elixir
# Serve issues_phoenix assets
plug Plug.Static,
  at: "/issues_phoenix/assets",
  from: {:issues_phoenix, "priv/static/assets"},
  gzip: false

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

> **Note:** If your `:browser` pipeline includes layout plugs, create a dedicated pipeline without them:
>
> ```elixir
> pipeline :issues_phoenix do
>   plug :accepts, ["html"]
>   plug :fetch_session
>   plug :fetch_live_flash
>   plug :protect_from_forgery
>   plug :put_secure_browser_headers
>   # Optional: Add basic authentication
>   plug :basic_auth, username: "username", password: "secret"
>   # Do NOT include :put_root_layout or :put_layout
> end
>
> scope "/" do
>   pipe_through :issues_phoenix
>   issues_phoenix_routes "/dev/issues"
> end
> ```

## Usage

Visit `/dev/issues` (or your configured path) to start tracking issues.

### Getting Started

1. **Manage Routes** - Click "Manage Routes" to scan and select which routes to track
2. **Create Issues** - Click "New Issue" to report bugs or tasks for specific routes
3. **Track Progress** - Update status and priority directly from the issues list
4. **Organize** - Use tags to categorize and filter issues

## Configuration Options

```elixir
# Either in config/dev.exs or config/prod.exs
# Depending on your environment
config :rent, dev_routes: true

config :issues_phoenix,
  repo: MyApp.Repo,                           # Required: Your Ecto repository
  assets_path: "/issues_phoenix/assets"       # Optional: Custom assets path

# Configure IssuesPhoenix.Repo to use your current database
config :issues_phoenix, IssuesPhoenix.Repo,
  # url: database_url # Alternatively, use a DATABASE_URL environment variable
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "db_dev"
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
