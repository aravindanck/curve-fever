defmodule CurveFever.GameServer do
  @moduledoc """
  Holds state for a game and exposes an interface to manage the game instance
  """

  use GenServer

  alias CurveFever.{Game, GameConfig, Player}

  require Logger

  @spec add_player(String.t(), Player.t()) ::
          :ok | {:error, :game_not_found | :name_taken}
  def add_player(game_id, player) do
    with {:ok, players} <- call_by_name(game_id, {:add_player, player}) do
      broadcast_players_updated!(game_id, players)
    end
  end

  @spec list_players(binary) :: any
  def list_players(game_id) do
    call_by_name(game_id, :list_players)
  end

  @spec turn_left(String.t(), String.t()) :: :ok
  def turn_left(game_id, player_id) do
    call_by_name(game_id, {:turn_left, player_id})
  end

  @spec turn_right(String.t(), String.t()) :: :ok
  def turn_right(game_id, player_id) do
    call_by_name(game_id, {:turn_right, player_id})
  end

  @spec start_game(String.t()) :: :ok
  def start_game(game_id) do
    call_by_name(game_id, :start_game)
  end

  @spec get_player_by_id(String.t(), String.t()) ::
          {:ok, Player.t()} | {:error, :game_not_found | :player_not_found}
  def get_player_by_id(game_id, player_id) do
    call_by_name(game_id, {:get_player_by_id, player_id})
  end

  @spec list_rooms :: list
  def list_rooms do
    games_room =
      Registry.select(CurveFever.GameRegistry, [
        {{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}
      ])

    Logger.info(room: games_room)
    games = Registry.select(CurveFever.GameRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    games
  end

  @spec get_game(String.t() | pid()) :: {:ok, Game.t()} | {:error, :game_not_found}
  def get_game(pid) when is_pid(pid) do
    GenServer.call(pid, :get_game)
  end

  def get_game(game_id) do
    call_by_name(game_id, :get_game)
  end

  # TODO: Refactor Registry Code
  @spec start_link(binary) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(game_id) do
    Logger.info("Starting game server GenServer for #{game_id}")
    GenServer.start(__MODULE__, game_id, name: via_tuple(game_id))
  end

  @impl GenServer
  def init(game_id) do
    Logger.info("Creating game server for #{game_id}")
    {:ok, %{game: Game.new(game_id)}}
  end

  @impl GenServer
  def handle_call({:add_player, player}, _from, state) do
    case Game.add_player(state.game, player) do
      {:ok, game} ->
        {:reply, {:ok, game.players}, %{state | game: game}}

      {:error, :name_taken} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_player_by_id, player_id}, _from, state) do
    {:reply, Game.get_player_by_id(state.game, player_id), state}
  end

  @impl GenServer
  def handle_call(:list_players, _from, state) do
    {:reply, {:ok, Game.list_players(state.game)}, state}
  end

  @impl GenServer
  def handle_call(:get_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call(:start_game, _from, %{game: %Game{} = game} = state) do
    case Game.start_game(game) do
      {:ok, %Game{config: %GameConfig{initial_delay: initial_delay}} = game} ->
        # Following broadcast is used to clear canvas while restarting game(Play again)
        broadcast_game_refresh!(game.id)
        broadcast_game_updated!(game.id, game)
        Process.send_after(self(), :tick, initial_delay)

        Logger.info(start_game_send_pid: self())
        {:reply, {:ok, game}, %{game: game}}

      {:error, :insufficient_players} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(
        {:turn_left, player_id},
        _from,
        %{game: %Game{} = game} = state
      ) do
    Logger.info("Turn left for player_id: #{player_id}")

    with {:ok, player} <- Game.get_player_by_id(game, player_id),
         true <- player.is_alive,
         {:ok, game, player} = Game.turn(game, player, 1),
         {:ok, game} = Game.update_player(game, player) do
      {:reply, {:ok, game, player}, %{game: game, player: player}}
    else
      _ ->
        {:reply, {:ok, game}, state}
    end
  end

  @impl GenServer
  def handle_call(
        {:turn_right, player_id},
        _from,
        %{game: %Game{} = game} = state
      ) do
    Logger.info("Turn right for player_id: #{player_id}")

    with {:ok, player} <- Game.get_player_by_id(game, player_id),
         true <- player.is_alive,
         {:ok, game, player} = Game.turn(game, player, -1),
         {:ok, game} = Game.update_player(game, player) do
      {:reply, {:ok, game, player}, %{game: game, player: player}}
    else
      _ ->
        {:reply, {:ok, game}, state}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    task = Task.async(fn -> tick(state) end)

    %{
      game:
        %Game{
          id: game_id,
          status: game_status,
          config: %GameConfig{step_frequency: step_frequency}
        } = game
    } = state = Task.await(task)

    if game_status == :running do
      Process.send_after(self(), :tick, step_frequency)
    else
      Logger.info("Game #{game_id} ended")
      broadcast_game_ended!(game_id, List.first(Game.players_alive(game)))
    end

    {:noreply, state}
  end

  defp tick(
         %{
           game:
             %Game{
               id: game_id,
               players: players
             } = game
         } = _state
       ) do
    {game, canvas_diff} =
      players
      |> Enum.filter(fn player -> player.is_alive end)
      |> Enum.reduce({game, []}, fn player, {game_acc, canvas_diff_acc} ->
        {:ok, game_acc, _player, diff} = Game.move_forward(game_acc, player)
        {game_acc, [diff] ++ canvas_diff_acc}
      end)

    broadcast_canvas_updated!(game_id, canvas_diff)

    %{game: game}
  end

  @spec broadcast!(String.t(), atom(), map()) :: :ok
  def broadcast!(game_id, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(CurveFever.PubSub, game_id, %{event: event, payload: payload})
  end

  def game_pid(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end

  defp call_by_name(game_id, command) do
    case game_pid(game_id) do
      game_pid when is_pid(game_pid) ->
        GenServer.call(game_pid, command)

      nil ->
        {:error, :game_not_found}
    end
  end

  defp broadcast_players_updated!(game_id, players) do
    broadcast!(game_id, :players_updated, players)
  end

  defp broadcast_game_updated!(game_id, game) do
    broadcast!(game_id, :game_updated, %{:game => game})
  end

  defp broadcast_game_refresh!(game_id) do
    broadcast!(game_id, :refresh)
  end

  defp broadcast_canvas_updated!(game_id, canvas_diff) do
    broadcast!(game_id, :canvas_updated, canvas_diff)
  end

  defp broadcast_game_ended!(game_id, winner) do
    broadcast!(game_id, :game_ended, winner)
  end

  @spec via_tuple(String.t()) :: {:via, Registry, {CurveFever.GameRegistry, String.t()}}
  defp via_tuple(game_id) do
    {:via, Registry, {CurveFever.GameRegistry, game_id}}
  end
end
