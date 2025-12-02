defmodule IssuesPhoenix.TagTest do
  use IssuesPhoenix.DataCase, async: true

  alias IssuesPhoenix.Schemas.Tag

  describe "changeset/2" do
    test "valid changeset with name" do
      changeset =
        Tag.changeset(%Tag{}, %{
          name: "bug"
        })

      assert changeset.valid?
    end

    test "invalid changeset when name is missing" do
      changeset = Tag.changeset(%Tag{}, %{})

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "unique constraint on name" do
      # First create a tag
      %Tag{}
      |> Tag.changeset(%{name: "duplicate"})
      |> Repo.insert!()

      # Try to create another with the same name
      changeset = Tag.changeset(%Tag{}, %{name: "duplicate"})

      assert {:error, failed_changeset} = Repo.insert(changeset)
      assert %{name: ["has already been taken"]} = errors_on(failed_changeset)
    end

    test "rejects empty name" do
      changeset = Tag.changeset(%Tag{}, %{name: ""})

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts name at minimum length" do
      changeset = Tag.changeset(%Tag{}, %{name: "a"})

      assert changeset.valid?
    end

    test "accepts name at maximum length" do
      # 50 characters
      long_name = String.duplicate("a", 50)
      changeset = Tag.changeset(%Tag{}, %{name: long_name})

      assert changeset.valid?
    end

    test "rejects name exceeding maximum length" do
      # 51 characters
      too_long_name = String.duplicate("a", 51)
      changeset = Tag.changeset(%Tag{}, %{name: too_long_name})

      refute changeset.valid?
      assert %{name: ["should be at most 50 character(s)"]} = errors_on(changeset)
    end

    test "accepts tag names with spaces" do
      changeset = Tag.changeset(%Tag{}, %{name: "needs review"})

      assert changeset.valid?
    end

    test "accepts tag names with hyphens" do
      changeset = Tag.changeset(%Tag{}, %{name: "high-priority"})

      assert changeset.valid?
    end

    test "accepts tag names with underscores" do
      changeset = Tag.changeset(%Tag{}, %{name: "needs_work"})

      assert changeset.valid?
    end
  end

  describe "associations" do
    test "has issues association" do
      assert %Ecto.Association.ManyToMany{} = Tag.__schema__(:association, :issues)
    end
  end
end
