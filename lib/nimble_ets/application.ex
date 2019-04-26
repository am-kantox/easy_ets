defmodule NimbleETS.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    Supervisor.start_link([NimbleETS.Tables], strategy: :one_for_one, name: NimbleETS.Supervisor)
  end
end
