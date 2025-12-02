defmodule IssuesPhoenixWeb.DummyController do
  use IssuesPhoenixWeb, :controller

  def index(conn, _params) do
    text(conn, "Dummy")
  end
end
