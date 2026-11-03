defmodule IssuesPhoenixWeb.HostIntegrationTest do
  @moduledoc """
  End-to-end tests of IssuesPhoenix mounted inside a host app
  (`TestHost.Router` at `/admin/tracker`, using `TestHost.Repo`).
  """
  use IssuesPhoenixWeb.HostCase

  alias IssuesPhoenix.{Issues, TrackedRoutes}
  alias IssuesPhoenix.Schemas.{Issue, Tag}

  defp tracked_route!(attrs \\ %{}) do
    {:ok, route} =
      attrs
      |> Enum.into(%{
        path: "/host/page",
        method: "GET",
        controller: "TestHost.PagePlug",
        route_type: :controller
      })
      |> TrackedRoutes.create_tracked_route()

    route
  end

  describe "repo configuration" do
    test "contexts read and write through the host repo" do
      {:ok, issue} = Issues.create_issue(%{title: "From host"})

      assert Repo.get!(Issue, issue.id).title == "From host"
      assert [%Issue{title: "From host"}] = Issues.list_issues()
      assert %{total: 1, open: 1} = Issues.stats()
    end
  end

  describe "mounting" do
    test "host on_mount hooks run, so hosts can protect the pages", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"admin" => false})

      assert {:error, {:redirect, %{to: "/host/page"}}} = live(conn, "/admin/tracker")
    end
  end

  describe "index page" do
    test "renders with the host repo and links under the mount path", %{conn: conn} do
      tag = Repo.insert!(%Tag{name: "host-tag"})
      route = tracked_route!()
      {:ok, issue} = Issues.create_issue(%{title: "Broken page", tracked_route_id: route.id})

      issue
      |> Repo.preload(:tags)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, [tag])
      |> Repo.update!()

      {:ok, view, _html} = live(conn, "/admin/tracker")

      assert has_element?(view, "td", "Broken page")
      assert has_element?(view, ~s|a[href="/admin/tracker/new"]|)
      assert has_element?(view, ~s|a[href="/admin/tracker/routes"]|)
      assert has_element?(view, ~s|a[href="/admin/tracker/#{issue.id}/edit"]|)
      refute has_element?(view, ~s|a[href^="/dev/issues"]|)
    end

    test "uses the library root layout instead of the host's", %{conn: conn} do
      html = conn |> get("/admin/tracker") |> html_response(200)
      doc = LazyHTML.from_document(html)

      assert LazyHTML.query(doc, "#host-root-layout") |> Enum.empty?()
      refute LazyHTML.query(doc, ~s|link[href="/issues_phoenix/pico.min.css"]|) |> Enum.empty?()
    end

    test "the stylesheet the layout links to is actually served", %{conn: conn} do
      assert conn |> get("/issues_phoenix/pico.min.css") |> response(200) =~ "pico"
    end

    test "filtering by an unknown status does not create atoms or crash", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/tracker")

      view
      |> element("form[phx-change=filter]")
      |> render_change(%{"status" => "definitely_not_a_status_#{System.unique_integer()}"})

      assert render(view)
    end
  end

  describe "issue form" do
    test "creates an issue with tags through the host repo and returns to the mount path",
         %{conn: conn} do
      route = tracked_route!()
      tag = Repo.insert!(%Tag{name: "ui"})

      {:ok, view, _html} = live(conn, "/admin/tracker/new")

      assert has_element?(view, ~s|a[href="/admin/tracker"]|)
      assert has_element?(view, ~s|a[href="/admin/tracker/tags/new"]|)

      view
      |> element(~s|select[name="tags[]"]|)
      |> render_change(%{"tags" => [to_string(tag.id)]})

      assert {:error, {:live_redirect, %{to: "/admin/tracker"}}} =
               view
               |> form("form[phx-submit=save]",
                 issue: %{title: "New from host", tracked_route_id: route.id}
               )
               |> render_submit()

      issue = Repo.get_by!(Issue, title: "New from host") |> Repo.preload(:tags)
      assert [%Tag{name: "ui"}] = issue.tags
    end

    test "edits an existing issue", %{conn: conn} do
      {:ok, issue} = Issues.create_issue(%{title: "Old"})

      {:ok, view, _html} = live(conn, "/admin/tracker/#{issue.id}/edit")

      assert {:error, {:live_redirect, %{to: "/admin/tracker"}}} =
               view
               |> form("form[phx-submit=save]", issue: %{title: "New"})
               |> render_submit()

      assert Repo.get!(Issue, issue.id).title == "New"
    end
  end

  describe "tag form" do
    test "creates a tag through the host repo and returns to the mount path", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/tracker/tags/new")

      assert {:error, {:live_redirect, %{to: "/admin/tracker/new"}}} =
               view
               |> form("form[phx-submit=save]", tag: %{name: "backend"})
               |> render_submit()

      assert Repo.get_by(Tag, name: "backend")
    end
  end

  describe "routes page" do
    test "scans the host router it is mounted in, not the library's router", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/tracker/routes")

      assert has_element?(view, ~s|button[phx-value-path="/host/page"]|)
      assert has_element?(view, ~s|button[phx-value-path="/admin/tracker/new"]|)
      refute has_element?(view, ~s|button[phx-value-path="/demo"]|)
      assert has_element?(view, ~s|a[href="/admin/tracker"]|)
    end

    @tag issues_phoenix_env: [router: IssuesPhoenixWeb.Router]
    test "an explicitly configured router still wins", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/tracker/routes")

      assert has_element?(view, ~s|button[phx-value-path="/demo"]|)
      refute has_element?(view, ~s|button[phx-value-path="/host/page"]|)
    end

    test "tracking a host route stores it in the host repo", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/tracker/routes")

      view
      |> element(~s|button[phx-click=track_route][phx-value-path="/host/page"]|)
      |> render_click()

      assert TrackedRoutes.get_by_path_and_method("/host/page", "GET")
    end
  end
end
