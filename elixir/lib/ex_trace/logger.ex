defmodule ExTrace.Logger do
  require Logger

  def log(procs), do: _log(procs(procs))

  def log(procs, ptrns) do
    _log(procs(procs) <> " and #{format_count(ptrns)} patterns")
  end

  defp _log(msg), do: Logger.info msg

  defp procs(procs), do: "Matched #{format_count(procs)} processes"

  defp format_count(cnt) when is_list(cnt), do: Enum.sum cnt
  defp format_count(cnt) when is_integer(cnt), do: cnt
  
end
