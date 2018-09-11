if Code.ensure_loaded?(:tesla) do
defmodule ShopiexRL.Tesla.Middleware do
  @moduledoc """
  Middleware between the Tesla client and the Leakybucket process
  """

  @behaviour Tesla.Middleware
  require Logger

  def call(env, next, opts) do
    opts = opts || []
    name = opts

    case ShopiexRL.Interface.ask(name) do
      :ok ->
        Logger.info(fn ->
          "[API.Tesla.Middleware.Leakybucket]: #{inspect(name)}: ok"
        end)

        run(env, next, name)

      :backoff ->
        Logger.info(fn ->
          "[API.Tesla.Middleware.Leakybucket]: #{inspect(name)}: backoff"
        end)

        {:error, :backoff}

      {:error, :not_found} ->
        Logger.info(fn ->
          "[API.Tesla.Middleware.Leakybucket]: #{inspect(name)} was not found"
        end)

        ShopiexRL.Interface.install(name)
        call(env, next, name)
    end
  end

  defp run(env, next, name: name) do
    case Tesla.run(env, next) do
      {:ok, env} ->
        Logger.info(fn ->
          "[API.Tesla.Middleware.Leakybucket]: #{inspect(name)} incrementing value"
        end)

        ShopiexRL.Interface.increment(name)
        {:ok, env}

      {:error, reason} ->
        Logger.info(fn ->
          "[API.Tesla.Middleware.Leakybucket]: #{inspect(name)} errored with reason #{
            inspect(reason)
          }"
        end)

        {:error, :unavailable}
    end
  end
end
end
