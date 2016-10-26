defmodule ExTrace.Dbg do
  @moduledoc ~S"""
  This module demonstrates tracing techniques that make use of
  the Erlang [Dbg](http://erlang.org/doc/man/dbg.html): The Text Based
  Trace Facility.

  ## The Dbg basics
  
  The following example illustrates how to use the :dbg to trace calls:
  
  iex> :dbg.tracer() # Start the default trace message receiver
  {ok,<0.36.0>}
  iex> :dbg.p(:all, :c) # Setup call (c) tracing on all processes
  {:ok, [{:matched, :nonode@nohost, 45}]}
  iex> :dbg.tp(Enum, :to_list, :x) # Setup an exception return trace (:x) on Enum.to_list
  {ok,[{matched,nonode@nohost,2},{saved,x}]}
  iex> Enum.to_list(1..10)
  (<0.80.0>) call 'Elixir.Enum':to_list(#{'__struct__' => 'Elixir.Range',first => 1,last => 10})
  (<0.80.0>) returned from 'Elixir.Enum':to_list/1 -> [1,2,3,4,5,6,7,8,9,10]
  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  
  ## Tracing Processes Events

  With the Erlang Tracing facilitiy it is possible to see different
  processes events, These are related to:
  * spawning
  * exiting
  * (un)registering
  * (un)linking
  
  Let's enable processes events (the :p flag) so that we can see the
  tasks spawned buckets under the `Task.Supervisor`.

  ### Example
  
  iex> ExTrace.Dbg.trace_buckets
  iex> ExTrace.test_kv_server
  # The task is spawned under the KV.Bucket.Supervisor
  (<0.167.0>) spawn <0.184.0> as proc_lib:init_p('Elixir.KV.Bucket.Supervisor',[<0.165.0>,<0.164.0>],gen,init_it,[gen_server,<0.167.0>,<0.167.0>,'Elixir.Agent.Server',
  #Fun<Elixir.KV.Bucket.3.120435444>,[]])
  # Then the supervisor links to it
  (<0.167.0>) link <0.184.0>
  iex> ExTrace.Dbg.stop_clear
  
  As we only have one connection in the test, the Task supervisor
  spawns just one process.

  ## Tracing Chain of Processes

  We can make the new processes that are spawned by the one being trace
  inherit the trace flags. With that in place, it is possible to trace
  not only one process, but all its descendants as well. 

  The `sos` and `sol` trace flags are to be used for that. They stand
  for `set_on_spawn` and `set_on_link` respectively.

  Good example of such tracing would be to see all the processes that
  are involved when serving a TCP request.

  ### Example
  
  iex> ExTrace.Dbg.trace_chain
  iex> ExTrace.test_kv_server
  # KV SERVER
  ## The Task.Supervisor (<0.167.0>) "spawn_links" a new task (<0.648.0>)
  (<0.167.0>) spawn <0.648.0> as proc_lib:init_p('Elixir.KVServer.TaskSupervisor',['Elixir.KVServer.Supervisor',<0.165.0>],'Elixir.Task.Supervised',noreply,[{'foo@szm-mac',<0.168.0>},
  {erlang,apply,[#Fun<Elixir.KVServer.0.112946037>,[]]}])
  ## The Task.Supervised is spawned and linked to the Task.Supervisor
  ## and the Socket
  (<0.648.0>) spawned <0.167.0> {proc_lib,init_p,
  ['Elixir.KVServer.TaskSupervisor',
  ['Elixir.KVServer.Supervisor',<0.165.0>],
  'Elixir.Task.Supervised',noreply,
  [{'foo@szm-mac',<0.168.0>},
  {erlang,apply,[#Fun<Elixir.KVServer.0.112946037>,[]]}]]}
  (<0.648.0>) getting_linked <0.167.0>
  (<0.648.0>) getting_linked #Port<0.7269>
  ## When the task is done it exists
  (<0.648.0>) exit shutdown
  ## The Task.Supervisor gets unlined
  (<0.167.0>) getting_unlinked <0.648.0>
  # KV
  ## KV.Bucket.Supervisor spawns a bucket and links to it
  (<0.178.0>) spawn <0.223.0> as proc_lib:init_p('Elixir.KV.Bucket.Supervisor',[<0.176.0>,<0.175.0>],gen,init_it,[gen_server,<0.178.0>,<0.178.0>,'Elixir.Agent.Server',
  #Fun<Elixir.KV.Bucket.3.120435444>,[]])
  (<0.178.0>) link <0.223.0>
  ## The bucket is spawned and gets linked to
  (<0.223.0>) spawned <0.178.0> {proc_lib,init_p,
  ['Elixir.KV.Bucket.Supervisor',
  [<0.176.0>,<0.175.0>],
  gen,init_it,
  [gen_server,<0.178.0>,<0.178.0>,'Elixir.Agent.Server',
  #Fun<Elixir.KV.Bucket.3.120435444>,[]]]}
  (<0.223.0>) getting_linked <0.178.0>
  
  ## Tracing in a Distributed System

  Dbg allows to add remote nodes for tracing. With that in place, the
  trace flags/patterns are set accross the whole cluster. The :dbg.n/1
  function allows adding the nodes to be traced.

  The `trace_chain_distributed/0` enables tracing for all nodes with 
  the `:call` flag for all the processes and with the `:procs` and
  `set_on_spawn` flags for the `KVServer.TaskSupervisor`. Then it sets
  up the trace pattern to capture calls to the KV.Registry.create/2
  which are performed from the `KV.Router`. This is achieved with 
  the Match Specification that also enables tracing of the processes'
  events and trace flags inheritance (`:procs` and `:set_on_spawn`
  flags) for the `KV.Bucket.Supervisor` processes on the node, 
  on which the call to `KV.Registry.create/2` occurred.

  This way, we can trace the `processes chain` regardless of the fact
  that they may be living/spawned on a node that is different from the
  one that enabled the tracing or on which the tracer processes
  is spawned.

  ### Example

      iex> ExTrace.Dbg.trace_chain_distributed
      ...
  
  """

  def trace_buckets() do
    :dbg.tracer()
    :dbg.p(ExTrace.kv_bucket_supervisor_pid(), :p)
  end

  def trace_chain() do
    :dbg.tracer()
    {:dbg.p(ExTrace.kvserver_task_supervisor_pid,[:p, :sos]),
     :dbg.p(ExTrace.kv_bucket_supervisor_pid, [:p, :sos])}
  end

  def trace_chain_distributed() do
    :dbg.tracer()
    true = for n <- other_nodes() do
      :dbg.n(n)
    end |> Enum.all?(&(elem(&1,0) == :ok))
    :dbg.p(:processes, :c)
    ms = [{
           [:_, :_],
           [],
           [{:enable_trace, KV.Bucket.Supervisor, :procs},
            {:enable_trace, KV.Bucket.Supervisor, :set_on_spawn}]
           }]
    {:dbg.p(ExTrace.kvserver_task_supervisor_pid,[:p, :sos]),
     :dbg.tpl(KV.Registry, :create, ms)}
  end

  def stop_clear() do
    true = for n <- other_nodes() do
      :dbg.cn(n)
    end |> Enum.all?(&(&1 == :ok))
    :dbg.p(:all, :clear)
    :dbg.stop_clear()
  end

  def other_nodes() do
    KV.Router.table
    |> Enum.unzip
    |> elem(1)
    |> Enum.reject(&(&1 == node()))
  end

end
