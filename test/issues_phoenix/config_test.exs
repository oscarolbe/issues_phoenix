defmodule IssuesPhoenix.ConfigTest do
  # Mutates application env
  use ExUnit.Case, async: false

  alias IssuesPhoenix.Config

  setup do
    previous = Application.get_all_env(:issues_phoenix)

    on_exit(fn ->
      for {key, _} <- Application.get_all_env(:issues_phoenix),
          not Keyword.has_key?(previous, key),
          do: Application.delete_env(:issues_phoenix, key)

      for {key, value} <- previous, do: Application.put_env(:issues_phoenix, key, value)
    end)
  end

  describe "repo/0" do
    test "returns the configured repo" do
      Application.put_env(:issues_phoenix, :repo, TestHost.Repo)
      assert Config.repo() == TestHost.Repo
    end

    test "raises a helpful error instead of silently falling back to a second repo" do
      Application.delete_env(:issues_phoenix, :repo)

      assert_raise ArgumentError, ~r/config :issues_phoenix, repo: MyApp.Repo/, fn ->
        Config.repo()
      end
    end
  end

  describe "router/0" do
    test "is nil unless configured, so the mounting router is used" do
      Application.delete_env(:issues_phoenix, :router)
      assert Config.router() == nil

      Application.put_env(:issues_phoenix, :router, TestHost.Router)
      assert Config.router() == TestHost.Router
    end
  end

  describe "prefix/0" do
    test "defaults to nil (the repo's default schema)" do
      Application.delete_env(:issues_phoenix, :prefix)
      assert Config.prefix() == nil
    end
  end

  describe "assets_path/0" do
    test "defaults to the path the README tells hosts to serve" do
      Application.delete_env(:issues_phoenix, :assets_path)
      assert Config.assets_path() == "/issues_phoenix"
    end
  end
end
