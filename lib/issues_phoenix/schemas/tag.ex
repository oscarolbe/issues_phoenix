defmodule IssuesPhoenix.Schemas.Tag do
  @moduledoc """
  Schema for tags that can be applied to issues.
  Tags are user-defined labels for organizing and filtering issues.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name, :string

    many_to_many :issues, IssuesPhoenix.Schemas.Issue, join_through: "issues_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 1, max: 50)
  end
end
