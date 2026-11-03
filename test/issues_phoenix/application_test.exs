defmodule IssuesPhoenix.ApplicationTest do
  use ExUnit.Case, async: true

  alias IssuesPhoenix.Application, as: App

  test "as a dependency of a host app, the library starts no processes (no second repo)" do
    assert App.children([]) == []
    assert App.children(repo: TestHost.Repo) == []
  end

  test "standalone mode starts the dev harness: repo, pubsub and endpoint" do
    children = App.children(standalone: true)

    assert IssuesPhoenix.Repo in children
    assert IssuesPhoenixWeb.Endpoint in children
    assert {Phoenix.PubSub, name: IssuesPhoenix.PubSub} in children
  end
end
