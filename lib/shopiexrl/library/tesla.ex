if Code.ensure_loaded?(:tesla) do
defmodule ShopiexRL.Tesla.Middleware do
  @moduledoc """
  Middleware for [tesla](https://github.com/teamon/tesla)
  Remember to add `{:tesla, "~> 1.1.0"}` to dependencies (and `:tesla` to applications in `mix.exs`)
  Also, you need to recompile ShopiexRL after adding `:tesla` dependency:
  ```
  mix deps.clean shopiexrl
  mix deps.get
  mix deps.compile shopiexrl
  ```
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
