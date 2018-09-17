defmodule ShopiexRL.Store do
  use GenServer
  import ShopiexRL.Guards

  @spec start_link({store_name :: any(), initial_count :: any()}) :: any()
  def start_link({name, initial_count}) do
    GenServer.start_link(
      __MODULE__,
      %State.Store{name: name, count: initial_count, rates: store_rates_provider(1), killdown: 0},
      name: name
    )
  end

  def init(state_obj) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :boot
    })

    send(self(), :leak)

    {:ok, state_obj}
  end

  def handle_call(:health_check, _from, state_obj), do: health_check(state_obj)
  def handle_call(:request_lock, from, state_obj), do: request_lock(from, state_obj)
  def handle_info(:leak, state_obj), do: leak(state_obj)

  ##  ==================================
  ##  Private
  ##  ==================================

  def request_lock(pid, state_obj) do
    # figure out if can assign
    {:ok, "", state_obj}
  end


  defp leak_connection do

  end

  defp release_connection(pid) do

  end

  defp assign_connection(pid) do

  end

end
