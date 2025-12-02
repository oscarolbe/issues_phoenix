defmodule IssuesPhoenix.Schemas.Category do
  @moduledoc """
  Schema for categories that classify issues.
  Categories are predefined types like UI, UX, Bug, Feature, etc.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :description, :string
    field :color, :string

    many_to_many :issues, IssuesPhoenix.Schemas.Issue, join_through: "issues_categories"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :color])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 1, max: 50)
  end

  @doc """
  Returns the default categories to seed.
  """
  def default_categories do
    [
      %{name: "Bug", description: "Something isn't working", color: "#dc2626"},
      %{name: "Feature", description: "New feature or request", color: "#2563eb"},
      %{name: "Enhancement", description: "Improvement to existing feature", color: "#059669"},
      %{name: "UI", description: "User interface issue", color: "#7c3aed"},
      %{name: "UX", description: "User experience issue", color: "#db2777"},
      %{name: "Performance", description: "Performance or optimization", color: "#ea580c"},
      %{name: "Documentation", description: "Documentation related", color: "#0891b2"},
      %{name: "Security", description: "Security concern", color: "#dc2626"},
      %{name: "Refactor", description: "Code refactoring", color: "#65a30d"},
      %{name: "Testing", description: "Testing related", color: "#8b5cf6"}
    ]
  end
end
