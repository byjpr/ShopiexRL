defmodule ShopiexRL.StoreSupervisor do
  use DynamicSupervisor

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_store(store_name, initial_count) do
    child_spec = {ShopiexRL.Store, {store_name, initial_count}}
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
