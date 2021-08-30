defmodule CurveFeverWeb.LobbyLive do
  use CurveFeverWeb, :live_view

  alias CurveFever.Player
  alias CurveFever.GameServer

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, player_name: "", game_id: "")}
  end

  @impl true
  def handle_event("new_game", %{"value" => ""}, socket) do
    game_id = MnemonicSlugs.generate_slug(1)
    Logger.info(game_id: game_id)

    # TODO: Use GameSupervisor instead
    GameServer.start_link(game_id)
    {:noreply, assign(socket, game_id: game_id)}
  end

  @impl true
  def handle_event("join-game", %{"lobby_form" => fields}, socket) do
    %{"game_id" => game_id, "player_name" => player_name} = fields

    Logger.info("Join Game invoked")
    Logger.info(player_name: player_name, game_id: game_id)

    payload = %{
      game_id: game_id,
      player_name: player_name
    }

    send(self(), {:join_game, payload})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:join_game, attrs}, socket) do
    %{game_id: game_id, player_name: player_name} = attrs

    Logger.info(game_id: game_id, player_name: player_name)

    player = Player.new(player_name)

    # TODO: Game Server should be created in Create Game event handler
    GameServer.start_link(game_id)

    socket =
      case GameServer.add_player(game_id, player) do
        :ok ->
          url =
            Routes.game_path(
              socket,
              :join,
              game_id: game_id,
              player_id: player.id
            )

          Logger.info(url: url)

          socket
          |> put_temporary_flash(:info, "Joined successfully")
          |> push_redirect(to: url)

        {:error, :name_taken} ->
          socket
          |> put_temporary_flash(:error, "Name already taken, please choose a different name")
      end

    {:noreply, socket}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end