defmodule ShopiexRL.Interface do
  require Logger

  @spec ask(atom()) :: any()
  def ask(name) do
    case Process.whereis(name) do
      nil ->
        {:error, :not_found}

      pid ->
        GenServer.call(pid, :health_check)
    end
  end

  @spec install(atom()) :: any()
  def install(name) do
    Logger.info(fn ->
      "[ShopiexRL.Interface]: Asking supervisor to start a store for #{inspect(name)}"
    end)
    ShopiexRL.StoreSupervisor.add_store(name, 0)
  end

  @spec increment(atom()) :: any()
  def increment(name) do
    case __MODULE__.ask(name) do
      :ok ->
        GenServer.call(String.to_atom(name), :increment)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end
end
