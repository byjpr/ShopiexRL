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
  def handle_call(:increment, _from, state_obj), do: increment(state_obj)
  def handle_info(:leak, state_obj), do: leak(state_obj)

  ##  ==================================
  ##  Private
  ##  ==================================

  # -------------------
  # When the bucket is full
  # -------------------
  defp health_check(
         %State.Store{
           count: count,
           rates: %State.StoreRates{
             increment_rate: increment_rate,
             cap: cap
           }
         } = state_obj
       )
       when will_overfill?(count, increment_rate, cap) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :health_check,
      response: :backoff
    })

    {:reply, :backoff, state_obj}
  end

  # -------------------
  # Default health check
  # -------------------
  defp health_check(state_obj) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :health_check,
      response: :ok
    })

    {:reply, :ok, state_obj}
  end

  # -------------------
  # When the bucket is full
  # -------------------
  defp increment(
         %State.Store{
           count: count,
           rates: %State.StoreRates{
             increment_rate: increment_rate,
             cap: cap
           }
         } = state_obj
       )
       when will_overfill?(count, increment_rate, cap) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :increment,
      response: :too_many_requests
    })

    {:reply, :too_many_requests, state_obj}
  end

  # -------------------
  # Default increment event
  # -------------------
  defp increment(%State.Store{} = state_obj) do
    next_state = state_obj |> increase_count |> empty_killdown

    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      next_state: next_state,
      type: :increment,
      response: :ok
    })

    {:reply, next_state, state_obj}
  end

  # -------------------
  # Shutdown when killdown reaches 15
  # -------------------
  defp leak(
         %State.Store{
           count: count,
           killdown: killdown,
           rates: %State.StoreRates{
             leak_rate: leak_rate
           }
         } = state_obj
       )
       when will_underfill?(count, leak_rate) and killdown >= 15 do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :shutting_down,
      response: :ok
    })

    ShopiexRL.StoreSupervisor.kill_worker(self())
  end

  # -------------------
  # Leak when `leak_rate` is greater than `count`,
  # set count to just `0`
  # -------------------
  defp leak(
         %State.Store{
           count: count,
           rates: %State.StoreRates{
             leak_interval: leak_interval,
             leak_rate: leak_rate
           }
         } = state_obj
       )
       when will_underfill?(count, leak_rate) do
    next_state = state_obj |> empty_count |> inc_killdown

    ShopiexRL.event(:shopiexrl_store_leak_events, %{
      state: state_obj,
      next_state: next_state,
      type: :inc_killdown,
      response: :ok
    })

    Process.send_after(self(), :leak, leak_interval)
    {:noreply, next_state}
  end

  # Default leak event
  defp leak(%State.Store{rates: %State.StoreRates{leak_interval: leak_interval}} = state_obj) do
    next_state = decrease_count(state_obj)

    ShopiexRL.event(:shopiexrl_store_leak_events, %{
      state: state_obj,
      next_state: next_state,
      type: :normal,
      response: :ok
    })

    Process.send_after(self(), :leak, leak_interval)
    {:noreply, next_state}
  end

  #  ==================================
  #  State Providers and Modifiers
  #  ==================================
  defp store_rates_provider(multiplier \\ 1) do
    %State.StoreRates{
      increment_rate: 1,
      leak_rate: 2 * multiplier,
      leak_interval: 500,
      cap: 20 * multiplier
    }
  end

  # -------------------
  #  Increase killdown
  # -------------------
  defp inc_killdown(
         %State.Store{
           killdown: killdown
         } = state_obj
       ) do
    Map.put(state_obj, :killdown, killdown + 1)
  end

  # -------------------
  #  Empty killdown
  defp empty_killdown(
         %State.Store{
           killdown: killdown
         } = state_obj
       ) do
    Map.put(state_obj, :killdown, 0)
  end

  # -------------------
  #  Increase count
  # -------------------
  defp increase_count(
         %State.Store{
           count: count,
           rates: %State.StoreRates{
             increment_rate: increment_rate
           }
         } = state_obj
       ) do
    Map.put(state_obj, :count, count + increment_rate)
  end

  # -------------------
  #  Increase count
  # -------------------
  defp decrease_count(
         %State.Store{
           count: count,
           rates: %State.StoreRates{
             leak_rate: leak_rate
           }
         } = state_obj
       ) do
    Map.put(state_obj, :count, count - leak_rate)
  end

  # -------------------
  #  Increase count
  # -------------------
  defp empty_count(%State.Store{} = state_obj) do
    Map.put(state_obj, :count, 0)
  end
end
