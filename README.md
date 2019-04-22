# Metasploit

A Elixir API to access the Metasploit framework. Allows a Metsploit session to
be controlled via Elixir over the msgprc protocol.

## Usage

With the Metasploit RPC daemon started:

`msfrpcd -U msf -P correct_horse_battery_staple -a 127.0.0.1  -p 55553`

The RPC framework can be used directly to issue RPC calls:

```elixir
alias Metasploit.RPC
client = RPC.client("msf", "correct_horse_battery_staple", endpoint: "https://127.0.0.1:55553")
client |> RPC.call("core.version")
```


Or alternatively you can run a series of commands as you would via the
console:

```elixir
alias Metasploit.Console

# create a console session
console = Console.client!("msf", "correct_horse_battery_staple", endpoint: "https://127.0.0.1:55553")

# Issue write / read commands individually
console
|> Console.write("use auxiliary/scanner/http/ssl")
|> Console.write("set RHOSTS 192.168.1.0/24")
|> Console.write("run")
|> Console.read()


# Or run a batch series of commands
Console.run(console, ~s(
  use auxiliary/scanner/http/ssl
  set RHOSTS 192.168.1.0/24
  run
))

# And wait for the output
output = Task.await!(Console.read_with_retry(console))

```

It should be noted that:
  - A console session becomes inactive 5 minutes after last command was sent.
  - Reading output from the console is best done via polling as it is not
    guaranteed to return output as soon as you issue a command.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `metasploit_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:metasploit_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/metasploit_ex](https://hexdocs.pm/metasploit_ex).
