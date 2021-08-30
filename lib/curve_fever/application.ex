defmodule CurveFever.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CurveFeverWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CurveFever.PubSub},
      {Registry, keys: :unique, name: CurveFever.GameRegistry},
      CurveFeverWeb.Presence,
      # Start the Endpoint (http/https)
      CurveFeverWeb.Endpoint,
      CurveFever.GameServer
      # Start a worker by calling: CurveFever.Worker.start_link(arg)
      # {CurveFever.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CurveFever.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CurveFeverWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
