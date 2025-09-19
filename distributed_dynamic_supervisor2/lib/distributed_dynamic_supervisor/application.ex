defmodule DistributedDynamicSupervisor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Add the node to the scopes
    :ok = :syn.add_node_to_scopes([DistributedDynamicSupervisor])

    children = [
      DistributedDynamicSupervisor.child_spec()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DistributedDynamicSupervisor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
