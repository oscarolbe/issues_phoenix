defmodule IssuesPhoenix.Repo do
  use Ecto.Repo,
    otp_app: :issues_phoenix,
    adapter: Ecto.Adapters.Postgres
end
