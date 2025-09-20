defmodule DistributedDynamicSupervisor do
  @moduledoc """
  A distributed dynamic supervisor that manages child processes
  across multiple nodes.

  ## Example

  A distributed dynamic supervisor is started with no children and often a name:

      DistributedDynamicSupervisor.start_link(name: MyApp.DistSupervisor)

  If you want to start it as a supervisor within the application's supervision
  tree, you can do in `lib/my_app/application.ex`, inside the `start/2`
  function:

      def start(_type, _args) do
        children = [
          {DistributedDynamicSupervisor, name: MyApp.DistSupervisor},
          ...
        ]

        ...
      end

  Start a child process with a key:

      iex> DistributedDynamicSupervisor.start_child(
      ...>   MyApp.DistSupervisor,
      ...>   MyApp.Worker,
      ...>   "key"
      ...> )
      {:ok, pid}

  Look up a child process by key:

      iex> DistributedDynamicSupervisor.lookup(MyApp.DistSupervisor, "key")
      #PID<0.123.456>

  Terminate a child process by key:

      iex> DistributedDynamicSupervisor.terminate_child(MyApp.DistSupervisor, "key")
      :ok

  ## Cluster

  The `DistributedDynamicSupervisor` assumes a cluster is already set up.
  You can use [`libcluster`](https://github.com/bitwalker/libcluster) to
  set up your cluster. Once the cluster is set up, the
  `DistributedDynamicSupervisor` handles the key distribution across the nodes
  automatically.

  ## Caveats

  The `DistributedDynamicSupervisor` is a simple implementation for handling
  processes across multiple nodes. It does not handle:

  - Network splits. If a network split occurs, there may be issues such as:

    - Duplicate child processes running on the same key.
    - Looking up a child process can fail despite it could be running on a
      different node.
    - Starting a child process may start the process on the wrong node due to
      a temporary network issue.
    - Terminating a child process may not terminate the process since it may
      not be able to find it.

  - Node failures (no automatic recovery). If a node fails, the child processes
    on that node will be terminated.

  - Node joins and leaves (no automatic rebalancing). If a node joins or leaves,
    the child processes will not be rebalanced across the cluster.

  If you need a more robust solution with more advanced features, consider using
  [`Horde`](https://github.com/derekkraan/horde).
  """

  use Supervisor

  alias __MODULE__.{RingManager, RPC}
  alias Phoenix.PubSub

  @typedoc "A child spec for the global supervisor"
  @type child_spec() :: {module(), keyword()} | module()

  # Inline common instructions
  @compile {:inline, register_name: 2, registry: 1, partition_sup: 1, via_partition_sup: 2, ring: 1}

  # Phoenix PubSub
  @pubsub __MODULE__.PubSub

  ## API

  @doc """
  Starts the global supervisor.
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)

    Supervisor.start_link(__MODULE__, {name, opts}, name: name)
  end

  @doc """
  Starts a child process with a key.
  """
  @spec start_child(atom(), child_spec(), any()) :: DynamicSupervisor.on_start_child()
  def start_child(name \\ __MODULE__, child_spec, key) when is_atom(name) do
    rpc_call(name, key, __MODULE__, :start_child_local, [name, child_spec, key])
  end

  @doc """
  Starts a child process with a key on the local node.
  """
  @spec start_child_local(atom(), child_spec(), any()) :: {:ok, pid()} | {:error, term()}
  def start_child_local(name, child_spec, key) when is_atom(name) do
    with {:ok, pid} <-
           DynamicSupervisor.start_child(
             via_partition_sup(name, key),
             start_child_spec(name, child_spec, key)
           ) do
      PubSub.broadcast(@pubsub, "dds:#{name}", {:child_started, key, pid})

      {:ok, pid}
    end
  end

  @doc """
  Terminates a child process by key.
  """
  @spec terminate_child(atom(), any()) :: :ok | {:error, :not_found}
  def terminate_child(name \\ __MODULE__, key) do
    rpc_call(name, key, __MODULE__, :terminate_child_local, [name, key])
  end

  @doc """
  Terminates a child process by key on the local node.
  """
  @spec terminate_child_local(atom(), any()) :: :ok | {:error, :not_found}
  def terminate_child_local(name, key) do
    pid = lookup_local(name, key)

    if is_pid(pid) and Process.alive?(pid) do
      DynamicSupervisor.terminate_child(via_partition_sup(name, key), pid)
    else
      {:error, :not_found}
    end
  catch
    :exit, _reason -> {:error, :not_found}
  end

  @doc """
  Looks up a child process by key.
  """
  @spec lookup(atom(), any()) :: pid() | nil
  def lookup(name \\ __MODULE__, key) do
    rpc_call(name, key, __MODULE__, :lookup_local, [name, key])
  end

  @doc """
  Looks up a child process by key on the local node.
  """
  @spec lookup_local(atom(), any()) :: pid() | nil
  def lookup_local(name, key) do
    name
    |> registry()
    |> Registry.lookup(key)
    |> case do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc """
  Looks up a child process by key.
  """
  @spec lookup!(atom(), any()) :: pid()
  def lookup!(name \\ __MODULE__, key) do
    case lookup(name, key) do
      nil -> raise "Child process not found for key: #{inspect(key)}"
      pid -> pid
    end
  end

  @doc """
  Returns the registered name for a key.
  """
  @spec register_name(atom(), any()) :: {:via, Registry, {module(), any()}}
  def register_name(name, key) do
    {:via, Registry, {registry(name), key}}
  end

  @doc """
  Returns the ring module for a name.
  """
  @spec ring(atom()) :: module()
  def ring(name), do: Module.concat([name, Ring])

  ## Callbacks

  @impl true
  def init({name, _opts}) do
    ring = ring(name)

    children = [
      {ExHashRing.Ring, name: ring},
      {RingManager, name: name, ring: ring},
      {Registry, keys: :unique, name: registry(name)},
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: partition_sup(name)}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  ## Private functions

  defp registry(name), do: Module.concat([name, Registry])

  defp partition_sup(name), do: Module.concat([name, PartitionSupervisor])

  defp via_partition_sup(name, key) do
    {:via, PartitionSupervisor, {partition_sup(name), key}}
  end

  defp start_child_spec(name, {module, opts}, key)
       when is_atom(name) and is_atom(module) and is_list(opts) do
    {module, Keyword.put(opts, :name, register_name(name, key))}
  end

  defp start_child_spec(name, module, key) do
    start_child_spec(name, {module, []}, key)
  end

  defp rpc_call(name, key, module, fun, args) do
    with {:badrpc, reason} <- RPC.call(name, key, module, fun, args) do
      raise "Failed to call #{inspect(module)}.#{fun} on node #{node()}: #{inspect(reason)}"
    end
  end
end
