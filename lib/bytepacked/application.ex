defmodule Bytepacked.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Bytepacked.Repo,
      # Start the Telemetry supervisor
      BytepackedWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Bytepacked.PubSub},
      # Start the Endpoint (http/https)
      BytepackedWeb.Endpoint
      # Start a worker by calling: Bytepacked.Worker.start_link(arg)
      # {Bytepacked.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bytepacked.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BytepackedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
