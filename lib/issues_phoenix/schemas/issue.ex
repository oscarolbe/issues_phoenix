defmodule IssuesPhoenix.Schemas.Issue do
  @moduledoc """
  Schema for tracking issues related to Phoenix routes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type status :: :open | :in_progress | :resolved | :closed
  @type priority :: :low | :medium | :high | :critical

  schema "issues" do
    field :title, :string
    field :description, :string
    field :status, Ecto.Enum, values: [:open, :in_progress, :resolved, :closed], default: :open
    field :priority, Ecto.Enum, values: [:low, :medium, :high, :critical], default: :medium

    belongs_to :tracked_route, IssuesPhoenix.Schemas.TrackedRoute

    many_to_many :tags, IssuesPhoenix.Schemas.Tag, join_through: "issues_tags", on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [
      :title,
      :description,
      :status,
      :priority,
      :tracked_route_id
    ])
    |> validate_required([:title, :status])
    |> foreign_key_constraint(:tracked_route_id)
  end
end
