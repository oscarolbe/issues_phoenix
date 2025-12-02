defmodule IssuesPhoenix.TrackedRoutes do
  @moduledoc """
  The TrackedRoutes context.

  Provides functions for managing tracked routes in the database.
  """

  import Ecto.Query, warn: false
  alias IssuesPhoenix.Config
  alias IssuesPhoenix.Schemas.TrackedRoute

  @doc """
  Returns the list of tracked routes.

  ## Options

  - `:enabled` - Filter by enabled status (true/false)
  - `:route_type` - Filter by route type (:controller or :live_view)

  ## Examples

      iex> list_tracked_routes()
      [%TrackedRoute{}, ...]

      iex> list_tracked_routes(enabled: true)
      [%TrackedRoute{enabled: true}, ...]

  """
  def list_tracked_routes(opts \\ []) do
    repo = Config.repo()

    TrackedRoute
    |> apply_filters(opts)
    |> order_by([t], [asc: t.display_order, asc: t.path])
    |> repo.all()
  end

  @doc """
  Gets a single tracked route.

  Raises `Ecto.NoResultsError` if the TrackedRoute does not exist.
  """
  def get_tracked_route!(id) do
    repo = Config.repo()
    repo.get!(TrackedRoute, id)
  end

  @doc """
  Gets a tracked route by path and method.
  """
  def get_by_path_and_method(path, method) do
    repo = Config.repo()
    repo.get_by(TrackedRoute, path: path, method: method)
  end

  @doc """
  Creates a tracked route.

  ## Examples

      iex> create_tracked_route(%{path: "/users", method: "GET"})
      {:ok, %TrackedRoute{}}

  """
  def create_tracked_route(attrs \\ %{}) do
    repo = Config.repo()

    %TrackedRoute{}
    |> TrackedRoute.changeset(attrs)
    |> repo.insert()
  end

  @doc """
  Updates a tracked route.
  """
  def update_tracked_route(%TrackedRoute{} = tracked_route, attrs) do
    repo = Config.repo()

    tracked_route
    |> TrackedRoute.changeset(attrs)
    |> repo.update()
  end

  @doc """
  Deletes a tracked route.
  """
  def delete_tracked_route(%TrackedRoute{} = tracked_route) do
    repo = Config.repo()
    repo.delete(tracked_route)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tracked route changes.
  """
  def change_tracked_route(%TrackedRoute{} = tracked_route, attrs \\ %{}) do
    TrackedRoute.changeset(tracked_route, attrs)
  end

  @doc """
  Creates or updates tracked routes from route scanner results.

  ## Examples

      iex> sync_from_scan([%{path: "/users", method: "GET", ...}])
      {:ok, 5}

  """
  def sync_from_scan(scanned_routes) do

    {created, updated} =
      Enum.reduce(scanned_routes, {0, 0}, fn route_info, {created, updated} ->
        case get_by_path_and_method(route_info.path, route_info.method) do
          nil ->
            attrs = %{
              path: route_info.path,
              method: route_info.method,
              controller: route_info.controller,
              action: to_string(route_info.action || ""),
              route_type: route_info.type
            }

            case create_tracked_route(attrs) do
              {:ok, _} -> {created + 1, updated}
              {:error, _} -> {created, updated}
            end

          existing ->
            attrs = %{
              controller: route_info.controller,
              action: to_string(route_info.action || ""),
              route_type: route_info.type
            }

            case update_tracked_route(existing, attrs) do
              {:ok, _} -> {created, updated + 1}
              {:error, _} -> {created, updated}
            end
        end
      end)

    {:ok, %{created: created, updated: updated}}
  end

  @doc """
  Returns all tracked route paths with their methods.
  """
  def tracked_route_identifiers do
    repo = Config.repo()

    TrackedRoute
    |> select([t], {t.path, t.method})
    |> repo.all()
  end

  @doc """
  Returns tracked routes grouped by category and ordered by display_order.

  Routes without a category are grouped under nil.

  ## Examples

      iex> list_grouped_by_category()
      %{
        "Login" => [%TrackedRoute{display_order: 1}, %TrackedRoute{display_order: 2}],
        "Posts" => [%TrackedRoute{display_order: 1}],
        nil => [%TrackedRoute{}]
      }
  """
  def list_grouped_by_category(opts \\ []) do
    list_tracked_routes(opts)
    |> Enum.group_by(& &1.category)
  end

  # Private functions

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:enabled, enabled} | rest]) do
    query
    |> where([t], t.enabled == ^enabled)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:route_type, route_type} | rest]) do
    query
    |> where([t], t.route_type == ^route_type)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_other | rest]) do
    apply_filters(query, rest)
  end
end
