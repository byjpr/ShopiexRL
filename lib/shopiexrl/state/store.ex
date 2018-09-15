defmodule State.Store do
  @type t :: %__MODULE__{
          name: String.t(),
          count: integer(),
          rates: State.StoreRates.t(),
          killdown: integer()
        }
  defstruct [:name, :count, :rates, :killdown]
end
