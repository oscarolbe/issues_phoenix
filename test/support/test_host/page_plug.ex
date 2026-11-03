defmodule TestHost.PagePlug do
  @moduledoc "A route that only exists in the host app."
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts), do: Plug.Conn.send_resp(conn, 200, "host page")
end
