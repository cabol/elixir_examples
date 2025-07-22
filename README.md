# Elixir Examples

## About

This project aims to showcase the Elixir capabilities for building distributed
applications and the relevant tools available in the ecosystem, using a set of
examples that implement common patterns and use cases.

_**DISCLAIMER:**_ These examples don't aim to cover features like failure,
recovery, network splits, cluster rebalancing, etc. They may be useful for
some simpler use cases, but they are not a complete, robust solution to cover
all failure scenarios. If you require a more robust solution with advanced
features, consider using a project based on your specific needs.

## Catalog

- [DistributedDynamicSupervisor](./distributed_dynamic_supervisor) -
  A supervisor that manages child processes across multiple nodes.
- [OpenTelemetry Demo](./otel_demo) -
  A comprehensive Phoenix application demonstrating OpenTelemetry tracing
  patterns, best practices, and utility helpers for Elixir/Phoenix applications.
