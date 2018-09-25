defmodule State.Store do
  @type t :: %__MODULE__{
          id: <<_::288>>,
          name: String.t(),
          rates: State.StoreRates.t(),
          killdown: integer()
        }
  defstruct [:id, :name, :rates, :killdown]
end
