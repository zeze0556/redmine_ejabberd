defmodule Chat.Redmine do

  def init(req, state) do
    handle(req, state)
  end

  def terminate(_reason, _request, _state) do
    :ok
  end

  def post_user(msg) do
    m = msg["msg"]
    name = Application.get_env(:chat, Chat.Robot)[:name]
    pid = :global.whereis_name(name)
    String.split(msg["to"],[" ", ",", ";"]) |> Enum.map(fn
      ""->
        :ok;
      (user)->
      msg = %Hedwig.Message{
      type: "chat",
      user: %Hedwig.User{id: user},
      text: m}
      # Send the message
      spawn( fn -> 
        Hedwig.Robot.send(pid, msg)
        :ok
        end)
    end)

  end

  def handle(request, state) do
    {:ok, body, _Req} = :cowboy_req.read_body(request)
    json = :jsx.decode(body,  [:return_maps])
    post_user(json)
    req = :cowboy_req.reply(
      200,
      %{"content-type"=>"text/html"},
      <<"ok">>,
      request
    )
    {:ok, req, state}
  end

end
