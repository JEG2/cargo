defmodule Cargo.Generators.Sector do
  alias Cargo.Sector

  def generate(config \\ [ ], fields) do
    Sector.new(fields)
  end
end
