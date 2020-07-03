defmodule Cargo do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    Application.get_env(:cargo, :headless)
    |> children
    |> Supervisor.start_link(strategy: :one_for_one)
  end

  defp children(false) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:cargo, :viewport)

    children(true) ++
      [
        {Scenic, viewports: [main_viewport_config]}
      ]
  end

  defp children(true) do
    []
  end
end
