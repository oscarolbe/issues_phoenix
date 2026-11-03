defmodule IssuesPhoenix.Issues do
  @moduledoc """
  The Issues context.

  Provides functions for managing issues in the database.
  """

  import Ecto.Query, warn: false
  alias IssuesPhoenix.DB
  alias IssuesPhoenix.Schemas.{Issue, Tag}

  @doc """
  Returns the list of issues.

  ## Options

  - `:status` - Filter by status
  - `:priority` - Filter by priority
  - `:tracked_route_id` - Filter by tracked route ID

  ## Examples

      iex> list_issues()
      [%Issue{}, ...]

      iex> list_issues(status: :open)
      [%Issue{status: :open}, ...]

  """
  def list_issues(opts \\ []) do
    Issue
    |> apply_filters(opts)
    |> order_by([i], desc: i.inserted_at)
    |> DB.all()
  end

  @doc """
  Gets a single issue.

  Raises `Ecto.NoResultsError` if the Issue does not exist.

  ## Examples

      iex> get_issue!(123)
      %Issue{}

      iex> get_issue!(456)
      ** (Ecto.NoResultsError)

  """
  def get_issue!(id) do
    DB.get!(Issue, id)
  end

  @doc """
  Creates an issue.

  ## Examples

      iex> create_issue(%{title: "Fix bug"})
      {:ok, %Issue{}}

      iex> create_issue(%{title: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_issue(attrs \\ %{}) do
    %Issue{}
    |> Issue.changeset(attrs)
    |> DB.insert()
  end

  @doc """
  Updates an issue.

  ## Examples

      iex> update_issue(issue, %{status: "closed"})
      {:ok, %Issue{}}

      iex> update_issue(issue, %{status: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_issue(%Issue{} = issue, attrs) do
    issue
    |> Issue.changeset(attrs)
    |> DB.update()
  end

  @doc """
  Deletes an issue.

  ## Examples

      iex> delete_issue(issue)
      {:ok, %Issue{}}

      iex> delete_issue(issue)
      {:error, %Ecto.Changeset{}}

  """
  def delete_issue(%Issue{} = issue) do
    DB.delete(issue)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue changes.

  ## Examples

      iex> change_issue(issue)
      %Ecto.Changeset{data: %Issue{}}

  """
  def change_issue(%Issue{} = issue, attrs \\ %{}) do
    Issue.changeset(issue, attrs)
  end

  @doc """
  Returns a list of issues grouped by status.

  ## Examples

      iex> group_by_status()
      %{
        "open" => [%Issue{}, ...],
        "closed" => [%Issue{}, ...]
      }

  """
  def group_by_status do
    list_issues()
    |> Enum.group_by(& &1.status)
  end

  @doc """
  Returns statistics about issues.

  ## Examples

      iex> stats()
      %{
        total: 42,
        open: 10,
        in_progress: 5,
        resolved: 20,
        closed: 7
      }

  """
  def stats do
    status_counts =
      Map.new(statuses(), fn status ->
        {status, Issue |> where([i], i.status == ^status) |> DB.aggregate(:count)}
      end)

    Map.put(status_counts, :total, DB.aggregate(Issue, :count))
  end

  @doc """
  All valid issue statuses, as atoms.
  """
  def statuses, do: Ecto.Enum.values(Issue, :status)

  @doc """
  Parses a status coming from user input without creating atoms.

  Returns `nil` for blank or unknown values.

      iex> parse_status("open")
      :open

      iex> parse_status("bogus")
      nil
  """
  def parse_status(value) when is_binary(value) do
    Enum.find(statuses(), &(Atom.to_string(&1) == value))
  end

  def parse_status(_), do: nil

  @doc """
  Gets an issue with its tracked route and tags preloaded.
  """
  def get_issue_with_assocs!(id), do: id |> get_issue!() |> DB.preload([:tracked_route, :tags])

  @doc """
  Lists issues (see `list_issues/1`) with tracked route and tags preloaded.

  Also accepts `:tag_id` to only return issues carrying that tag.
  """
  def list_issues_with_assocs(opts \\ []) do
    opts
    |> list_issues()
    |> DB.preload([:tracked_route, :tags])
    |> filter_by_tag(Keyword.get(opts, :tag_id))
  end

  defp filter_by_tag(issues, nil), do: issues

  defp filter_by_tag(issues, tag_id) do
    Enum.filter(issues, fn issue -> Enum.any?(issue.tags, &(&1.id == tag_id)) end)
  end

  @doc """
  Replaces the tags of an issue with the tags whose ids are given.
  """
  def set_issue_tags(%Issue{} = issue, tag_ids) when is_list(tag_ids) do
    tags = if tag_ids == [], do: [], else: DB.all(from t in Tag, where: t.id in ^tag_ids)

    issue
    |> DB.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> DB.update()
  end

  @doc """
  Lists all tags ordered by name.
  """
  def list_tags, do: DB.all(from t in Tag, order_by: t.name)

  @doc """
  Returns the tag with the given name, creating it if needed.
  """
  def find_or_create_tag(name) when is_binary(name) do
    case DB.get_by(Tag, name: name) do
      nil -> %Tag{} |> Tag.changeset(%{name: name}) |> DB.insert()
      tag -> {:ok, tag}
    end
  end

  # Private functions

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:status, nil} | rest]), do: apply_filters(query, rest)

  defp apply_filters(query, [{:status, status} | rest]) do
    query
    |> where([i], i.status == ^status)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:priority, nil} | rest]), do: apply_filters(query, rest)

  defp apply_filters(query, [{:priority, priority} | rest]) do
    query
    |> where([i], i.priority == ^priority)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:tracked_route_id, nil} | rest]), do: apply_filters(query, rest)

  defp apply_filters(query, [{:tracked_route_id, tracked_route_id} | rest]) do
    query
    |> where([i], i.tracked_route_id == ^tracked_route_id)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_other | rest]) do
    apply_filters(query, rest)
  end
end
