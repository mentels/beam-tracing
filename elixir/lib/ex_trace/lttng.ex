defmodule ExTrace.LTTng do
  require Logger

  @type trace_point() :: :process_spawn | :process_link | :process_exit
  @type trace_file() :: Path.t
  
  @lttng_domain :org_erlang_dyntrace

  @spec setup([trace_point()]) :: trace_file()
  def setup(trace_points) do
    teardown()
    trace_file = create_session()
    enable_trace_points(trace_points)
    {:module, _} = Code.ensure_loaded(:dyntrace)
    start_tracing()
    trace_file
  end

  @spec view_traces() :: :ok
  def view_traces() do
    _ = call(["stop"])
    _ = call(["view"])
  end
  
  @spec teardown() :: :ok
  defp teardown() do
    _ = call(["stop"], :any)
    _ = call(["destroy", "--all"], :any)
    :ok
  end

  @spec create_session() :: trace_file()
  defp create_session() do
    call(["create", "ex_trace"]) |> String.split |> Enum.reverse |> hd
  end

  @spec enable_trace_points([trace_point()]) :: :ok
  defp enable_trace_points(trace_points) do
    events =
      trace_points
      |> Enum.map(&("#{@lttng_domain}:#{&1}"))
      |> Enum.join(",")
    _ = call(["enable-event", "-u", events])
    :ok
  end

  @spec start_tracing() :: :ok
  def start_tracing(), do: _ = call(["start"]); :ok
  
  defp call(args, return_code \\ 0)
  defp call(args, :any) do
    cmd(List.flatten(args)) |> elem(0)
  end
  defp call(args, return_code) do
    {result, ^return_code} = cmd(List.flatten(args))
    result
  end

  defp cmd(args) do
    Logger.debug "Running: lttng #{Enum.join args, " "}"
    System.cmd("lttng", args, stderr_to_stdout: true)
  end

end
