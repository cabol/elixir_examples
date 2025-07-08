defmodule DistributedDynamicSupervisor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias DistributedDynamicSupervisor.PG

  @impl true
  def start(_type, _args) do
    children = [
      # PG scope
      PG.child_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DistributedDynamicSupervisor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
