defmodule Metasploit.Middleware.MessagePack do
  @moduledoc """
  Tesla middleware to encode / decode body to / from msgpack format. This is
  a requirement of the msgrpc API of metasploit.
  """

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _) do
    env = Tesla.put_header(env, "content-type", "binary/message-pack")

    with {:ok, env} <- encode(env),
         {:ok, env} <- Tesla.run(env, next) do
      decode(env)
    end
  end

  defp encode(env, _opts \\ []) do
    with {:ok, body} <- Msgpax.pack(env.body) do
      {:ok, Tesla.put_body(env, IO.iodata_to_binary(body))}
    end
  end

  defp decode(env, _opts \\ []) do
    with {:ok, body} <- Msgpax.unpack(env.body) do
      {:ok, Tesla.put_body(env, body)}
    end
  end
end
