defmodule DistributedDynamicSupervisor.TestUtils do
  @moduledoc false

  @doc false
  defmacro assert_eventually(retries \\ 50, delay \\ 100, expr) do
    quote do
      unquote(__MODULE__).wait_until(unquote(retries), unquote(delay), fn ->
        unquote(expr)
      end)
    end
  end

  @doc false
  def start_sup(name \\ DistributedDynamicSupervisor) do
    children = [
      DistributedDynamicSupervisor.child_spec(name)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc false
  def wait_until(retries \\ 50, delay \\ 100, fun)

  def wait_until(1, _delay, fun), do: fun.()

  def wait_until(retries, delay, fun) when retries > 1 do
    fun.()
  rescue
    _ ->
      :ok = Process.sleep(delay)

      wait_until(retries - 1, delay, fun)
  end

  @doc false
  def safe_stop(pid) do
    if Process.alive?(pid), do: Supervisor.stop(pid, :normal, 5000)
  catch
    # Perhaps the `pid` has terminated already (race-condition),
    # so we don't want to crash the test
    :exit, _ -> :ok
  end
end
