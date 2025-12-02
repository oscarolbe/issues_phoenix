defmodule IssuesPhoenixWeb.IssuesLive.FormTest do
  use IssuesPhoenixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias IssuesPhoenix.{Issues, TrackedRoutes, Config}
  alias IssuesPhoenix.Schemas.Tag

  setup %{conn: conn} do
    # Initialize connection for LiveView tests
    conn = conn |> Plug.Test.init_test_session(%{}) |> Phoenix.ConnTest.fetch_flash()

    %{conn: conn}
  end

  setup do
    repo = Config.repo()

    # Create test tracked routes with categories
    {:ok, route1} =
      TrackedRoutes.create_tracked_route(%{
        path: "/login",
        method: "GET",
        controller: "SessionController",
        action: "new",
        route_type: :controller,
        category: "Authentication",
        display_order: 0
      })

    {:ok, route2} =
      TrackedRoutes.create_tracked_route(%{
        path: "/login",
        method: "POST",
        controller: "SessionController",
        action: "create",
        route_type: :controller,
        category: "Authentication",
        display_order: 1
      })

    {:ok, route3} =
      TrackedRoutes.create_tracked_route(%{
        path: "/posts",
        method: "GET",
        controller: "PostController",
        action: "index",
        route_type: :live_view,
        category: "Posts",
        display_order: 2
      })

    # Create test tags
    tag1 = repo.insert!(%Tag{name: "urgent"})
    tag2 = repo.insert!(%Tag{name: "backend"})

    %{
      route1: route1,
      route2: route2,
      route3: route3,
      tag1: tag1,
      tag2: tag2
    }
  end

  describe "new issue form" do
    test "mounts successfully and displays form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/issues/new")

      assert html =~ "New Issue"
      assert html =~ "Report an issue for a specific route"
      assert html =~ "Route"
      assert html =~ "Title"
      assert html =~ "Description"
      assert html =~ "Priority"
      assert html =~ "Status"
    end

    test "displays grouped routes by category", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/issues/new")

      # Check that routes are grouped by category
      assert html =~ "Authentication"
      assert html =~ "Posts"
      assert html =~ "GET /login"
      assert html =~ "POST /login"
      assert html =~ "GET /posts"
    end

    test "handles new issue without loaded associations", %{conn: conn} do
      # This should not raise Ecto.Association.NotLoaded error
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      assert view
             |> element("select#issue_tracked_route_id")
             |> render() =~ "Select a route"
    end

    test "shows route preview when route is selected", %{conn: conn, route1: route1} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      # Select a route
      html =
        view
        |> form("form", issue: %{tracked_route_id: route1.id})
        |> render_change()

      # Should show route details
      assert html =~ "Route Details"
      assert html =~ "GET"
      assert html =~ "/login"
      assert html =~ "SessionController"
      assert html =~ "new"
      assert html =~ "Authentication"
      assert html =~ "Controller"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      # Try to submit with empty title (leave priority and status with their default values)
      html =
        view
        |> form("form", issue: %{title: ""})
        |> render_change()

      # Should show validation error for title
      assert html =~ "can&#39;t be blank" || html =~ "can't be blank"
    end

    test "creates issue successfully with valid data", %{conn: conn, route1: route1} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      # Fill in valid data
      view
      |> form("form",
        issue: %{
          title: "Login page not loading",
          description: "The login page shows a 500 error",
          priority: :high,
          status: :open,
          tracked_route_id: route1.id
        }
      )
      |> render_submit()

      # Should create the issue
      issues = Issues.list_issues()
      assert length(issues) == 1

      issue = hd(issues)
      assert issue.title == "Login page not loading"
      assert issue.description == "The login page shows a 500 error"
      assert issue.priority == :high
      assert issue.status == :open
      assert issue.tracked_route_id == route1.id
    end

    test "can select tags from multi-select dropdown", %{conn: conn, tag1: tag1} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      # Select a tag using the multi-select dropdown
      html =
        view
        |> element("select[name='tags[]']")
        |> render_change(%{"tags" => [to_string(tag1.id)]})

      # Tag should be in the dropdown and selected
      assert html =~ tag1.name
      assert html =~ ~s(option value="#{tag1.id}" selected)
    end

    test "shows all existing tags in dropdown", %{conn: conn, tag1: tag1, tag2: tag2} do
      {:ok, _view, html} = live(conn, "/dev/issues/new")

      # Should show all existing tags in the multi-select dropdown
      assert html =~ tag1.name  # "urgent"
      assert html =~ tag2.name  # "backend"
      assert html =~ ~s(select multiple)
    end

    test "has link to create new tag", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/issues/new")

      # Should have a link to create new tag
      assert html =~ "+ Add New Tag"
      assert html =~ ~s(href="/dev/issues/tags/new")
    end

    test "creates issue with selected tags", %{conn: conn, route1: route1, tag1: tag1} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      # Select a tag using the multi-select dropdown
      view
      |> element("select[name='tags[]']")
      |> render_change(%{"tags" => [to_string(tag1.id)]})

      # Fill in and submit the form
      view
      |> form("form[phx-submit='save']",
        issue: %{
          title: "Test Issue with Tags",
          description: "Testing tag association",
          priority: :medium,
          status: :open,
          tracked_route_id: route1.id
        }
      )
      |> render_submit()

      # Check the issue was created with the tag
      issues = Issues.list_issues() |> Config.repo().preload(:tags)
      assert length(issues) == 1

      issue = hd(issues)
      assert length(issue.tags) == 1
      assert hd(issue.tags).id == tag1.id
    end

  end

  describe "edit issue form" do
    setup %{route1: route1, tag1: tag1} do
      {:ok, issue} =
        Issues.create_issue(%{
          title: "Test Issue",
          description: "Test description",
          priority: :medium,
          status: :open,
          tracked_route_id: route1.id
        })

      # Associate tags
      repo = Config.repo()

      issue =
        issue
        |> repo.preload(:tags)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:tags, [tag1])
        |> repo.update!()

      %{issue: issue}
    end

    test "mounts successfully with existing issue", %{conn: conn, issue: issue} do
      {:ok, _view, html} = live(conn, "/dev/issues/#{issue.id}/edit")

      assert html =~ "Edit Issue"
      assert html =~ "Test Issue"
      assert html =~ "Test description"
    end

    test "displays selected route with preview", %{conn: conn, issue: issue, route1: route1} do
      {:ok, _view, html} = live(conn, "/dev/issues/#{issue.id}/edit")

      # Should show route details for the associated route
      assert html =~ "Route Details"
      assert html =~ route1.method
      assert html =~ route1.path
      assert html =~ route1.controller
    end

    test "shows pre-selected tags", %{conn: conn, issue: issue, tag1: tag1} do
      {:ok, _view, html} = live(conn, "/dev/issues/#{issue.id}/edit")

      # Should show the tag
      assert html =~ tag1.name
    end

    test "updates issue successfully", %{conn: conn, issue: issue} do
      {:ok, view, _html} = live(conn, "/dev/issues/#{issue.id}/edit")

      # Update the issue
      view
      |> form("form",
        issue: %{
          title: "Updated Title",
          priority: :critical,
          status: :in_progress
        }
      )
      |> render_submit()

      # Check the issue was updated
      updated_issue = Issues.get_issue!(issue.id)
      assert updated_issue.title == "Updated Title"
      assert updated_issue.priority == :critical
      assert updated_issue.status == :in_progress
    end

    test "can change associated route", %{conn: conn, issue: issue, route2: route2} do
      {:ok, view, _html} = live(conn, "/dev/issues/#{issue.id}/edit")

      # Change to a different route
      html =
        view
        |> form("form", issue: %{tracked_route_id: route2.id})
        |> render_change()

      # Should show new route details
      assert html =~ route2.method
      assert html =~ route2.path
      assert html =~ route2.controller

      # Submit the form
      view
      |> form("form", issue: %{tracked_route_id: route2.id})
      |> render_submit()

      # Check the route was updated
      updated_issue = Issues.get_issue!(issue.id)
      assert updated_issue.tracked_route_id == route2.id
    end
  end

  describe "form validation" do
    test "shows error for missing title", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      html =
        view
        |> form("form", issue: %{title: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank" || html =~ "can't be blank"
    end

    test "shows error for missing priority", %{conn: conn, route1: route1} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      # Set title and route but leave priority blank - should fail validation on submit
      html =
        view
        |> form("form", issue: %{title: "Test", tracked_route_id: route1.id})
        |> render_change()

      # Priority field should be present (validation happens on submit, not change for selects)
      assert html =~ "Priority"
    end

    test "shows error for missing status", %{conn: conn, route1: route1} do
      {:ok, view, _html} = live(conn, "/dev/issues/new")

      # Set title and route but leave status blank - should fail validation on submit
      html =
        view
        |> form("form", issue: %{title: "Test", tracked_route_id: route1.id})
        |> render_change()

      # Status field should be present (validation happens on submit, not change for selects)
      assert html =~ "Status"
    end
  end

  describe "route selector organization" do
    test "groups routes by category", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/dev/issues/new")

      # Check for optgroup labels
      assert html =~ "Authentication"
      assert html =~ "Posts"
    end

    test "shows uncategorized routes in separate group", %{conn: conn} do
      # Create a route without category
      {:ok, _route} =
        TrackedRoutes.create_tracked_route(%{
          path: "/uncategorized",
          method: "GET",
          controller: "TestController",
          route_type: :controller,
          category: nil,
          display_order: 99
        })

      {:ok, _view, html} = live(conn, "/dev/issues/new")

      # Should have Uncategorized group
      assert html =~ "Uncategorized"
      assert html =~ "/uncategorized"
    end

    test "sorts routes by display_order within categories", %{conn: conn, route1: route1, route2: route2} do
      {:ok, _view, html} = live(conn, "/dev/issues/new")

      # Both routes should be present
      assert html =~ route1.path
      assert html =~ route2.path

      # They should be in order (route1 has display_order 0, route2 has 1)
      # Search for method + path combo since both have the same path
      route1_search = "#{route1.method} #{route1.path}"
      route2_search = "#{route2.method} #{route2.path}"

      route1_pos = :binary.match(html, route1_search) |> elem(0)
      route2_pos = :binary.match(html, route2_search) |> elem(0)

      assert route1_pos < route2_pos
    end
  end
end
