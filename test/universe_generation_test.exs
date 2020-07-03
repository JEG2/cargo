defmodule UniverseGenerationTest do
  use ExUnit.Case, async: true

  alias Cargo.{Generators, Universe, Sector}

  test "generation returns a universe" do
    assert %Universe{} = Generators.Universe.generate()
  end

  test "the starting sector is always generated" do
    number = 42
    coordinates = {7, 42}

    universe =
      Generators.Universe.generate(
        starting_number: number,
        starting_coordinates: coordinates
      )

    sector = Universe.at_coordinates(universe, coordinates)
    assert %Sector{number: ^number, coordinates: ^coordinates} = sector
  end

  test "the starting sector always has the maximum possible connections" do
    coordinates = {0, 0}
    universe = Generators.Universe.generate(starting_coordinates: coordinates)
    sector = Universe.at_coordinates(universe, coordinates)
    assert length(sector.connections) == 6
  end

  test "sectors are not built past boundaries" do
    coordinates = {max_x, max_y} = {10, 10}

    universe =
      Generators.Universe.generate(
        starting_coordinates: coordinates,
        max_x_coordinate: max_x,
        max_y_coordinate: max_y
      )

    sector = Universe.at_coordinates(universe, coordinates)
    assert length(sector.connections) == 2
  end

  test "the configured count of sectors are generated" do
    count = 10

    universe =
      Generators.Universe.generate(
        min_x_coordinate: -10,
        max_x_coordinate: 10,
        min_y_coordinate: -10,
        max_y_coordinate: 10,
        sector_count: count
      )

    assert map_size(universe.sectors) == count
  end

  test "sectors are reused in connection generation" do
    universe = Generators.Universe.generate()

    assert Enum.any?(universe.sectors, fn {number, sector} ->
             sector.connections
             |> Enum.count(fn connection -> connection < number end)
             |> Kernel.>(1)
           end)
  end

  test "no sector has more than the maximum allowed connections" do
    universe = Generators.Universe.generate()

    refute Enum.any?(universe.sectors, fn {_number, sector} ->
             length(sector.connections) > 6
           end)
  end

  test "generated universes have more connections towards the center" do
    universe = Generators.Universe.generate()

    {min_x, max_x} =
      universe.sectors
      |> Enum.map(fn {_number, sector} -> elem(sector.coordinates, 0) end)
      |> Enum.min_max()

    {min_y, max_y} =
      universe.sectors
      |> Enum.map(fn {_number, sector} -> elem(sector.coordinates, 1) end)
      |> Enum.min_max()

    x_range = abs(min_x) + abs(max_x)
    one_tenth_x = x_range / 10
    y_range = abs(min_y) + abs(max_y)
    one_tenth_y = y_range / 10

    edge_sectors =
      Enum.filter(universe.sectors, fn {_number, sector} ->
        {x, y} = sector.coordinates

        x <= min_x + one_tenth_x or x >= max_x - one_tenth_x or
          y <= min_y + one_tenth_y or y >= max_y - one_tenth_y
      end)

    inner_sectors =
      Enum.filter(universe.sectors, fn {_number, sector} ->
        {x, y} = sector.coordinates

        (x >= -one_tenth_x and x <= one_tenth_x) or
          (y >= -one_tenth_y and y <= one_tenth_y)
      end)

    edge_average =
      edge_sectors
      |> Enum.map(fn {_number, sector} -> length(sector.connections) end)
      |> average

    inner_average =
      inner_sectors
      |> Enum.map(fn {_number, sector} -> length(sector.connections) end)
      |> average

    assert edge_average <= inner_average
  end

  defp average(list) do
    {total, count} =
      Enum.reduce(list, {0, 0}, fn n, {t, c} -> {t + n, c + 1} end)
    total / count
  end
end
