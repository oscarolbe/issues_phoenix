defmodule IssuesPhoenix.Config do
  @moduledoc """
  Configuration helpers for IssuesPhoenix.

  Provides access to configuration values set in the host application.
  """

  @doc """
  Gets the Ecto repository module configured for IssuesPhoenix.

  Defaults to the application's main repo if not explicitly configured.

  ## Configuration

      config :issues_phoenix,
        repo: MyApp.Repo

  """
  def repo do
    Application.get_env(:issues_phoenix, :repo) || IssuesPhoenix.Repo
  end

  @doc """
  Gets the router module to scan for routes.

  Defaults to IssuesPhoenixWeb.Router if not configured.

  ## Configuration

      config :issues_phoenix,
        router: MyAppWeb.Router

  """
  def router do
    Application.get_env(:issues_phoenix, :router) || IssuesPhoenixWeb.Router
  end

  @doc """
  Checks if IssuesPhoenix should be enabled.

  By default, only enabled in development environment.

  ## Configuration

      config :issues_phoenix,
        enabled: true

  """
  def enabled? do
    case Application.get_env(:issues_phoenix, :enabled) do
      nil -> Mix.env() == :dev
      value -> value
    end
  end

  @doc """
  Gets the path prefix for serving assets.

  Defaults to "/issues_phoenix/assets".

  ## Configuration

      config :issues_phoenix,
        assets_path: "/my/custom/path"

  """
  def assets_path do
    Application.get_env(:issues_phoenix, :assets_path, "/issues_phoenix/assets")
  end
end
