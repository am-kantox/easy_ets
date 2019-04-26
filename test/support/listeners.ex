defmodule NimbleETS.Listeners.Test.Baz do
  use Envio.Subscriber, channels: [{NimbleETS.Envio, NimbleETS.Tables.Test.Baz}]

  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect(message)
    {:noreply, state}
  end
end
