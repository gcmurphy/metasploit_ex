defmodule Metasploit.Console do
  @moduledoc """

  Provides a programatic interaction with the metasploit framework console. Allows
  you to issue commands as you would via msfconsole, and is a thin wrapper around
  the msgrpc endpoint.

  Note: There is currently a bit of a bug in metasploit around this feature.
  https://github.com/rapid7/metasploit-framework/issues/11600

  This means that you need to use msgrpcd not the `msfconsole load msgrpc` option!

  Note: In general interacting with the console in this manner is fairly unstable
  in the limited testing that I've done. There seem to be a number of bugs
  and race conditions that exist within the metasploit framework.
  """

  use GenServer
  alias Metasploit.RPC

  @delay 250

  defmodule Connection do
    defstruct client: nil, id: nil
  end

  def start_link({username, password, opts}) do
    client = RPC.client(username, password, opts)

    with {:ok, id} <- console_session_id(client) do
      GenServer.start(__MODULE__, {%Connection{id: id, client: client}})
    end
  end

  @doc """
  Write a single command to the metasploit console
  """
  def write(pid, command, timeout \\ 10_000) do
    GenServer.call(pid, {:write, command}, timeout)
  end

  @doc """
  Attempts to read from the metasploit console buffer. This is not guarenteed
  to contain output from previously run commands as it is gathered by polling.
  """
  def read(pid, timeout \\ 10_000) do
    GenServer.call(pid, {:read}, timeout)
  end

  @doc """
  Run a series of metasploit commands in sequence (to enable scripting
  and automation).

  Example:

  #{__MODULE__}.run(msf, ~s(
    use auxiliary/scanner/http/ssl
    set RHOSTS 192.168.1.0/24
    run
  ))
  """
  def run(pid, script) do
    GenServer.cast(pid, {:execute, script})
  end

  defp create_console(%Tesla.Client{} = client) do
    with {:ok, resp} <- RPC.call(client, "console.create") do
      case resp.body do
        %{"id" => id} -> {:ok, id}
        error -> {:error, error}
      end
    end
  end

  defp console_session_id(%Tesla.Client{} = client) do
    with {:ok, resp} <- RPC.call(client, "console.list") do
      case resp.body do
        %{"consoles" => [%{"id" => id}]} -> {:ok, id}
        %{"consoles" => []} -> create_console(client)
        error -> {:error, error}
      end
    end
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def handle_cast({:execute, script}, state) do
    String.split(script, "\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.each(&send(self(), {:write, &1}))

    {:noreply, state}
  end

  @impl true
  def handle_call({:write, command}, _from, {conn} = state) do
    RPC.call(conn.client, "console.write", [conn.id, command <> "\n"])
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:read}, from, state) do
    Process.send(self(), {:poll_read, from}, [:noconnect])
    {:noreply, state}
  end

  @impl true
  def handle_info({:poll_read, from}, {conn} = state) do
    with {:ok, resp} <- RPC.call(conn.client, "console.read", [conn.id]) do
      case resp.body do
        %{"data" => ""} ->
          Process.send_after(self(), {:poll_read, from}, @delay)

        %{"data" => buffer} ->
          GenServer.reply(from, buffer)
      end
    end

    {:noreply, state}
  end
end
