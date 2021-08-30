defmodule CurveFever.GameConfig do
  @moduledoc """
  Represents a CurveFever Game Configuration
  """

  defstruct canvasWidth: 800,
            canvasHeight: 700,
            lineWidth: 3,
            frameRate: 100,         # rendering: frames per second
            pixelsPerSecond: 100,    # pixels per second
            maximumChangeOfAngle: 7 # angle change on direction change key press


  @type t :: %__MODULE__{
            canvasWidth: pos_integer(),
            canvasHeight: pos_integer(),
            lineWidth: pos_integer(),
            frameRate: pos_integer(),
            pixelsPerSecond: pos_integer(),
            maximumChangeOfAngle: pos_integer(),
          }

  @spec new() :: t()
  def new do
    struct!(__MODULE__)
  end
end
