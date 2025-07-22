defmodule OtelDemo.OTel.Decorators do
  @moduledoc """
  Function decorators for instrumentation with OTel.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use unquote(__MODULE__).Defs

      import unquote(__MODULE__)
    end
  end

  @doc """
  This is a helper macro to build the special return for adding stop attributes
  to the current span when using the `spannable` decorator. The first argument
  `result` is the value to be returned by the function and the second argument
  `attributes` is a map with the stop attributes to add to the span.

  ## Example

      defmodule MyApp.Example do
        use OtelDemo.OTel.Decorators

        @decorate spannable(attributes: %{arg: arg})
        def some_fun(arg) do
          # your logic goes here
          return_with_span_attrs :ok, %{bar: "foo"}
        end
      end

  """
  defmacro return_with_span_attrs(return, attributes) do
    quote do
      {:with_span_attributes, {unquote(return), unquote(attributes)}}
    end
  end
end
