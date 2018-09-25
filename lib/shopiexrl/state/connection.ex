defmodule Shopiexrl.Connection do
  use Memento.Table,
    attributes: [:id, :pool, :pid, :updated_at, :created_at, :state],
    index: [:pool, :pid, :updated_at],
    type: :ordered_set,
    autoincrement: true

  use Machinery,
    # The first state declared will be considered
    # the initial state
    states: [
      "unassigned",
      "assigned",
      "cooldown"
    ],
    transitions: %{
      "unassigned" => "assigned",
      "assigned" => "cooldown",
      "cooldown" => "unassigned"
    }

  ##  Assign
  def create(pool \\ :unassigned, pid \\ nil) when is_atom(pool) do
    %__MODULE__{
      id: UUID.uuid4(),
      pool: pool,
      pid: pid,
      updated_at: :os.system_time(:seconds),
      created_at: :os.system_time(:seconds)
    }
  end

  ##  Change Pool
  def change_pool(:"$end_of_table", _pool), do: :"$end_of_table"
  def change_pool(self, pool) do
    %__MODULE__{self | pool: pool, updated_at: :os.system_time(:seconds)}
  end

  ##  Release Lock
  def release_lock(:"$end_of_table"), do: :"$end_of_table"
  def release_lock([self]) do
    %__MODULE__{self | pid: nil}
  end

  ##  Assign 
  def assign_to(:"$end_of_table", _pid), do: :"$end_of_table"
  def assign_to([self], pid) do
    %__MODULE__{self | pid: pid, updated_at: :os.system_time(:seconds)}
  end

  ##  ==================================
  ##  guards
  ##  ==================================
  def with_id(id), do: {:==, :id, id}

  def from_pool(pool), do: {:==, :pool, pool}
  def from_pid(pid), do: {:==, :pid, pid}

  def updated_before(timestamp), do: {:<=, :updated_at, timestamp}
  def updated_after(timestamp), do: {:>=, :updated_at, timestamp}

  def created_before(timestamp), do: {:<=, :created_at, timestamp}
  def created_after(timestamp), do: {:>=, :created_at, timestamp}


  ##  ==================================
  ##  Query
  ##  ==================================
  def get(guards, opts \\ [limit: 1]), do: Memento.Query.select(__MODULE__, guards, opts)

  def get_unassigned(), do: __MODULE__.get(from_pool(:unassigned))

  def get_assigned(), do: __MODULE__.get(from_pool(:assigned))
  def get_assigned({:pid, pid}), do: __MODULE__.get([from_pool(:assigned), from_pid(pid)])
  def get_assigned({:id, id}), do: __MODULE__.get([from_pool(:assigned), with_id(id)])

  def get_cooldown(), do: __MODULE__.get(from_pool(:cooldown))

end
