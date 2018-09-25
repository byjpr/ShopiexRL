defmodule ShopiexRL.EventSink do
  @moduledoc """
    EventSink blocks EventBus from producing any warnings for topics missing subscribers.
  """

  def process({_topic, _id} = event_shadow) do
    EventBus.mark_as_completed({ShopiexRL.EventSink, event_shadow})
  end
end
