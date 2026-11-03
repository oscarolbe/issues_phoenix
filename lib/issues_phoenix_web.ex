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

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt pico.min.css)

  @doc """
  Mounts the IssuesPhoenix pages in a host router.

  ## Usage

  In your host app's router.ex:

      use MyAppWeb, :router
      use IssuesPhoenixWeb, :router

      scope "/" do
        pipe_through :browser
        issues_phoenix_routes "/dev/issues"
      end

  The pages work under any path and nested scope (e.g. `scope "/admin"` +
  `issues_phoenix_routes "/issues"` serves them at `/admin/issues`).

  ## Options

    * `:on_mount` - extra `on_mount` hooks for the pages' `live_session`, e.g.
      your authentication hook. They run after IssuesPhoenix's own hook.
    * `:live_session_name` - name of the generated `live_session`
      (default `:issues_phoenix`). Only needed when mounting more than once.

  Pages always render with IssuesPhoenix's own root layout, regardless of the
  `put_root_layout` in your pipeline, so host styles don't leak in.
  """
  defmacro issues_phoenix_routes(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      base_path = Phoenix.Router.scoped_path(__MODULE__, path)

      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 3, live_session: 3]

        live_session Keyword.get(opts, :live_session_name, :issues_phoenix),
          root_layout: {IssuesPhoenixWeb.Layouts, :root},
          on_mount:
            [{IssuesPhoenixWeb.Hooks, {:init, base_path}}] ++
              List.wrap(Keyword.get(opts, :on_mount, [])) do
          live "/", IssuesPhoenixWeb.IssuesLive.Index, :index
          live "/new", IssuesPhoenixWeb.IssuesLive.Form, :new
          live "/:id/edit", IssuesPhoenixWeb.IssuesLive.Form, :edit
          live "/routes", IssuesPhoenixWeb.IssuesLive.Routes, :index
          live "/tags/new", IssuesPhoenixWeb.TagsLive.Form, :new
        end
      end
    end
  end

  @doc """
  For host routers: imports `issues_phoenix_routes/2`.

  It deliberately does not `use Phoenix.Router`; your router already does, and
  using it twice makes the second set of route clauses shadow your routes.
  """
  def router do
    quote do
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
