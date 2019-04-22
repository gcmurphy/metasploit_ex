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

  alias Metasploit.RPC

  defstruct client: nil, id: nil

  @doc """
  Attempt to connect to an existing metasploit console, or create a new
  console instance if one doesn't exist.

  """
  def client!(username, password, opts \\ []) do
    client = RPC.client(username, password, opts)

    with {:ok, id} <- console_session_id(client) do
      %__MODULE__{id: id, client: client}
    else
      {:error, error} ->
        raise "rpc error: #{inspect(error["error_backtrace"])}"
    end
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

  @doc """
  Write a single command to the metasploit console
  """
  def write(%__MODULE__{} = console, command) do
    RPC.call(console.client, "console.write", [console.id, command <> "\n"])
    console
  end

  @doc """
  Attempts to read from the metasploit console buffer. This is not guarenteed
  to contain output from previously run commands. As such you should consider
  running read_with_retry() with Task.await() to return the first time the
  buffer is not empty.
  """
  def read(%__MODULE__{} = console) do
    with {:ok, resp} <- RPC.call(console.client, "console.read", [console.id]) do
      case resp.body do
        %{"data" => data, "prompt" => _prompt} ->
          {:ok, data}

        error ->
          {:error, error}
      end
    end
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
  def run(%__MODULE__{} = console, script) do
    # write script line by line to console, ignoring blank lines or comments
    String.split(script, "\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.each(&write(console, &1))
  end

  defp try_read(console, delay, retries) when retries > 0 do
    :timer.sleep(delay)

    case read(console) do
      {:ok, ""} ->
        try_read(console, delay, retries - 1)

      {:ok, data} ->
        data

      otherwise ->
        otherwise
    end
  end

  defp try_read(console, delay, _) do
    :timer.sleep(delay)
    read(console)
  end

  @doc """
  Repeditly tries to read from the msfconsole buffer every `delay` milliseconds.
  This is done with a Task.async, and the resulting future can be waited on
  via Task.await() to obtain the result.
  """
  def read_with_retry(console, delay \\ 250, retries \\ 10) do
    Task.async(fn ->
      try_read(console, delay, retries)
    end)
  end
end
