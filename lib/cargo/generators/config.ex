defmodule Cargo.Generators.Config do
  defstruct starting_coordinates: {0, 0},
            starting_number: 1,
            min_x_coordinate: -1_000,
            max_x_coordinate: 1_000,
            min_y_coordinate: -1_000,
            max_y_coordinate: 1_000,
            sector_count: 10_000

  def new(fields \\ []) do
    struct!(__MODULE__, fields)
  end
end
