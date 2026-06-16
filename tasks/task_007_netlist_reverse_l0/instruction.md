A combinational lock service is running at http://target:8107.
Retrieve the Verilog design from `GET /design`, analyse it to find
the 16-bit `attempt` value that makes the `match` output go high,
then submit it via `POST /unlock {"key":"4hex"}` to get the flag.
