defmodule OtelDemo.Test.Mem do
  use GenServer

  import OtelDemo.OTel

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Set additional OTel attributes on the process
    put_process_attrs(%{foo: "bar", bar: "baz"})

    {:ok, [generate_data()], 10}
  end

  @impl true
  def handle_info(:timeout, _data) do
    # IO.inspect("Generating new data")

    {:noreply, generate_data(), 1000}
  end

  defp generate_data do
    :crypto.strong_rand_bytes(1024 * 1024 * 1024)
  end
end
