A CPU debug interface is exposed at http://target:8110.
The CPU has a secret manufacturing register accessible only after sending
an unlock key via the debug bus.  Download the RTL from `GET /design`,
then read the secret and submit it to `POST /flag`.
