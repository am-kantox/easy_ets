defmodule EasyETS.Listeners.Test.Baz do
  use Envio.Subscriber, channels: [{EasyETS.Envio, EasyETS.Tables.Test.Baz}]

  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect(message)
    {:noreply, state}
  end
end
