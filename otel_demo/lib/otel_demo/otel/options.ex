defmodule OtelDemo.OTel.Options do
  @moduledoc """
  Option definitions for the OpenTelemetry helpers.
  """

  # NimbleOptions: span options
  span_opts_def = [
    time_unit: [
      type: {:in, [:second, :millisecond, :microsecond, :nanosecond]},
      required: false,
      default: :millisecond,
      doc: """
      Defines the time unit for the `:duration` attribute which is added to the
      span automatically. Defaults to `:millisecond`.
      """
    ]
  ]

  @span_opts_def NimbleOptions.new!(span_opts_def)

  @doc false
  def definition(:span), do: @span_opts_def

  @doc false
  def validate!(opts, op) do
    NimbleOptions.validate!(opts, __MODULE__.definition(op))
  end
end
