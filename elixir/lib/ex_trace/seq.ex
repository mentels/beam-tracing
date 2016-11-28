defmodule ExTrace.Seq do

    defp seq_tracer() do
        Process.register(self(),:seq_tracer)
        loop_fn = fn (fun, tracer_pid)->
            receive do
                :stop_seq_tracer ->
                    :ok
                {:set_tracer_pid, pid} ->
                    fun.(fun,pid)
                msg when is_pid(tracer_pid) -> 
                    send tracer_pid, msg
                    fun.(fun,tracer_pid)
                _ ->
                    fun.(fun,tracer_pid)
            end
        end            
        loop_fn.(loop_fn,:no_tracer)
    end
    
    def start_seq_tracer_process() do
        case Process.whereis(:seq_tracer) do
            pid when is_pid(pid) -> pid
            _ -> spawn(&seq_tracer/0)
        end
    end
    
    def start_seq_tracer() do
        for n <- Node.list do
            p = :rpc.call(n,ExTrace.Seq,:start_seq_tracer_process,[])
            :rpc.call(n,:seq_trace,:set_system_tracer,[p])
        end 
    end
    
    def start_dbg_tracer() do
        :dbg.tracer()
        :erlang.trace(:all,false,[:all])
        for n <- Node.list do
          :dbg.n(n)
          :rpc.call(n,:erlang,:trace,[:all,false,[:all]])
        end
    end

    def start_tracer() do
        :dbg.stop_clear
        start_dbg_tracer
        start_seq_tracer
        {:ok,pid} = :dbg.get_tracer()
        :seq_trace.set_system_tracer(pid)
        for n <- Node.list do
            send {:seq_tracer,n}, {:set_tracer_pid,pid}
        end
    end

    defp set_trace_flags_for_sup_tree(pid,tp) do
        {pid,:dbg.p(pid,[:sos|tp])} |> IO.inspect
        {:dictionary, dict} = Process.info(pid,:dictionary)
        case dict[:"$initial_call"] do
            {:supervisor,_,_} ->
                for {_,cpid,_,_} <- :supervisor.which_children(pid) do
                    set_trace_flags_for_sup_tree(cpid,tp)
                end
            _ -> :ok 
        end
    end
    
    def set_trace_flags_for_app(app,tp) do
        {pid,_} = :application_master.get_child(:application_controller.get_master(app))
        set_trace_flags_for_sup_tree(pid,tp)
    end

end
