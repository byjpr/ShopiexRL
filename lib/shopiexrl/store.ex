defmodule ShopiexRL.Store do
  use GenServer
  import ShopiexRL.Guards

  @spec start_link({store_name :: any(), initial_count :: any()}) :: any()
  def start_link({name, initial_count}) do
    GenServer.start_link(
      __MODULE__,
      %State.Store{name: name, count: initial_count, rates: store_rates_provider(1)},
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

  ##  -------------------
  ## Private
  ##  -------------------

  # Health check when the bucket is full
  defp health_check(%State.Store{
    count: count,
    rates: %State.StoreRates{
      increment_rate: increment_rate,
      cap: cap
    }
  } = state_obj) when will_overfill?(count, increment_rate, cap) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :health_check,
      response: :backoff
    })

    {:reply, :backoff, state_obj}
  end

  # default health check
  defp health_check(state_obj) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :health_check,
      response: :ok
    })

    {:reply, :ok, state_obj}
  end

  # Increment when bucket is already full
  defp increment(%State.Store{
    count: count,
    rates: %State.StoreRates{
      increment_rate: increment_rate,
      cap: cap
    }
  } = state_obj) when will_overfill?(count, increment_rate, cap) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :increment,
      response: :too_many_requests
    })

    {:reply, :too_many_requests, state_obj}
  end

  # Default increment event
  defp increment(%State.Store{ } = state_obj) do
    next_state = increase_count(state_obj)

    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      next_state: next_state,
      type: :increment,
      response: :ok
    })

    {:reply, next_state, state_obj}
  end

  # Leak when `leak_rate` is greater than `count`,
  # set count to just `0`
  defp leak(%State.Store{
    count: count,
    rates: %State.StoreRates{
      leak_interval: leak_interval,
      leak_rate: leak_rate
    }
  } = state_obj) when will_underfill?(count, leak_rate) do
    next_state = empty_count(state_obj)

    ShopiexRL.event(:shopiexrl_store_leak_events, %{
      state: state_obj,
      next_state: next_state,
      type: :leak,
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
      type: :leak,
      response: :ok
    })

    Process.send_after(self(), :leak, leak_interval)
    {:noreply, next_state}
  end

  #  ==================================
  #  State Providers and Modifiers
  #  ==================================
  defp store_rates_provider(multiplier \\ 1) do
    %State.StoreRates {
      increment_rate: 1,
      leak_rate: 2 * multiplier,
      leak_interval: 500,
      cap: 20 * multiplier
    }
  end

  defp increase_count(%State.Store{
    count: count,
    rates: %State.StoreRates{
      increment_rate: increment_rate
    }
  } = state_obj) do
    Map.put(state_obj, :count, (count + increment_rate))
  end

  defp decrease_count(%State.Store{
    count: count,
    rates: %State.StoreRates{
      leak_rate: leak_rate
    }
  } = state_obj) do
    Map.put(state_obj, :count, (count - leak_rate))
  end

  defp empty_count(%State.Store{ } = state_obj) do
    Map.put(state_obj, :count, 0)
  end
end
