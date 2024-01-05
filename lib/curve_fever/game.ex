defmodule CurveFever.Game do
  @moduledoc """
  Represents the game structure and exposes actions that can be taken to update
  game state
  """

  alias CurveFever.{Game, Player, GameConfig}

  require Logger

  defstruct id: nil,
            players: [],
            online_players: [],
            canvas: [],
            config: %GameConfig{},
            status: :waiting_to_start

  @type game_status ::
          :waiting_to_start
          | :running
          | :completed

  @type t :: %__MODULE__{
          id: String.t(),
          players: list(Player.t()),
          canvas: list(),
          config: GameConfig.t(),
          status: game_status()
        }

  @spec new(String.t()) :: t()
  def new(id) do
    struct!(__MODULE__, id: id)
  end

  @doc """
  Adds a new player to the game
  """
  @spec add_player(t(), Player.t()) :: {:ok, t()} | {:error, :name_taken}
  def add_player(game, %Player{name: name} = player) do
    case find_player(game, %{name: {:case_insensitive, name}}, match: :any) do
      nil ->
        {:ok, Map.update!(game, :players, &[player | &1])}

      %Player{} ->
        {:error, :name_taken}
    end
  end

  @doc """
  Updates a player's data
  """
  # @spec update_player(t(), Player.t()) :: {:ok, t()} | {:error, :player_not_found}
  def update_player(game, player) do
    case get_player_by_id(game, player.id) do
      {:ok, _} ->
        game = Map.update!(game, :players, &update_player_by_id(&1, player))
        {:ok, game}

      {:error, :player_not_found} = error ->
        error
    end
  end

  @spec get_player_by_id(t(), String.t()) :: {:ok, Player.t()} | {:error, :player_not_found}
  def get_player_by_id(game, player_id) do
    case find_player(game, %{id: player_id}) do
      %Player{} = player -> {:ok, player}
      nil -> {:error, :player_not_found}
    end
  end

  @doc """
  Returns a full list of players in the game
  """
  @spec list_players(t()) :: list(Player.t())
  def list_players(%Game{players: [_ | _] = players}), do: players
  def list_players(_), do: []

  @doc """
  Start game
  """
  @spec start_game(t()) :: {:ok, t()} | {:error, :insufficient_players}
  def start_game(
        %Game{
          players: players,
          config: %GameConfig{canvas_width: canvas_width, canvas_height: canvas_height} = config
        } = game
      )
      when length(players) > 1 do
    canvas = initialize_canvas(canvas_height, canvas_width)
    players = initialize_players_state(players, config)

    game =
      game
      |> Map.put(:status, :running)
      |> Map.put(:canvas, canvas)
      |> Map.put(:players, players)

    {:ok, game}
  end

  def start_game(_game),
    do: {:error, :insufficient_players}

  def move_forward(
        %Game{config: %GameConfig{pixels_per_iteration: pixels_per_iteration}} = game,
        %Player{name: name, x: x, y: y, color: color} = player
      ) do

    Logger.info("Moving forward , invoked_by: #{inspect(self())}, for_player: #{name}")

    {%Game{} = game_updated, %Player{x: new_x, y: new_y} = player_updated} =
      Enum.reduce_while(1..pixels_per_iteration, {game, player}, fn _i,
                                                                    {updated_game, updated_player} ->
        {:ok, game, player, _diff} = move_step(updated_game, updated_player)

        if player.is_alive do
          {:cont, {game, player}}
        else
          {:halt, {game, player}}
        end
      end)

    canvas_diff = %{
      color: color,
      x1: x,
      y1: y,
      x2: new_x,
      y2: new_y
    }

    Logger.info(canvas_diff: canvas_diff)

    {:ok, game_updated, player_updated, canvas_diff}
  end

  defp move_step(
         %Game{
           config: %GameConfig{
             speed: speed,
             canvas_width: canvas_width,
             canvas_height: canvas_height
           }
         } = game,
         %Player{name: name, x: x, y: y, color: color} = player
       ) do
    delta_x = :math.cos(player.angle * :math.pi() / 180) * speed
    delta_y = :math.sin(player.angle * :math.pi() / 180) * speed

    current_pos_index = trunc(x) * canvas_width + trunc(y)

    new_x = x + delta_x
    new_y = y + delta_y

    {_, x_decimal} = split_float(new_x)
    {_, y_decimal} = split_float(new_y)
    canvas_value = [color, x_decimal, y_decimal]
    canvas_diff = %{color: color, x1: x, y1: y, x2: new_x, y2: new_y}

    res = clears_hit_test?(new_x, new_y, canvas_width, canvas_height)
    player = Map.put(player, :x, new_x)
    player = Map.put(player, :y, new_y)

    new_pos_index = trunc(new_x) * canvas_width + trunc(new_y)

    if res == false or
         (new_pos_index != current_pos_index and Enum.at(game.canvas, new_pos_index) != -1) do
      player =
        player
        |> Map.put(:is_alive, false)
        |> Map.put(:is_active, false)

      Logger.info("Player failed to clear hit test": name)
      {:ok, game} = update_player(game, player)

      if length(players_alive(game)) == 1 do
        Logger.info("Game #{game.id} ended as the number of players alive is 1")
        game = %{game | status: :completed}
        {:ok, game, player, canvas_diff}
      else
        {:ok, game, player, canvas_diff}
      end
    else
      game = %{
        game
        | canvas: List.update_at(game.canvas, new_pos_index, fn _ -> canvas_value end)
      }

      {:ok, game} = update_player(game, player)

      {:ok, game, player, canvas_diff}
    end
  end

  def players_alive(game) do
    list_players(game)
    |> Enum.filter(fn player -> player.is_playing and player.is_alive end)
  end

  defp clears_hit_test?(x, y, canvas_width, canvas_height) do
    if x < 0 or y < 0 or x >= canvas_height or y >= canvas_width do
      false
    else
      true
    end
  end

  def turn(game, player, direction) do
    angle = player.angle + game.config.maximum_change_of_angle * direction

    angle = rem(angle, 360)

    if angle < 0 do
      angle = angle + 360
      player = Map.put(player, :angle, angle)
      {:ok, game, player}
    else
      player = Map.put(player, :angle, angle)
      {:ok, game, player}
    end
  end

  def set_canvas(%__MODULE__{} = game, canvas) do
    %{game | canvas: canvas}
  end

  defp find_player(%__MODULE__{players: players}, %{} = attrs, match: :any) do
    players
    |> Enum.find(fn player ->
      Enum.any?(attrs, &has_equal_attribute?(player, &1))
    end)
  end

  defp find_player(%__MODULE__{players: players}, %{} = attrs) do
    players
    |> Enum.find(fn player ->
      Enum.all?(attrs, &has_equal_attribute?(player, &1))
    end)
  end

  defp has_equal_attribute?(%{} = map, {key, {:case_insensitive, value}}) when is_binary(value) do
    String.downcase(Map.get(map, key, "")) == String.downcase(value)
  end

  defp has_equal_attribute?(%{} = map, {key, value}) do
    Map.get(map, key) == value
  end

  defp initialize_players_state(players, config) do
    players
    |> Enum.with_index()
    |> Enum.map(fn {player, index} -> Player.initialize_state(player, config, index) end)
  end

  def initialize_canvas(h, w) do
    arr_len = h * w
    List.duplicate(-1, arr_len - 1)
  end

  defp split_float(f) when is_float(f) do
    i = trunc(f)

    {
      i,
      Decimal.sub(
        Decimal.from_float(f),
        Decimal.new(i)
      )
      |> Decimal.to_float()
    }
  end

  defp update_player_by_id(players, player) do
    Enum.map(players, fn %{id: id} = original_player ->
      if id == player.id do
        player
      else
        original_player
      end
    end)
  end
end
