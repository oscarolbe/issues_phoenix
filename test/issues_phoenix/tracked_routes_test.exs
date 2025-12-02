defmodule IssuesPhoenix.TrackedRoutesTest do
  use IssuesPhoenix.DataCase, async: true

  alias IssuesPhoenix.TrackedRoutes
  alias IssuesPhoenix.Schemas.TrackedRoute

  describe "list_tracked_routes/1" do
    setup do
      route1 =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/users",
          method: "GET",
          controller: "UserController",
          route_type: :controller,
          enabled: true
        })
        |> Repo.insert!()

      route2 =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/posts",
          method: "GET",
          controller: "PostController",
          route_type: :controller,
          enabled: false
        })
        |> Repo.insert!()

      route3 =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/demo",
          method: "GET",
          controller: "DemoLive",
          route_type: :live_view,
          enabled: true
        })
        |> Repo.insert!()

      %{route1: route1, route2: route2, route3: route3}
    end

    test "returns all tracked routes", %{route1: route1, route2: route2, route3: route3} do
      routes = TrackedRoutes.list_tracked_routes()

      assert length(routes) == 3
      route_ids = Enum.map(routes, & &1.id)
      assert route1.id in route_ids
      assert route2.id in route_ids
      assert route3.id in route_ids
    end

    test "orders routes by display_order, then path" do
      # Add category and display_order to existing routes
      [route1, route2, route3] = TrackedRoutes.list_tracked_routes()

      # Update routes with different categories and orders
      TrackedRoutes.update_tracked_route(route1, %{category: "Login", display_order: 2})
      TrackedRoutes.update_tracked_route(route2, %{category: "Login", display_order: 1})
      TrackedRoutes.update_tracked_route(route3, %{category: "Posts", display_order: 0})

      routes = TrackedRoutes.list_tracked_routes()

      # Should be ordered by display_order: Posts (0), Login (1), Login (2)
      assert Enum.at(routes, 0).category == "Posts"
      assert Enum.at(routes, 0).display_order == 0

      assert Enum.at(routes, 1).category == "Login"
      assert Enum.at(routes, 1).display_order == 1

      assert Enum.at(routes, 2).category == "Login"
      assert Enum.at(routes, 2).display_order == 2
    end

    test "filters by enabled status", %{route1: route1, route3: route3} do
      routes = TrackedRoutes.list_tracked_routes(enabled: true)

      assert length(routes) == 2
      route_ids = Enum.map(routes, & &1.id)
      assert route1.id in route_ids
      assert route3.id in route_ids
    end

    test "filters by route_type", %{route3: route3} do
      routes = TrackedRoutes.list_tracked_routes(route_type: :live_view)

      assert length(routes) == 1
      assert hd(routes).id == route3.id
    end

    test "combines multiple filters", %{route1: route1} do
      routes = TrackedRoutes.list_tracked_routes(enabled: true, route_type: :controller)

      assert length(routes) == 1
      assert hd(routes).id == route1.id
    end

    test "returns empty list when no routes match filters" do
      routes = TrackedRoutes.list_tracked_routes(enabled: false, route_type: :live_view)

      assert routes == []
    end
  end

  describe "get_tracked_route!/1" do
    test "returns tracked route when it exists" do
      route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller
        })
        |> Repo.insert!()

      result = TrackedRoutes.get_tracked_route!(route.id)

      assert result.id == route.id
      assert result.path == "/test"
    end

    test "raises Ecto.NoResultsError when route doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        TrackedRoutes.get_tracked_route!(999_999)
      end
    end
  end

  describe "get_by_path_and_method/2" do
    test "returns tracked route when found" do
      route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/unique",
          method: "POST",
          controller: "UniqueController",
          route_type: :controller
        })
        |> Repo.insert!()

      result = TrackedRoutes.get_by_path_and_method("/unique", "POST")

      assert result.id == route.id
      assert result.path == "/unique"
      assert result.method == "POST"
    end

    test "returns nil when not found" do
      result = TrackedRoutes.get_by_path_and_method("/nonexistent", "GET")

      assert result == nil
    end

    test "distinguishes routes by method" do
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/same",
        method: "GET",
        controller: "Controller",
        route_type: :controller
      })
      |> Repo.insert!()

      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/same",
        method: "POST",
        controller: "Controller",
        route_type: :controller
      })
      |> Repo.insert!()

      get_result = TrackedRoutes.get_by_path_and_method("/same", "GET")
      post_result = TrackedRoutes.get_by_path_and_method("/same", "POST")

      assert get_result.method == "GET"
      assert post_result.method == "POST"
      assert get_result.id != post_result.id
    end
  end

  describe "create_tracked_route/1" do
    test "creates tracked route with valid attributes" do
      attrs = %{
        path: "/new",
        method: "GET",
        controller: "NewController",
        route_type: :controller
      }

      assert {:ok, %TrackedRoute{} = route} = TrackedRoutes.create_tracked_route(attrs)
      assert route.path == "/new"
      assert route.method == "GET"
      assert route.controller == "NewController"
      assert route.route_type == :controller
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{path: nil}

      assert {:error, %Ecto.Changeset{}} = TrackedRoutes.create_tracked_route(attrs)
    end

    test "sets default enabled to true" do
      attrs = %{
        path: "/default",
        method: "GET",
        controller: "DefaultController",
        route_type: :controller
      }

      assert {:ok, route} = TrackedRoutes.create_tracked_route(attrs)
      assert route.enabled == true
    end
  end

  describe "update_tracked_route/2" do
    test "updates tracked route with valid attributes" do
      route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/original",
          method: "GET",
          controller: "OriginalController",
          route_type: :controller
        })
        |> Repo.insert!()

      attrs = %{controller: "UpdatedController", enabled: false}

      assert {:ok, updated} = TrackedRoutes.update_tracked_route(route, attrs)
      assert updated.id == route.id
      assert updated.controller == "UpdatedController"
      assert updated.enabled == false
    end

    test "returns error changeset with invalid attributes" do
      route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller
        })
        |> Repo.insert!()

      attrs = %{path: nil}

      assert {:error, %Ecto.Changeset{}} = TrackedRoutes.update_tracked_route(route, attrs)
    end
  end

  describe "delete_tracked_route/1" do
    test "deletes the tracked route" do
      route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/delete",
          method: "GET",
          controller: "DeleteController",
          route_type: :controller
        })
        |> Repo.insert!()

      assert {:ok, deleted} = TrackedRoutes.delete_tracked_route(route)
      assert deleted.id == route.id

      assert_raise Ecto.NoResultsError, fn ->
        TrackedRoutes.get_tracked_route!(route.id)
      end
    end
  end

  describe "change_tracked_route/2" do
    test "returns a changeset for tracking changes" do
      route = %TrackedRoute{}

      changeset = TrackedRoutes.change_tracked_route(route)

      assert %Ecto.Changeset{} = changeset
      assert changeset.data == route
    end

    test "returns changeset with attributes" do
      route = %TrackedRoute{}
      attrs = %{path: "/new"}

      changeset = TrackedRoutes.change_tracked_route(route, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.path == "/new"
    end
  end

  describe "sync_from_scan/1" do
    test "creates new tracked routes from scan results" do
      scanned_routes = [
        %{path: "/users", method: "GET", controller: "UserController", action: :index, type: :controller},
        %{path: "/posts", method: "GET", controller: "PostController", action: :index, type: :controller}
      ]

      assert {:ok, result} = TrackedRoutes.sync_from_scan(scanned_routes)
      assert result.created == 2
      assert result.updated == 0

      routes = TrackedRoutes.list_tracked_routes()
      assert length(routes) == 2
    end

    test "updates existing tracked routes from scan results" do
      # Create an existing route
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/existing",
        method: "GET",
        controller: "OldController",
        route_type: :controller
      })
      |> Repo.insert!()

      # Scan with updated controller name
      scanned_routes = [
        %{path: "/existing", method: "GET", controller: "NewController", action: :index, type: :controller}
      ]

      assert {:ok, result} = TrackedRoutes.sync_from_scan(scanned_routes)
      assert result.created == 0
      assert result.updated == 1

      updated = TrackedRoutes.get_by_path_and_method("/existing", "GET")
      assert updated.controller == "NewController"
    end

    test "creates and updates in same sync" do
      # Create an existing route
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/old",
        method: "GET",
        controller: "OldController",
        route_type: :controller
      })
      |> Repo.insert!()

      scanned_routes = [
        %{path: "/old", method: "GET", controller: "UpdatedController", action: :index, type: :controller},
        %{path: "/new", method: "GET", controller: "NewController", action: :index, type: :controller}
      ]

      assert {:ok, result} = TrackedRoutes.sync_from_scan(scanned_routes)
      assert result.created == 1
      assert result.updated == 1

      routes = TrackedRoutes.list_tracked_routes()
      assert length(routes) == 2
    end

    test "handles routes with nil action" do
      scanned_routes = [
        %{path: "/test", method: "GET", controller: "TestController", action: nil, type: :controller}
      ]

      assert {:ok, result} = TrackedRoutes.sync_from_scan(scanned_routes)
      assert result.created == 1

      route = TrackedRoutes.get_by_path_and_method("/test", "GET")
      # Empty string gets stored as nil in database
      assert route.action == nil || route.action == ""
    end

    test "handles LiveView routes" do
      scanned_routes = [
        %{path: "/demo", method: "GET", controller: "DemoLive", action: :index, type: :live_view}
      ]

      assert {:ok, result} = TrackedRoutes.sync_from_scan(scanned_routes)
      assert result.created == 1

      route = TrackedRoutes.get_by_path_and_method("/demo", "GET")
      assert route.route_type == :live_view
    end
  end

  describe "tracked_route_identifiers/0" do
    test "returns list of path and method tuples" do
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/users",
        method: "GET",
        controller: "UserController",
        route_type: :controller
      })
      |> Repo.insert!()

      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/posts",
        method: "POST",
        controller: "PostController",
        route_type: :controller
      })
      |> Repo.insert!()

      identifiers = TrackedRoutes.tracked_route_identifiers()

      assert length(identifiers) == 2
      assert {"/users", "GET"} in identifiers
      assert {"/posts", "POST"} in identifiers
    end

    test "returns empty list when no tracked routes" do
      identifiers = TrackedRoutes.tracked_route_identifiers()

      assert identifiers == []
    end
  end

  describe "list_grouped_by_category/1" do
    test "groups routes by category" do
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/login",
        method: "GET",
        controller: "LoginController",
        route_type: :controller,
        category: "Login",
        display_order: 1
      })
      |> Repo.insert!()

      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/login_rfc",
        method: "POST",
        controller: "LoginController",
        route_type: :controller,
        category: "Login",
        display_order: 2
      })
      |> Repo.insert!()

      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/posts",
        method: "GET",
        controller: "PostController",
        route_type: :controller,
        category: "Posts",
        display_order: 1
      })
      |> Repo.insert!()

      grouped = TrackedRoutes.list_grouped_by_category()

      assert is_map(grouped)
      assert Map.has_key?(grouped, "Login")
      assert Map.has_key?(grouped, "Posts")

      assert length(grouped["Login"]) == 2
      assert length(grouped["Posts"]) == 1
    end

    test "groups routes without category under nil" do
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/uncategorized",
        method: "GET",
        controller: "TestController",
        route_type: :controller
      })
      |> Repo.insert!()

      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/categorized",
        method: "GET",
        controller: "TestController",
        route_type: :controller,
        category: "Test"
      })
      |> Repo.insert!()

      grouped = TrackedRoutes.list_grouped_by_category()

      assert Map.has_key?(grouped, nil)
      assert Map.has_key?(grouped, "Test")

      assert length(grouped[nil]) == 1
      assert length(grouped["Test"]) == 1
    end

    test "maintains display order within each category" do
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/login2",
        method: "GET",
        controller: "LoginController",
        route_type: :controller,
        category: "Login",
        display_order: 2
      })
      |> Repo.insert!()

      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/login1",
        method: "GET",
        controller: "LoginController",
        route_type: :controller,
        category: "Login",
        display_order: 1
      })
      |> Repo.insert!()

      grouped = TrackedRoutes.list_grouped_by_category()
      login_routes = grouped["Login"]

      assert Enum.at(login_routes, 0).display_order == 1
      assert Enum.at(login_routes, 1).display_order == 2
    end

    test "returns empty map when no routes" do
      grouped = TrackedRoutes.list_grouped_by_category()

      assert grouped == %{}
    end
  end
end
