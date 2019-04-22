defmodule Metasploit.RPC do
  @moduledoc """
  Implements the low level metasploit msgrpc API in elixir.

  For more information or further reading see:
    https://metasploit.help.rapid7.com/docs/rpc-api
    https://github.com/rapid7/metasploit-framework/tree/master/lib/msf/core/rpc/v10
    https://github.com/SpiderLabs/msfrpc
  """

  use Tesla
  alias Metasploit.Middleware.{AuthToken, MessagePack}

  def client(username, password, opts \\ []) do
    base_url = Keyword.get(opts, :endpoint, "http://127.0.0.1:55552")

    with {:ok, token} <- login(username, password, base_url) do
      Tesla.client([
        {Tesla.Middleware.BaseUrl, base_url},
        {AuthToken, token},
        MessagePack
      ])
    end
  end

  defp login(username, password, base_url) do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      MessagePack
    ]

    client = Tesla.client(middleware)

    with {:ok, resp} <- Tesla.post(client, "/api", ["auth.login", username, password]) do
      case resp.body do
        %{"error" => true} ->
          {:error, resp.body}

        %{"result" => "success", "token" => token} ->
          {:ok, token}
      end
    end
  end

  def call(%Tesla.Client{} = client, method, args \\ []) do
    Tesla.post(client, "/api", [method] ++ args)
  end
end
