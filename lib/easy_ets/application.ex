defmodule EasyETS.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    Supervisor.start_link([EasyETS.Tables], strategy: :one_for_one, name: EasyETS.Supervisor)
  end
end
