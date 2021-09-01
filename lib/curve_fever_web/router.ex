defmodule CurveFeverWeb.Router do
  use CurveFeverWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CurveFeverWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CurveFeverWeb do
    pipe_through :browser

    live "/", SigninLive, :index
    get("/join_game", GameController, :join)
    get("/game", GameController, :index)
    get("/lobby", LobbyController, :join)
    get("/join_lobby", LobbyController, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CurveFeverWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CurveFeverWeb.Telemetry
    end
  end
end
