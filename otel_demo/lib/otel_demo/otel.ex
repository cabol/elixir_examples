defmodule OtelDemo.OTel do
  @moduledoc """
  Utility functions for OpenTelemetry with automatic duration tracking,
  error handling, and global attributes.
  """

  alias OtelDemo.OTel.Options

  require OpenTelemetry.Tracer
  require OpenTelemetry.Span

  ## Types

  @typedoc "Span function type"
  @type span_fun() :: (-> {:with_span_attributes, {result :: term(), stop_attrs :: map()}} | any())

  @typedoc "Proxy type for the span name"
  @type span_name() :: :opentelemetry.span_name()

  @typedoc "Proxy type for the span attributes"
  @type span_attrs() :: :opentelemetry.attributes_map()

  ## API

  @doc """
  This is a wrapper function for `OpenTelemetry.Tracer.with_span/3`
  but it adds some extra features.

  By default, no stop attributes are added to the span when the `span_fun`
  returns a value. If you want to add stop attributes, you can return a
  `{:with_span_attributes, {result, stop_attributes}}` tuple. However,
  you can use the `return_span_attrs/2` function to return a tuple with the
  result and the stop attributes (recommended).

  ## Options

    * `:time_unit` - The time unit for the `:duration` attribute which is added
      to the span automatically. The value for `:time_unit` option can be:
      `:second`, `:millisecond`, `:microsecond`, `:nanosecond`.
      Defaults to `:millisecond`.

  ## Example

      iex> import OtelDemo.OTel
      iex> with_span "my-span", fn ->
      ...>   :ok
      ...> end
      :ok
      iex> with_span "my-span", %{foo: "bar"}, fn ->
      ...>   return_span_attrs  :ok, %{my_tag: "tag"}
      ...> end
      :ok

  """
  @spec with_span(span_name(), span_attrs(), span_fun(), keyword()) :: term()
  def with_span(span_name, span_attrs \\ %{}, span_fun, opts \\ []) do
    # Validate options
    opts = Options.validate!(opts, :span)

    time_unit = Keyword.fetch!(opts, :time_unit)

    start_opts = %{
      attributes: Map.merge(global_attrs(), span_attrs)
    }

    OpenTelemetry.Tracer.with_span span_name, start_opts do
      start_time = System.monotonic_time(time_unit)

      try do
        {return, stop_attrs} =
          case span_fun.() do
            {:with_span_attributes, {result, stop_attrs}} ->
              {result, stop_attrs}

            result ->
              {result, %{}}
          end

        stop_attrs
        |> Map.put(:duration, System.monotonic_time(time_unit) - start_time)
        |> OpenTelemetry.Tracer.set_attributes()

        OpenTelemetry.Tracer.set_status(:ok, "OK")

        return
      rescue
        e ->
          handle_error(:exception, e, __STACKTRACE__, start_time, time_unit)
      catch
        :exit, reason ->
          handle_error(:exit, reason, __STACKTRACE__, start_time, time_unit)
      end
    end
  end

  @doc """
  This is a helper macro to return a tuple with the result and the stop
  attributes.

  ## Example

      iex> import OtelDemo.OTel
      iex> with_span "my-span", %{foo: "bar"}, fn ->
      ...>   return_span_attrs  :ok, %{my_tag: "tag"}
      ...> end
      :ok

  """
  defmacro return_span_attrs(return, attributes) do
    quote do
      {:with_span_attributes, {unquote(return), unquote(attributes)}}
    end
  end

  @doc """
  Get global attributes that are added to every span.
  These include application information and environment details.
  """
  @spec global_attrs() :: %{optional(atom() | binary()) => atom() | binary() | number()}
  def global_attrs do
    with nil <- :persistent_term.get({__MODULE__, :global_attrs}, nil) do
      %{
        app: "otel-demo",
        env: to_string(Mix.env()),
        app_vsn: "#{Application.spec(:otel_demo, :vsn)}",
        node: to_string(Node.self()),
        pid: inspect(self())
      }
      |> tap(&:persistent_term.put({__MODULE__, :global_attrs}, &1))
    end
  end

  @doc """
  Update global attributes. Useful for setting environment-specific
  or runtime-discovered attributes.

  ## Example

      iex> update_global_attrs(%{instance_id: "i-1234567890abcdef0"})
      :ok

  """
  @spec update_global_attrs(map()) :: :ok
  def update_global_attrs(new_attrs) when is_map(new_attrs) do
    current_attrs = global_attrs()
    updated_attrs = Map.merge(current_attrs, new_attrs)

    :ok = :persistent_term.put({__MODULE__, :global_attrs}, updated_attrs)
  end

  @doc """
  Clears the cached global attributes, forcing them to be recalculated
  on the next call to global_attrs/0.
  """
  @spec clear_global_attrs() :: :ok
  def clear_global_attrs do
    :persistent_term.erase({__MODULE__, :global_attrs})

    :ok
  end

  ## Private functions

  # Avoid dialyzer warnings
  @dialyzer {:nowarn_function, handle_error: 5}

  defp handle_error(:exception, e, st, start_time, time_unit) do
    current_span = OpenTelemetry.Tracer.current_span_ctx()

    if current_span != :undefined do
      OpenTelemetry.Span.record_exception(current_span, e, st,
        duration: System.monotonic_time(time_unit) - start_time
      )
    end

    OpenTelemetry.Tracer.set_status(:error, Exception.message(e))

    duration = System.monotonic_time(time_unit) - start_time
    OpenTelemetry.Tracer.set_attribute(:duration, duration)

    reraise e, st
  end

  defp handle_error(:exit, reason, st, start_time, time_unit) do
    error_attributes = [
      {"error.kind", "exit"},
      {"error.reason", inspect(reason)},
      {"error.stacktrace", Exception.format_stacktrace(st)}
    ]

    current_span = OpenTelemetry.Tracer.current_span_ctx()

    if current_span != :undefined do
      OpenTelemetry.Span.add_event(current_span, "exit", error_attributes)
    end

    OpenTelemetry.Tracer.set_status(:error, "Process exited with reason: #{inspect(reason)}")

    duration = System.monotonic_time(time_unit) - start_time
    OpenTelemetry.Tracer.set_attribute(:duration, duration)

    exit(reason)
  end
end
