defmodule ExTrace do

  def send_command() do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    send_and_recv(socket, "GET shopping eggs\r\n")
  end

  def test_kv_server(bucket \\ "alaska") do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    send_and_recv(socket, "GET #{bucket} bear\r\n")
    send_and_recv(socket, "CREATE #{bucket}\r\n")
    send_and_recv(socket, "PUT #{bucket} bear 3\r\n")
    send_and_recv(socket, "GET #{bucket} bear\r\n")
    send_and_recv(socket, "DELETE #{bucket} bear\r\n")
    :gen_tcp.close(socket)
  end

  def kvserver_task_supervisor_pid() do
    case Process.whereis(KVServer.TaskSupervisor) do
      pid when is_pid(pid) -> pid
      _ -> raise "Unable to find KVServer pid"
    end
  end

  def kv_bucket_supervisor_pid() do
    case Process.whereis(KV.Bucket.Supervisor) do
      pid when is_pid(pid) -> pid
      _ -> raise "Unable to find KV.Bucket.Supervisor pid"
    end
  end

  def kv_bucket_supervisor_pids() do
    case Process.whereis(KV.Bucket.Supervisor) do
      pid when is_pid(pid) -> pid
      _ -> raise "Unable to find KV.Bucket.Supervisor pid"
    end
  end

  def clear_all() ,do: :erlang.trace(:all, false, [:all])

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    IO.puts "Sent: #{command}Got: #{data}"
  end
  
end
