defmodule OtelDemoWeb.TestController do
  use OtelDemoWeb, :controller

  use OtelDemo.OTel.Decorators

  import OtelDemo.OTel

  # Avoid dialyzer warnings
  @dialyzer {:nowarn_function, error: 2}

  ## Controller actions

  def index(conn, _params) do
    # Using the wrapper with automatic duration and error handling
    result =
      with_span(
        "test_controller.index",
        %{
          "controller" => "TestController",
          "action" => "index",
          "custom.demo" => true
        },
        fn ->
          # Simulate some work with nested spans
          simulate_database_call()
          simulate_external_api_call()

          response_data = %{
            message: "Hello from OpenTelemetry demo!",
            timestamp: DateTime.utc_now()
          }

          # Return {result, stop_attributes}
          return_span_attrs(
            response_data,
            %{
              "response.size" => byte_size(Jason.encode!(response_data)),
              "http.status_code" => 200
            }
          )
        end
      )

    json(conn, result)
  end

  def slow(conn, _params) do
    result =
      with_span(
        "test_controller.slow",
        %{
          "controller" => "TestController",
          "action" => "slow",
          "operation.type" => "slow_operation"
        },
        fn ->
          # Simulate slow operations
          simulate_slow_database_query()
          simulate_slow_external_service()
          simulate_complex_calculation()

          response_data = %{
            message: "Slow operation completed",
            duration_ms: 2500
          }

          return_span_attrs(
            response_data,
            %{
              "operation.completed" => true,
              "http.status_code" => 200
            }
          )
        end
      )

    json(conn, result)
  end

  def error(conn, _params) do
    # This will automatically handle the error and set proper span status
    try do
      with_span(
        "test_controller.error",
        %{
          "controller" => "TestController",
          "action" => "error",
          "will.error" => true
        },
        fn ->
          # Simulate an error - the wrapper will handle it automatically
          raise "Simulated error for tracing demo"
        end
      )
    rescue
      _e ->
        # The error was already recorded in the span by the wrapper
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          error: "Something went wrong"
        })
    end
  end

  def success(conn, _params) do
    # Example using the with_span helper for cases where you don't need stop attributes
    result =
      with_span(
        "test_controller.success",
        %{
          "controller" => "TestController",
          "action" => "success"
        },
        fn ->
          # Small delay to see duration
          Process.sleep(10)

          return_span_attrs(
            %{ok: :ok},
            %{
              message: "Success!",
              timestamp: DateTime.utc_now()
            }
          )
        end
      )

    json(conn, result)
  end

  def async(conn, _params) do
    result =
      with_span(
        "test_controller.async",
        %{
          "controller" => "TestController",
          "action" => "async"
        },
        fn ->
          Process.sleep(100)

          simulate_async_call()
          simulate_database_call()

          return_span_attrs(
            :ok,
            %{
              message: "Async operation completed",
              timestamp: DateTime.utc_now()
            }
          )
        end
      )

    json(conn, result)
  end

  ## Private functions

  # Private helper functions to simulate work
  @decorate spannable(
              name: "database.query",
              attributes: %{
                "db.operation" => "SELECT",
                "db.table" => "users"
              }
            )
  defp simulate_database_call do
    # Simulate DB latency
    Process.sleep(50)

    {:ok, %{}}
  end

  defp simulate_async_call do
    with_span(
      "async_task.simulate",
      %{
        "async.task.id" => "123"
      },
      fn ->
        # Simulate DB latency
        Process.sleep(50)

        OtelDemo.OTel.Task.async(fn ->
          with_span("task.async", %{"task.id" => "123"}, fn ->
            Process.sleep(100)

            {:ok,
             %{
               message: "Async task completed",
               timestamp: DateTime.utc_now()
             }}
          end)
        end)
        |> Task.await()

        :ok
      end
    )
  end

  defp simulate_external_api_call do
    with_span(
      "http.client.request",
      %{
        "http.method" => "GET",
        "http.url" => "https://api.example.com",
        "service.name" => "example-api"
      },
      fn ->
        # Simulate API latency
        Process.sleep(100)

        {:ok, %{api_response: "api_response"}}
      end
    )
  end

  defp simulate_slow_database_query do
    with_span(
      "database.slow_query",
      %{
        "db.operation" => "SELECT",
        "db.slow" => true,
        "db.query_time_ms" => 1000
      },
      fn ->
        # Simulate slow query
        Process.sleep(1000)

        {:ok, %{query_result: "query_result"}}
      end
    )
  end

  defp simulate_slow_external_service do
    with_span(
      "external.slow_service",
      %{
        "service.name" => "slow-api",
        "service.timeout" => 5000,
        "http.method" => "POST"
      },
      fn ->
        # Simulate slow external service
        Process.sleep(800)

        {:ok, %{slow_service_response: "slow_service_response"}}
      end
    )
  end

  defp simulate_complex_calculation do
    with_span(
      "calculation.complex",
      %{
        "operation" => "factorial",
        "input" => 1_000_000
      },
      fn ->
        # Simulate complex calculation
        Process.sleep(700)

        # Simulated calculation result
        result = 42

        {result,
         %{
           "calculation.result" => result,
           "calculation.complexity" => "high"
         }}
      end
    )
  end
end
