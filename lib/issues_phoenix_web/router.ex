defmodule IssuesPhoenixWeb.Router do
  use IssuesPhoenixWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {IssuesPhoenixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", IssuesPhoenixWeb do
    pipe_through :browser

    # get "/", PageController, :home
    if Mix.env() == :test do
      get "/dummy", DummyController, :index
    end
    live "/demo", DemoLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", IssuesPhoenixWeb do
  #   pipe_through :api
  # end

  # Enable IssuesPhoenix dashboard in development
  if Application.compile_env(:issues_phoenix, :dev_routes) do
    issues_phoenix_routes "/dev/issues"
  end
end
