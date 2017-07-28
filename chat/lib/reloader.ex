defmodule Chat.Reloader do
  @moduledoc """
  """
  use GenServer
  @doc """
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, tref} = :timer.send_interval(:timer.seconds(1), :doit)
    {:ok, %{last: stamp(), tref: tref}}
  end

  def handle_call(:stop, _from, state) do
    {:reply, :shutdown, :stopped, state}
  end
  
  def handle_call(_, _, state) do
    {:reply, {:error, :badrequest}, state}
  end

  def handle_info(:doit, state) do
    now = stamp()
    _ = doit(state[:last], now)
    state = %{state | last: now }
    {:noreply,state}
  end
  
  def handle_info(_, state) do
    {:noreply, state}
  end

  def reload_modules(modules) do
    modules |> Enum.map(fn(one) -> :code.purge(one); :code.load_file(one) end)
  end

  def all_changed() do
    for {m, fun} <- :code.all_loaded(), is_list(fun) and is_changed(m) == true, do: {m, fun}
  end

  def is_changed(m) do
    try do
        module_vsn(m.module_info()) !== module_vsn(:code.get_object_code(m))
    catch _ ->
            false
    end
  end

  def module_vsn({m, beam, _}) do
    {:ok, {m, vsn}} = :beam_lib.version(beam)
    vsn
  end

  def module_vsn(l) when is_list(l) do
    {_, attrs} = List.keyfind(l, :attributes, 1)
    {_, vsn} = List.keyfind(attrs,:vsn, 1)
    vsn
  end

  def doit(from, to) do
    for {m, f} <- :code.all_loaded(), is_list(f) do
      case File.stat(f) do
        {:ok, %File.Stat{mtime: mtime}} when mtime >= from and mtime < to ->
          reload(m)
        {:ok, _} ->
          :unmodified
        {:error, :enoent} ->
          :gone;
        {:error, :enotdir} ->
          :gone;
        {:error, reason} ->
          IO.puts("error reading #{m} #{f} #{inspect(reason)}")
          :error
      end
    end
  end

  def reload(m) do
    IO.puts("reloading2 #{m}")
    :code.purge(m)
    case :code.load_file(m) do
      {:module, m} ->
        IO.puts("ok")
        case :erlang.function_exported(m, :test, 0) do
          true ->
            IO.puts(" call #{m}:test")
            case m.test() do
              :ok ->
                IO.puts("ok")
                :reload
              reason ->
                IO.puts("fail #{inspect(reason)}")
            end
          false ->
            :reload
        end
      {:error, reason} ->
        IO.puts("fail #{inspect(reason)}")
        :error
    end
  end

  def stamp do
    :erlang.localtime |> :erlang.localtime_to_universaltime
    #|> :calendar.now_to_universal_time
#    :erlang.localtime |> :calendar.now_to_universal_time
  end


end
