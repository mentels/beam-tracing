defmodule BIFs do

  @doc """
  Enable tracing the commands received by the server

  Trace all the processes.
  """  
  def sent_commands(tracer \\ self) do
    matched = :erlang.trace(:all, true, [:call])
    IO.puts "Matched #{matched} processes"
    matched = :erlang.trace_pattern({KVServer.Command, :run, 1},
      true, [])
    IO.puts "Matched #{matched} trace patterns"
  end

  @doc """
  Enable tracing the commands received by the server
  and their results

  Trace all the processes.

  * If the tracing process and the calling traced function are the same,
  the trace is not sent. open new shell or run with
  spawn fn -> KVServer.Command.run({:create, "shopping"}) end
  """  
  def sent_commands_and_results(tracer \\ self) do
    matched = :erlang.trace(:all, true, [:call])
    IO.puts "Matched #{matched} processes"
    matched = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = :_,
                     _Conditions = [],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    IO.puts "Matched #{matched} trace patterns"
  end

  @doc """
  Enable tracing commands but only those spawned from the supervisor
  for the connections
  """
  def sent_commands_and_results_only_kvserver(tracer \\ self) do
    matched = :erlang.trace(ExTrace.kvserver_task_supervisor_pid(),
      true, [:call, :set_on_spawn])
    IO.puts "Matched #{matched} processes"
    matched = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = :_,
                     _Conditions = [],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    IO.puts "Matched #{matched} trace patterns"
  end

  @doc """
  Enable tracing commands but only those spawned from the supervisor
  for the connections. Pretty print stuff with own tracer
  """
  def sent_commands_and_results_only_kvserver_pretty() do
    tracer = spawn fn -> ExTrace.tracer() end
    matched = :erlang.trace(ExTrace.kvserver_task_supervisor_pid(),
      true, [:call, :set_on_spawn, {:tracer, tracer}])
    IO.puts "Matched #{matched} processes"
    matched = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = :_,
                     _Conditions = [],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    IO.puts "Matched #{matched} trace patterns"
  end

  @doc """
  Enable tracing commands but only those spawned from the supervisor
  for the connections. Pretty print stuff with own tracer. Only for
  :put
  """
  def sent_commands_and_results_only_kvserver_get_pretty() do
    tracer = spawn fn -> ExTrace.tracer() end
    matched = :erlang.trace(ExTrace.kvserver_task_supervisor_pid(),
      true, [:call, :set_on_spawn, {:tracer, tracer}])
    IO.puts "Matched #{matched} processes"
    matched = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = [{:"$1", :_, :_, :_}],
                     _Conditions = [{:==, :"$1", :put}],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    IO.puts "Matched #{matched} trace patterns"
  end

  def tracer do
    action = receive do
      {:trace, _pid, :call, {KVServer.Command, :run, [action]}} ->
        action
    end
    result = receive do
      {:trace, _pid, :return_from, {KVServer.Command, :run, 1}, result} ->
        result
    end
    IO.puts "#{inspect action} -> #{inspect result}"
    tracer
  end
  
end
