defmodule Cargo.Sector do
  @enforce_keys ~w[number coordinates]a
  defstruct number: nil, coordinates: nil, connections: [ ]

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
