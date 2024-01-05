defmodule CurveFeverWeb.LobbyLive do
  use CurveFeverWeb, :live_view

  alias CurveFever.Player
  alias CurveFever.GameServer
  alias CurveFever.GameSupervisor

  require Logger

  @impl true
  def mount(%{"player_name" => player_name} = _params, _session, socket) do
    Logger.info(lobby_live_length: Enum.count(GameServer.list_rooms()))
    Logger.info("games: #{GameServer.list_rooms()}")

    {:ok, assign(socket, player_name: player_name, games: GameServer.list_rooms())}
  end

  @impl true
  def handle_event("new_game", %{"value" => ""}, socket) do
    game_id = MnemonicSlugs.generate_slug(2)
    Logger.info(game_id: game_id)

    {:ok, _pid} = GameSupervisor.start_game(game_id)

    player_name = socket.assigns.player_name
    player = Player.new(player_name)

    socket =
      case GameServer.add_player(game_id, player) do
        :ok ->
          socket
          |> push_navigate(to: ~p"/game?player_id=#{player.id}&game_id=#{game_id}")

        {:error, :name_taken} ->
          socket
          |> put_temporary_flash(:error, "Name already taken, please choose a different name")
      end

    {:reply, %{}, socket}
  end

  @impl true
  def handle_event("join_game", %{"column" => game_id}, socket) do
    Logger.info("Join Game invoked")

    player_name = socket.assigns.player_name
    player = Player.new(player_name)

    socket =
      case GameServer.add_player(game_id, player) do
        :ok ->
          socket
          |> push_navigate(to: ~p"/game?player_id=#{player.id}&game_id=#{game_id}")

        {:error, :name_taken} ->
          socket
          |> put_temporary_flash(:error, "Name already taken, please choose a different name")
      end

    {:reply, %{}, socket}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
