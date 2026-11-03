defmodule IssuesPhoenixWeb.HostCase do
  @moduledoc """
  Test case that runs IssuesPhoenix the way a host application does:

    * requests go through `TestHost.Endpoint` / `TestHost.Router`, where the
      library is mounted at `/admin/tracker`
    * `config :issues_phoenix, repo: TestHost.Repo`
    * only `TestHost.Repo` has a sandbox connection, so any query that goes
      to `IssuesPhoenix.Repo` fails the test

  These tests mutate application env, so they are always synchronous.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint TestHost.Endpoint

      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import IssuesPhoenixWeb.HostCase

      alias TestHost.Repo
    end
  end

  setup tags do
    if tags[:async], do: raise("HostCase tests cannot be async (they change app env)")

    previous = Application.get_all_env(:issues_phoenix)
    Application.put_env(:issues_phoenix, :repo, TestHost.Repo)

    for {key, value} <- Map.get(tags, :issues_phoenix_env, []) do
      Application.put_env(:issues_phoenix, key, value)
    end

    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(TestHost.Repo, shared: true)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
      restore_env(previous)
    end)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})

    {:ok, conn: conn}
  end

  defp restore_env(previous) do
    for {key, _} <- Application.get_all_env(:issues_phoenix),
        not Keyword.has_key?(previous, key) do
      Application.delete_env(:issues_phoenix, key)
    end

    for {key, value} <- previous, do: Application.put_env(:issues_phoenix, key, value)
  end
end
