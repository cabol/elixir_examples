defmodule OtelDemoWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},

      # Prometheus metrics reporter - integrated into Phoenix
      {TelemetryMetricsPrometheus, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond},
        description: "Total time spent processing request"
      ),

      # VM Metrics
      last_value("vm.memory.total",
        unit: {:byte, :kilobyte},
        description: "Total VM memory usage"
      ),
      last_value("vm.total_run_queue_lengths.total",
        description: "Total run queue length"
      ),
      last_value("vm.total_run_queue_lengths.cpu",
        description: "CPU run queue length"
      ),
      last_value("vm.total_run_queue_lengths.io",
        description: "IO run queue length"
      ),

      # Extra metrics
      last_value("process.memory.total",
        unit: {:byte, :kilobyte},
        tags: [:name, :pid],
        description: "Total process memory usage"
      )
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {OtelDemoWeb, :count_users, []},

      # VM measurements
      # {__MODULE__, :vm_measurements, []}
    ]
  end
end
