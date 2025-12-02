defmodule IssuesPhoenix.LiveSession do
  @moduledoc """
  LiveView session hooks for IssuesPhoenix.

  This module handles configuration injection and authorization checks
  for IssuesPhoenix LiveViews.
  """
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  @doc """
  on_mount callback for configuring IssuesPhoenix LiveViews.

  This callback injects configuration options passed to the
  `issues_phoenix_dashboard` macro into the socket assigns.
  """
  def on_mount({:configure, opts}, _params, _session, socket) do
    # Store configuration in socket assigns for use by LiveViews
    socket =
      socket
      |> assign(:issues_phoenix_config, opts)
      |> maybe_configure_repo(opts)
      |> maybe_configure_router(opts)

    # Check if IssuesPhoenix is enabled for this environment
    if IssuesPhoenix.Config.enabled?() do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "IssuesPhoenix is only available in development mode")
       |> redirect(to: "/")}
    end
  end

  defp maybe_configure_repo(socket, opts) do
    case Keyword.get(opts, :repo) do
      nil -> socket
      repo -> assign(socket, :issues_phoenix_repo, repo)
    end
  end

  defp maybe_configure_router(socket, opts) do
    case Keyword.get(opts, :router) do
      nil -> socket
      router -> assign(socket, :issues_phoenix_router, router)
    end
  end
end
