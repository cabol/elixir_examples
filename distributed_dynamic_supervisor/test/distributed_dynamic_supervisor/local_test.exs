defmodule DistributedDynamicSupervisor.LocalTest do
  use ExUnit.Case

  import DistributedDynamicSupervisor.TestUtils

  alias DistributedDynamicSupervisor, as: DDS

  setup do
    {:ok, pid1} = DDS.start_link()
    {:ok, pid2} = DDS.start_link(name: :named_global_sup)

    on_exit(fn ->
      safe_stop(pid1)
      safe_stop(pid2)
    end)

    {:ok, named_sup: :named_global_sup}
  end

  describe "start_child/1" do
    test "ok: starts a child process with a default global supervisor" do
      assert {:ok, pid} = DDS.start_child(TestCounter, "start_child_test")

      assert is_pid(pid)
      assert TestCounter.inc(pid) == 1
    end

    test "ok: starts a child process with a named global supervisor", %{named_sup: named_sup} do
      assert {:ok, pid} = DDS.start_child(named_sup, TestCounter, "start_child_test")

      assert is_pid(pid)
      assert TestCounter.inc(pid) == 1
    end
  end

  describe "terminate_child/1" do
    test "ok: terminates a child process with a default global supervisor" do
      assert {:ok, _pid} = DDS.start_child(TestCounter, "terminate_child_test")

      assert DDS.terminate_child("terminate_child_test") == :ok

      assert_eventually do
        assert DDS.lookup("terminate_child_test") == nil
      end
    end

    test "ok: terminates a child process with a named global supervisor", %{named_sup: named_sup} do
      assert {:ok, _pid} =
               DDS.start_child(named_sup, TestCounter, "terminate_child_test")

      assert DDS.terminate_child(named_sup, "terminate_child_test") == :ok

      assert_eventually do
        assert DDS.lookup("terminate_child_test") == nil
      end
    end

    test "error: returns an error if the child process is not found" do
      assert DDS.terminate_child("unknown") == {:error, :not_found}
    end
  end

  describe "lookup/1" do
    setup %{named_sup: named_sup} do
      {:ok, pid1} = DDS.start_child(TestCounter, "lookup_test")
      {:ok, pid2} = DDS.start_child(named_sup, TestCounter, "lookup_test")

      on_exit(fn ->
        :ok = DDS.terminate_child("lookup_test")
        :ok = DDS.terminate_child(named_sup, "lookup_test")
      end)

      {:ok, pid1: pid1, pid2: pid2, key: "lookup_test"}
    end

    test "ok: returns the pid of the child process", %{
      named_sup: named_sup,
      pid1: pid1,
      pid2: pid2,
      key: key
    } do
      assert DDS.lookup(key) == pid1
      assert DDS.lookup(named_sup, key) == pid2
    end

    test "ok: returns nil if the child process is not found" do
      assert DDS.lookup("unknown") == nil
    end

    test "ok: increments the counter", %{
      named_sup: named_sup,
      pid1: pid1,
      pid2: pid2,
      key: key
    } do
      assert DDS.lookup!(key) == pid1
      assert DDS.lookup!(named_sup, key) == pid2

      assert TestCounter.inc(pid1) == 1
      assert TestCounter.inc(pid1) == 2
      assert TestCounter.inc(pid1) == 3

      assert TestCounter.inc(pid2) == 1
      assert TestCounter.inc(pid2) == 2
      assert TestCounter.inc(pid2) == 3
    end
  end

  describe "lookup!/1" do
    test "ok: returns the pid of the child process" do
      assert {:ok, pid} = DDS.start_child(TestCounter, "lookup!_test")

      assert DDS.lookup!("lookup!_test") == pid
    end

    test "error: raises an error if the child process is not found" do
      assert_raise RuntimeError, ~r"Child process not found for key: \"unknown\"", fn ->
        DDS.lookup!("unknown")
      end
    end
  end
end
