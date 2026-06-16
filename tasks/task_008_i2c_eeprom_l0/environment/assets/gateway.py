#!/usr/bin/env python3
"""HTTP reverse-proxy: forwards target:8108 → service:5000."""
import http.server, urllib.request, urllib.error, sys, os

ROUTES = {8108: ("service", 5000)}

class Proxy(http.server.BaseHTTPRequestHandler):
    timeout = 90
    def log_message(self, *a): pass

    def _forward(self, body=None):
        host, port = ROUTES.get(self.server.server_port, ("service", 5000))
        url = f"http://{host}:{port}{self.path}"
        headers = {k: v for k, v in self.headers.items()
                   if k.lower() not in ("host", "connection")}
        req = urllib.request.Request(url, data=body, headers=headers,
                                     method=self.command)
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                self.send_response(resp.status)
                for k, v in resp.headers.items():
                    if k.lower() not in ("transfer-encoding", "connection"):
                        self.send_header(k, v)
                self.end_headers()
                self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            body_err = e.read()
            self.send_response(e.code)
            for k, v in e.headers.items():
                if k.lower() not in ("transfer-encoding", "connection"):
                    self.send_header(k, v)
            self.end_headers()
            self.wfile.write(body_err)
        except Exception as exc:
            self.send_response(502); self.end_headers()
            self.wfile.write(str(exc).encode())

    def do_GET(self):  self._forward()
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        self._forward(self.rfile.read(n) if n else None)

if __name__ == "__main__":
    srv = http.server.HTTPServer(("0.0.0.0", 8108), Proxy)
    print(f"[gateway] listening on 8108 → service:5000", flush=True)
    srv.serve_forever()
