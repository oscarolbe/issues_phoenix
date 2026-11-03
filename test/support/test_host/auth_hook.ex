defmodule TestHost.AuthHook do
  @moduledoc "A host app's auth hook, passed via `issues_phoenix_routes ..., on_mount: ...`."

  def on_mount(:require_admin, _params, session, socket) do
    if session["admin"] == false do
      {:halt, Phoenix.LiveView.redirect(socket, to: "/host/page")}
    else
      {:cont, socket}
    end
  end
end
