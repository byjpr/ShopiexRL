defmodule ShopiexRL.Store do
  use GenServer

  @base_increment_rate 1
  @base_leak_rate 2
  @base_leak_interval 500
  @base_size 20

  @spec start_link({store_name :: any(), initial_count :: any()}) :: any()
  def start_link({name, initial_count}) do
    GenServer.start_link(
      __MODULE__,
      {name, initial_count},
      name: name
    )
  end

  @spec init({store_name :: any(), initial_count :: any()}) :: any()
  def init({name, initial_count}) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      name: name,
      count: initial_count,
      type: :boot
    })

    send(self(), :leak)

    {:ok, %{name: name, count: initial_count}}
  end

  @spec handle_call(:health_check, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:health_check, _from, %{count: count, name: name}) when count + @base_increment_rate > @base_size do
    ShopiexRL.event(:shopiexrl_store_events, %{
      name: name,
      count: count,
      type: :health_check,
      response: :backoff
    })

    {:reply, :backoff, %{count: count, name: name}}
  end

  @spec handle_call(:health_check, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:health_check, _from, %{count: count, name: name}) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      name: name,
      count: count,
      type: :health_check,
      response: :ok
    })

    {:reply, :ok, %{count: count, name: name}}
  end

  @spec handle_call(:increment, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:increment, _from, %{count: count, name: name}) when count + @base_increment_rate > @base_size do
    ShopiexRL.event(:shopiexrl_store_events, %{
      name: name,
      count: count,
      type: :increment,
      response: :too_many_requests
    })

    {:reply, :too_many_requests, %{count: count, name: name}}
  end

  @spec handle_call(:increment, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:increment, _from, %{count: count, name: name}) do
    ShopiexRL.event(:shopiexrl_store_events, %{
      name: name,
      count: count,
      next_count: count + @base_increment_rate,
      type: :increment,
      response: :ok
    })

    {:reply, count + @base_increment_rate, %{count: count + @base_increment_rate, name: name}}
  end

  @spec handle_info(:leak, %{count: any(), name: any()}) :: tuple()
  def handle_info(:leak, %{count: count, name: name}) when count < @base_leak_rate do
    ShopiexRL.event(:shopiexrl_store_leak_events, %{
      name: name,
      count: count,
      next_count: 0,
      type: :leak,
      response: :ok
    })

    Process.send_after(self(), :leak, @base_leak_interval)

    {:noreply, %{count: 0, name: name}}
  end

  @spec handle_info(:leak, %{count: any(), name: any()}) :: tuple()
  def handle_info(:leak, %{count: count, name: name}) do
    ShopiexRL.event(:shopiexrl_store_leak_events, %{
      name: name,
      count: count,
      next_count: count - @base_leak_rate,
      type: :leak,
      response: :ok
    })

    Process.send_after(self(), :leak, @base_leak_interval)

    {:noreply, %{count: count - @base_leak_rate, name: name}}
  end
end
