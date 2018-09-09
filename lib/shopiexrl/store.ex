defmodule ShopiexRL.Store do
  use GenServer

  @base_increment_rate 1
  @base_leak_rate 2
  @base_leak_interval 500
  @base_size 20

  @spec start_link({store_name :: any(), initial_count :: any()}) :: any()
  def start_link({store_name, initial_count}) do
    GenServer.start_link(
      __MODULE__,
      {store_name, initial_count},
      name: store_name
    )
  end

  @spec init({store_name :: any(), initial_count :: any()}) :: any()
  def init({store_name, initial_count}) do
    send(self(), :leak)
    {:ok, %{name: store_name, count: initial_count}}
  end

  @spec handle_call(:health_check, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:health_check, _from, %{count: count, name: name})
      when count + @base_increment_rate > @base_size do
    {:reply, :backoff, %{count: count, name: name}}
  end

  @spec handle_call(:health_check, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:health_check, _from, %{count: count, name: name}) do
    {:reply, :ok, %{count: count, name: name}}
  end

  @spec handle_call(:increment, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:increment, _from, %{count: count, name: name})
      when count + @base_increment_rate > @base_size do
    {:reply, :too_many_requests, %{count: count, name: name}}
  end

  @spec handle_call(:increment, pid(), %{count: any(), name: any()}) :: tuple()
  def handle_call(:increment, _from, %{count: count, name: name}) do
    {:reply, count + @base_increment_rate, %{count: count + @base_increment_rate, name: name}}
  end

  @spec handle_info(:leak, %{count: any(), name: any()}) :: tuple()
  def handle_info(:leak, %{count: count, name: name}) when count < @base_leak_rate do
    Process.send_after(self(), :leak, @base_leak_interval)
    {:noreply, %{count: 0, name: name}}
  end

  @spec handle_info(:leak, %{count: any(), name: any()}) :: tuple()
  def handle_info(:leak, %{count: count, name: name}) do
    Process.send_after(self(), :leak, @base_leak_interval)
    {:noreply, %{count: count - @base_leak_rate, name: name}}
  end
end
