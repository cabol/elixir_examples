defmodule OtelDemo.BinLeakMonitor do
  use GenServer

  import OtelDemo.OTel

  # Ideally, this interval should be greater than the
  # `OtelDemo.ProcessMemoryMonitor` interval, because it garbage collects the
  # entire node first.
  @interval :timer.minutes(5)

  defstruct interval: @interval, top: 3

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
          top: top
        } = state
      ) do
    :recon.bin_leak(top)
    |> Enum.map(fn {pid, refc, meta} -> {pid, proc_name(meta), refc} end)
    |> Enum.each(fn {pid, name, refc} ->
      dispatch_telemetry(pid, name, refc)
    end)

    schedule_tick(interval)

    {:noreply, state}
  end

  defp schedule_tick(interval) do
    Process.send_after(self(), :collect, interval)
  end

  defp dispatch_telemetry(pid, name, refc) do
    {:dictionary, dict} = :recon.info(pid, :dictionary)

    with_span(
      "bin_leak_monitor",
      %{
        pid: inspect(pid),
        name: name,
        # This will show how many individual binaries were held and then freed
        # by each process as a delta. The value -5580 means there were 5580
        # fewer refc binaries after the call than before.
        refc_binaries_delta: refc
      }
      |> Map.merge(get_process_attrs(dict)),
      fn -> :noop end
    )
  end

  defp proc_name([name | _]) when is_atom(name) do
    name
  end

  defp proc_name(_) do
    nil
  end
end
