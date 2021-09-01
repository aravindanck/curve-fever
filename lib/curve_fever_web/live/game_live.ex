defmodule CurveFeverWeb.GameLive do
  @moduledoc """
  LiveView implementation of Curve Fever
  """

  use CurveFeverWeb, :live_view
  alias CurveFever.GameServer
  # alias CurveFeverWeb.Presence

  require Logger

  # TODO: Fix lobby_path issue
  @impl true
  def mount(_params, session, socket) do
    socket =
      with %{"game_id" => game_id, "player_id" => player_id} <- session,
           {:ok, game} <- GameServer.get_game(game_id),
           {:ok, player} <- GameServer.get_player_by_id(game_id, player_id),
          #  {:ok, _} <- Presence.track(self(), game_id, player_id, %{}),
           :ok <- Phoenix.PubSub.subscribe(CurveFever.PubSub, game_id) do
        assign(socket, game: game, player: player, canvas_diff: [])
      else
        _ ->
          _params =
            if Map.has_key?(session, "game_id") do
              Map.take(session, ["game_id"])
            else
              []
            end

          # lobby_path = Routes.live_path(socket, LobbyLive, params)
          push_redirect(socket, to: "/")
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("start-game", params, socket) do
    Logger.info("Start Game invoked", params)

    with {:ok, game, _player} <- GameServer.start_game(game_id(socket), socket.assigns.player) do
      assign(socket, game: game)
    end

    {:noreply, socket}
  end


  def handle_event("key_press", %{"key" => "ArrowLeft"}, socket) do

    Logger.info("Arrow Left pressed")
    game_id = socket |> game_id()
    player_id = socket |> player_id()

    GameServer.turn_left(game_id, player_id)

    {:noreply, socket}
  end

  def handle_event("key_press", %{"key" => "ArrowRight"}, socket) do

    Logger.info("Arrow Right pressed")
    game_id = socket |> game_id()
    player_id = socket |> player_id()

    GameServer.turn_right(game_id, player_id)

    {:noreply, socket}
  end

  def handle_event("key_press", keypressed, socket) do
    Logger.info("Invalid key", keypressed)
    {:noreply, socket}
  end



  @impl true
  def handle_info(%{event: :players_updated, payload: players}, socket) do
    %{game: game} = socket.assigns

    # online_players =
    #   socket
    #   |> game_id()
    #   |> online_players()

    {:noreply, assign(socket, game: %{game | players: players})}
  end

  @impl true
  def handle_info(%{event: :game_updated, payload: state}, socket) do
    Logger.info("Game Updated(:game_updated) broadcast caught")
    Logger.info(game_updated_socket: socket)
    Logger.info(game_started_signal_received_by: socket.assigns.player.name)
    {:noreply, assign(socket, game: state.game)}
  end

  @impl true
  def handle_info(%{event: :canvas_updated, payload: canvas_diff}, socket) do
    Logger.info("Canvas Updated broadcast caught ")
    Logger.info(canvas_update_event_received_by: socket.assigns.player.name, canvas_diff: canvas_diff)
    {:noreply, assign(socket, canvas_diff: canvas_diff)}
  end

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    %{game: game} = socket.assigns

    # online_players =
    #   socket
    #   |> game_id()
    #   |> online_players()

    Logger.info(payload: payload)

    # game = %{game | online_players: online_players}

    {:noreply, assign(socket, game: game)}
  end

  def handle_info(_params, socket) do
    %{game: game} = socket.assigns


    {:noreply, assign(socket, game: game)}
  end

  defp game_id(socket) do
    socket.assigns.game.id
  end

  defp player_id(socket) do
    socket.assigns.player.id
  end


  # defp online_players(game_id) do
  #   Logger.info(Presence.list(game_id))
  #   game_id
  #   |> Presence.list()
  #   |> Enum.map(fn {_k, %{player: player}} -> player end)
  # end

end
