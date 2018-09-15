defmodule ShopiexRL.Guards do
  @moduledoc """
  Guards used in the ShopiexRL OTP application
  """

  @doc """
  Checks if `count` is greater than `cap`
  """
  defmacro at_cap?(count, rate_cap) do
    quote do
      unquote(count) > unquote(rate_cap)
    end
  end

  @doc """
  Checks if `count` is less than `cap`
  """
  defmacro below_cap?(count, rate_cap) do
    quote do
      unquote(count) < unquote(rate_cap)
    end
  end

  @doc """
  Checks if incrementing by `increment_rate` will overflow `cap`
  """

  defmacro will_overfill?(count, incr_rate, rate_cap) do
    quote do
      unquote(count) + unquote(incr_rate) > unquote(rate_cap)
    end
  end

  @doc """
  Checks if decrementing by `increment_rate` will make `cap` negative
  """
  defmacro will_underfill?(count, leak_rate) do
    quote do
      unquote(count) < unquote(leak_rate)
    end
  end

end
