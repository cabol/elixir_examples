defmodule OtelDemo.OTel.Decorators.Defs do
  @moduledoc """
  Function decorators for instrumentation.
  """

  use Decorator.Define, spannable: 0, spannable: 1

  alias OtelDemo.OTel

  @doc false
  def spannable(block, context) do
    spannable([], block, context)
  end

  @doc ~S"""
  Provides an annotation-based declarative approach to emit OTEL spans;
  it is a wrapper for `OtelDemo.OTel.with_span/3`.

  ## Options

    * `:name` - (Optional) A string or atom defining the span name.
      This is particularly useful and required when working with tracing
      APIs and/or tools (e.g.: OpenTelemetry, OpenTracing, etc.) to set
      the name of the span. Defaults the the string given by
      `"#{ctx.module}.#{ctx.name}/#{ctx.arity}"`. For example,
      `"MyApp.some_function/1"`.

    * `:attributes` - (Optional) A map with the span attributes. It is also
      useful when working with tracing APIs and/or tools, the same as
      `:name` option.

    * `:time_unit` - The time unit for the `:duration` attribute which is added
      to the span automatically. The value for `:time_unit` option can be:
      `:second`, `:millisecond`, `:microsecond`, `:nanosecond`.
      Defaults to `:millisecond`.

  ## Example

      defmodule MyApp.DecoratedExample do
        use OtelDemo.OTel.Decorators

        @decorate spannable()
        def my_fun(arg) do
          # your logic goes here
        end

        @decorate spannable(name: "my-span", attributes: %{arg: arg})
        def another_fun(arg) do
          # your logic goes here
        end

        # Returning stop attributes
        @decorate spannable(attributes: %{arg: arg})
        def another_fun(arg) do
          # your logic goes here
          return_with_span_attrs :ok, %{bar: "foo"}
        end
      end

  It is possible also to decorate all functions in a module by using
  `@decorate_all` attribute. It is important to note that the `@decorate_all`
  attribute only affects the function clauses below its definition.
  For example:

      defmodule MyApp.AllDecoratedExample do
        use OtelDemo.OTel.Decorators

        @decorate_all spannable()

        def my_fun(arg) do
          # your logic goes here
        end

        def another_fun(arg) do
          # your logic goes here
        end
      end

  In this example, the `spannable()` decorator is applied to both `my_fun/1`
  and `another_fun/1`.

  Decorating all functions in a module is particularly useful for those cases
  we are sure we want spans for all the functions and also there are not
  specific span attributes per function, for instance, attributes bound to
  some input argument.
  """
  def spannable(attrs, block, ctx) do
    span_name =
      Keyword.get_lazy(attrs, :name, fn ->
        "#{ctx.module}.#{ctx.name}/#{ctx.arity}"
      end)

    span_attrs =
      Keyword.get_lazy(attrs, :attributes, fn ->
        quote(do: %{})
      end)

    time_unit = Keyword.get(attrs, :time_unit, :millisecond)

    quote do
      OTel.with_span(
        unquote(span_name),
        unquote(span_attrs),
        fn ->
          unquote(__MODULE__).eval_result(unquote(block))
        end,
        time_unit: unquote(time_unit)
      )
    end
  end

  @doc """
  Internal convenience function to evaluate whether the result comes
  with span metadata or not.
  """
  @spec eval_result(term()) :: {term, map}
  def eval_result(result)

  def eval_result({:with_span_attributes, {_, _} = return_with_meta}) do
    return_with_meta
  end

  def eval_result(return) do
    {return, %{}}
  end
end
