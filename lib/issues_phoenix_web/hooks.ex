defmodule IssuesPhoenixWeb.Hooks do
  @moduledoc """
  `on_mount` hook for the IssuesPhoenix live_session (see
  `IssuesPhoenixWeb.issues_phoenix_routes/2`).

  Assigns:

    * `:base_path` - full path the pages are mounted at, e.g. `"/admin/issues"`
    * `:issues_phoenix_router` - router scanned by "Manage Routes": the
      configured `:router`, else the router the pages are mounted in
    * `:assets_path` - where the host serves IssuesPhoenix static files
    * `:issues_phoenix_class` - CSS scope class wrapping every page
  """

  import Phoenix.Component, only: [assign: 3]

  def on_mount({:init, base_path}, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:base_path, base_path)
     |> assign(:issues_phoenix_router, IssuesPhoenix.Config.router() || socket.router)
     |> assign(:assets_path, IssuesPhoenix.Config.assets_path())
     |> assign(:issues_phoenix_class, "issues-phoenix")}
  end
end
