defmodule IssuesPhoenixWeb.Router do
  @moduledoc false
  # Standalone dev/test harness router. Mounts the library exactly the way the
  # README tells host apps to.
  use Phoenix.Router, helpers: false
  use IssuesPhoenixWeb, :router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", IssuesPhoenixWeb do
    pipe_through :browser

    if Mix.env() == :test do
      get "/dummy", DummyController, :index
    end

    live "/demo", DemoLive
  end

  scope "/" do
    pipe_through :browser

    issues_phoenix_routes "/dev/issues"
  end
end
