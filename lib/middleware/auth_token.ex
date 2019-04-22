defmodule Metasploit.Middleware.AuthToken do
  @moduledoc """
  Inject the configured auth token into the request body, only after the method.

  Typically msgrpc requires a format like:
  [method, token, [args...]]
  """
  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, token) do
    body =
      case env.body do
        [method] ->
          [method, token]

        [method | args] ->
          [method, token] ++ args

        _ ->
          env.body
      end

    env
    |> Tesla.put_body(body)
    |> Tesla.run(next)
  end
end
