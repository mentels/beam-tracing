defmodule ExTrace.ReqFlowBifs do
  alias ExTrace.{KvUtils, Logger}

  @moduledoc """
  This module implements tracing different stages of creating a bucket
  in the KV application. It will work only if the buckets are spawned
  on the same as node as tracing is running on.
  """
  
  ### API

  @doc """
  Trace processes spawned by KVServer.TaskSupervisor

  The tracer process will get a bunch of trace messages related
  to spawning/linking/unliking/exitting of the processes handling
  the TCP requests.
  """
  def stage1(tracer \\ self()) do
    KvUtils.setup()
    pid = KvUtils.server_task_sup_pid()
    flags = [:procs, {:tracer, tracer}]
    :erlang.trace(pid, true, flags) |> Logger.log
    KvUtils.create("beam")
  end

  @doc """
  Trace function calls to KVServer.Command.run/1 from processes
  spawned by the TaskSupervisor that handle TCP requests

  The tracer process will receive trace messages on the calls
  specified with the trace patterns.
  """
  def stage2(tracer \\ self()) do
    KvUtils.setup()
    pid = KvUtils.server_task_sup_pid()
    flags = [:procs, :set_on_spawn, :call, {:tracer, tracer}]
    procs = :erlang.trace(pid, true, flags)
    ms =  [{_head = :_, _guards = [], _body = [{:return_trace}]}]
    ptrns = :erlang.trace_pattern({KVServer.Command, :run, 1}, ms, [])
    Logger.log(procs, ptrns)
    KvUtils.create("beam")
  end

  @doc """
  Trace funtion calls to KV.Registry.create/2 from processes
  spawned by the TaskSupervisor that handle TCP requests
  
  The tracer process will receive trace messages on the calls
  specified with the trace patterns.
  """
  def stage3(tracer \\ self()) do
    KvUtils.setup()
    pid = KvUtils.server_task_sup_pid()
    flags = [:procs, :set_on_spawn, :call, {:tracer, tracer}]
    procs = :erlang.trace(pid, true, flags)
    ms = [{_Head = :_, guards = [], _Body = [{:return_trace}]}]
    mfas = [{KVServer.Command, :run, 1}, {KV.Registry, :create, 2}]
    ptrns = for mfa <- mfas, do: :erlang.trace_pattern(mfa, ms, [])
    Logger.log(procs, ptrns)
    KvUtils.create("beam")
  end

  @doc """
  Trace spawning the bucket processes by the KV.Bucket.Supervisor
  
  The tracer process will receive trace messages on the calls
  specified with the trace patterns.
  """
  def stage4(tracer \\ self()) do
    KvUtils.setup()
    sups = [KvUtils.server_task_sup_pid(), KvUtils.bucket_sup_pid()]
    flags = [:procs, :set_on_spawn, :call, {:tracer, tracer}]
    procs = for pid <- sups, do: :erlang.trace(pid, true, flags)
    mfas = [{KVServer.Command, :run, 1}, {KV.Registry, :create, 2}]
    ms = [{_Head = :_, guards = [], _Body = [{:return_trace}]}]
    ptrns = for mfa <- mfas, do: :erlang.trace_pattern(mfa, ms, [])
    Logger.log(procs, ptrns)
    KvUtils.create("beam")
  end

end
