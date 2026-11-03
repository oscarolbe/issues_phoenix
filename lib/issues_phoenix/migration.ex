defmodule IssuesPhoenix.Migration do
  @moduledoc """
  Migration helpers for setting up IssuesPhoenix tables.

  ## Usage

  Create a new migration:

      mix ecto.gen.migration add_issues_phoenix_tables

  Then in your migration file:

      defmodule MyApp.Repo.Migrations.AddIssuesPhoenixTables do
        use Ecto.Migration

        def up do
          IssuesPhoenix.Migration.up()
        end

        def down do
          IssuesPhoenix.Migration.down()
        end
      end

  ## Keeping the tables out of your schema

  If your app already has tables named `issues`, `tags` or `categories`, put
  IssuesPhoenix in its own Postgres schema:

      def up, do: IssuesPhoenix.Migration.up(prefix: "issues_phoenix")
      def down, do: IssuesPhoenix.Migration.down(prefix: "issues_phoenix")

  and set the same prefix in config:

      config :issues_phoenix, repo: MyApp.Repo, prefix: "issues_phoenix"
  """

  use Ecto.Migration

  @doc """
  Creates all IssuesPhoenix tables: tracked_routes, issues, tags, categories, and join tables.

  Note: status, priority, and route_type are stored as strings in the database
  but are managed as Ecto.Enum in the application for type safety.
  """
  def up(opts \\ []) do
    prefix = Keyword.get(opts, :prefix)

    if prefix, do: execute("CREATE SCHEMA IF NOT EXISTS #{quote_ident(prefix)}")

    # Create tracked_routes table first (issues will reference it)
    create table(:tracked_routes, prefix: prefix) do
      add :path, :string, null: false
      add :method, :string, null: false
      add :controller, :string, null: false
      add :action, :string
      add :route_type, :string, null: false
      add :enabled, :boolean, default: true
      add :category, :string
      add :display_order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tracked_routes, [:path, :method], prefix: prefix)
    create index(:tracked_routes, [:route_type], prefix: prefix)
    create index(:tracked_routes, [:enabled], prefix: prefix)
    create index(:tracked_routes, [:category], prefix: prefix)
    create index(:tracked_routes, [:category, :display_order], prefix: prefix)

    # Create issues table
    create table(:issues, prefix: prefix) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "open"
      add :priority, :string, null: false, default: "medium"
      add :tracked_route_id, references(:tracked_routes, on_delete: :nilify_all, prefix: prefix)

      timestamps(type: :utc_datetime)
    end

    create index(:issues, [:status], prefix: prefix)
    create index(:issues, [:priority], prefix: prefix)
    create index(:issues, [:tracked_route_id], prefix: prefix)
    create index(:issues, [:inserted_at], prefix: prefix)

    # Create tags table
    create table(:tags, prefix: prefix) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:name], prefix: prefix)

    # Create categories table
    create table(:categories, prefix: prefix) do
      add :name, :string, null: false
      add :description, :string
      add :color, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name], prefix: prefix)

    # Create join table for issues and tags
    create table(:issues_tags, primary_key: false, prefix: prefix) do
      add :issue_id, references(:issues, on_delete: :delete_all, prefix: prefix), null: false
      add :tag_id, references(:tags, on_delete: :delete_all, prefix: prefix), null: false
    end

    create index(:issues_tags, [:issue_id], prefix: prefix)
    create index(:issues_tags, [:tag_id], prefix: prefix)
    create unique_index(:issues_tags, [:issue_id, :tag_id], prefix: prefix)

    # Create join table for issues and categories
    create table(:issues_categories, primary_key: false, prefix: prefix) do
      add :issue_id, references(:issues, on_delete: :delete_all, prefix: prefix), null: false

      add :category_id, references(:categories, on_delete: :delete_all, prefix: prefix),
        null: false
    end

    create index(:issues_categories, [:issue_id], prefix: prefix)
    create index(:issues_categories, [:category_id], prefix: prefix)
    create unique_index(:issues_categories, [:issue_id, :category_id], prefix: prefix)
  end

  @doc """
  Drops all IssuesPhoenix tables.
  """
  def down(opts \\ []) do
    prefix = Keyword.get(opts, :prefix)

    drop table(:issues_categories, prefix: prefix)
    drop table(:issues_tags, prefix: prefix)
    drop table(:categories, prefix: prefix)
    drop table(:tags, prefix: prefix)
    drop table(:issues, prefix: prefix)
    drop table(:tracked_routes, prefix: prefix)
  end

  # The schema name is interpolated into DDL, so only allow plain identifiers.
  defp quote_ident(prefix) do
    if prefix =~ ~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/ do
      ~s("#{prefix}")
    else
      raise ArgumentError, "invalid IssuesPhoenix prefix: #{inspect(prefix)}"
    end
  end
end
