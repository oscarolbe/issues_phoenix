defmodule IssuesPhoenix.Schemas.TrackedRoute do
  @moduledoc """
  Schema for routes that are being tracked for issues.

  Only routes registered in this table can have issues created for them.
  Users can scan all application routes and select which ones they want to track.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type route_type :: :controller | :live_view

  schema "tracked_routes" do
    field :path, :string
    field :method, :string
    field :controller, :string
    field :action, :string
    field :route_type, Ecto.Enum, values: [:controller, :live_view]
    field :enabled, :boolean, default: true
    field :category, :string
    field :display_order, :integer, default: 0

    has_many :issues, IssuesPhoenix.Schemas.Issue

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tracked_route, attrs) do
    tracked_route
    |> cast(attrs, [:path, :method, :controller, :action, :route_type, :enabled, :category, :display_order])
    |> validate_required([:path, :method, :controller, :route_type])
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> unique_constraint([:path, :method], name: :tracked_routes_path_method_index)
  end

  @doc """
  Creates a TrackedRoute from a route scan result.

  ## Examples

      iex> from_route_scan(%{path: "/users", method: "GET", controller: "UserController", action: :index, type: :controller})
      %TrackedRoute{path: "/users", method: "GET", ...}
  """
  def from_route_scan(route_info) do
    %__MODULE__{
      path: route_info.path,
      method: route_info.method,
      controller: route_info.controller,
      action: to_string(route_info.action || ""),
      route_type: route_info.type
    }
  end
end
