defmodule ShopiexRL.Supervisor do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_store(store_name, initial_count) do
    # Note that start_child now directly takes in a child_spec.
    child_spec = {ShopiexRL.Store, {store_name, initial_count}}
    # Equivalent to:
    # child_spec = Leakybucket.Store.child_spec({store_name, initial_count})
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def kill_worker(store_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, store_pid)
  end

  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
