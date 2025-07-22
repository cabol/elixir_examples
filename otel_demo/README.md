# OpenTelemetry Phoenix Demo

A comprehensive Phoenix application demonstrating OpenTelemetry tracing
patterns, best practices, and utility helpers for Elixir/Phoenix applications.

## 🎯 Project Overview

This project showcases how to integrate OpenTelemetry into a Phoenix application
with production-ready patterns including:

- **Custom tracing utilities** with automatic error handling and duration
  tracking.
- **Declarative function decorators** for annotation-based instrumentation
- **Context propagation** across async tasks and processes
- **Real-world simulation** of database queries, external API calls, and complex
  operations.
- **Visual trace inspection** using Jaeger UI

## ✨ Features

### Core OpenTelemetry Integration

- ✅ **Standard OTLP exporter** configuration
- ✅ **Jaeger integration** for visual trace inspection
- ✅ **Proper span hierarchy** and context propagation
- ✅ **Error handling** with automatic exception recording
- ✅ **Global attributes** (app name, version, environment)

### Custom Utilities

- 🔧 **`OtelDemo.OTel`** - Enhanced spanning utilities with automatic duration and error handling
- 🎨 **`OtelDemo.OTel.Decorators`** - Function decorators for declarative instrumentation
- ⚡ **`OtelDemo.OTel.Task`** - Context-aware async task wrappers
- ⚙️ **`OtelDemo.OTel.Options`** - Configuration validation using NimbleOptions

### Demo Scenarios

- 🚀 **Basic operations** with nested spans
- 🐌 **Slow operations** demonstrating timing visualization
- 💥 **Error handling** with proper span status and exception recording
- 🔄 **Async operations** with context propagation across tasks

## 🏗️ Architecture

### Main Components

```
lib/
├── otel_demo/
│   └── otel/                    # OpenTelemetry utilities
│       ├── decorators/          # Function decorators
│       ├── options.ex           # Configuration validation
│       └── task.ex             # Context-aware Task wrappers
├── otel_demo_web/
│   └── controllers/
│       └── test_controller.ex   # Demo endpoints
└── otel_demo.ex               # Main application module
```

#### `OtelDemo.OTel`

The core utility module providing:
- **`with_span/4`** - Full-featured span wrapper with stop attributes
- **`simple_span/4`** - Simplified span wrapper for basic use cases
- **Automatic duration tracking** in configurable time units
- **Comprehensive error handling** with exception recording
- **Global attributes** management

#### `OtelDemo.OTel.Decorators`

Function decorators for declarative instrumentation:

```elixir
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
```

#### `OtelDemo.OTel.Task`

Context-aware wrappers for Elixir's `Task` module:
- **`async/1`** - Maintains span context in async tasks
- **`async_stream/3`** - Context propagation for stream processing

### Demo Endpoints

| Endpoint | Purpose | Demonstrates |
|----------|---------|--------------|
| `GET /api/test/` | Basic tracing | Nested spans, attributes, duration tracking |
| `GET /api/test/slow` | Slow operations | Multiple slow operations with timing |
| `GET /api/test/error` | Error handling | Exception recording and span status |
| `GET /api/test/async` | Async operations | Context propagation across tasks |

## 🚀 Getting Started

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 23+
- Docker and Docker Compose (for Jaeger)
- Phoenix 1.7+

### Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd otel_demo
```

2. **Install dependencies**

```bash
mix deps.get
```

3. **Set up the database**

```bash
mix ecto.setup
```

4. **Install assets**

```bash
mix assets.setup
```

### Running with Jaeger

1. **Start Jaeger**

```bash
docker-compose up -d jaeger
```

Jaeger will be available at http://localhost:16686

2. **Start the Phoenix application**

```bash
mix phx.server
```

Application runs at http://localhost:4000

3. **Generate some traces**

```bash
# Basic tracing example
curl http://localhost:4000/api/test/

# Slow operations with multiple spans
curl http://localhost:4000/api/test/slow

# Error handling demonstration
curl http://localhost:4000/api/test/error

# Async operations with context propagation
curl http://localhost:4000/api/test/async
```

4. **View traces in Jaeger**

- Open http://localhost:16686
- Select **"otel-demo"** from the Service dropdown
- Click **"Find Traces"**
- Click on individual traces to explore span details

## 📊 Understanding the Traces

### Span Hierarchy

Each request creates a hierarchical trace showing:
- **Root span** - The HTTP request
- **Controller span** - The Phoenix controller action
- **Nested spans** - Database queries, API calls, calculations
- **Async spans** - Background tasks with proper context

### Span Attributes

Traces include rich metadata:
- **HTTP attributes** - Method, status code, URL
- **Database attributes** - Operation type, table names, query time
- **Service attributes** - External service calls, timeouts
- **Custom attributes** - Business logic metadata
- **Global attributes** - App version, environment, instance info

### Error Tracking

Error scenarios demonstrate:
- **Exception recording** - Full stack traces in spans
- **Span status** - Proper error/ok status setting
- **Error propagation** - How errors bubble up through span hierarchy

## 🔧 Usage Patterns

### Basic Instrumentation

```elixir
import OtelDemo.OTel

def my_function(arg) do
  with_span "my_function", %{"input" => arg}, fn ->
    result = do_work(arg)
    {result, %{"output_size" => byte_size(result)}}
  end
end
```

### Simple Cases

```elixir
def simple_operation do
  simple_span "database.query", %{"table" => "users"}, fn ->
    # Your database query
    {:ok, results}
  end
end
```

### Declarative Decorators

```elixir
use OtelDemo.OTel.Decorators

@decorate spannable(name: "user.create", attributes: %{user_id: user_id})
def create_user(user_id, attrs) do
  # Business logic
  return_with_span_attrs({:ok, user}, %{created: true})
end
```

### Async Operations

```elixir
def process_async(data) do
  with_span "process.async", %{}, fn ->
    task = OtelDemo.OTel.Task.async(fn ->
      # This task maintains the span context
      process_in_background(data)
    end)

    result = Task.await(task)
    {result, %{processed: true}}
  end
end
```

## 🛠️ Configuration

### OpenTelemetry Setup

The application is configured to use:
- **OTLP exporter** with gRPC protocol
- **Batch span processor** for efficiency
- **Jaeger backend** for visualization
- **Resource attributes** for service identification

### Development vs Production

- **Development**: Uses local Jaeger instance
- **Production**: Configure `otlp_endpoint` to your observability platform

## 📁 Project Structure

```
├── config/
│   └── config.exs              # OpenTelemetry configuration
├── lib/
│   ├── otel_demo/
│   │   ├── otel/               # Core tracing utilities
│   │   │   ├── decorators/     # Function decorators
│   │   │   ├── decorators.ex   # Decorator macros
│   │   │   ├── options.ex      # Configuration validation
│   │   │   └── task.ex        # Context-aware tasks
│   │   └── otel.ex            # Main tracing utilities
│   └── otel_demo_web/
│       ├── controllers/
│       │   └── test_controller.ex  # Demo endpoints
│       └── router.ex          # Route definitions
├── docker-compose.yml         # Jaeger setup
└── mix.exs                   # Dependencies and releases
```

## 🔍 Best Practices Demonstrated

This demo follows some of the **OpenTelemetry patterns** that align with
industry best practices:

### ✅ **Implemented Best Practices**
1. **Separation of Concerns** - Instrumentation separated from export configuration
2. **Multiple Instrumentation Patterns** - Auto-instrumentation, manual spans, and declarative decorators
3. **Consistent Error Handling** - All spans properly record exceptions and set error status
4. **Automatic Duration Tracking** - Every operation gets timing without developer intervention
5. **Advanced Context Propagation** - Spans maintain relationships across async Task boundaries
6. **Semantic Attributes** - Following OpenTelemetry semantic conventions for HTTP, database, and service calls
7. **Global Attributes** - Consistent service metadata applied to all spans
8. **Developer Experience** - Production-ready wrappers that make correct patterns easy
9. **Resource Management** - Proper span lifecycle management with batch processing

### 📝 **Areas for Future Enhancement (Next Steps)**

While this demo covers the core patterns, additional production considerations could include:

#### **Sampling Strategies**

- **Current**: Uses default batch processing
- **Enhancement**: Demonstrate probabilistic, tail-based, and error-preserving sampling
- **Reference**: [OpenTelemetry Sampling Documentation](https://opentelemetry.io/docs/concepts/sampling/)

#### **Advanced Resource Detection**

- **Current**: Basic service identification attributes
- **Enhancement**: Environment-specific resource detectors (Kubernetes, AWS, etc.)
- **Example**: Container ID, pod name, cloud provider metadata

#### **Production Deployment Patterns**

- **Current**: Single-service demo with local Jaeger
- **Enhancement**: Multi-service setup with OpenTelemetry Collector
- **Topics**: Service mesh integration, collector deployment strategies

#### **Security & Performance**

- **Current**: Development-focused configuration
- **Enhancement**: Production security considerations, sampling rates, attribute sanitization
- **Topics**: Sensitive data handling, performance impact measurement

#### **Advanced Semantic Conventions**

- **Current**: Manual attribute definitions
- **Enhancement**: Using official semantic convention constants
- **Reference**: [Semantic Conventions Registry](https://opentelemetry.io/docs/specs/semconv/)

#### **Metrics and Logs Integration**

- **Current**: Tracing-focused demo
- **Enhancement**: Complete observability with metrics and structured logs
- **Topics**: Correlation between signals, unified observability patterns

### 🎯 **Demo Scope**

This project intentionally focuses on **tracing fundamentals and instrumentation
patterns** to provide a solid foundation. The patterns demonstrated here
(especially the utility wrappers and context propagation) solve real production
challenges and can be extended with the enhancements above as your observability
needs grow.

## 🐛 Troubleshooting

### No traces appearing in Jaeger
1. Ensure Jaeger is running: `docker-compose ps`
2. Check Phoenix logs for OpenTelemetry initialization
3. Verify endpoint configuration in `config/config.exs`

### Spans not linking properly
1. Check that you're using `OtelDemo.OTel.Task` for async operations
2. Ensure spans are created within the same process or properly propagated

### Performance concerns
1. Use batch processor (default) for production
2. Configure appropriate batch sizes and timeouts
3. Consider sampling for high-throughput applications

## 📚 Further Reading

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/languages/erlang/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Phoenix Framework](https://phoenixframework.org/)
- [Elixir Task Documentation](https://hexdocs.pm/elixir/Task.html)

## 🤝 Contributing

This is a demo project showcasing OpenTelemetry patterns. Feel free to:
- Add more instrumentation examples
- Improve the utility functions
- Add additional observability features
- Enhance documentation

## 📄 License

This project is available under the MIT License.