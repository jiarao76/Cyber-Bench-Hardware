#!/usr/bin/env python3
"""
Minimal HTTP reverse proxy for Harbor task environments.
Maps external ports on `target` to internal service ports.
"""
import http.server
import threading
import urllib.error
import urllib.request

ROUTES = {
    8105: ("service", 5000),
}


class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def _proxy(self, method):
        port = self.server.server_address[1]
        host, target_port = ROUTES[port]

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else None

        url = f"http://{host}:{target_port}{self.path}"
        req = urllib.request.Request(url, data=body, method=method)

        ct = self.headers.get("Content-Type")
        if ct:
            req.add_header("Content-Type", ct)

        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                self.send_response(resp.status)
                for k, v in resp.headers.items():
                    if k.lower() != "transfer-encoding":
                        self.send_header(k, v)
                self.end_headers()
                self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(502)
            self.end_headers()
            self.wfile.write(str(e).encode())

    def do_GET(self):
        self._proxy("GET")

    def do_POST(self):
        self._proxy("POST")

    def log_message(self, fmt, *args):
        pass


def _serve(port):
    http.server.HTTPServer(("", port), ProxyHandler).serve_forever()


if __name__ == "__main__":
    threads = [threading.Thread(target=_serve, args=(p,), daemon=True) for p in ROUTES]
    for t in threads:
        t.start()
    print(f"gateway listening on {list(ROUTES)}", flush=True)
    threads[0].join()
