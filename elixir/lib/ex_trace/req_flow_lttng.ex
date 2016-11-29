defmodule ExTrace.ReqFlowLTTng do
  alias ExTrace.{KvUtils, LTTng, Logger}
  
  @moduledoc """
  This module implements tracing different stages of creating a bucket
  in the KvUtils application using LTTng.
  
  The LTTng is called through the System.cmd/X.
  """
  
  ### API

  @doc """
  Trace processes spawned by KvUtilsServer.TaskSupervisor

  The LTTng tracer will get a bunch of trace messages related
  to spawning/linking/unliking/exitting of the processes handling
  the TCP requests.
  """
  def stage1(tracer \\ self()) do
    KvUtils.setup()
    LTTng.setup([:process_spawn, :process_link, :process_exit])
    pid = KvUtils.server_task_sup_pid()
    flags = [:procs, {:tracer, :dyntrace, []}]
    :erlang.trace(pid, true, flags) |> Logger.log
    KvUtils.create("beam")
  end

  @doc """
  Trace function calls to KvUtilsServer.Command.run/1 from processes
  handling the TCP requests

  Apart from what was defined in `stage1`, the LTTng tracer will 
  receive trace events on the calls to KvUtilsServer.Command.run/1
  made from processes handling the TCP requests.
  """
  def stage2(tracer \\ self()) do
    KvUtils.setup()
    LTTng.setup([:process_spawn, :process_link, :process_exit,
                 :function_call, :function_return])
    pid = KvUtils.server_task_sup_pid()
    flags = [:procs, :set_on_spawn, :call, :return_to,
             {:tracer, :dyntrace, []}]
    procs = :erlang.trace(pid, true, flags)
    ptrns = :erlang.trace_pattern({KVServer.Command, :run, 1},
      true, [:local])
    Logger.log(procs, ptrns)
    KvUtils.create("beam")
  end

  @doc """
  Trace funtion calls to KvUtils.Registry.create/2 from processes
  handling TCP requests

  Apart from what was defined in up to `stage2`, the LTTng tracer
  will receive trace events on the calls to KvUtils.Registry.create/2
  made from processes handling the TCP requests.
  """
  def stage3(tracer \\ self()) do
    KvUtils.setup()
    LTTng.setup([:process_spawn, :process_link, :process_exit,
                 :function_call, :function_return])
    pid = KvUtils.server_task_sup_pid()
    flags = [:procs, :set_on_spawn, :call, :return_to,
             {:tracer, :dyntrace, []}]
    mfas = [{KVServer.Command, :run, 1}, {KV.Registry, :create, 2}]
    procs = :erlang.trace(pid, true, flags)
    ptrns = for mfa <- mfas do
      :erlang.trace_pattern(mfa, true, [:local])
    end
    Logger.log(procs, ptrns)
    KvUtils.create("beam")
  end

  @doc """
  Trace spawning bucket processes
  
  Apart from what was defined in up to `stage3`, the LTTng tracer
  will receive trace events indicating that a bucket was spawned
  under the KV.Buket.Supervisor.
  """
  def stage4(tracer \\ self()) do
    KvUtils.setup()
    LTTng.setup([:process_spawn, :process_link, :process_exit,
                 :function_call, :function_return])
    sups = [KvUtils.server_task_sup_pid(), KvUtils.bucket_sup_pid()]
    flags = [:procs, :set_on_spawn, :call, :return_to,
             {:tracer, :dyntrace, []}]
    mfas = [{KVServer.Command, :run, 1}, {KV.Registry, :create, 2}]
    procs = for pid <- sups, do: :erlang.trace(pid, true, flags)
    ptrns = for mfa <- mfas,
      do: :erlang.trace_pattern(mfa, true, [:local])
    Logger.log(procs, ptrns)
    KvUtils.create("beam")
  end

end
