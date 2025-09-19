# DistributedDynamicSupervisor
> Distributed dynamic supervisor example.

## Getting started

A distributed dynamic supervisor is started with no children and often a name:

```elixir
DistributedDynamicSupervisor.start_link(name: MyApp.DistSupervisor)
```

If you want to start it as a supervisor within the application's supervision
tree, you can do in `lib/my_app/application.ex`, inside the `start/2`
function:

```elixir
def start(_type, _args) do
  children = [
    {DistributedDynamicSupervisor, name: MyApp.DistSupervisor},
    ...
  ]

  ...
end
```

Start a child process with a key:

```elixir
iex> DistributedDynamicSupervisor.start_child(
...>   MyApp.DistSupervisor,
...>   MyApp.Worker,
...>   "key"
...> )
{:ok, pid}
```

Look up a child process by key:

```elixir
iex> DistributedDynamicSupervisor.lookup(MyApp.DistSupervisor, "key")
#PID<0.123.456>
```

Terminate a child process by key:

```elixir
iex> DistributedDynamicSupervisor.terminate_child(MyApp.DistSupervisor, "key")
:ok
```
