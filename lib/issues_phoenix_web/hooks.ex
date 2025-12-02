defmodule IssuesPhoenixWeb.Hooks do
  @moduledoc """
  LiveView hooks for Issues Phoenix.

  Provides on_mount hooks for:
  - Adding CSS scoping class to avoid conflicts with host app
  - Setting up configuration from host app
  """

  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:add_css_scope, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:add_css_class, :handle_params, fn _params, _url, socket ->
       {:cont,
        socket
        |> assign(:issues_phoenix_class, "issues-phoenix")
        |> assign(:assets_path, IssuesPhoenix.Config.assets_path())}
     end)}
  end

  @doc """
  Wraps LiveView content with CSS scoping class.
  
  ## Usage
  
  In your LiveView render function:
  
      def render(assigns) do
        ~H\"\"\"
        <div class={@issues_phoenix_class}>
          <!-- your content -->
        </div>
        \"\"\"
      end
  
  Or let the render_scoped/2 helper do it:
  
      def render(assigns) do
        render_scoped(assigns, fn assigns ->
          ~H\"\"\"
          <!-- your content -->
          \"\"\"
        end)
      end
  """
  def render_scoped(assigns, content_fun) when is_function(content_fun, 1) do
    assigns = assign_new(assigns, :issues_phoenix_class, fn -> "issues-phoenix" end)
    
    ~H"""
    <div class={@issues_phoenix_class}>
      <%= content_fun.(assigns) %>
    </div>
    """
  end
end
