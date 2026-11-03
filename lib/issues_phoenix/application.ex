defmodule IssuesPhoenix.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = children(Application.get_all_env(:issues_phoenix))
    Supervisor.start_link(children, strategy: :one_for_one, name: IssuesPhoenix.Supervisor)
  end

  @doc """
  Returns the processes to supervise for the given `:issues_phoenix` env.

  When used as a dependency the library starts nothing: all queries go through
  the host's repo (`config :issues_phoenix, repo: MyApp.Repo`) and pages are
  served by the host's endpoint.

  `standalone: true` (set in this project's dev/test config) starts the
  development harness from `dev/`. Those modules are not compiled when the
  library is used as a dependency.
  """
  def children(env) do
    if Keyword.get(env, :standalone, false) do
      [
        IssuesPhoenix.Repo,
        {Phoenix.PubSub, name: IssuesPhoenix.PubSub},
        IssuesPhoenixWeb.Endpoint
      ]
    else
      []
    end
  end
end
