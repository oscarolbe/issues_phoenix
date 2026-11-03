defmodule IssuesPhoenix.Test.PrefixedMigration do
  @moduledoc """
  What a host migration looks like when it keeps IssuesPhoenix tables in
  their own Postgres schema. Run from `test_helper.exs`.
  """
  use Ecto.Migration

  def up, do: IssuesPhoenix.Migration.up(prefix: "issues_phoenix_prefixed")
  def down, do: IssuesPhoenix.Migration.down(prefix: "issues_phoenix_prefixed")
end
