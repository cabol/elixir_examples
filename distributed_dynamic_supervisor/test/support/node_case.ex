defmodule DistributedDynamicSupervisor.NodeCase do
  @moduledoc """
  Based on `Phoenix.PubSub.NodeCase`.
  Copyright (c) 2014 Chris McCord
  """

  @timeout 5000

  defmacro __using__(opts \\ [async: true]) do
    quote do
      use ExUnit.Case, unquote(opts)
      import unquote(__MODULE__)
      @moduletag :clustered

      @timeout unquote(@timeout)
    end
  end

  def start_supervisors(nodes, supervisors) do
    for node <- nodes, {supervisor, opts} <- supervisors do
      {:ok, pid} = start_supervisor(node, supervisor, opts)

      {node, supervisor, pid}
    end
  end

  def start_supervisor(node, supervisor, opts \\ []) do
    rpc(node, supervisor, :start_link, [opts])
  end

  def stop_supervisors(node_pid_list) do
    Enum.each(node_pid_list, fn {node, _supervisor, pid} ->
      stop_supervisor(node, pid)
    end)
  end

  def stop_supervisor(node, pid) do
    rpc(node, Supervisor, :stop, [pid, :normal, @timeout])
  end

  def rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end
end
