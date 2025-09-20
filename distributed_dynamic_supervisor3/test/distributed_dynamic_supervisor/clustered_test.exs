defmodule DistributedDynamicSupervisor.ClusteredTest do
  use DistributedDynamicSupervisor.NodeCase
  use Mimic

  import DistributedDynamicSupervisor.TestUtils

  alias DistributedDynamicSupervisor, as: DDS
  alias DistributedDynamicSupervisor.RPC

  setup do
    nodes = [node() | Node.list()]

    node_pid_list =
      start_supervisors(
        nodes,
        [{DDS, name: :global_clustered_sup}]
      )

    on_exit(fn ->
      stop_supervisors(node_pid_list)
    end)

    {:ok, named_sup: :global_clustered_sup}
  end

  describe "cluster" do
    test "processes are started, looked up and terminated on the correct node", %{
      named_sup: named_sup
    } do
      for _ <- 0..100 do
        key = generate_key(32)

        assert {:ok, pid} =
                 RPC.call(named_sup, key, DDS, :start_child, [named_sup, TestCounter, key])

        assert_eventually do
          assert DDS.lookup(named_sup, key) == pid
        end

        assert TestCounter.inc(pid) == 1

        assert RPC.call(named_sup, key, DDS, :terminate_child, [named_sup, key]) == :ok

        assert_eventually do
          assert DDS.lookup(named_sup, key) == nil
        end
      end
    end

    test "badrpc errors are raised", %{named_sup: named_sup} do
      DistributedDynamicSupervisor.RPC
      |> expect(:call, fn _name, _key, _module, _fun, _args ->
        {:badrpc, :timeout}
      end)

      err =
        "Failed to call #{inspect(DDS)}.start_child_local on node #{node()}: :timeout"

      assert_raise RuntimeError, err, fn ->
        DDS.start_child(named_sup, TestCounter, "badrpc_error")
      end
    end
  end

  ## Private functions

  defp generate_key(len) do
    len
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
    |> String.slice(0, len)
  end
end
