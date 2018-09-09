defmodule ShopiexRL.Interface do
  use GenServer

  # TODO:
  # Need to stop using atoms as the name for bucket processes
  # move to something more stable like a register
  @spec init(state :: any()) :: any()
  def init(state) do
    {:ok, state}
  end

  @spec start_link() :: any()
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec ask(nonempty_list()) :: any()
  def ask(name: name), do: ask(name)

  @spec ask(atom()) :: any()
  @spec ask(String.t()) :: any()
  def ask(name) do
    name = String.to_atom(name)

    case Process.whereis(name) do
      nil ->
        {:error, :not_found}

      pid ->
        GenServer.call(pid, :health_check)
    end
  end

  @spec install(nonempty_list()) :: any()
  def install(name: name), do: install(name)

  @spec install(atom()) :: any()
  @spec install(String.t()) :: any()
  def install(name) do
    name = String.to_atom(name)
    ShopiexRL.Supervisor.add_store(name, 0)
  end

  @spec increment(nonempty_list()) :: any()
  def increment(name: name), do: increment(name)

  @spec increment(atom()) :: any()
  @spec increment(String.t()) :: any()
  def increment(name) do
    case __MODULE__.ask(name) do
      :ok ->
        GenServer.call(String.to_atom(name), :increment)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end
end
