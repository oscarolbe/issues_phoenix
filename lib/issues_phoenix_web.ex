defmodule IssuesPhoenixWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use IssuesPhoenixWeb, :controller
      use IssuesPhoenixWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  @doc """
  Macro for host applications to mount Issues Phoenix routes.

  ## Usage

  In your host app's router.ex:

      use IssuesPhoenixWeb, :router

      scope "/" do
        pipe_through :browser
        issues_phoenix_routes "/dev/issues"
      end

  ## Options

  - `:repo` - The Ecto repo to use (default: from config)
  - `:layout` - Custom layout tuple (default: uses host's layout)

  ## CSS Scoping

  This macro automatically wraps routes with `class="issues-phoenix"` to scope
  our CSS and avoid conflicts with your host application styles.
  """
  defmacro issues_phoenix_routes(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router
        import Plug.Conn

        # Force the library's layouts by using a pipeline
        pipeline :issues_phoenix_layouts do
          plug :put_root_layout, html: {IssuesPhoenixWeb.Layouts, :root}
          plug :put_layout, html: {IssuesPhoenixWeb.Layouts, :app}
        end

        pipe_through :issues_phoenix_layouts

        # All LiveViews use the library's own layouts (root + app) to ensure proper
        # HTML structure and styling, avoiding conflicts with host app's layout
        live_session :issues_phoenix,
          on_mount: {IssuesPhoenixWeb.Hooks, :add_css_scope} do

          live "/", IssuesPhoenixWeb.IssuesLive.Index, :index
          live "/new", IssuesPhoenixWeb.IssuesLive.Form, :new
          live "/:id/edit", IssuesPhoenixWeb.IssuesLive.Form, :edit
          live "/routes", IssuesPhoenixWeb.IssuesLive.Routes, :index
          live "/tags/new", IssuesPhoenixWeb.TagsLive.Form, :new
        end
      end
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
      
      # Import our routing macro
      import IssuesPhoenixWeb, only: [issues_phoenix_routes: 1, issues_phoenix_routes: 2]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: IssuesPhoenixWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: IssuesPhoenixWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import IssuesPhoenixWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias IssuesPhoenixWeb.Layouts
    end
  end

  # Note: We don't use Phoenix.VerifiedRoutes (~p sigil) to avoid compile-time
  # dependency on the endpoint when used as a library dependency.
  # All paths in this library use plain strings instead.
  def verified_routes do
    quote do
      # No-op - using string paths instead of ~p sigil
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
