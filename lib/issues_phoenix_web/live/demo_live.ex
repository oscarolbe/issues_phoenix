defmodule IssuesPhoenixWeb.DemoLive do
  use IssuesPhoenixWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :message, "Hello from LiveView!")}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Demo LiveView</h1>
      <p><%= @message %></p>
    </div>
    """
  end
end
