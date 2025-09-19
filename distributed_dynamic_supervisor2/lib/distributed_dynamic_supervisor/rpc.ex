defmodule DistributedDynamicSupervisor.RPC do
  @moduledoc false

  ## API

  @doc """
  Calls a function on a remote node.
  """
  @spec call(atom(), any(), module(), atom(), [any()]) :: any()
  def call(name, key, module, fun, args) do
    name
    |> pick_node(key)
    |> do_call(module, fun, args)
  end

  ## Private functions

  defp do_call(node, module, fun, args) when node == node() do
    apply(module, fun, args)
  end

  defp do_call(node, module, fun, args) do
    :rpc.call(node, module, fun, args)
  end

  defp pick_node(name, key) do
    nodes = [node() | :syn.subcluster_nodes(:registry, name)]
    index = :erlang.phash2(key, length(nodes))

    Enum.at(nodes, index)
  end
end
