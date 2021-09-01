defmodule CurveFever.GameConfig do
  @moduledoc """
  Represents a CurveFever Game Configuration
  """

  defstruct canvasWidth: 800,
            canvasHeight: 700,
            lineWidth: 3,
            speed: 1,
            maximumChangeOfAngle: 4, # angle change on direction change key press
            initialDelay: 5000,
            stepFrequency: 75


  @type t :: %__MODULE__{
            canvasWidth: pos_integer(),
            canvasHeight: pos_integer(),
            lineWidth: pos_integer(),
            speed: float(),
            maximumChangeOfAngle: pos_integer(),
            initialDelay: pos_integer(),
            stepFrequency: pos_integer()
          }

  @spec new() :: t()
  def new do
    struct!(__MODULE__)
  end
end
