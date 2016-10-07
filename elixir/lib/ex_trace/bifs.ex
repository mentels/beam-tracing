defmodule ExTrace.BIFs do
  @moduledoc ~S"""
  This module demonstrates tracing techniques that make use of 
  the basic Erlang BIFs: `:erlang:trace/3` and 
  `:erlang:trace_pattern/3 BIFs.`

  ## Tracing Commands

  The `trace_commands/1` enables tracing of all the processes in 
  the system. Trace messages will be generated for those which run
  the `KVServer.Command.run/1` function. 

  The trace messages are sent to the process that called 
  the `erlang:trace/3`.

  To clear all of the traces call `clear_all/0`.
  
  ### Example:
     
      iex> ExTrace.BIFs.trace_commands()
      iex> ExTrace.test_kv_server()
      iex> flush()
      {:trace, #PID<0.162.0>, :call, 
       {KVServer.Command, :run, [{:get, "shopping", "eggs"}]}}


  ## Tracing Commands and Returns

  The `trace_commands_and_returns/1` enables tracing of all 
  the processes in the system. Trace messages will be generated 
  for those which run the `KVServer.Command.run/1` function. The return
  value will be included as well.

  ### Example:
  
      iex> ExTrace.BIFs.trace_commands_and_returns()
      iex> ExTrace.test_kv_server()
      iex> flush()
      {:trace, #PID<0.162.0>, :call, 
       {KVServer.Command, :run, [{:get, "shopping", "eggs"}]}}
      {:trace, #PID<0.177.0>, :return_from, {KVServer.Command, :run, 1},
       {:ok, "\r\nOK\r\n"}} 


  ## The Tracer is not Traced

  Try the following:
      
      iex> ExTrace.BIFs.trace_commands_and_returns()
      iex> KVServer.Command.run({:create, "shopping"})
      iex> flush()
      nil

  The process that is to recive the trace messages cannot be traced.
  Howerver, we can specify a process that will receive those messages.
  All the functions in this module can take a pid of a tracer process.
  It also includes the `tracer/0` function that spawns a process that
  handles trace messages and outputs them on the console in 
  the following format:
      COMMAND: {:get, "shopping", "eggs"}
      RESULT: {:ok, "\r\nOK\r\n"}
      
  ### Example:

      iex> ExTrace.BIFs.trace_commands_and_returns(pid = BIFs.tracer())
      iex> KVServer.Command.run({:create, "shopping"})
      COMMAND: {:create, "shopping"}
      RESULT: {:ok, "OK\r\n"}

  # Tracing Specific Processes

  With the above approches all the processes were traced. It is possible
  to narrow them down. For example with `trace_supervised_commands/0`
  only the processes started by the `KVServer.TaskSupervisor` will be
  traced. In other words, trace messages won't be generated when a
  command is run from the IEx shell.

  It is achieved by enabling tracing of the aforementioned process with
  the `:set_on_spawn` flag. With that in place, all the processes 
  spawned by `KVServer.TaskSupervisor` will inherit its trace flags. 
  It boils down to the fact, that all of these processes will have 
  call tracing enabled.

  ### Example:
  
      iex> ExTrace.BIFs.trace_supervised_commands(BIFs.tracer())
      iex> KVServer.Command.run({:create, "shopping"}) # nothing 
      iex> ExTrace.test_kv_server()
      COMMAND: {:create, "shopping"}
      RESULT: {:ok, "OK\r\n"}
      
  The traces appear when calling the `ExTrace.test_kv_server/0`
  becase it talks with the `KVServer` through TCP.

  ## Refining the Match

  We can refine the trace pattern further and specify the exact
  function's arguments that have to match for the trace message to be
  generated. To achieve that, we need to use the 
  [Erlang Match Specification](http://erlang.org/doc/apps/erts/match_spec.html).
  They are in short called Match Specs and are lists of Match Functions.
  A Match Function is a tuple with a Match Head that is used to match
  on the functions' arguments, the Match Conditions which we can use
  to test the match arguments against certain things and the 
  Match Body that can influce the trace messages.

  The `trace_put_commands/0` funtion enables tracing  with a pattern
  that captures only the `PUT` Commands.

  ### Example:
  
      iex> ExTrace.BIFs.trace_put_commands(BIFs.tracer())
      iex> ExTrace.test_kv_server()
      COMMAND: {:put, "shopping", "eggs", "3"}
      RESULT: {:ok, "OK\r\n"}
  
  TODO: Describe the MatchSpec.

  """
  require Logger
  alias KVServer.Command
  require Command

  @doc """
  Enables tracing of the commands sent to the KVServer
  """  
  def trace_commands(tracer \\ self) do
    procs = :erlang.trace(:all, true, [:call, {:tracer, tracer}])
    ptrns = :erlang.trace_pattern({Command, :run, 1}, true, [])
    Logger.info "Matched #{procs} procs and #{ptrns} patterns"
  end

  @doc """
  Enables tracing of the commands sent to the KVServer and the return
  values
  """  
  def trace_commands_and_returns(tracer \\ self) do
    procs = :erlang.trace(:all, true, [:call, {:tracer, tracer}])
    ptrns = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = :_,
                     _Conditions = [],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    Logger.info "Matched #{procs} procs and #{ptrns} patterns"
  end

  @doc """
  Enables tracing of only those commands that are supervised
  """
  def trace_supervised_commands(tracer \\ self) do
    procs = :erlang.trace(ExTrace.kvserver_task_supervisor_pid(),
      true, [:call, :set_on_spawn, {:tracer, tracer}])
    ptrns = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = :_,
                     _Conditions = [],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    Logger.info "Matched #{procs} procs and #{ptrns} patterns"
  end
  
  @doc """
  Enables tracing only of the `PUT <BUCKET> <ITEM> <CNT>` commands
  """
  def trace_put_commands(tracer \\ self) do
    procs = :erlang.trace(:all, true, [:call, {:tracer, tracer}])
    ptrns = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = [{:"$1", :_, :_, :_}],
                     _Conditions = [{:==, :"$1", :put}],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    Logger.info "Matched #{procs} procs and #{ptrns} patterns"
  end

  @doc """
  Enables tracing only of the `PUT <BUCKET> <ITEM> <CNT>` and 
  `GET <BUCKET> <ITEM> <CNT>` commands
  """
  def trace_put_and_get_commands(tracer \\ self) do
    procs = :erlang.trace(:all, true, [:call, {:tracer, tracer}])
    ptrns = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = [{:"$1", :_, :_, :_}],
                     _Conditions = [{:==, :"$1", :put}],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    Logger.info "Matched #{procs} procs and #{ptrns} patterns"
  end
  
  def clear_all() ,do: :erlang.trace(:all, false, [:all])
  
  def tracer, do: spawn_link(fn -> tracer([]) end)
  
  defp tracer(traces) do
    traces = receive do
      {:trace, _, :call, {KVServer.Command, :run, [command]}} ->
        [~s(COMMAND: #{inspect command}) | traces]
      {:trace, _, :return_from, {KVServer.Command, :run, 1}, return} ->
        [~s(RESULT: #{inspect return}) | traces]
    after
      500 ->
        if !Enum.empty?(traces) do
          traces |> Enum.reverse |> Enum.join("\n") |> IO.puts
        end
        []
    end
    tracer(traces)
  end
  
end
