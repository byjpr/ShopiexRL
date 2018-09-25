defmodule ShopiexRL.Store do
  use GenServer

  @spec start_link({store_name :: any()}) :: any()
  def start_link({name}) do
    GenServer.start_link(
      __MODULE__,
      %State.Store{name: name, rates: store_rates_provider(1), killdown: 0},
      name: name
    )
  end

  def init(state_obj) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :boot
    })

    {:ok, state_obj, {:continue, :init}}
  end

  def handle_continue(:init, %State.Store{
       rates: %State.StoreRates{
         cap: cap
       }
     } = state_obj
    ) do

    ShopiexRL.event(:shopiexrl_store_events, %{
      state: state_obj,
      type: :async_boot
    })

    # generate pool items by `cap`
    generate_pool_items(cap)

    # Start leak messages
    send(self(), :leak)

    {:noreply, state_obj}
  end


  def handle_call(:request_lock, from, state_obj), do: request_lock(from, state_obj)
  def handle_call({:release_lock, id}, _from, state_obj), do: release_lock(id, state_obj)
  def handle_info(:leak, state_obj), do: leak_connection(state_obj)

  ##  ==================================
  ##  Private
  ##  ==================================

  defp generate_pool_items(count) when count >= 2, do: (create_pool_item(); generate_pool_items(count - 1))
  defp generate_pool_items(count) when count < 2, do: create_pool_item()

  ## Creates a pool record and sends a
  ## `boot_event` to `shopiexrl_store_events`
  ## with the details of the record
  defp create_pool_item do
    operation = fn ->
      Shopiexrl.Connection.create()
      |> Memento.Query.write()
    end

    transaction = Memento.Transaction.execute_sync(operation, 5)

    ShopiexRL.event(:shopiexrl_store_events, %{
      object: transaction,
      type: :boot_event
    })
  end

  ##
  ##
  defp store_rates_provider(multiplier \\ 1) do
    %State.StoreRates{
      increment_rate: 1,
      leak_rate: 2 * multiplier,
      leak_interval: 500,
      cap: 20 * multiplier
    }
  end

  ##
  ##
  def request_lock(pid, state_obj) do
    operation = fn ->
      Shopiexrl.Connection.get_unassigned()
      |> Shopiexrl.Connection.assign_to(pid)
      |> Shopiexrl.Connection.change_pool(:assigned)
    end

    transaction = Memento.Transaction.execute_sync(operation, 5)

    {:reply, transaction, state_obj}
  end

  ##
  ##
  defp release_lock(connection_id, state_obj) do
    operation = fn ->
      Shopiexrl.Connection.get_assigned({:id, connection_id})
      |> Shopiexrl.Connection.release_lock()
      |> Shopiexrl.Connection.change_pool(:cooldown)
    end

    transaction = Memento.Transaction.execute_sync(operation, 5)

    {:reply, transaction, state_obj}
  end

  ##
  ##
  defp leak_connection(%State.Store{rates: %State.StoreRates{leak_interval: leak_interval}} = state_obj) do
    Process.send_after(self(), :leak, leak_interval)

    operation = fn ->
      Shopiexrl.Connection.get_cooldown()
      |> Shopiexrl.Connection.change_pool(:unassigned)
    end

    case Memento.Transaction.execute_sync(operation, 5) do
      :"$end_of_table" ->
        # Empty
        ShopiexRL.event(:shopiexrl_store_events, %{
          state: state_obj,
          type: :leak,
          reply: :"$end_of_table"
        })

        {:noreply, state_obj}
      nil ->
        # Dunno
        ShopiexRL.event(:shopiexrl_store_events, %{
          state: state_obj,
          type: :leak,
          reply: nil
        })

        {:noreply, state_obj}
      transaction ->
        # Successful
        ShopiexRL.event(:shopiexrl_store_events, %{
          state: state_obj,
          type: :leak,
          reply: transaction
        })

        {:noreply, state_obj}
    end
  end

end
