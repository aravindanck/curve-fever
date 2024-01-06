defmodule CurveFeverWeb.GameLive do
  @moduledoc """
  LiveView implementation of Curve Fever
  """

  use CurveFeverWeb, :live_view
  alias CurveFever.GameServer

  require Logger

  @impl true
  def mount(%{"player_id" => player_id, "game_id" => game_id}, _session, socket) do
    socket =
      with {:ok, game} <- GameServer.get_game(game_id),
           {:ok, player} <- GameServer.get_player_by_id(game_id, player_id),
           :ok <- Phoenix.PubSub.subscribe(CurveFever.PubSub, game_id) do
        assign(socket, game: game, player: player, canvas_diff: [])
      else
        error ->
          Logger.warning("Error while joining game redirecting to homepage, #{inspect(error)}")
          push_navigate(socket, to: "/")
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("start_game", params, socket) do
    Logger.info("Start Game invoked", params)

    case GameServer.start_game(game_id(socket)) do
      {:ok, game} ->
        player_id = socket |> player_id()

        socket =
          socket
          |> assign(game: game)
          # Navigating to the game page to refresh caller's canvas. For other players, :refresh event is broadcasted
          |> push_navigate(to: ~p"/game?player_id=#{player_id}&game_id=#{game.id}")

        {:reply, %{game: game}, socket}

      {:error, :insufficient_players} ->
        socket =
          socket
          |> put_temporary_flash(:error, "A game needs a minimum of two players!")

        {:noreply, socket}
    end
  end

  def handle_event("key_press", %{"key" => "ArrowLeft"}, socket) do
    game_id = socket |> game_id()
    player_id = socket |> player_id()

    GameServer.turn_left(game_id, player_id)

    {:noreply, socket}
  end

  def handle_event("key_press", %{"key" => "ArrowRight"}, socket) do
    game_id = socket |> game_id()
    player_id = socket |> player_id()

    GameServer.turn_right(game_id, player_id)

    {:noreply, socket}
  end

  def handle_event("key_press", _keypressed, socket) do
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
    Logger.info(game_started_signal_received_by: socket.assigns.player.name)
    {:noreply, assign(socket, game: state.game)}
  end

  @impl true
  def handle_info(%{event: :canvas_updated, payload: canvas_diff}, socket) do
    # Logger.info(canvas_update_event_received_by: socket.assigns.player.name)
    {:noreply, assign(socket, canvas_diff: canvas_diff)}
  end

  @impl true
  def handle_info(%{event: :refresh}, socket) do
    Logger.info(refresh_event_received_by: socket.assigns.player.name)
    game_id = socket |> game_id()
    player_id = socket |> player_id()

    socket =
      socket
      |> push_navigate(to: ~p"/game?player_id=#{player_id}&game_id=#{game_id}")

    {:noreply, socket}
  end

  def handle_info(%{event: :game_ended, payload: winner}, socket) do
    socket =
      socket
      |> put_temporary_flash(:info, "Player #{winner.name} won!")
      |> assign(:game, %{socket.assigns.game | status: :completed})

    {:noreply, socket}
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

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
