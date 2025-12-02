defmodule IssuesPhoenix.IssuesTest do
  use IssuesPhoenix.DataCase, async: true

  alias IssuesPhoenix.Issues
  alias IssuesPhoenix.Schemas.{Issue, TrackedRoute}

  describe "list_issues/1" do
    setup do
      # Create a tracked route for association
      tracked_route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller
        })
        |> Repo.insert!()

      # Create multiple issues with different attributes
      issue1 =
        %Issue{}
        |> Issue.changeset(%{
          title: "Open Bug",
          status: :open,
          priority: :high,
          tracked_route_id: tracked_route.id
        })
        |> Repo.insert!()

      issue2 =
        %Issue{}
        |> Issue.changeset(%{
          title: "In Progress Feature",
          status: :in_progress,
          priority: :medium,
          tracked_route_id: tracked_route.id
        })
        |> Repo.insert!()

      issue3 =
        %Issue{}
        |> Issue.changeset(%{
          title: "Resolved Issue",
          status: :resolved,
          priority: :low,
          tracked_route_id: tracked_route.id
        })
        |> Repo.insert!()

      %{
        tracked_route: tracked_route,
        issue1: issue1,
        issue2: issue2,
        issue3: issue3
      }
    end

    test "returns all issues", %{issue1: issue1, issue2: issue2, issue3: issue3} do
      issues = Issues.list_issues()

      assert length(issues) == 3
      issue_ids = Enum.map(issues, & &1.id)
      assert issue1.id in issue_ids
      assert issue2.id in issue_ids
      assert issue3.id in issue_ids
    end

    test "orders issues by inserted_at descending" do
      issues = Issues.list_issues()

      # Most recent should be first
      assert Enum.at(issues, 0).inserted_at >= Enum.at(issues, 1).inserted_at
      assert Enum.at(issues, 1).inserted_at >= Enum.at(issues, 2).inserted_at
    end

    test "filters by status", %{issue1: issue1} do
      issues = Issues.list_issues(status: :open)

      assert length(issues) == 1
      assert hd(issues).id == issue1.id
      assert hd(issues).status == :open
    end

    test "filters by priority", %{issue1: issue1} do
      issues = Issues.list_issues(priority: :high)

      assert length(issues) == 1
      assert hd(issues).id == issue1.id
      assert hd(issues).priority == :high
    end

    test "filters by tracked_route_id", %{tracked_route: tracked_route} do
      # Create another tracked route and issue
      other_route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/other",
          method: "GET",
          controller: "OtherController",
          route_type: :controller
        })
        |> Repo.insert!()

      %Issue{}
      |> Issue.changeset(%{
        title: "Other Issue",
        status: :open,
        tracked_route_id: other_route.id
      })
      |> Repo.insert!()

      issues = Issues.list_issues(tracked_route_id: tracked_route.id)

      assert length(issues) == 3
      assert Enum.all?(issues, fn i -> i.tracked_route_id == tracked_route.id end)
    end

    test "combines multiple filters", %{issue1: issue1, tracked_route: tracked_route} do
      issues =
        Issues.list_issues(
          status: :open,
          priority: :high,
          tracked_route_id: tracked_route.id
        )

      assert length(issues) == 1
      assert hd(issues).id == issue1.id
    end

    test "returns empty list when no issues match filters" do
      issues = Issues.list_issues(status: :closed)

      assert issues == []
    end
  end

  describe "get_issue!/1" do
    test "returns issue when it exists" do
      issue =
        %Issue{}
        |> Issue.changeset(%{title: "Test", status: :open})
        |> Repo.insert!()

      result = Issues.get_issue!(issue.id)

      assert result.id == issue.id
      assert result.title == "Test"
    end

    test "raises Ecto.NoResultsError when issue doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Issues.get_issue!(999_999)
      end
    end
  end

  describe "create_issue/1" do
    test "creates issue with valid attributes" do
      attrs = %{
        title: "New Issue",
        status: :open,
        priority: :medium,
        description: "Test description"
      }

      assert {:ok, %Issue{} = issue} = Issues.create_issue(attrs)
      assert issue.title == "New Issue"
      assert issue.status == :open
      assert issue.priority == :medium
      assert issue.description == "Test description"
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{title: nil}

      assert {:error, %Ecto.Changeset{}} = Issues.create_issue(attrs)
    end

    test "associates issue with tracked route" do
      tracked_route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller
        })
        |> Repo.insert!()

      attrs = %{
        title: "Associated Issue",
        status: :open,
        tracked_route_id: tracked_route.id
      }

      assert {:ok, issue} = Issues.create_issue(attrs)
      assert issue.tracked_route_id == tracked_route.id
    end
  end

  describe "update_issue/2" do
    test "updates issue with valid attributes" do
      issue =
        %Issue{}
        |> Issue.changeset(%{title: "Original", status: :open})
        |> Repo.insert!()

      attrs = %{title: "Updated", status: :closed}

      assert {:ok, updated_issue} = Issues.update_issue(issue, attrs)
      assert updated_issue.id == issue.id
      assert updated_issue.title == "Updated"
      assert updated_issue.status == :closed
    end

    test "returns error changeset with invalid attributes" do
      issue =
        %Issue{}
        |> Issue.changeset(%{title: "Test", status: :open})
        |> Repo.insert!()

      attrs = %{title: nil}

      assert {:error, %Ecto.Changeset{}} = Issues.update_issue(issue, attrs)
    end

    test "can update priority" do
      issue =
        %Issue{}
        |> Issue.changeset(%{title: "Test", status: :open, priority: :low})
        |> Repo.insert!()

      assert {:ok, updated} = Issues.update_issue(issue, %{priority: :critical})
      assert updated.priority == :critical
    end
  end

  describe "delete_issue/1" do
    test "deletes the issue" do
      issue =
        %Issue{}
        |> Issue.changeset(%{title: "To Delete", status: :open})
        |> Repo.insert!()

      assert {:ok, deleted_issue} = Issues.delete_issue(issue)
      assert deleted_issue.id == issue.id

      assert_raise Ecto.NoResultsError, fn ->
        Issues.get_issue!(issue.id)
      end
    end
  end

  describe "change_issue/2" do
    test "returns a changeset for tracking changes" do
      issue = %Issue{}

      changeset = Issues.change_issue(issue)

      assert %Ecto.Changeset{} = changeset
      assert changeset.data == issue
    end

    test "returns changeset with attributes" do
      issue = %Issue{}
      attrs = %{title: "New Title"}

      changeset = Issues.change_issue(issue, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.title == "New Title"
    end
  end

  describe "group_by_status/0" do
    setup do
      # Create issues with different statuses
      %Issue{}
      |> Issue.changeset(%{title: "Open 1", status: :open})
      |> Repo.insert!()

      %Issue{}
      |> Issue.changeset(%{title: "Open 2", status: :open})
      |> Repo.insert!()

      %Issue{}
      |> Issue.changeset(%{title: "Closed", status: :closed})
      |> Repo.insert!()

      :ok
    end

    test "groups issues by status" do
      grouped = Issues.group_by_status()

      assert is_map(grouped)
      assert Map.has_key?(grouped, :open)
      assert Map.has_key?(grouped, :closed)
    end

    test "returns correct counts per status" do
      grouped = Issues.group_by_status()

      assert length(grouped[:open]) == 2
      assert length(grouped[:closed]) == 1
    end
  end

  describe "stats/0" do
    setup do
      # Create issues with different statuses
      %Issue{}
      |> Issue.changeset(%{title: "Open 1", status: :open})
      |> Repo.insert!()

      %Issue{}
      |> Issue.changeset(%{title: "Open 2", status: :open})
      |> Repo.insert!()

      %Issue{}
      |> Issue.changeset(%{title: "In Progress", status: :in_progress})
      |> Repo.insert!()

      %Issue{}
      |> Issue.changeset(%{title: "Resolved", status: :resolved})
      |> Repo.insert!()

      %Issue{}
      |> Issue.changeset(%{title: "Closed", status: :closed})
      |> Repo.insert!()

      :ok
    end

    test "returns stats map with all status counts" do
      stats = Issues.stats()

      assert is_map(stats)
      assert Map.has_key?(stats, :total)
      assert Map.has_key?(stats, :open)
      assert Map.has_key?(stats, :in_progress)
      assert Map.has_key?(stats, :resolved)
      assert Map.has_key?(stats, :closed)
    end

    test "returns correct counts" do
      stats = Issues.stats()

      assert stats.total == 5
      assert stats.open == 2
      assert stats.in_progress == 1
      assert stats.resolved == 1
      assert stats.closed == 1
    end

    test "returns zero for statuses with no issues" do
      Repo.delete_all(Issue)

      stats = Issues.stats()

      assert stats.total == 0
      assert stats.open == 0
      assert stats.in_progress == 0
      assert stats.resolved == 0
      assert stats.closed == 0
    end
  end
end
