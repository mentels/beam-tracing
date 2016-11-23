defmodule ExTrace.ReqFlowDbg do
  require Logger

  ## TODO

  ### API

  @doc """
  Trace processes spawned by KVServer.TaskSupervisor

  The tracer process will get a bunch of trace messages related
  to spawning/linking/unliking/exitting of the processes handling
  the TCP requests.
  """
  def stage1(tracer \\ self()) do
    procs = :erlang.trace(
      ExTrace.KV.server_task_sup_pid(),
      true,
      [:procs, {:tracer, tracer}])
    test_create()
    Logger.info "Matched #{procs} procs"
    :erlang.trace(:all, false, [:all])
  end

  @doc """
  Trace funtion calls to KVServer.Command.run/1 from processes
  handling TCP requests

  The tracer process will receive trace messages on the calls
  specifited with the trace patterns.
  """
  def stage2(tracer \\ self()) do
    procs = :erlang.trace(
      ExTrace.KV.server_task_sup_pid(),
      true,
      [:procs, :set_on_spawn, :return_to, :call, {:tracer, tracer}])
    ptrns = :erlang.trace_pattern(
      _MFA = {KVServer.Command, :run, 1},
      _match_fun = [{_Head = :_,
                     _Conditions = [],
                     _Body = [{:return_trace}]}],
      _Flags = [])
    Logger.info "Matched #{procs} procs and #{ptrns} patterns"
    test_create()
    :erlang.trace(:all, false, [:all])
  end

  @doc """
  Trace funtion calls to KVServer.Command.run/1 from processes
  handling TCP requests

  The tracer process will receive trace messages on the calls
  specifited with the trace patterns.
  """
  def stage3(tracer \\ self()) do
    procs = :erlang.trace(
      ExTrace.KV.server_task_sup_pid(),
      true,
      [:procs, :set_on_spawn, :return_to, :call, {:tracer, tracer}])
    ptrns = for mfa <- [{KVServer.Command, :run, 1},
                        {KV.Registry, :create, 2}] do
        :erlang.trace_pattern(
          mfa,
          _match_fun = [{_Head = :_,
                         _Conditiaons = [],
                         _Body = [{:return_trace}]}],
          _Flags = [])
    end
    Logger.info "Matched #{procs} procs and #{Enum.sum ptrns} patterns"
    test_create()
    :erlang.trace(:all, false, [:all])
  end

  def stage4(tracer \\ self()) do
    supervisors = [ExTrace.KV.server_task_sup_pid(),
                   ExTrace.KV.bucket_sup_pid()]
    procs = for pid <- supervisors do
      :erlang.trace(pid, true, [:procs, :set_on_spawn,
                                :return_to, :call, {:tracer, tracer}])
    end
    calls = [{KVServer.Command, :run, 1}, {KV.Registry, :create, 2}]
    ptrns = for mfa <- calls  do
      :erlang.trace_pattern(
        mfa,
        _match_fun = [{_Head = :_,
                       _Conditiaons = [],
                       _Body = [{:return_trace}]}],
        _Flags = [])
    end
    Logger.info "Matched #{Enum.sum procs} procs" <>
      " and #{Enum.sum ptrns} patterns"
    test_create()
    :erlang.trace(:all, false, [:all])
  end

  ### Private

  defp test_create() do
    ExTrace.KV.create("beam")
    # ExTrace.KV.put("beam", "elixir", "2012")
  end

end

