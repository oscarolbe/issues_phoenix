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

  """

  use Ecto.Migration

  @doc """
  Creates all IssuesPhoenix tables: tracked_routes, issues, tags, categories, and join tables.

  Note: status, priority, and route_type are stored as strings in the database
  but are managed as Ecto.Enum in the application for type safety.
  """
  def up do
    # Create tracked_routes table first (issues will reference it)
    create table(:tracked_routes) do
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

    create unique_index(:tracked_routes, [:path, :method])
    create index(:tracked_routes, [:route_type])
    create index(:tracked_routes, [:enabled])
    create index(:tracked_routes, [:category])
    create index(:tracked_routes, [:category, :display_order])

    # Create issues table
    create table(:issues) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "open"
      add :priority, :string, null: false, default: "medium"
      add :tracked_route_id, references(:tracked_routes, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:issues, [:status])
    create index(:issues, [:priority])
    create index(:issues, [:tracked_route_id])
    create index(:issues, [:inserted_at])

    # Create tags table
    create table(:tags) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:name])

    # Create categories table
    create table(:categories) do
      add :name, :string, null: false
      add :description, :string
      add :color, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])

    # Create join table for issues and tags
    create table(:issues_tags, primary_key: false) do
      add :issue_id, references(:issues, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
    end

    create index(:issues_tags, [:issue_id])
    create index(:issues_tags, [:tag_id])
    create unique_index(:issues_tags, [:issue_id, :tag_id])

    # Create join table for issues and categories
    create table(:issues_categories, primary_key: false) do
      add :issue_id, references(:issues, on_delete: :delete_all), null: false
      add :category_id, references(:categories, on_delete: :delete_all), null: false
    end

    create index(:issues_categories, [:issue_id])
    create index(:issues_categories, [:category_id])
    create unique_index(:issues_categories, [:issue_id, :category_id])
  end

  @doc """
  Drops all IssuesPhoenix tables.
  """
  def down do
    drop table(:issues_categories)
    drop table(:issues_tags)
    drop table(:categories)
    drop table(:tags)
    drop table(:issues)
    drop table(:tracked_routes)
  end
end
