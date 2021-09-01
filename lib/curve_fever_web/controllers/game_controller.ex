defmodule CurveFeverWeb.GameController do
  use CurveFeverWeb, :controller
  alias Phoenix.LiveView.Controller
  require Logger

  def join(conn, params) do
    %{"game_id" => game_id, "player_id" => player_id} = params

    game_path = Routes.game_path(conn, :index, game_id: game_id)

    Logger.info(game_path: game_path)

    conn
    |> put_session(:game_id, game_id)
    |> put_session(:player_id, player_id)
    |> redirect(to: game_path)
  end

  def leave(conn, _params) do
    # lobby_path = Routes.live_path(conn, CurveFever.LobbyLive)
    lobby_path = "/"

    conn
    |> clear_session()
    |> redirect(to: lobby_path)
  end

  def index(conn, %{"game_id" => game_id}) do
    Logger.info(game_id: game_id)
    conn
    |> put_session(:game_id, game_id)
    |> Controller.live_render(CurveFeverWeb.GameLive)
  end
end
