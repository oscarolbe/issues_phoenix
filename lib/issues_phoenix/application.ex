defmodule IssuesPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      IssuesPhoenix.Repo
    ] ++ children(Application.get_env(:issues_phoenix, :start_endpoint))

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IssuesPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children(true), do: [IssuesPhoenixWeb.Endpoint]
  defp children(_), do: []
end
