defmodule TestHost.Router do
  @moduledoc """
  A host application's router that mounts IssuesPhoenix under a nested scope,
  the way a real app would (`/admin` + `/tracker`), with its own root layout
  in the browser pipeline.
  """
  # What `use MyAppWeb, :router` expands to in a `mix phx.new` app...
  use Phoenix.Router, helpers: false
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  # ...followed by the line the README asks hosts to add.
  use IssuesPhoenixWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TestHost.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    get "/host/page", TestHost.PagePlug, []
  end

  scope "/admin" do
    pipe_through :browser

    issues_phoenix_routes "/tracker", on_mount: [{TestHost.AuthHook, :require_admin}]
  end
end
