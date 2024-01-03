defmodule CurveFever.Player do
  @moduledoc """
  Represents a CurveFever Player
  """

  defstruct [
    :id,
    :name,
    :x,
    :y,
    :speed,
    :angle,
    :color,
    :distance,
    :isPlaying,
    :isAlive,
    :canceled
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          x: integer(),
          y: integer(),
          speed: integer(),
          angle: integer(),
          color: String.t(),
          distance: integer(),
          isPlaying: boolean(),
          isAlive: boolean()
        }

  @spec new(String.t()) :: t()
  def new(name) do
    params = %{
      id: UUID.uuid4(),
      name: name
    }

    struct!(__MODULE__, params)
  end

  @spec initialize_state(t(), GameConfig.t(), integer()) :: t()
  def initialize_state(player, config, index) do
    color = %{
      0 => "red",
      1 => "purple",
      2 => "lime",
      3 => "orangered",
      4 => "blue",
      5 => "saddlebrown",
      6 => "black",
      7 => "deeppink",
      8 => "green",
      9 => "navy"
    }

    initialized_player =
      player
      |> Map.update!(:x, fn _ -> :rand.uniform(config.canvasHeight - 1) end)
      |> Map.update!(:y, fn _ -> :rand.uniform(config.canvasWidth - 1) end)
      |> Map.update!(:color, fn _ -> color[index] end)
      |> Map.update!(:isAlive, fn _ -> true end)
      |> Map.update!(:isPlaying, fn _ -> true end)
      |> Map.update!(:canceled, fn _ -> false end)
      |> Map.update!(:speed, fn _ -> 1 end)
      |> Map.update!(:angle, fn _ -> :rand.uniform(360) end)
      |> Map.update!(:distance, fn _ -> 0 end)

    initialized_player
  end
end
