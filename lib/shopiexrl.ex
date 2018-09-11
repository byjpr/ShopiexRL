defmodule ShopiexRL do
  @moduledoc """
  ShopiexRL OTP application
  """
  use Application

  def start(_type, _args) do
    children = [
      {ShopiexRL.StoreSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: ShopiexRL.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
