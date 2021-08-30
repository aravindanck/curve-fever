defmodule CurveFever.Game do
  @moduledoc """
  Represents the game structure and exposes actions that can be taken to update
  game state
  """

  alias CurveFever.Player
  alias CurveFever.GameConfig

  require Logger

  # TODO: Diff between defstruct and @type
  defstruct id: nil,
            players: [],
            online_players: [],
            canvas: [],
            canvas_diff: %{},
            config: %GameConfig{},
            game_state: :waiting_to_start

    @type game_state ::
      :waiting_to_start
      | :running
      | :completed

    @type t :: %__MODULE__{
            id: String.t(),
            players: list(Player.t()),
            canvas: list(),
            config: GameConfig.t(),
            game_state: game_state()
          }

  @spec new(String.t()) :: t()
  def new(id) do
    struct!(__MODULE__, id: id)
  end

  @doc """
  Adds a new player to the game
  """
  @spec add_player(t(), Player.t()) :: {:ok, t()} | {:error, :name_taken}
  def add_player(game, player) do
    %{name: name} = player

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
  def list_players(game), do: game.players

  @doc """
  Start game
  """
  @spec start_game(t()) :: {:ok, t()}
  def start_game(game) do
    {:ok, config} = Map.fetch(game, :config)

    canvas = initialize_canvas(config.canvasHeight, config.canvasWidth)
    players = initialize_players_state(game.players, config)

    game =
      game
      |> Map.put(:game_state, :running)
      |> Map.put(:canvas, canvas)
      |> Map.put(:players, players)

    Logger.info(updated_game: game)
    {:ok, game}
  end

  @spec move_forward(any, atom | %{:isPlaying => boolean, optional(any) => any}) ::
          {:ok, any, atom | %{:isPlaying => boolean, optional(any) => any}}
  def move_forward(game, player) do
    Logger.info("**********************************Move player forward**********************************")
    if player.isPlaying and player.isAlive do

      # speed = game.config.pixelsPerSecond * (1000 / game.config.frameRate / 1000)
      speed = 1
      deltaX = :math.cos(player.angle * :math.pi / 180) * speed
      deltaY = :math.sin(player.angle * :math.pi / 180) * speed

      Logger.info(deltaX: deltaX, deltaY: deltaY)
      current_pos_index = (trunc(player.x) * game.config.canvasWidth) + trunc(player.y)

      new_x = player.x + deltaX
      new_y = player.y + deltaY

      {_, x_decimal} = split_float(new_x);
      {_, y_decimal} = split_float(new_y);
      canvas_value = [player.color, x_decimal, y_decimal];
      canvas_diff = %{color: player.color,
              x1: player.x,
              y1: player.y,
              x2: new_x,
              y2: new_y};

      Logger.info(canvas_diff: canvas_diff)

      game = %{game | canvas_diff: canvas_diff}

      res = clears_hit_test?(new_x, new_y, game.config.canvasWidth, game.config.canvasHeight)
      Logger.info(x: player.x, y: player.y, new_pos_X: new_x, new_pos_y: new_y, clears_hit_test?: res)
      player = Map.put(player, :x, new_x)
      player = Map.put(player, :y, new_y)

      new_pos_index = (trunc(new_x) * game.config.canvasWidth) + trunc(new_y)

      if res == :false or (new_pos_index != current_pos_index and Enum.at(game.canvas, new_pos_index) != -1) do
        player = Map.put(player, :isAlive, :false)
        player = Map.put(player, :isActive, :false)
        Logger.info("Player failed to clear hit test", player: player.name)
        {:ok, game} = update_player(game, player)

        {:ok, game, player}
      else
        Logger.info(new_pos_index: new_pos_index)
        game = %{game | canvas: List.update_at(game.canvas, new_pos_index, fn _ -> canvas_value end)}

        Logger.info(new_x: new_x, new_y: new_y, val: Enum.at(game.canvas, new_pos_index))
        {:ok, game} = update_player(game, player)

        {:ok, game, player}
      end

    else
      Logger.info("Player is either not playing or already lost!", player: player);
      {:ok, game, player, nil}
    end
  end

  defp clears_hit_test?(x, y, canvasWidth, canvasHeight) do
    if x < 0 or y < 0 or x >= canvasHeight or y >= canvasWidth do
      :false
    else
      :true
    end
  end

  def turn(game, player, direction) do

    Logger.info(angle_before: player.angle)
    angle = player.angle + (game.config.maximumChangeOfAngle * direction);

    angle = rem(angle, 360)
    Logger.info(reminder_angle: angle)

    if angle < 0 do
      angle = angle + 360
      Logger.info(angle_after_add360_since_negative: angle)
      player = Map.put(player, :angle, angle)
      {:ok, game, player}
    else
      player = Map.put(player, :angle, angle)
      Logger.info(angle_after_positive_so_just_return: angle)
      {:ok, game, player}
    end
  end

  def set_canvas(%__MODULE__{} = game, canvas) do
    %{game | canvas: canvas}
  end

  defp find_player(game, %{} = attrs, match: :any) do
    game.players
    |> Enum.find(fn player ->
      Enum.any?(attrs, &has_equal_attribute?(player, &1))
    end)
  end

  defp find_player(game, %{} = attrs) do
    game.players
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
    Logger.info(before_initialization_players: players)

    initialized_players = players
    |> Enum.with_index()
    |> Enum.map(fn {player, index} -> Player.initialize_state(player, config, index) end)


    Logger.info(after_initialization_players: initialized_players)
    initialized_players
  end

  def initialize_canvas(h,w) do
    arr_len = h * w
    List.duplicate(-1, arr_len-1)
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
