defmodule CurveFever.GameServer do
  @moduledoc """
  Holds state for a game and exposes an interface to managing the game instance
  """

  use GenServer

  alias CurveFever.Game

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

  def start_game(game_id, player) do
    Logger.info(start_game_player: player)
    call_by_name(game_id, {:start_game, player})
  end

  @spec get_player_by_id(String.t(), String.t()) ::
  {:ok, Player.t()} | {:error, :game_not_found | :player_not_found}
  def get_player_by_id(game_id, player_id) do
    call_by_name(game_id, {:get_player_by_id, player_id})
  end

  def update_canvas(game_id, player_id) do
    Logger.info(update_canvas_player_id_input: player_id)
    cast_by_name(game_id, {:update_canvas, player_id})
  end

  @spec get_game(String.t() | pid()) :: {:ok, Game.t()} | {:error, :game_not_found}
  def get_game(pid) when is_pid(pid) do
    GenServer.call(pid, :get_game)
  end

  def get_game(game_id) do
    call_by_name(game_id, :get_game)
  end

  # TODO: Refctor Registry Code
  @spec start_link(binary) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(game_id) do
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
    Logger.info(get_game: state)
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call({:start_game, player}, _from, state) do
    Logger.info(state)
    with {:ok, game} <- Game.start_game(state.game),
        {:ok, player} <- Game.get_player_by_id(game, player.id)
     do
      Logger.info(player: player)
      broadcast_game_updated!(game.id, %{game: game, player: player})
      # Process.send_after(self(), {:update_canvas, player.id}, 1000)
      Logger.info(start_game_send_pid: self())
      {:reply, {:ok, game, player}, %{game: game, player: player}}
    end
  end

  @impl GenServer
  def handle_call({:turn_left, player_id}, _from, state) do
    Logger.info(player_id: player_id)

    with {:ok, player} <- Game.get_player_by_id(state.game, player_id) do
      if player.isAlive do
        {:ok, game, player} = Game.turn(state.game, player, 1)
        {:ok, game} = Game.update_player(game, player)
        {:reply, {:ok, game, player}, %{game: game, player: player}}
      else
        {:reply, {:ok, state.game, player}, %{game: state.game, player: player}}
      end
    end
  end


  @impl GenServer
  def handle_call({:turn_right, player_id}, _from, state) do
    Logger.info(player_id: player_id)

    with {:ok, player} <- Game.get_player_by_id(state.game, player_id) do
      if player.isAlive do
        {:ok, game, player} = Game.turn(state.game, player, -1)
        {:ok, game} = Game.update_player(game, player)
        Logger.info(after_turn_player: player)
        Logger.info(after_turn_game: game)
        # broadcast_canvas_updated!(game.id, game, player)
        {:reply, {:ok, game, player}, %{game: game, player: player}}
      else
        {:reply, {:ok, state.game, player}, %{game: state.game, player: player}}
      end
    end
  end

  # STill necessary?
  @impl GenServer
  def handle_cast({:update_canvas, player_id}, state) do
    Logger.info("Update Canvas handler - call")
    Logger.info(update_canvas_cast_state: state)
    Logger.info(receive_pid: self())
    # canvas_update(player_id, state)
    Process.send_after(self(), {:update_canvas, player_id}, 3000)
    {:noreply, state}
  end

  @impl true
  def handle_info({:update_canvas, player_id}, state) do
    Logger.info("Update Canvas handler - info")
    canvas_update(player_id, state)
  end

  defp canvas_update(player_id, state) do
    with {:ok, player} <- Game.get_player_by_id(state.game, player_id),
        {:ok, game, player} <- Game.move_forward(state.game, player) do
      broadcast_canvas_updated!(game.id, game.canvas_diff)
      if game.game_state == :running and player.isAlive do
        Process.send_after(self(), {:update_canvas, player.id}, 25)
      end
      {:noreply, %{game: game, player: player}}
    end
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

  defp cast_by_name(game_id, command) do
    case game_pid(game_id) do
      game_pid when is_pid(game_pid) ->
        GenServer.cast(game_pid, command)

      nil ->
        {:error, :game_not_found}
    end
  end

  defp broadcast_players_updated!(game_id, players) do
    broadcast!(game_id, :players_updated, players)
  end

  defp broadcast_game_updated!(game_id, game) do
    Logger.info(game_id: game_id, game_state: game)
    broadcast!(game_id, :game_updated, %{:game => game})
  end

  defp broadcast_canvas_updated!(game_id, canvas_diff) do
    Logger.info("Canvas updated broadcast")
    broadcast!(game_id, :canvas_updated, canvas_diff)
  end

  @spec via_tuple(String.t()) :: {:via, Registry, {CurveFever.GameRegistry, String.t()}}
  defp via_tuple(game_id) do
    {:via, Registry, {CurveFever.GameRegistry, game_id}}
  end

end
