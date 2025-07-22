defmodule OtelDemoWeb.Plugs.OtelPlug do
  @moduledoc """
  A plug that creates OpenTelemetry spans for Phoenix requests
  """

  import Plug.Conn
  require OpenTelemetry.Tracer, as: Tracer

  def init(opts), do: opts

  def call(conn, _opts) do
    # Extract route information
    route = get_route_info(conn)
    span_name = "HTTP #{conn.method} #{route}"

    Tracer.with_span span_name do
      # Set HTTP attributes following OpenTelemetry semantic conventions
      OpenTelemetry.Tracer.set_attributes([
        {"http.method", conn.method},
        {"http.route", route},
        {"http.scheme", to_string(conn.scheme)},
        {"http.host", get_host(conn)},
        {"http.user_agent", get_user_agent(conn)},
        {"phoenix.controller", get_controller(conn)},
        {"phoenix.action", get_action(conn)}
      ])

      # Process the request
      conn = conn |> continue_request()

      # Set response attributes
      OpenTelemetry.Tracer.set_attributes([
        {"http.status_code", conn.status || 200},
        {"http.response.size", get_response_size(conn)}
      ])

      # Set span status based on HTTP status code
      set_span_status(conn.status || 200)

      conn
    end
  end

  defp continue_request(conn) do
    # Continue with the rest of the plug pipeline
    conn
  end

  defp get_route_info(conn) do
    case conn.private do
      %{phoenix_route: route} -> route
      %{plug_route: {route, _}} -> route
      _ -> conn.request_path
    end
  end

  defp get_host(conn) do
    case get_req_header(conn, "host") do
      [host | _] -> host
      [] -> "unknown"
    end
  end

  defp get_user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [ua | _] -> ua
      [] -> "unknown"
    end
  end

  defp get_controller(conn) do
    case conn.private do
      %{phoenix_controller: controller} -> inspect(controller)
      _ -> "unknown"
    end
  end

  defp get_action(conn) do
    case conn.private do
      %{phoenix_action: action} -> to_string(action)
      _ -> "unknown"
    end
  end

  defp get_response_size(conn) do
    case get_resp_header(conn, "content-length") do
      [size | _] -> size
      [] -> "0"
    end
  end

  defp set_span_status(status_code) when status_code >= 400 do
    OpenTelemetry.Tracer.set_status(:error, "HTTP #{status_code}")
  end

  defp set_span_status(_status_code) do
    OpenTelemetry.Tracer.set_status(:ok, "OK")
  end
end
