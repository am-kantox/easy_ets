defmodule NimbleETS do
  @moduledoc """
  Documentation for NimbleETS.
  """

  @doc """
  Creates new ETS table(s) wrapper(s) based on definitions passed as a parameter.
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

      @spec ets_put(key :: term(), value :: term()) :: t()
      def ets_put(key, value) do
        NimbleETS.Tables.ets_put(ets_table_name(), key, value)
        %__MODULE__{table: ets_table_name()}
      end

      @spec ets_get(key :: term(), default :: any()) :: term()
      def ets_get(key, default \\ nil),
        do: NimbleETS.Tables.ets_get(ets_table_name(), key, default)

      @spec ets_del(key :: term()) :: t()
      def ets_del(key) do
        NimbleETS.Tables.ets_del(ets_table_name(), key)
        %__MODULE__{table: ets_table_name()}
      end

      @spec ets_all() :: list()
      def ets_all(),
        do: NimbleETS.Tables.ets_all(ets_table_name())

      @doc "The ETS table name to be used. Defaults to #{__MODULE__}."
      def ets_table_name(), do: @table

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

        this = ets_del(key)

        case function.(value) do
          :pop -> {value, this}
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
