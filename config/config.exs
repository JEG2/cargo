# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Configure the main viewport for the Scenic application
config :cargo, :viewport, %{
  name: :main_viewport,
  size: {700, 600},
  default_scene: {Cargo.Scene.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "cargo"]
    }
  ]
}

config :cargo, :headless, Mix.env() == :test
