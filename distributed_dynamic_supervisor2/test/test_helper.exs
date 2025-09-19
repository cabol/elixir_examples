# Mocks
[
  DistributedDynamicSupervisor.RPC
]
|> Enum.each(&Mimic.copy/1)

# Set nodes
nodes = [:"node1@127.0.0.1", :"node2@127.0.0.1", :"node3@127.0.0.1", :"node4@127.0.0.1"]
:ok = Application.put_env(:distributed_dynamic_supervisor, :nodes, nodes)

# Spawn remote nodes
unless :clustered in Keyword.get(ExUnit.configuration(), :exclude, []) do
  DistributedDynamicSupervisor.TestCluster.spawn(nodes)
end

# For tasks/generators testing
Mix.start()
Mix.shell(Mix.Shell.Process)

# Start ExUnit
ExUnit.start()
