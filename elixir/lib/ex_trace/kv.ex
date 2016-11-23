defmodule ExTrace.KV do
  def create(bucket), do: send_command("CREATE #{bucket}\r\n")
  def put(bucket, key, value),
    do: send_command("PUT #{bucket} #{key} #{value}\r\n")
  def delete(bucket, key),
    do: send_command("DELETE #{bucket} #{key}\r\n")

  def server_task_sup_pid() do
    case Process.whereis(KVServer.TaskSupervisor) do
      pid when is_pid(pid) -> pid
      _ -> raise "Unable to find KVServer pid"
    end
  end

  def bucket_sup_pid() do
    case Process.whereis(KV.Bucket.Supervisor) do
      pid when is_pid(pid) -> pid
      _ -> raise "Unable to find KV.Bucket.Supervisor pid"
    end
  end
  
  defp send_command(command) do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    send_and_recv(socket, command)
    :gen_tcp.close(socket)
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    IO.puts "Sent: #{command} Got: #{data}"
  end
end
