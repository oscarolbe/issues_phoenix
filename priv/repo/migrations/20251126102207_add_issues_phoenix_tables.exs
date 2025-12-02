defmodule IssuesPhoenix.Repo.Migrations.AddIssuesPhoenixTables do
  use Ecto.Migration

  def up do
    IssuesPhoenix.Migration.up()
  end

  def down do
    IssuesPhoenix.Migration.down()
  end
end
