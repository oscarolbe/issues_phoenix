defmodule IssuesPhoenix.DB do
  @moduledoc false
  # The single place IssuesPhoenix talks to the database.
  #
  # Every call goes through the host's repo (`IssuesPhoenix.Config.repo/0`)
  # with the configured query prefix, so no code path can end up on another
  # repo or on the host's own tables in the default schema.

  alias IssuesPhoenix.Config

  def all(queryable), do: Config.repo().all(queryable, opts())
  def get!(queryable, id), do: Config.repo().get!(queryable, id, opts())
  def get_by(queryable, clauses), do: Config.repo().get_by(queryable, clauses, opts())
  def aggregate(queryable, agg), do: Config.repo().aggregate(queryable, agg, opts())
  def preload(structs, preloads), do: Config.repo().preload(structs, preloads, opts())
  def insert(struct_or_changeset), do: Config.repo().insert(struct_or_changeset, opts())
  def insert!(struct_or_changeset), do: Config.repo().insert!(struct_or_changeset, opts())
  def update(changeset), do: Config.repo().update(changeset, opts())
  def update!(changeset), do: Config.repo().update!(changeset, opts())
  def delete(struct), do: Config.repo().delete(struct, opts())

  defp opts do
    case Config.prefix() do
      nil -> []
      prefix -> [prefix: prefix]
    end
  end
end
