defmodule State.StoreRates do
  @type t :: %__MODULE__{
          increment_rate: integer(),
          leak_rate: integer(),
          leak_interval: integer(),
          cap: integer()
        }
  defstruct increment_rate: 1,
            leak_rate: 2,
            leak_interval: 500,
            cap: 20
end
