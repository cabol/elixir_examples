defmodule OtelDemo.ProcessMemoryMonitor do
  use GenServer

  import OtelDemo.OTel

  @interval :timer.seconds(5)

  defstruct interval: @interval, top: 3, telemetry: :otel

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    state = struct!(__MODULE__, opts)

    schedule_tick(state.interval)

    {:ok, state}
  end

  @impl true
  def handle_info(
        :collect,
        %__MODULE__{
          interval: interval,
          top: top,
          telemetry: telemetry
        } = state
      ) do
    :recon.proc_count(:memory, top)
    |> Kernel.++(:recon.proc_count(:binary_memory, top))
    |> Enum.reduce(%{}, fn {pid, mem, meta}, acc ->
      Map.update(acc, pid, {proc_name(meta), mem}, fn {_, m} ->
        {proc_name(meta), m + mem}
      end)
    end)
    |> Enum.map(fn {pid, {name, mem}} -> {pid, name, mem} end)
    |> Enum.sort(&(elem(&1, 2) > elem(&2, 2)))
    |> Enum.take(top)
    |> Enum.each(fn {pid, name, _mem} ->
      dispatch_telemetry(telemetry, pid, name)
    end)

    schedule_tick(interval)

    {:noreply, state}
  end

  defp schedule_tick(interval) do
    Process.send_after(self(), :collect, interval)
  end

  defp dispatch_telemetry(:otel, pid, name) do
    {:memory, memory} = :recon.info(pid, :memory)
    {:binary_memory, binary_memory} = :recon.info(pid, :binary_memory)
    {:dictionary, dict} = :recon.info(pid, :dictionary)

    with_span(
      "process_memory_monitor",
      %{
        pid: inspect(pid),
        name: name,
        memory: memory,
        binary_memory: binary_memory,
        total_memory: memory + binary_memory
      }
      |> Map.merge(get_process_attrs(dict)),
      fn -> :noop end
    )
  end

  defp dispatch_telemetry(:telemetry, pid, name) do
    {:memory, memory} = :recon.info(pid, :memory)
    {:binary_memory, binary_memory} = :recon.info(pid, :binary_memory)

    :telemetry.execute(
      [:process, :memory],
      %{total: memory + binary_memory},
      %{pid: inspect(pid), name: name}
    )
  end

  defp proc_name([name | _]) when is_atom(name) do
    name
  end

  defp proc_name(_) do
    nil
  end
end
