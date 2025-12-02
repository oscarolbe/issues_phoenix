defmodule IssuesPhoenix.TrackedRouteTest do
  use IssuesPhoenix.DataCase, async: true

  alias IssuesPhoenix.Schemas.TrackedRoute

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/users",
          method: "GET",
          controller: "UserController",
          route_type: :controller
        })

      assert changeset.valid?
    end

    test "invalid changeset when path is missing" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          method: "GET",
          controller: "UserController",
          route_type: :controller
        })

      refute changeset.valid?
      assert %{path: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset when method is missing" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/users",
          controller: "UserController",
          route_type: :controller
        })

      refute changeset.valid?
      assert %{method: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset when controller is missing" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/users",
          method: "GET",
          route_type: :controller
        })

      refute changeset.valid?
      assert %{controller: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset when route_type is missing" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/users",
          method: "GET",
          controller: "UserController"
        })

      refute changeset.valid?
      assert %{route_type: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid route_type values" do
      valid_types = [:controller, :live_view]

      for type <- valid_types do
        changeset =
          TrackedRoute.changeset(%TrackedRoute{}, %{
            path: "/test",
            method: "GET",
            controller: "TestController",
            route_type: type
          })

        assert changeset.valid?, "Expected #{type} to be valid"
      end
    end

    test "rejects invalid route_type values" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :invalid_type
        })

      refute changeset.valid?
      assert %{route_type: [_]} = errors_on(changeset)
    end

    test "accepts string route_type values and converts to atoms" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: "live_view"
        })

      assert changeset.valid?
      assert changeset.changes.route_type == :live_view
    end

    test "sets default enabled to true" do
      route = %TrackedRoute{}
      assert route.enabled == true
    end

    test "accepts enabled as false" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller,
          enabled: false
        })

      assert changeset.valid?
      assert changeset.changes.enabled == false
    end

    test "accepts optional action field" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller,
          action: "index"
        })

      assert changeset.valid?
      assert changeset.changes.action == "index"
    end

    test "accepts optional category field" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller,
          category: "Login"
        })

      assert changeset.valid?
      assert changeset.changes.category == "Login"
    end

    test "sets default display_order to 0" do
      route = %TrackedRoute{}
      assert route.display_order == 0
    end

    test "accepts custom display_order" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller,
          display_order: 5
        })

      assert changeset.valid?
      assert changeset.changes.display_order == 5
    end

    test "validates display_order is non-negative" do
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/test",
          method: "GET",
          controller: "TestController",
          route_type: :controller,
          display_order: -1
        })

      refute changeset.valid?
      assert %{display_order: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "unique constraint on path and method combination" do
      # First create a tracked route
      _tracked_route =
        %TrackedRoute{}
        |> TrackedRoute.changeset(%{
          path: "/unique",
          method: "GET",
          controller: "TestController",
          route_type: :controller
        })
        |> Repo.insert!()

      # Try to create another with the same path and method
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/unique",
          method: "GET",
          controller: "AnotherController",
          route_type: :controller
        })

      assert {:error, failed_changeset} = Repo.insert(changeset)
      assert %{path: ["has already been taken"]} = errors_on(failed_changeset)
    end

    test "allows same path with different method" do
      # Create a tracked route
      %TrackedRoute{}
      |> TrackedRoute.changeset(%{
        path: "/same",
        method: "GET",
        controller: "TestController",
        route_type: :controller
      })
      |> Repo.insert!()

      # Create another with same path but different method
      changeset =
        TrackedRoute.changeset(%TrackedRoute{}, %{
          path: "/same",
          method: "POST",
          controller: "TestController",
          route_type: :controller
        })

      assert {:ok, _route} = Repo.insert(changeset)
    end
  end

  describe "associations" do
    test "has issues association" do
      assert %Ecto.Association.Has{} = TrackedRoute.__schema__(:association, :issues)
    end
  end

  describe "from_route_scan/1" do
    test "creates TrackedRoute from route scan result with controller" do
      route_info = %{
        path: "/users",
        method: "GET",
        controller: "UserController",
        action: :index,
        type: :controller
      }

      tracked_route = TrackedRoute.from_route_scan(route_info)

      assert tracked_route.path == "/users"
      assert tracked_route.method == "GET"
      assert tracked_route.controller == "UserController"
      assert tracked_route.action == "index"
      assert tracked_route.route_type == :controller
    end

    test "creates TrackedRoute from route scan result with live_view" do
      route_info = %{
        path: "/demo",
        method: "GET",
        controller: "DemoLive",
        action: :index,
        type: :live_view
      }

      tracked_route = TrackedRoute.from_route_scan(route_info)

      assert tracked_route.path == "/demo"
      assert tracked_route.method == "GET"
      assert tracked_route.controller == "DemoLive"
      assert tracked_route.action == "index"
      assert tracked_route.route_type == :live_view
    end

    test "handles nil action field" do
      route_info = %{
        path: "/test",
        method: "GET",
        controller: "TestController",
        action: nil,
        type: :controller
      }

      tracked_route = TrackedRoute.from_route_scan(route_info)

      assert tracked_route.action == ""
    end

    test "converts action to string" do
      route_info = %{
        path: "/test",
        method: "GET",
        controller: "TestController",
        action: :show,
        type: :controller
      }

      tracked_route = TrackedRoute.from_route_scan(route_info)

      assert tracked_route.action == "show"
      assert is_binary(tracked_route.action)
    end
  end
end
