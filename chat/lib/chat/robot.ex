defmodule Chat.Robot do
  use Hedwig.Robot, otp_app: :chat

  def handle_connect(%{name: name} = state) do
    if :undefined == :global.whereis_name(name) do
      :yes = :global.register_name(name, self())
    end
    redmine_get_info(state.opts)
    {:ok, tref} = :timer.send_interval(:timer.seconds(state.opts[:pull_delay]), :doit)
    {:ok, state}
  end

  def handle_disconnect(_reason, state) do
    {:reconnect, 5000, state}
  end

  def handle_in(%Hedwig.Message{} = msg, state) do
    {:dispatch, msg, state}
  end

  def handle_in(_msg, state) do
    {:noreply, state}
  end


  def handle_cast({:issue, msg}, state) do
    spawn(fn ->
      case get_redmine_user(msg.user, state) do
        :error ->
          msg.fn.(:error)
        u ->
          case put_issue(msg, u, state) do
            :error ->
              msg.fn.(:error)
            :ok ->
              msg.fn.(:ok)
          end
      end
    end)
    {:noreply, state}
  end


  def handle_cast({:users, users}, state) do
    new_state = Map.merge(state, %{:redmine_users => users })
    {:noreply,new_state}
  end

  def handle_cast({:projects, proj}, state) do
    {:noreply, Map.merge(state, %{:redmine_projects => proj})}
  end

  def handle_cast({:issue_states, states}, state) do
    {:noreply, Map.merge(state, %{:redmine_states => states})}
  end

  def handle_info(:doit, state) do
    redmine_get_info(state.opts)
    {:noreply, state}
  end


  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def http_get(url, api_key) do
    HTTPotion.request(:get, url, [headers: ["Content-Type": "application/json",
                                                                          "X-Redmine-API-Key": api_key
                                                                         ]])
  end

  def http_put(url, apikey, body) do
    HTTPotion.request(:put, url, [headers: ["Content-Type": "application/json",
                                            "X-Redmine-API-Key": apikey
                                           ],
                                  timeout: 30000,
                                  body: body
                                 ])
  end

  def http_post(url, apikey, body) do
    HTTPotion.request(:post, url, [headers: ["Content-Type": "application/json",
                                            "X-Redmine-API-Key": apikey
                                           ],
                                  timeout: 30000,
                                  body: body
                                 ])
  end



  def get_user(state) do
    r = http_get("#{state[:redmine_url]}users.json", state[:api_key])
    case r do
      %HTTPotion.ErrorResponse{} ->
        :error
      _ ->
        users = :jsx.decode(r.body,[:return_maps])["users"]
        name = Application.get_env(:chat, Chat.Robot)[:name]
        pid = :global.whereis_name(name)
        GenServer.cast(pid, {:users, users})
    end
  end

  def get_project(state) do
    r = http_get("#{state[:redmine_url]}projects.json", state[:api_key])
    case r do
      %HTTPotion.ErrorResponse{} ->
        :error
      _ ->
        users = :jsx.decode(r.body,[:return_maps])["projects"]
        name = Application.get_env(:chat, Chat.Robot)[:name]
        pid = :global.whereis_name(name)
        GenServer.cast(pid, {:projects, users})
    end
  end

  def get_issus_status(state) do
    r = http_get("#{state[:redmine_url]}issue_statuses.json", state[:api_key])
    case r do
      %HTTPotion.ErrorResponse{} ->
        :error
      _ ->
        users = :jsx.decode(r.body,[:return_maps])["issue_statuses"]
        name = Application.get_env(:chat, Chat.Robot)[:name]
        pid = :global.whereis_name(name)
        GenServer.cast(pid, {:issue_states, users})
    end
  end

  def get_user_apikey(user, state) do
    r = http_get("#{state[:redmine_url]}users/#{user["id"]}.json", state[:api_key])
    case r do
      %HTTPotion.ErrorResponse{} ->
        :error
      _ ->
        users = :jsx.decode(r.body,[:return_maps])["user"]
    end
  end

  def redmine_get_info(state) do
    spawn( fn -> 
      get_user(state)
      get_project(state)
      get_issus_status(state)
      :ok
    end)
  end

  def filter_user([], result, _state) do
    result
  end

  def filter_user([user|rest], result, state) do
    case Enum.find(state.redmine_users, fn(u) ->
          u["login"] == user or "#{user}" == "#{u["lastname"]}#{u["firstname"]}"
        end) do
      :nil ->
        filter_user(rest, result, state)
      u ->
        filter_user(rest, result++[u["id"]], state)
    end
  end


  def fix_issue(%{"issue"=>%{"watcher_user" => watchers}} = issue, state) do
    users = state.redmine_users
    {_,new_issue} = pop_in(issue,["issue", "watcher_user"])
    s = case filter_user(watchers, [], state) do
          [] ->
            fix_issue(new_issue, state)
          u ->
            new_issue2 = put_in(new_issue, ["issue", "watcher_user_ids"], u)
            fix_issue(new_issue2, state)
        end
  end


  def fix_issue(%{"issue"=>%{"assigned_to" => name}} = issue, state) do
    users = state.redmine_users
    {_,new_issue} = pop_in(issue,["issue", "assigned_to"])
    s = case Enum.find(users, fn(u) ->
              u["login"] == name or "#{name}" == "#{u["lastname"]}#{u["firstname"]}"
            end) do
          :nil ->
            fix_issue(new_issue, state)
          u ->
            new_issue2 = put_in(new_issue, ["issue", "assigned_to_id"], u["id"])
            fix_issue(new_issue2, state)
        end
  end


  def fix_issue(%{"issue"=>%{"project" => proj }} = issue, state) do
    projs = state.redmine_projects
    {_,new_issue} = pop_in(issue,["issue", "project"])
    s = case Enum.find(projs, fn(u) ->
              u["name"] == proj or u["identifier"] == proj
            end) do
          :nil ->
            fix_issue(new_issue, state)
          u ->
            new_issue2 = put_in(new_issue, ["issue", "project_id"], u["id"])
            fix_issue(new_issue2, state)
        end
  end

  def fix_issue(%{"issue"=>%{"status" => status }} = issue, state) do
    states = state.redmine_states
    {_,new_issue} = pop_in(issue,["issue", "status"])
    s = case Enum.find(states, fn(u) ->
              u["name"] == status
            end) do
          :nil ->
            fix_issue(new_issue, state)
          u ->
            new_issue2 = put_in(new_issue, ["issue", "status_id"], u["id"])
            fix_issue(new_issue2, state)
        end
  end
  def fix_issue(issue, _state) do
    issue
  end

  def put_issue(msg, user, state) do
    issue = fix_issue(msg.issue, state)
    issue_s = :jsx.encode(issue)
    r = case msg[:issue_id] do
          :nil ->
            http_post("#{state.opts[:redmine_url]}issues.json", user["api_key"], issue_s)
#            :ok
          issue_id ->
            http_put("#{state.opts[:redmine_url]}issues/#{msg.issue_id}.json", user["api_key"], issue_s)
        end
    case r do
      %HTTPotion.ErrorResponse{} ->
        :error
      _ ->
        #users = :jsx.decode(r.body,[:return_maps])["user"]
        :ok
    end
  end

  def get_redmine_user(name, state) do
    users = state.redmine_users
    username = String.split(name, "@") |> hd
    u = case Enum.find(users, fn(u) ->
              u["login"] == username
            end) do
          :nil ->
            :error
          u ->
            get_user_apikey(u, state.opts)
        end
    u
  end

  def test do
    :ok
  end
end
