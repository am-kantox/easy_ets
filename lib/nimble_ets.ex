defmodule NimbleETS do
  @moduledoc """
  `NimbleETS` is a very thin simple ETS wrapper, simplifying the trivial usage of ETS
  as key-value store. It is not intended to replicate `:ets` module functionality
  by any mean. It might be used as a drop-in to avoid process-based `Agent` as
  key-value store.

  It exposes _only_ `CRUD` functionality of _ETS_, alongside with `Access` behaviour.

  Built on top of `:ets`, it’s not distributed. Tables created are sets; `public`
  and `named` by default. This might be changed by passing `{table_name, options}`
  tuple instead of just table name to the initializer (see below.)

  ### Usage

  There are two ways `NimbleETS` might be used: as a standalone module,
  or as a module extension.

  #### Standalone usage

      {:ok, pid} = NimbleETS.Tables.start_link()
      NimbleETS.new(MyApp.MyModuleToBeGenerated)
      MyApp.MyModuleToBeGenerated.ets_put(:foo, 42)
      #⇒ %MyApp.MyModuleToBeGenerated{table: MyApp.MyModuleToBeGenerated}

      MyApp.MyModuleToBeGenerated.ets_get(:foo, 42)
      #⇒ 42

      term = %{data: MyApp.MyModuleToBeGenerated.ets_put(:value, 42)}
      update_in(term, [:data, :value], fn _ -> "👍" end)
      get_in(term, [:data, :value])
      #⇒ "👍"
      GenServer.stop(pid)

  The table is actually managed by the `NimbleETS` application,
  so it won’t be destroyed if the process called `NimbleETS.new/1` exits.

  #### Module

      defmodule MyApp.MyModuleBackedByTable do
        use NimbleETS
      end
      MyApp.MyModuleBackedByTable.ets_put(:foo, 42)
      MyApp.MyModuleBackedByTable.ets_get(:foo)
      #⇒ 42
      MyApp.MyModuleBackedByTable.ets_del(:foo)
      MyApp.MyModuleBackedByTable.ets_get(:foo)
      #⇒ 42

  One might override `ets_table_name/0` in the module to change
  the name of the table.

  ### Interface exported

  `NimbleETS` exports the simplest possible interface for `CRUD` on purpose.
  Whether one needs more sophisticated `:ets` operations, it’s still possible
  through `%MyApp.MyModuleBackedByTable{}.table` (yes, it’s a struct underneath.)
  The latter holds the reference to the respective `:ets` table.

  ```elixir
  @doc "Updates the value in the table under the key passed"
  @spec ets_put(key :: term(), value :: term()) :: NimbleETS.t()

  @doc "Retrieves the value from the table stored under the key passed"
  @spec ets_get(key :: term(), default :: any()) :: term()

  @doc "Deletes the value from the table stored under the key passed"
  @spec ets_del(key :: term()) :: NimbleETS.t()

  @doc "Returns all the values from the table"
  @spec ets_all() :: list()
  ```

  ### `Access` behaviour

  Modules produced / updated by `NimbleETS` do support `Access` behaviour.

  ### [`Envío`](https://hexdocs.pm/envio) support

  Modules produced / updated by `NimbleETS` do send broadcast messages
  on both `:update` and `:delete` actions. See [`Envío`](https://hexdocs.pm/envio/envio.html#creating-a-subscriber) documentation on how to subscribe to them.

  Each message is sent to two channels: `:all` (all the updates managed by `NimbleCSV`)
  and the channel with the name equal to the name of the table updated.
  """

  @doc """
  Creates new ETS table(s) wrapper(s) based on definitions passed as a parameter.

  _Examples:_

      NimbleETS.new(MyApp.MyExistingModule)
      NimbleETS.new([{MyApp.WithOptions, [:bag]}, MyApp.ToCreate])

  For the full list of options please refer to
  [`:ets.new/2`](http://erlang.org/doc/man/ets.html#new-2) documentation.
  """
  defdelegate new(definitions), to: NimbleETS.Tables

  ##############################################################################
  # Meta (use NimbleETS)
  defmacro __using__(opts \\ []) do
    table = opts[:table]

    quote do
      @table unquote(table) || __MODULE__
      defstruct table: @table

      @type t :: %__MODULE__{table: atom()}

      @doc "Updates the value in the table under the key passed"
      @spec ets_put(key :: term(), value :: term()) :: t()
      def ets_put(key, value) do
        NimbleETS.Tables.ets_del(ets_table_name(), key)
        NimbleETS.Tables.ets_put(ets_table_name(), key, value)
        publish(%{action: :update, key: key, value: value})
        %__MODULE__{table: ets_table_name()}
      end

      @doc "Retrieves the value from the table stored under the key passed"
      @spec ets_get(key :: term(), default :: any()) :: term()
      def ets_get(key, default \\ nil),
        do: NimbleETS.Tables.ets_get(ets_table_name(), key, default)

      @doc "Deletes the value from the table stored under the key passed"
      @spec ets_del(key :: term()) :: t()
      def ets_del(key) do
        NimbleETS.Tables.ets_del(ets_table_name(), key)
        publish(%{action: :delete, key: key})
        %__MODULE__{table: ets_table_name()}
      end

      @doc "Returns all the values from the table"
      @spec ets_all() :: list()
      def ets_all(),
        do: NimbleETS.Tables.ets_all(ets_table_name())

      @doc "The ETS table name to be used. Defaults to #{__MODULE__}."
      def ets_table_name(), do: @table

      defp publish(data) do
        NimbleETS.Envio.broadcast(ets_table_name(), data)
        NimbleETS.Envio.broadcast(:all, data)
      end

      defoverridable ets_table_name: 0

      ##########################################################################
      ### Access behaviour implementation

      @behaviour Access

      @doc false
      @impl Access
      def fetch(this, key), do: NimbleETS.Tables.ets_fetch(ets_table_name(), key)

      @doc false
      @impl Access
      def get_and_update(this, key, function) do
        value =
          case fetch(this, key) do
            {:ok, value} -> value
            _ -> nil
          end

        case function.(value) do
          :pop -> {value, this = ets_del(key)}
          {_, updated} -> {value, this = ets_put(key, updated)}
        end
      end

      @doc false
      @impl Access
      def pop(this, key) do
        case fetch(this, key) do
          {:ok, value} -> {value, this = ets_del(key)}
          _ -> {nil, this}
        end
      end
    end
  end
end
