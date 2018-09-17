defmodule ShopiexRL do
  @moduledoc """
  ShopiexRL OTP application
  """
  use Application

  def start(_type, _args) do
    Memento.Table.create!(Shopiexrl.Connection)

    children = [
      {ShopiexRL.StoreSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: ShopiexRL.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def event(topic, data) do
    EventBus.notify(%EventBus.Model.Event{
      id: UUID.uuid4(),
      occurred_at: :os.system_time(:seconds),
      topic: topic,
      data: data
    })
  end
end
