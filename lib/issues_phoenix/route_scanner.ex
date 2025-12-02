defmodule IssuesPhoenix.RouteScanner do
  @moduledoc """
  Scans and extracts route information from a Phoenix router.

  This module provides functionality to introspect Phoenix routes
  and extract metadata useful for issue tracking.
  """

  @doc """
  Scans all routes from the given router module.

  Returns a list of route maps containing:
  - `:path` - The route path pattern
  - `:method` - HTTP method (GET, POST, etc.)
  - `:controller` - Controller module name (or LiveView module)
  - `:action` - Controller action name (or :live for LiveViews)
  - `:helper` - Route helper name
  - `:type` - Route type (:controller or :live_view)

  ## Examples

      iex> IssuesPhoenix.RouteScanner.scan_routes(MyAppWeb.Router)
      [
        %{
          path: "/",
          method: "GET",
          controller: "MyAppWeb.PageController",
          action: :index,
          helper: "page_path",
          type: :controller
        },
        %{
          path: "/users",
          method: "GET",
          controller: "MyAppWeb.UserLive.Index",
          action: :live,
          helper: "user_path",
          type: :live_view
        },
        ...
      ]
  """
  def scan_routes(router_module) when is_atom(router_module) do
    router_module.__routes__()
    |> Enum.map(&extract_route_info/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(fn route -> {route.path, route.method} end)
  rescue
    UndefinedFunctionError ->
      {:error, "Module #{inspect(router_module)} is not a valid Phoenix router"}
  end

  @doc """
  Scans routes and returns only those that don't have associated issues.

  Takes a router module and optionally a list of existing issue route paths.
  """
  def scan_untracked_routes(router_module, existing_route_paths \\ []) do
    scan_routes(router_module)
    |> case do
      {:error, _} = error ->
        error

      routes ->
        routes
        |> Enum.reject(fn route ->
          Enum.any?(existing_route_paths, fn {path, method} ->
            route.path == path && route.method == method
          end)
        end)
    end
  end

  @doc """
  Groups routes by controller for organized display.
  """
  def group_by_controller(routes) when is_list(routes) do
    routes
    |> Enum.group_by(& &1.controller)
    |> Enum.sort_by(fn {controller, _} -> controller end)
  end

  # Private functions

  defp extract_route_info(%{
         path: path,
         verb: verb,
         plug: plug,
         plug_opts: action,
         helper: helper,
         metadata: metadata
       }) do
    # Check if this is a LiveView route
    live_view_module = get_live_view_module(plug, metadata)

    # Skip Phoenix internal routes
    if skip_route?(plug, live_view_module, path) do
      nil
    else
      {controller, route_type} =
        if live_view_module do
          {inspect(live_view_module), :live_view}
        else
          {inspect(plug), :controller}
        end

      %{
        path: path,
        method: verb |> to_string() |> String.upcase(),
        controller: controller,
        action: action,
        helper: helper || "N/A",
        type: route_type
      }
    end
  end

  defp extract_route_info(_), do: nil

  # Extract LiveView module from metadata if this is a LiveView route
  defp get_live_view_module(Phoenix.LiveView.Plug, metadata) when is_map(metadata) do
    case Map.get(metadata, :phoenix_live_view) do
      {module, _, _, _} -> module
      _ -> nil
    end
  end

  defp get_live_view_module(_, _), do: nil

  defp skip_route?(plug, live_view_module, path) do
    plug_name = inspect(plug)
    live_view_name = if live_view_module, do: inspect(live_view_module), else: ""

    # Skip Phoenix internal routes
    String.starts_with?(path, "/_") ||
      # Skip Phoenix LiveDashboard routes (internal dev tool)
      String.contains?(plug_name, "LiveDashboard") ||
      String.contains?(live_view_name, "LiveDashboard") ||
      # Skip static file routes
      String.contains?(plug_name, "Plug.Static") ||
      # Skip LiveDashboard Assets
      String.contains?(plug_name, "Phoenix.LiveDashboard.Assets")
  end
end
