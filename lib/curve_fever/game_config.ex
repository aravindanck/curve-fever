defmodule CurveFever.GameConfig do
  @moduledoc """
  Represents a CurveFever Game Configuration
  """

  defstruct canvas_width: 800,
            canvas_height: 700,
            line_width: 3,
            speed: 1,
            # angle change on direction change key press
            maximum_change_of_angle: 5,
            initial_delay: 3000,
            step_frequency: 50,
            pixels_per_iteration: 2

  @type t :: %__MODULE__{
          canvas_width: pos_integer(),
          canvas_height: pos_integer(),
          line_width: pos_integer(),
          speed: float(),
          maximum_change_of_angle: pos_integer(),
          initial_delay: pos_integer(),
          step_frequency: pos_integer(),
          pixels_per_iteration: pos_integer()
        }

  @spec new() :: t()
  def new do
    struct!(__MODULE__)
  end
end
