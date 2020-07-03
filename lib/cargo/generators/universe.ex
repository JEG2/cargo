defmodule Cargo.Generators.Universe do
  @enforce_keys ~w[config next_number]a
  defstruct config: nil,
            next_number: nil,
            expansion_sectors: :queue.new(),
            sectors: Map.new(),
            used_coordinates: Map.new()

  alias Cargo.{Generators, Universe, Sector}

  def generate(config \\ []) do
    config
    |> seed_big_bang_from_config()
    |> generate_starting_sector
    |> expand_sectors
    |> to_universe()
  end

  defp seed_big_bang_from_config(config) do
    config = Generators.Config.new(config)
    %__MODULE__{config: config, next_number: config.starting_number}
  end

  defp generate_starting_sector(big_bang) do
    add_sector(big_bang, coordinates: big_bang.config.starting_coordinates)
  end

  defp add_sector(big_bang, sector_fields) do
    sector =
      Generators.Sector.generate(
        big_bang.config,
        Keyword.put(sector_fields, :number, big_bang.next_number)
      )

    sectors =
      Enum.reduce(
        sector.connections,
        Map.put(big_bang.sectors, sector.number, sector),
        fn connection, sectors ->
          connect_sectors(sectors, sector.number, connection)
        end
      )

    %__MODULE__{
      big_bang
      | next_number: big_bang.next_number + 1,
        expansion_sectors: :queue.in(sector, big_bang.expansion_sectors),
        sectors: sectors,
        used_coordinates:
          Map.put(
            big_bang.used_coordinates,
            sector.coordinates,
            sector.number
          )
    }
  end

  defp connect_sectors(sectors, number, connection) do
    Map.update!(sectors, connection, fn connected_sector ->
      %Sector{
        connected_sector
        | connections: Enum.uniq(connected_sector.connections ++ [number])
      }
    end)
  end

  defp expand_sectors(big_bang) do
    case find_next_expansion_sector(big_bang) do
      {sector, big_bang} ->
        big_bang
        |> generate_connections(sector)
        |> expand_sectors

      nil ->
        if map_size(big_bang.sectors) >= big_bang.config.sector_count do
          big_bang
        else
          big_bang
          |> find_new_expansion_point
          |> expand_sectors
        end
    end
  end

  defp find_next_expansion_sector(big_bang) do
    case :queue.out(big_bang.expansion_sectors) do
      {{:value, sector}, expansion_sectors} ->
        {sector, %__MODULE__{big_bang | expansion_sectors: expansion_sectors}}

      {:empty, _expansion_sectors} ->
        nil
    end
  end

  defp generate_connections(big_bang, sector) do
    {x, y} = sector.coordinates

    count =
      Enum.min([
        calculate_connection_count(big_bang, sector),
        big_bang.config.sector_count - map_size(big_bang.sectors)
      ])

    [{1, -1}, {1, 0}, {1, 1}, {-1, 1}, {-1, 0}, {-1, -1}]
    |> Enum.map(fn {x_offset, y_offset} -> {x + x_offset, y + y_offset} end)
    |> Enum.filter(fn {x, y} = coordinates ->
      coordinates != sector.coordinates and
        x >= big_bang.config.min_x_coordinate and
        x <= big_bang.config.max_x_coordinate and
        y >= big_bang.config.min_y_coordinate and
        y <= big_bang.config.max_y_coordinate
    end)
    |> Enum.shuffle()
    |> Enum.take(count)
    |> Enum.reduce(big_bang, fn coordinates, big_bang ->
      big_bang.sectors
      |> Map.get(Map.get(big_bang.used_coordinates, coordinates))
      |> case do
        %Sector{} = existing_sector ->
          sectors =
            big_bang.sectors
            |> connect_sectors(sector.number, existing_sector.number)
            |> connect_sectors(existing_sector.number, sector.number)

          %__MODULE__{big_bang | sectors: sectors}

        nil ->
          add_sector(
            big_bang,
            coordinates: coordinates,
            connections: [sector.number]
          )
      end
    end)
  end

  defp calculate_connection_count(
         %__MODULE__{config: %Generators.Config{starting_number: number}},
         %Sector{number: number}
       ) do
    6
  end

  defp calculate_connection_count(big_bang, sector) do
    weighted_connections_table =
      if sector.number <= big_bang.config.sector_count * 0.10 do
        %{5 => 22.5, 4 => 33, 3 => 22.5, 2 => 10, 1 => 7, 0 => 5}
      else
        %{5 => 5, 4 => 7, 3 => 10, 2 => 22.5, 1 => 33, 0 => 22.5}
      end

    selection = :rand.uniform(100)

    Enum.reduce_while(weighted_connections_table, 0, fn {count, percent}, sum ->
      sum = sum + percent

      if selection <= sum do
        {:halt, count}
      else
        {:cont, sum}
      end
    end)
  end

  defp find_new_expansion_point(big_bang) do
    {starting_x, starting_y} = big_bang.config.starting_coordinates

    sector =
      big_bang.sectors
      |> Map.values()
      |> Enum.min_by(fn sector ->
        {x, y} = sector.coordinates

        [
          length(sector.connections),
          abs(starting_x - x) + abs(starting_y - y),
          sector.number
        ]
      end)

    %__MODULE__{
      big_bang
      | expansion_sectors: :queue.in(sector, big_bang.expansion_sectors)
    }
  end

  # defp calculate_connection_count(big_bang, sector) do
  #   {x, y} = sector.coordinates

  #   # FIXME:  handle zeros
  #   nearest_edge =
  #     [
  #       x / big_bang.config.min_x_coordinate,
  #       x / big_bang.config.max_x_coordinate,
  #       y / big_bang.config.min_y_coordinate,
  #       y / big_bang.config.max_y_coordinate
  #     ]
  #     |> Enum.filter(fn percent -> percent >= 0 end)
  #     |> Enum.max()

  #   weighted_connections_table =
  #     cond do
  #       nearest_edge <= 0.1667 ->
  #         %{5 => 33, 4 => 25, 3 => 20, 2 => 10, 1 => 7, 0 => 5}

  #       nearest_edge <= 0.3333 ->
  #         %{5 => 22.5, 4 => 33, 3 => 22.5, 2 => 10, 1 => 7, 0 => 5}

  #       nearest_edge <= 0.5 ->
  #         %{5 => 8.5, 4 => 22.5, 3 => 33, 2 => 22.5, 1 => 8.5, 0 => 5}

  #       nearest_edge <= 0.6667 ->
  #         %{5 => 5, 4 => 8.5, 3 => 22.5, 2 => 33, 1 => 22.5, 0 => 8.5}

  #       nearest_edge <= 0.8333 ->
  #         %{5 => 5, 4 => 7, 3 => 10, 2 => 22.5, 1 => 33, 0 => 22.5}

  #       true ->
  #         %{5 => 5, 4 => 7, 3 => 10, 2 => 20, 1 => 25, 0 => 33}
  #     end

  #   selection = :rand.uniform(100)

  #   Enum.reduce_while(weighted_connections_table, 0, fn {count, percent}, sum ->
  #     sum = sum + percent

  #     if selection <= sum do
  #       {:halt, count}
  #     else
  #       {:cont, sum}
  #     end
  #   end)
  # end

  defp to_universe(big_bang) do
    coordinate_index =
      big_bang.used_coordinates
      |> Enum.filter(fn {_coordinates, contents} -> is_integer(contents) end)
      |> Map.new()

    Universe.new(sectors: big_bang.sectors, coordinate_index: coordinate_index)
  end
end
