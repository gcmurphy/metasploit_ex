alias Metasploit.Console

# System.cmd("msfrpcd", "-U", "msf", "-P", "correct_horse_battery_staple", "-a", "127.0.0.1", "-p", "55553"])

{:ok, pid} = Console.start_link({"msf", "correct_horse_battery_staple", endpoint: "https://127.0.0.1:55553"})
Console.write(pid, "use auxiliary/scanner/http/ssl")
Console.write(pid, "set RHOSTS 192.168.1.0/24")
Console.write(pid, "run")
IO.puts(Console.read(pid))
