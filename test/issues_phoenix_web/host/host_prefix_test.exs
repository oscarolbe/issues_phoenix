defmodule IssuesPhoenixWeb.HostPrefixTest do
  @moduledoc """
  A host that already has `issues`/`tags` tables can keep IssuesPhoenix in its
  own Postgres schema via `config :issues_phoenix, prefix: "..."`.
  """
  use IssuesPhoenixWeb.HostCase

  alias IssuesPhoenix.{Issues, TrackedRoutes}
  alias IssuesPhoenix.Schemas.{Issue, Tag, TrackedRoute}

  @prefix "issues_phoenix_prefixed"
  @moduletag issues_phoenix_env: [prefix: @prefix]

  defp count(schema, prefix), do: Repo.aggregate(schema, :count, prefix: prefix)

  test "contexts never touch the host's own tables in the default schema" do
    {:ok, route} =
      TrackedRoutes.create_tracked_route(%{
        path: "/x",
        method: "GET",
        controller: "X",
        route_type: :controller
      })

    {:ok, issue} = Issues.create_issue(%{title: "Prefixed", tracked_route_id: route.id})

    assert count(Issue, @prefix) == 1
    assert count(TrackedRoute, @prefix) == 1
    assert count(Issue, "public") == 0
    assert count(TrackedRoute, "public") == 0

    assert Issues.get_issue!(issue.id).title == "Prefixed"
    assert [%Issue{}] = Issues.list_issues()
    assert %{total: 1} = Issues.stats()
    assert TrackedRoutes.get_by_path_and_method("/x", "GET")
  end

  test "creating an issue with tags from the UI stays inside the prefix", %{conn: conn} do
    {:ok, view, _} = live(conn, "/admin/tracker/tags/new")

    view |> form("form[phx-submit=save]", tag: %{name: "p-tag"}) |> render_submit()

    assert count(Tag, @prefix) == 1
    assert count(Tag, "public") == 0
    tag = Repo.get_by!(Tag, [name: "p-tag"], prefix: @prefix)

    {:ok, view, _} = live(conn, "/admin/tracker/new")
    view |> element(~s|select[name="tags[]"]|) |> render_change(%{"tags" => [to_string(tag.id)]})
    view |> form("form[phx-submit=save]", issue: %{title: "Tagged"}) |> render_submit()

    issue = Repo.get_by!(Issue, [title: "Tagged"], prefix: @prefix) |> Repo.preload(:tags)
    assert [%Tag{name: "p-tag"}] = issue.tags
    assert count(Issue, "public") == 0

    {:ok, view, _} = live(conn, "/admin/tracker")
    assert has_element?(view, "td", "Tagged")
  end
end
