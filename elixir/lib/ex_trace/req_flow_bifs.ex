defmodule ExTrace.ReqFlowBifs do
  require Logger

  @moduledoc """
  This module implements tracing different stages of creating a bucket
  in the KV application. It will work only if the buckets are spawned
  on the same as node as tracing is running.
  """
  
  ### API

  @doc """
  Trace processes spawned by KVServer.TaskSupervisor

  The tracer process will get a bunch of trace messages related
  to spawning/linking/unliking/exitting of the processes handling
  the TCP requests.
  """
  def stage1(tracer \\ self()) do
    :erlang.trace(:all, false, [:all])
    buckets = Supervisor.which_children(KV.Bucket.Supervisor)
    for {_, pid, _, _,} <- buckets, do: Process.exit(pid, :kill)
    pid = ExTrace.KV.server_task_sup_pid()
    procs = :erlang.trace(pid, true, [:procs, {:tracer, tracer}])
    ExTrace.KV.create("beam")
    Logger.info "Matched #{procs} procs"
  end

  @doc """
  Trace function calls to KVServer.Command.run/1 from processes
  handling TCP requests

  The tracer process will receive trace messages on the calls
  specified with the trace patterns.
  """
  def stage2(tracer \\ self()) do
    :erlang.trace(:all, false, [:all])
    buckets = Supervisor.which_children(KV.Bucket.Supervisor)
    for {_, pid, _, _,} <- buckets, do: Process.exit(pid, :kill)
    pid = ExTrace.KV.server_task_sup_pid()
    procs = :erlang.trace(pid, true, [:procs, :set_on_spawn, :call,
                                      {:tracer, tracer}])
    ms =  [{_head = :_, _guards = [], _body = [{:return_trace}]}]
    ptrns = :erlang.trace_pattern({KVServer.Command, :run, 1}, ms, [])
    Logger.info "Matched #{procs} procs and #{ptrns} patterns"
    ExTrace.KV.create("beam")
  end

  @doc """
  Trace funtion calls to KV.Registry.create/2 from processes
  handling TCP requests.

  The tracer process will receive trace messages on the calls
  specified with the trace patterns.
  """
  def stage3(tracer \\ self()) do
    :erlang.trace(:all, false, [:all])
    buckets = Supervisor.which_children(KV.Bucket.Supervisor)
    for {_, pid, _, _,} <- buckets, do: Process.exit(pid, :kill)
    pid = ExTrace.KV.server_task_sup_pid()
    procs = :erlang.trace(pid, true, [:procs, :set_on_spawn, :call,
                                      {:tracer, tracer}])
    ms = [{_Head = :_, guards = [], _Body = [{:return_trace}]}]
    mfas = [{KVServer.Command, :run, 1}, {KV.Registry, :create, 2}]
    ptrns = for mfa <- mfas, do: :erlang.trace_pattern(mfa, ms, [])
    Logger.info "Matched #{procs} procs and #{Enum.sum ptrns} patterns"
    ExTrace.KV.create("beam")
  end

  @doc """
  Trace spawning bucket processes.
  
  The tracer process will receive trace messages on the calls
  specified with the trace patterns.
  """
  def stage4(tracer \\ self()) do
    :erlang.trace(:all, false, [:all])
    buckets = Supervisor.which_children(KV.Bucket.Supervisor)
    for {_, pid, _, _,} <- buckets, do: Process.exit(pid, :kill)
    supervisors = [ExTrace.KV.server_task_sup_pid(),
                   ExTrace.KV.bucket_sup_pid()]
    procs = for pid <- supervisors,
      do: :erlang.trace(pid, true, [:procs, :set_on_spawn, :call,
                                    {:tracer, tracer}])
    mfas = [{KVServer.Command, :run, 1}, {KV.Registry, :create, 2}]
    ms = [{_Head = :_, guards = [], _Body = [{:return_trace}]}]
    ptrns = for mfa <- mfas, do: :erlang.trace_pattern(mfa, ms, [])
    Logger.info "Matched #{Enum.sum procs} procs" <>
      " and #{Enum.sum ptrns} patterns"
    ExTrace.KV.create("beam")
  end

end
