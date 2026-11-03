defmodule TestHost.Endpoint do
  @moduledoc "The host app's endpoint, serving `TestHost.Router`."
  use Phoenix.Endpoint, otp_app: :issues_phoenix

  @session_options [
    store: :cookie,
    key: "_test_host_key",
    signing_salt: "testhost",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/issues_phoenix",
    from: {:issues_phoenix, "priv/static"},
    only: ~w(pico.min.css)

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.Session, @session_options
  plug TestHost.Router
end
