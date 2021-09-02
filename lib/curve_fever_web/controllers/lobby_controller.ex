defmodule CurveFeverWeb.LobbyController do
  use CurveFeverWeb, :controller
  alias Phoenix.LiveView.Controller
  require Logger

  def join(conn, params) do
    %{"player_name" => player_name} = params
    Logger.info(player_name: player_name)
    Logger.info(conn: conn)

    lobby_path = Routes.lobby_path(conn, :index, player_name: player_name)

    Logger.info(lobby_path: lobby_path)

    conn
    |> clear_session()
    |> put_session(:player_name, player_name)
    |> redirect(to: lobby_path)
  end

  def leave(conn, _params) do
    # lobby_path = Routes.live_path(conn, CurveFever.LobbyLive)
    lobby_path = "/"

    conn
    |> clear_session()
    |> redirect(to: lobby_path)
  end

  def index(conn, %{"player_name" => player_name}) do
    Logger.info(player_name: player_name)
    conn
    |> put_session(:player_name, player_name)
    |> Controller.live_render(CurveFeverWeb.LobbyLive)
  end
end
