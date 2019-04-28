# [![CircleCI](https://circleci.com/gh/am-kantox/nimble_ets.svg?style=svg)](https://circleci.com/gh/am-kantox/nimble_ets)    EasyETS

The very simple [`:ets`](http://erlang.org/doc/man/ets.html) wrapper simplifying
cross-process [`:ets`](http://erlang.org/doc/man/ets.html) handling
(like [`Agent`](https://hexdocs.pm/elixir/master/Agent.html),
but [`:ets`](http://erlang.org/doc/man/ets.html)).

## Intro

`EasyETS` is a very thin simple ETS wrapper, simplifying the trivial usage of ETS
as key-value store. It is not intended to replicate `:ets` module functionality
by any mean. It might be used as a drop-in to avoid process-based `Agent` as
key-value store.

It exposes _only_ `CRUD` functionality of _ETS_, alongside with `Access` behaviour.

Built on top of `:ets`, it’s not distributed. Tables created are sets; `public`
and `named` by default. This might be changed by passing `{table_name, options}`
tuple instead of just table name to the initializer (see below.)

## Usage

There are two ways `EasyETS` might be used: as a standalone module,
or as a module extension.

### Standalone usage

```elixir
iex> EasyETS.new(MyApp.MyModuleToBeGenerated)

iex> MyApp.MyModuleToBeGenerated.ets_put(:foo, 42)
%MyApp.MyModuleToBeGenerated{table: MyApp.MyModuleToBeGenerated}

iex> MyApp.MyModuleToBeGenerated.ets_get(:foo, 42)
42

iex> term = %{data: MyApp.MyModuleToBeGenerated.ets_put(:value, 42)}
iex> update_in(term, [:data, :value], fn _ -> "👍" end)
iex> get_in(term, [:data, :value])
"👍"
```

The table is actually managed by the `EasyETS` application,
so it won’t be destroyed if the process called `EasyETS.new/1` exits.

### Module

```elixir
defmodule MyApp.MyModuleBackedByTable do
  use EasyETS

  ...
end
```

One might override `EasyETS.ets_table_name/0` in the module to change
the name of the table.

## Interface exported

`EasyETS` exports the simplest possible interface for `CRUD` on purpose.
Whether one needs more sophisticated `:ets` operations, it’s still possible
through `%MyApp.MyModuleBackedByTable{}.table` (yes, it’s a struct underneath.)
The latter holds the reference to the respective `:ets` table.

```elixir
@doc "Updates the value in the table under the key passed"
@spec ets_put(key :: term(), value :: term()) :: EasyETS.t()

@doc "Retrieves the value from the table stored under the key passed"
@spec ets_get(key :: term(), default :: any()) :: term()

@doc "Deletes the value from the table stored under the key passed"
@spec ets_del(key :: term()) :: EasyETS.t()

@doc "Returns all the values from the table"
@spec ets_all() :: list()
```

## `Access` behaviour

Modules produced / updated by `EasyETS` do support `Access` behaviour.

## `Envío` support

Modules produced / updated by `EasyETS` do send broadcast messages
on both `:update` and `:delete` actions. See [`Envío`](https://hexdocs.pm/envio/envio.html#creating-a-subscriber) documentation on how to subscribe to them.

Each message is sent to two channels: `:all` (all the updates managed by `NimbleCSV`)
and the channel with the name equal to the name of the table updated.

## Installation

```elixir
def deps do
  [
    {:nimble_ets, "~> 0.1"}
  ]
end
```

## [Documentation](https://hexdocs.pm/nimble_ets).

