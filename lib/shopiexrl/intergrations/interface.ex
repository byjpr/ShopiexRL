defmodule ShopiexRL.Interface do
  require Logger

  @spec ask(atom()) :: any()
  def ask(name) do
    case Process.whereis(name) do
      nil ->
        {:error, :not_found}

      pid ->
        :ok
    end
  end

  @spec install(atom()) :: any()
  def install(name) do
    ShopiexRL.event(:shopiexrl_store_events, %{name: name, type: :install})
    ShopiexRL.StoreSupervisor.add_store(name)
  end

  @spec acquire_lock(atom()) :: any()
  def acquire_lock(name), do: do_call(name, :request_lock)

  @spec release_lock(atom()) :: any()
  def release_lock(name), do: do_call(name, :release_lock)

  defp do_call(name, action) when is_binary(name), do: String.to_atom(name) |> do_call(action)
  defp do_call(name, action) do
    case ask(name) do
      :ok ->
        GenServer.call(name, action)

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end
end
