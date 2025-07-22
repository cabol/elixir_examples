defmodule OtelDemo.OTel.Task do
  @moduledoc """
  Wrapper for Elixir `Task` module.
  """

  ## API

  @doc """
  Same as `Task.async/1` but it sets the current span context on each
  started task.
  """
  @spec async((-> any())) :: Task.t()
  def async(fun) do
    ctx = OpenTelemetry.Tracer.current_span_ctx()

    Task.async(fn ->
      OpenTelemetry.Tracer.set_current_span(ctx)

      fun.()
    end)
  end

  @doc """
  Same as `Task.async_stream/3` but it sets the current span context on each
  started task.
  """
  @spec async_stream(Enumerable.t(), (term() -> term()), keyword()) :: Enumerable.t()
  def async_stream(enumerable, fun, options \\ []) do
    ctx = OpenTelemetry.Tracer.current_span_ctx()

    Task.async_stream(
      enumerable,
      fn elem ->
        OpenTelemetry.Tracer.set_current_span(ctx)

        fun.(elem)
      end,
      options
    )
  end
end
