defmodule TestCounter do
  @moduledoc false
  use GenServer

  ## API

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc false
  def inc(pid) do
    GenServer.call(pid, :inc)
  end

  ## Callbacks

  @impl true
  def init(opts) do
    initial = Keyword.get(opts, :initial, 0)

    {:ok, initial}
  end

  @impl true
  def handle_call(:inc, _, count) do
    count = count + 1

    {:reply, count, count}
  end
end
