defmodule IssuesPhoenix.CategoryTest do
  use IssuesPhoenix.DataCase, async: true

  alias IssuesPhoenix.Schemas.Category

  describe "changeset/2" do
    test "valid changeset with name only" do
      changeset =
        Category.changeset(%Category{}, %{
          name: "Bug"
        })

      assert changeset.valid?
    end

    test "valid changeset with all fields" do
      changeset =
        Category.changeset(%Category{}, %{
          name: "Bug",
          description: "Something isn't working",
          color: "#dc2626"
        })

      assert changeset.valid?
    end

    test "invalid changeset when name is missing" do
      changeset = Category.changeset(%Category{}, %{})

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "unique constraint on name" do
      # First create a category
      %Category{}
      |> Category.changeset(%{name: "Duplicate"})
      |> Repo.insert!()

      # Try to create another with the same name
      changeset = Category.changeset(%Category{}, %{name: "Duplicate"})

      assert {:error, failed_changeset} = Repo.insert(changeset)
      assert %{name: ["has already been taken"]} = errors_on(failed_changeset)
    end

    test "rejects empty name" do
      changeset = Category.changeset(%Category{}, %{name: ""})

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts name at minimum length" do
      changeset = Category.changeset(%Category{}, %{name: "A"})

      assert changeset.valid?
    end

    test "accepts name at maximum length" do
      # 50 characters
      long_name = String.duplicate("a", 50)
      changeset = Category.changeset(%Category{}, %{name: long_name})

      assert changeset.valid?
    end

    test "rejects name exceeding maximum length" do
      # 51 characters
      too_long_name = String.duplicate("a", 51)
      changeset = Category.changeset(%Category{}, %{name: too_long_name})

      refute changeset.valid?
      assert %{name: ["should be at most 50 character(s)"]} = errors_on(changeset)
    end

    test "accepts optional description field" do
      changeset =
        Category.changeset(%Category{}, %{
          name: "Feature",
          description: "New feature or request"
        })

      assert changeset.valid?
      assert changeset.changes.description == "New feature or request"
    end

    test "accepts optional color field" do
      changeset =
        Category.changeset(%Category{}, %{
          name: "Bug",
          color: "#dc2626"
        })

      assert changeset.valid?
      assert changeset.changes.color == "#dc2626"
    end

    test "accepts hex color format" do
      valid_colors = ["#ffffff", "#000000", "#dc2626", "#2563eb"]

      for color <- valid_colors do
        changeset =
          Category.changeset(%Category{}, %{
            name: "Test",
            color: color
          })

        assert changeset.valid?, "Expected #{color} to be valid"
      end
    end
  end

  describe "associations" do
    test "has issues association" do
      assert %Ecto.Association.ManyToMany{} = Category.__schema__(:association, :issues)
    end
  end

  describe "default_categories/0" do
    test "returns list of default categories" do
      categories = Category.default_categories()

      assert is_list(categories)
      assert length(categories) == 10
    end

    test "all default categories have required fields" do
      categories = Category.default_categories()

      for category <- categories do
        assert Map.has_key?(category, :name)
        assert Map.has_key?(category, :description)
        assert Map.has_key?(category, :color)

        assert is_binary(category.name)
        assert is_binary(category.description)
        assert is_binary(category.color)
      end
    end

    test "includes expected category names" do
      categories = Category.default_categories()
      names = Enum.map(categories, & &1.name)

      expected_names = [
        "Bug",
        "Feature",
        "Enhancement",
        "UI",
        "UX",
        "Performance",
        "Documentation",
        "Security",
        "Refactor",
        "Testing"
      ]

      assert Enum.sort(names) == Enum.sort(expected_names)
    end

    test "all default categories have valid hex colors" do
      categories = Category.default_categories()

      for category <- categories do
        assert String.match?(category.color, ~r/^#[0-9a-f]{6}$/i),
               "Expected #{category.name} color #{category.color} to be valid hex"
      end
    end

    test "default categories can be inserted into database" do
      categories = Category.default_categories()

      for category_attrs <- categories do
        changeset = Category.changeset(%Category{}, category_attrs)
        assert changeset.valid?, "Expected #{category_attrs.name} changeset to be valid"

        assert {:ok, _category} = Repo.insert(changeset)
      end
    end
  end
end
