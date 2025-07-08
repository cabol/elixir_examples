defmodule DistributedDynamicSupervisor.RPC do
  @moduledoc false

  alias DistributedDynamicSupervisor.PG

  ## API

  @doc """
  Calls a function on a remote node.
  """
  @spec rpc_call(atom(), any(), module(), atom(), [any()]) :: any()
  def rpc_call(name, key, module, fun, args) do
    name
    |> pick_node(key)
    |> rpc_call(module, fun, args)
  end

  ## Private functions

  defp rpc_call(node, module, fun, args) when node == node() do
    apply(module, fun, args)
  end

  defp rpc_call(node, module, fun, args) do
    :rpc.call(node, module, fun, args)
  end

  defp pick_node(name, key) do
    nodes = PG.nodes(name)
    index = :erlang.phash2(key, length(nodes))

    Enum.at(nodes, index)
  end
end
