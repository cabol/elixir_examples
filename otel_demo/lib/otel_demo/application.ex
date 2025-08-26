defmodule OtelDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Setup OpenTelemetry
    setup_opentelemetry()

    children = [
      OtelDemoWeb.Telemetry,
      OtelDemo.Repo,
      {DNSCluster, query: Application.get_env(:otel_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OtelDemo.PubSub},
      # Start the Finch HTTP client for making HTTP requests
      {Finch, name: OtelDemo.Finch},
      # Start the Endpoint (http/https)
      OtelDemoWeb.Endpoint,
      {OtelDemo.ProcessMemoryMonitor, []},
      {OtelDemo.BinLeakMonitor, []},
      OtelDemo.Test.Mem
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OtelDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OtelDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp setup_opentelemetry do
    # OpenTelemetry will initialize automatically based on configuration
    # The tracer and resource are configured via application environment
    :ok
  end
end
