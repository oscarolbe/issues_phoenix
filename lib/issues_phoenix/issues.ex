defmodule IssuesPhoenix.Issues do
  @moduledoc """
  The Issues context.

  Provides functions for managing issues in the database.
  """

  import Ecto.Query, warn: false
  alias IssuesPhoenix.Config
  alias IssuesPhoenix.Schemas.Issue

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
    repo = Config.repo()

    Issue
    |> apply_filters(opts)
    |> order_by([i], [desc: i.inserted_at])
    |> repo.all()
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
    repo = Config.repo()
    repo.get!(Issue, id)
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
    repo = Config.repo()

    %Issue{}
    |> Issue.changeset(attrs)
    |> repo.insert()
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
    repo = Config.repo()

    issue
    |> Issue.changeset(attrs)
    |> repo.update()
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
    repo = Config.repo()
    repo.delete(issue)
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
    repo = Config.repo()

    statuses = ["open", "in_progress", "resolved", "closed"]

    status_counts =
      Enum.reduce(statuses, %{}, fn status, acc ->
        count =
          Issue
          |> where([i], i.status == ^status)
          |> repo.aggregate(:count)

        Map.put(acc, String.to_atom(status), count)
      end)

    total = repo.aggregate(Issue, :count)

    Map.put(status_counts, :total, total)
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
