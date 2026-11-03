{:ok, _} = Application.ensure_all_started(:issues_phoenix)

# A stand-in for a host application: its own repo and endpoint
# (see test/support/test_host and IssuesPhoenixWeb.HostCase).
{:ok, _} = TestHost.Repo.start_link()
{:ok, _} = TestHost.Endpoint.start_link()

# Host apps may keep IssuesPhoenix tables in a separate Postgres schema.
Ecto.Migrator.run(
  TestHost.Repo,
  [{20_990_101_000_000, IssuesPhoenix.Test.PrefixedMigration}],
  :up,
  all: true,
  log: false
)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(IssuesPhoenix.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(TestHost.Repo, :manual)
