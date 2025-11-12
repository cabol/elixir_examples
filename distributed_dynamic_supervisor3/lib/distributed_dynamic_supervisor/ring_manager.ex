defmodule DistributedDynamicSupervisor.RingManager do
  @moduledoc """
  Manages the hash ring for the distributed dynamic supervisor.
  """

  use GenServer

  alias DistributedDynamicSupervisor.PG
  alias ExHashRing.Ring
  alias Phoenix.PubSub

  # Internal state
  defstruct name: nil, ring: nil, pg_ref: nil

  # Phoenix PubSub
  @pubsub DistributedDynamicSupervisor.PubSub

  # Join timeout
  @join_timeout :timer.seconds(30)

  ## API

  @doc """
  Starts the ring manager.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = opts |> Keyword.fetch!(:name) |> name()

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Finds a node in the ring.
  """
  @spec find_node(Ring.ring(), any()) :: {:ok, node()} | {:error, atom()}
  def find_node(ring, key) do
    with {:ok, node} <- Ring.find_node(ring, :erlang.phash2(key)) do
      {:ok, to_node(node)}
    end
  end

  @doc """
  Returns the list of nodes in the ring.
  """
  @spec nodes(Ring.ring()) :: [node()]
  def nodes(ring) do
    {:ok, nodes} = Ring.get_nodes(ring)

    Enum.map(nodes, &to_node/1)
  end

  ## GenServer callbacks

  @impl true
  def init(opts) do
    # Trap exit signals to run cleanup job
    _ = Process.flag(:trap_exit, true)

    # Get options
    name = Keyword.fetch!(opts, :name)
    ring = Keyword.fetch!(opts, :ring)

    # Monitor the PG group
    pg_ref = PG.monitor_scope()

    # Join the PG group
    :ok = PG.join(ring)

    # Set up the ring
    _ignore = add_ring_nodes(ring, [node()])

    # Subscribe to the PubSub topic
    :ok = PubSub.subscribe(@pubsub, "dds:#{name}")

    {:ok, %__MODULE__{name: name, ring: ring, pg_ref: pg_ref}, @join_timeout}
  end

  @impl true
  def handle_info(message, state)

  # Handle EXIT signals
  def handle_info({:EXIT, _from, reason}, %__MODULE__{} = state) do
    {:stop, reason, state}
  end

  # Handle PubSub messages
  def handle_info({:child_started, key, pid}, %__MODULE__{name: name} = state)
      when node() != node(pid) do
    _ignore = DistributedDynamicSupervisor.terminate_child_local(name, key)

    {:noreply, state}
  end

  # PG join event
  def handle_info(
        {pg_ref, :join, ring, pids},
        %__MODULE__{pg_ref: pg_ref, ring: ring} = state
      ) do
    _ignore = add_ring_nodes(ring, pids)

    {:noreply, state}
  end

  # PG leave event
  def handle_info(
        {pg_ref, :leave, ring, pids},
        %__MODULE__{pg_ref: pg_ref, ring: ring} = state
      ) do
    _ignore = rem_ring_nodes(ring, pids)

    {:noreply, state}
  end

  # Join timeout
  def handle_info(:timeout, %__MODULE__{ring: ring} = state) do
    # Join the PG group
    :ok = PG.join(ring)

    {:noreply, state, @join_timeout}
  end

  # Ignore
  def handle_info(_info, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %__MODULE__{ring: ring}) do
    # Ensure leaving the cluster when the cache stops
    :ok = PG.leave(ring)
  end

  ## Private functions

  # Inline common instructions
  @compile {:inline, name: 1}

  defp name(name), do: Module.concat([name, RingManager])

  defp add_ring_nodes(ring, pids) do
    ring
    |> PG.nodes()
    |> MapSet.new()
    |> MapSet.difference(ring |> ring_nodes() |> MapSet.new())
    |> MapSet.union(pids |> node_names() |> MapSet.new())
    |> MapSet.to_list()
    |> for_ring_node(&Ring.add_node(ring, &1))
  end

  defp rem_ring_nodes(ring, pids) do
    ring
    |> ring_nodes()
    |> MapSet.new()
    |> MapSet.difference(ring |> PG.nodes() |> MapSet.new())
    |> MapSet.union(pids |> node_names() |> MapSet.new())
    |> MapSet.to_list()
    |> for_ring_node(&Ring.remove_node(ring, &1))
  end

  defp for_ring_node(nodes, action) do
    Enum.reduce(nodes, [], fn node, acc ->
      case action.(node) do
        {:ok, _nodes} -> [node | acc]
        {:error, _reason} -> acc
      end
    end)
  end

  defp node_names(pids_or_nodes) do
    Enum.map(pids_or_nodes, fn
      pid when is_pid(pid) -> node(pid)
      node when is_atom(node) -> node
    end)
  end

  def ring_nodes(ring) do
    {:ok, nodes} = Ring.get_nodes(ring)

    Enum.map(nodes, &to_node/1)
  end

  # FIXME: This is a hack due to HashRing defines a node name as a binary.
  defp to_node(node) when is_atom(node), do: node
  # coveralls-ignore-start
  # sobelow_skip ["DOS.StringToAtom"]
  defp to_node(node) when is_binary(node), do: String.to_atom(node)
  # coveralls-ignore-stop
end
