defmodule DistributedDynamicSupervisor.RPC do
  @moduledoc false

  import DistributedDynamicSupervisor, only: [ring: 1]

  alias DistributedDynamicSupervisor.RingManager

  ## API

  @doc """
  Calls a function on a remote node.
  """
  @spec call(atom(), any(), module(), atom(), [any()]) :: any()
  def call(name, key, module, fun, args) do
    name
    |> ring()
    |> find_node!(key)
    |> rpc_call(module, fun, args)
  end

  ## Private functions

  defp rpc_call(node, module, fun, args) when node == node() do
    apply(module, fun, args)
  end

  defp rpc_call(node, module, fun, args) do
    :rpc.call(node, module, fun, args)
  end

  defp find_node!(ring, key) do
    case RingManager.find_node(ring, key) do
      {:ok, node} ->
        node

      {:error, reason} ->
        raise "Failed to find ring node (ring=#{inspect(ring)}, key=#{inspect(key)}): #{inspect(reason)}"
    end
  end
end
