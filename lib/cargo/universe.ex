defmodule Cargo.Universe do
  @enforce_keys ~w[sectors coordinate_index]a
  defstruct sectors: nil, coordinate_index: nil

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def at_coordinates(universe, coordinates) do
    Map.get(universe.sectors, Map.get(universe.coordinate_index, coordinates))
  end
end
