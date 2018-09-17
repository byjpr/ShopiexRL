defmodule Shopiexrl.Connection do
  use Memento.Table,
    attributes: [:id, :pool, :pid, :updated_at, :created_at],
    index: [:pool, :pid, :updated_at],
    type: :ordered_set,
    autoincrement: true

  def create(pool, pid) when is_atom(pool) and is_pid(pid) do
    %__MODULE__{
      id: UUID.uuid4(),
      pool: pool,
      pid: pid,
      updated_at: :os.system_time(:seconds),
      created_at: :os.system_time(:seconds)
    }
  end

  def change_pool(self, pool) do
    %__MODULE__{self | pool: pool, updated_at: :os.system_time(:seconds)}
    |> __MODULE__.write
  end
end
