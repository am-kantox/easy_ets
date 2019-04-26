defmodule NimbleETS.Tables do
  @moduledoc false
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct opts: [], tables: []
  end

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec state() :: %State{}
  def state(), do: GenServer.call(__MODULE__, :state)

  @spec ets_put(name :: atom(), key :: term(), value :: term()) :: :ok
  def ets_put(name, key, value) do
    :ets.insert(name, {key, value})
    :ok
  end

  @spec ets_get(name :: atom(), key :: term(), default :: any()) :: term()
  def ets_get(name, key, default \\ nil) do
    name
    |> ets_fetch(key)
    |> case do
      :error -> default
      {:ok, result} -> result
    end
  end

  @spec ets_fetch(name :: atom(), key :: term()) :: {:ok, term()} | :error
  def ets_fetch(name, key) do
    name
    |> :ets.lookup(key)
    |> case do
      [] -> :error
      [result] -> {:ok, result}
      list -> {:ok, for({_, v} <- list, do: v)}
    end
  end

  @spec ets_del(name :: atom(), key :: term()) :: :ok
  def ets_del(name, key) do
    :ets.delete(name, key)
    :ok
  end

  @spec ets_all(name :: atom()) :: list()
  def ets_all(name), do: name |> :ets.tab2list() |> Enum.map(&elem(&1, 1))

  ##############################################################################
  # Server (callbacks)

  @impl GenServer
  def init(opts), do: {:ok, %State{opts: opts}, {:continue, :tables}}

  @impl GenServer
  def handle_call(:state, _from, state), do: {:reply, state, state}

  # @impl GenServer
  # def handle_call({:new, table}, _from, state) do
  #
  #   {:reply, state, state}
  # end

  @impl GenServer
  def handle_continue(:tables, %State{opts: opts} = state) do
    tables =
      opts
      |> Keyword.get(:tables, [])
      |> Enum.map(fn
        {t, opts} -> {t, [:named_table, :public | opts]}
        t -> {t, [:set, :named_table, :public, {:read_concurrency, true}]}
      end)
      |> Enum.into(%{}, fn {t, opts} -> {t, :ets.new(t, opts)} end)

    {:noreply, %State{state | tables: tables}}
  end
end
