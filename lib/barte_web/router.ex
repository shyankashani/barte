defmodule BarteWeb.Router do
  use BarteWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BarteWeb do
    pipe_through :api
  end
end
