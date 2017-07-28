defmodule Chat.Responders.Redmine do
  @moduledoc """
  Responds for redmine
  """

  use Hedwig.Responder

  @usage """
  hedwig: +#XXXX msg 添加注释
  """
  hear ~r/^\+#(?<issue>[0-9]+)\s(?<m>(.+?)*)/ims, msg, state do
              name = msg.user.id
              f = fn(r) ->
                case r do
                  :error ->
                    reply msg, "issue #{msg.matches["issue"]} maybe not append #{msg.matches["m"]}"
                  :ok ->
                    reply msg, "issue #{msg.matches["issue"]} append #{msg.matches["m"]}"
                end
              end
              GenServer.cast(msg.robot, {:issue, %{"user": name,
                                                         "fn": f,
                                                         "issue_id": msg.matches["issue"],
                                                         "issue": create_issue( msg.matches["m"])}})
  end
  @usage """
  hedwig: .#XXXX status 更改状态
  """
  hear ~r/^\.#(?<issue>[0-9]+)\s(?<m>[^\s]*)/ims, msg, state do
    name = msg.user.id
    f = fn(r) ->
      case r do
        :error ->
          reply msg, "issue #{msg.matches["issue"]} maybe not change status #{msg.matches["m"]}"
        :ok ->
          reply msg, "issue #{msg.matches["issue"]} change status #{msg.matches["m"]}"
      end
    end
    GenServer.cast(msg.robot, {:issue, %{"user": name,
                                               "fn": f,
                                               "issue_id": msg.matches["issue"],
                                               "issue": change_issue_status( msg.matches["m"])}})
  end

  @usage """
  hedwig: !# <description> +<project_name_substring_or_id> [!<assigned_to>]* [@<watcher>]*  创建issue
  """
  hear ~r/^\!#\s(?<m>(.+?)*)/ims, msg, state do
    m = msg.matches["m"]
    desc = Regex.named_captures(~r/(?<desc>[^\+]*)\+(?<proj>[^\s]*)(?<u>(.+?)*)/ims, m)
    assign = Regex.named_captures(~r/!(?<assign>[^\s]*)/ims, desc["u"])
    watch = get_watch(desc["u"], [])
    name = msg.user.id
    f = fn(r) ->
      case r do
        :error ->
          reply msg, "create issue maybe error"
        :ok ->
          reply msg, "create issue #{msg.matches["desc"]} "
      end
    end
    GenServer.cast(msg.robot, {:issue, %{"user": name,
                                         "fn": f,
                                         "issue": create_new_issue(desc["desc"], desc["proj"],assign["assign"], watch)}})
    #reply msg, "create issue #{msg.matches["m"]} "
  end

  def get_watch(msg, w) do
    case Regex.named_captures(~r/@(?<watch>[^\s]*)(?<u>(.+?)*)/ims, msg) do
      :nil ->
        w
      watch ->
        get_watch(watch["u"], w++[watch["watch"]])
    end
  end

  def create_new_issue(desc, proj, assign, watch) do
    %{"issue" => %{
    "project" => String.trim_trailing(proj),
    "subject"=>String.trim_trailing(desc),
    "assigned_to"=>assign,
    "watcher_user"=>watch
  }}
  end

  def create_issue(note) do
    %{"issue" => %{
    "notes" => note
  }}
  end

  def change_issue_status(status) do
    %{"issue" => %{
                 "status" => status
  }}
  end


  def test do
    p = Regex.run(~r/^\+#(?<issue>[0-9]+)\s(?<m>(.+?)*)/ims, "+#55 aa bb cc\n ee ff")
    p2 = Regex.run(~r/^\.#(?<issue>[0-9]+)\s(?<m>[^\s]*)/ims, ".#55 aa bb cc\n ee ff")
    p3 = Regex.run(~r/![^\s]*/ims, " \n!aa \n@gg \n@hh")
    p4 = get_watch(" \n!aa \n@gg \n@hh", [])
    #task()
    :ok
  end
end
