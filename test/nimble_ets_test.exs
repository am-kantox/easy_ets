defmodule NimbleETSTest do
  use ExUnit.Case, async: true
  doctest NimbleETS

  import ExUnit.CaptureIO
  use Envio.Subscriber, channels: [{NimbleETS.Envio, NimbleETS.Tables.Test.Baz}]
  alias NimbleETS.Tables.Test, as: T

  setup_all do
    NimbleETS.new(NimbleETS.Tables.Test.Foo)
    NimbleETS.new([{NimbleETS.Tables.Test.Bar, [:bag]}, NimbleETS.Tables.Test.Baz])

    :ok
  end

  test "NimbleETS.new/1" do
    assert :ets.info(NimbleETS.Tables.Test.Foo)[:type] == :set
    assert :ets.info(NimbleETS.Tables.Test.Bar)[:type] == :bag
    assert :ets.info(NimbleETS.Tables.Test.Baz)[:type] == :set
  end

  test "CRUD" do
    T.Foo.ets_put(:key, :value)

    assert nil == T.Foo.ets_get(:inexisting)
    assert :bar == T.Foo.ets_get(:inexisting, :bar)
    assert :value == T.Foo.ets_get(:key)
    assert Enum.member?(T.Foo.ets_all(), :value)

    assert %T.Foo{table: NimbleETS.Tables.Test.Foo} == T.Foo.ets_del(:inexisting)
    assert :value == T.Foo.ets_get(:key)
    assert %T.Foo{table: NimbleETS.Tables.Test.Foo} == T.Foo.ets_del(:key)
    refute Enum.member?(T.Foo.ets_all(), :value)

    T.Foo.ets_put(:dup, 1)
    T.Foo.ets_put(:dup, 2)
    T.Foo.ets_put(:dup, 42)
    assert 42 == T.Foo.ets_get(:dup)
  end

  test "Access" do
    T.Bar.ets_put(:baz, 42)
    T.Foo.ets_put(:bar, %T.Bar{})
    input = %{foo: %T.Foo{}}

    assert get_in(input, [:foo, :bar, :baz]) == 42
    assert %{foo: %T.Foo{table: T.Foo}} = put_in(input, [:foo, :bar, :baz], 3.14)
    assert get_in(input, [:foo, :bar, :baz]) == 3.14

    assert %{foo: %T.Foo{table: T.Foo}} =
             update_in(input, [:foo, :bar, :baz], fn pi ->
               3.14 = pi
               42
             end)

    assert get_in(input, [:foo, :bar, :baz]) == 42
  end

  test "Envío" do
    output =
      capture_io(fn ->
        with {:ok, pid} <- NimbleETS.Listeners.Test.Baz.start_link() do
          T.Baz.ets_put(:baz, 42)
          T.Baz.ets_del(:baz)
          # to allow message delivery delay
          Process.sleep(100)
          GenServer.stop(pid)
        end
      end)

    assert output =~ ~r/%{action: :update, key: :baz, value: 42}/
    assert output =~ ~r/%{action: :delete, key: :baz}/
  end
end
