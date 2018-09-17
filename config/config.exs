use Mix.Config

config :event_bus,
  topics: [:shopiexrl_store_events, :shopiexrl_store_leak_events]

config :event_bus_logger,
  enabled: {:system, "EB_LOGGER_ENABLED", "true"},
  level: {:system, "EB_LOGGER_LEVEL", :info},
  topics: {:system, "EB_LOGGER_TOPICS", ".*"},
  light_logging: {:system, "EB_LOGGER_LIGHT", "false"}

config :mnesia,
  dir: '.mnesia/#{Mix.env}/#{node()}'

import_config "#{Mix.env}.exs"
