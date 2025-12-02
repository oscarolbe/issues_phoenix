# Ensure the application and endpoint are started before tests run
# This is needed for verified routes (~p sigil) to work at compile time
{:ok, _} = Application.ensure_all_started(:issues_phoenix)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(IssuesPhoenix.Repo, :manual)
