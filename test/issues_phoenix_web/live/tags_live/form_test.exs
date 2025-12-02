defmodule IssuesPhoenixWeb.TagsLive.FormTest do
  use IssuesPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias IssuesPhoenix.Config
  alias IssuesPhoenix.Schemas.Tag

  setup %{conn: conn} do
    # Initialize connection for LiveView tests
    conn = conn |> Plug.Test.init_test_session(%{}) |> Phoenix.ConnTest.fetch_flash()

    %{conn: conn}
  end

  describe "new tag form" do
    test "mounts successfully and displays form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/issues/tags/new")

      assert html =~ "Create New Tag"
      assert html =~ "Create a new tag to categorize issues"
      assert html =~ "Tag Name"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/issues/tags/new")

      # Try to submit with empty name
      html =
        view
        |> form("form", tag: %{name: ""})
        |> render_change()

      # Should show validation error
      assert html =~ "can&#39;t be blank" || html =~ "can't be blank"
    end

    test "creates tag successfully with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/issues/tags/new")

      # Fill in valid data
      view
      |> form("form", tag: %{name: "frontend"})
      |> render_submit()

      # Should create the tag
      repo = Config.repo()
      tag = repo.get_by(Tag, name: "frontend")
      assert tag != nil
      assert tag.name == "frontend"
    end

    test "trims whitespace from tag name", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/issues/tags/new")

      # Submit with whitespace
      view
      |> form("form", tag: %{name: "  backend  "})
      |> render_submit()

      # Should create the tag with trimmed name
      repo = Config.repo()
      tag = repo.get_by(Tag, name: "backend")
      assert tag != nil
      assert tag.name == "backend"
    end

    test "handles duplicate tag names gracefully", %{conn: conn} do
      # Create a tag first
      repo = Config.repo()
      existing_tag = repo.insert!(%Tag{name: "urgent"})

      {:ok, view, _html} = live(conn, "/dev/issues/tags/new")

      # Try to create the same tag
      view
      |> form("form", tag: %{name: "urgent"})
      |> render_submit()

      # Should not create a duplicate
      tags = repo.all(Tag) |> Enum.filter(&(&1.name == "urgent"))
      assert length(tags) == 1
      assert hd(tags).id == existing_tag.id
    end

    test "has cancel link back to issues", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/issues/tags/new")

      assert html =~ "Cancel"
      assert html =~ ~s(href="/dev/issues/new")
    end
  end
end
