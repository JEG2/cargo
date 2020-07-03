defmodule Cargo.StarMap do
  def render(universe, path) do
    File.open!(path, [:write], fn star_map ->
      IO.puts star_map, "strict digraph StarMap {"
      Enum.each(universe.sectors, fn {number, sector} ->
        Enum.each(sector.connections, fn connection ->
          IO.puts star_map, "  sector_#{number} -> sector_#{connection};"
        end)
      end)
      IO.puts star_map, "}"
    end)
  end
end
