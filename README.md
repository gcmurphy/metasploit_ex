# Metasploit
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fgcmurphy%2Fmetasploit_ex.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fgcmurphy%2Fmetasploit_ex?ref=badge_shield)


A Elixir access the Metasploit framework. Allows a Metsploit session to
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
{:ok, pid} = Console.start_link({"msf", "correct_horse_battery_staple", endpoint: "https://127.0.0.1:55553"})

# Issue write / read commands individually

Console.write(pid, "use auxiliary/scanner/http/ssl")
Console.write(pid, "set RHOSTS 192.168.1.0/24")
Console.write(pid, "run")
Console.read(pid)


# Or run a batch series of commands
Console.run(pid, ~s(
  use auxiliary/scanner/http/ssl
  set RHOSTS 192.168.1.0/24
  run
))

```

It should be noted that:
  - A console session becomes inactive 5 minutes after last command was sent.
  - Read will block until it receives some data or times out.


## Status

This module is currently under development and has not been published to hex.pm
yet.



## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fgcmurphy%2Fmetasploit_ex.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fgcmurphy%2Fmetasploit_ex?ref=badge_large)