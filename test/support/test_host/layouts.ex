defmodule TestHost.Layouts do
  @moduledoc "The host app's root layout. IssuesPhoenix pages must not render inside it."
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <body>
        <div id="host-root-layout">{@inner_content}</div>
      </body>
    </html>
    """
  end
end
