defmodule Chat.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    :inets.start()
    :ssl.start()
    :crypto.start()
    dispatch_config = build_dispatch_config
    {:ok, _} = :cowboy.start_clear(:http, [{:port, 8080}],
      %{:env=>%{:dispatch=>dispatch_config}}
    )
    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Chat.Worker.start_link(arg1, arg2, arg3)
      worker(Chat.Reloader, []),
      worker(Chat.Robot, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def build_dispatch_config do
    :cowboy_router.compile([
      {
        :_,
        [
          {"/[...]", Chat.Redmine, []}
        ]
      }
    ])
  end
end
