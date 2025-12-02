defmodule IssuesPhoenix.Web do
  @moduledoc """
  Entry point for IssuesPhoenix web integration.

  Use this module in your router to access IssuesPhoenix macros:

      use IssuesPhoenix.Web, :router

  Then mount the dashboard:

      issues_phoenix_dashboard "/dev/issues"

  Or with custom options:

      issues_phoenix_dashboard "/admin/issues",
        repo: MyApp.Repo,
        router: MyAppWeb.Router
  """

  def router do
    quote do
      import IssuesPhoenix.Router
    end
  end

  @doc false
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
