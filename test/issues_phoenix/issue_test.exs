defmodule IssuesPhoenix.IssueTest do
  use IssuesPhoenix.DataCase, async: true

  alias IssuesPhoenix.Schemas.Issue

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset =
        Issue.changeset(%Issue{}, %{
          title: "Test Issue",
          status: :open
        })

      assert changeset.valid?
    end

    test "invalid changeset when title is missing" do
      changeset =
        Issue.changeset(%Issue{}, %{
          status: :open
        })

      refute changeset.valid?
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset when status is explicitly nil" do
      # Status has a default value, so we need to explicitly set it to nil
      changeset =
        Issue.changeset(%Issue{status: nil}, %{
          title: "Test Issue"
        })

      refute changeset.valid?
      assert %{status: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid status values" do
      valid_statuses = [:open, :in_progress, :resolved, :closed]

      for status <- valid_statuses do
        changeset =
          Issue.changeset(%Issue{}, %{
            title: "Test Issue",
            status: status
          })

        assert changeset.valid?, "Expected #{status} to be valid"
      end
    end

    test "rejects invalid status values" do
      changeset =
        Issue.changeset(%Issue{}, %{
          title: "Test Issue",
          status: :invalid_status
        })

      refute changeset.valid?
      assert %{status: [_]} = errors_on(changeset)
    end

    test "accepts valid priority values" do
      valid_priorities = [:low, :medium, :high, :critical]

      for priority <- valid_priorities do
        changeset =
          Issue.changeset(%Issue{}, %{
            title: "Test Issue",
            status: :open,
            priority: priority
          })

        assert changeset.valid?, "Expected #{priority} to be valid"
      end
    end

    test "rejects invalid priority values" do
      changeset =
        Issue.changeset(%Issue{}, %{
          title: "Test Issue",
          status: :open,
          priority: :invalid_priority
        })

      refute changeset.valid?
      assert %{priority: [_]} = errors_on(changeset)
    end

    test "sets default status to :open" do
      issue = %Issue{}
      assert issue.status == :open
    end

    test "sets default priority to :medium" do
      issue = %Issue{}
      assert issue.priority == :medium
    end

    test "accepts tracked_route_id" do
      changeset =
        Issue.changeset(%Issue{}, %{
          title: "Test Issue",
          status: :open,
          tracked_route_id: 1
        })

      assert changeset.valid?
      assert changeset.changes.tracked_route_id == 1
    end

    test "accepts description" do
      changeset =
        Issue.changeset(%Issue{}, %{
          title: "Test Issue",
          status: :open,
          description: "This is a detailed description"
        })

      assert changeset.valid?
      assert changeset.changes.description == "This is a detailed description"
    end

    test "accepts string status values and converts to atoms" do
      changeset =
        Issue.changeset(%Issue{}, %{
          title: "Test Issue",
          status: "in_progress"
        })

      assert changeset.valid?
      assert changeset.changes.status == :in_progress
    end

    test "accepts string priority values and converts to atoms" do
      changeset =
        Issue.changeset(%Issue{}, %{
          title: "Test Issue",
          status: :open,
          priority: "high"
        })

      assert changeset.valid?
      assert changeset.changes.priority == :high
    end
  end

  describe "associations" do
    test "has tracked_route association" do
      assert %Ecto.Association.BelongsTo{} = Issue.__schema__(:association, :tracked_route)
    end

    test "has tags association" do
      assert %Ecto.Association.ManyToMany{} = Issue.__schema__(:association, :tags)
    end

  end
end
