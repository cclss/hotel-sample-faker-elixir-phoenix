defmodule FakrWeb.PageController do
  use FakrWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
