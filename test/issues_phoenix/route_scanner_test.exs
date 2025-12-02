defmodule IssuesPhoenix.RouteScannerTest do
  use ExUnit.Case, async: true

  alias IssuesPhoenix.RouteScanner

  describe "scan_routes/1" do
    test "finds controller routes" do
      routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      assert Enum.any?(routes, fn r ->
               r.path == "/dummy" && r.type == :controller
             end)
    end

    test "finds LiveView routes" do
      routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      assert Enum.any?(routes, fn r ->
               r.path == "/demo" && r.type == :live_view
             end)
    end

    test "filters out internal Phoenix routes" do
      routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      refute Enum.any?(routes, fn r ->
               String.starts_with?(r.path, "/_")
             end)
    end

    test "filters out LiveDashboard routes" do
      routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      refute Enum.any?(routes, fn r ->
               String.contains?(r.controller, "LiveDashboard")
             end)
    end

    test "includes route type information" do
      routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      assert Enum.all?(routes, fn r ->
               r.type in [:controller, :live_view]
             end)
    end

    test "includes HTTP method information" do
      routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      assert Enum.all?(routes, fn r ->
               is_binary(r.method)
             end)
    end

    test "returns unique routes by path and method" do
      routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      unique_keys =
        routes
        |> Enum.map(fn r -> {r.path, r.method} end)
        |> Enum.uniq()

      assert length(unique_keys) == length(routes)
    end
  end

  describe "scan_untracked_routes/2" do
    test "returns all routes when no tracked routes provided" do
      routes = RouteScanner.scan_untracked_routes(IssuesPhoenixWeb.Router, [])
      all_routes = RouteScanner.scan_routes(IssuesPhoenixWeb.Router)

      assert length(routes) == length(all_routes)
    end

    test "filters out tracked routes" do
      tracked = [{"/", "GET"}, {"/demo", "GET"}]
      routes = RouteScanner.scan_untracked_routes(IssuesPhoenixWeb.Router, tracked)

      refute Enum.any?(routes, fn r -> r.path == "/" && r.method == "GET" end)
      refute Enum.any?(routes, fn r -> r.path == "/demo" && r.method == "GET" end)
    end

    test "returns error for invalid router" do
      result = RouteScanner.scan_untracked_routes(NonExistentRouter, [])

      assert {:error, message} = result
      assert message =~ "not a valid Phoenix router"
    end
  end

  describe "group_by_controller/1" do
    test "groups routes by controller name" do
      routes = [
        %{controller: "UserController", path: "/users", method: "GET"},
        %{controller: "UserController", path: "/users/:id", method: "GET"},
        %{controller: "PostController", path: "/posts", method: "GET"}
      ]

      grouped = RouteScanner.group_by_controller(routes)

      assert length(grouped) == 2
      assert {"UserController", user_routes} = List.keyfind(grouped, "UserController", 0)
      assert length(user_routes) == 2
    end

    test "sorts grouped controllers alphabetically" do
      routes = [
        %{controller: "ZController", path: "/z"},
        %{controller: "AController", path: "/a"},
        %{controller: "MController", path: "/m"}
      ]

      grouped = RouteScanner.group_by_controller(routes)
      controller_names = Enum.map(grouped, fn {name, _} -> name end)

      assert controller_names == ["AController", "MController", "ZController"]
    end

    test "handles empty route list" do
      grouped = RouteScanner.group_by_controller([])

      assert grouped == []
    end
  end
end
