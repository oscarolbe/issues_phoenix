defmodule IssuesPhoenix.Config do
  @moduledoc """
  Runtime configuration read from the host application.

      config :issues_phoenix,
        repo: MyApp.Repo,                 # required
        prefix: "issues_phoenix",         # optional Postgres schema for the tables
        router: MyAppWeb.Router,          # optional, defaults to the mounting router
        assets_path: "/issues_phoenix"    # optional, where pico.min.css is served
  """

  @doc """
  The host's Ecto repo. IssuesPhoenix never starts a repo of its own.
  """
  def repo do
    case Application.get_env(:issues_phoenix, :repo) do
      nil ->
        raise ArgumentError, """
        IssuesPhoenix has no repo configured. Point it at your application's repo:

            config :issues_phoenix, repo: MyApp.Repo
        """

      repo ->
        repo
    end
  end

  @doc """
  The Postgres schema (Ecto query prefix) holding the IssuesPhoenix tables.

  `nil` (default) uses the repo's default schema, usually `public`. Set it when
  your app already has tables named `issues`, `tags`, etc. It must match the
  `:prefix` given to `IssuesPhoenix.Migration.up/1`.
  """
  def prefix, do: Application.get_env(:issues_phoenix, :prefix)

  @doc """
  The router whose routes the "Manage Routes" page scans.

  `nil` (default) means the router IssuesPhoenix is mounted in.
  """
  def router, do: Application.get_env(:issues_phoenix, :router)

  @doc """
  The URL path the host serves IssuesPhoenix static files from.
  """
  def assets_path, do: Application.get_env(:issues_phoenix, :assets_path, "/issues_phoenix")
end
