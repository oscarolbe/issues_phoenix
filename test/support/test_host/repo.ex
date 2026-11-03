defmodule TestHost.Repo do
  @moduledoc """
  Stands in for a host application's repo (e.g. `MyApp.Repo`).

  It points at the same test database as `IssuesPhoenix.Repo`, but it is a
  separate pool with its own sandbox. Host tests only check out *this* repo,
  so any library code that accidentally talks to `IssuesPhoenix.Repo` raises
  an ownership error instead of silently working.
  """
  use Ecto.Repo,
    otp_app: :issues_phoenix,
    adapter: Ecto.Adapters.Postgres
end
