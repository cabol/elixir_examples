defmodule DistributedDynamicSupervisor.PG do
  @moduledoc """
  Wrapper for the `:pg` module.
  """

  @doc """
  Returns the `:pg` scope.
  """
  @spec scope() :: atom()
  def scope, do: __MODULE__

  @doc """
  Wrapper for `:pg.monitor_scope/1`.
  """
  @spec monitor_scope() :: reference()
  def monitor_scope do
    {pg_ref, _} = :pg.monitor_scope(scope())

    pg_ref
  end

  @doc """
  Returns the `:pg` child spec.
  """
  @spec child_spec() :: Supervisor.child_spec()
  def child_spec do
    %{id: :pg, start: {:pg, :start_link, [scope()]}}
  end

  @doc """
  Joins the node where the cache `name`'s supervisor process is running to the
  `name`'s node group.
  """
  @spec join(name :: atom()) :: :ok
  def join(name) do
    pid = Process.whereis(name) || self()

    if pid in pg_members(name) do
      :ok
    else
      :ok = pg_join(name, pid)
    end
  end

  @doc """
  Makes the node where the cache `name`'s supervisor process is running, leave
  the `name`'s node group.
  """
  @spec leave(name :: atom()) :: :ok
  def leave(name) do
    pg_leave(name, Process.whereis(name) || self())
  end

  @doc """
  Returns the list of nodes joined to given `name`'s node group.
  """
  @spec nodes(name :: atom()) :: [node()]
  def nodes(name) do
    name
    |> pg_members()
    |> Enum.map(&node/1)
    |> Enum.uniq()
  end

  ## PG

  defp pg_join(name, pid) do
    :ok = :pg.join(__MODULE__, name, pid)
  end

  defp pg_leave(name, pid) do
    _ = :pg.leave(__MODULE__, name, pid)

    :ok
  end

  defp pg_members(name) do
    :pg.get_members(__MODULE__, name)
  end
end
