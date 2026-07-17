import os
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import URLError, HTTPError
from urllib.request import Request, urlopen

SOURCE_URL = os.getenv("SOURCE_URL", "http://webgateway:80/api/monitor/metrics")
POLL_INTERVAL = float(os.getenv("POLL_INTERVAL", "20"))
TIMEOUT = float(os.getenv("REQUEST_TIMEOUT", "8"))
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "9101"))
OUTPUT_FILE = os.getenv("OUTPUT_FILE", "/shared/metrics.prom")

_cache_lock = threading.Lock()
_cache_body = None
_cache_content_type = "text/plain; charset=utf-8"
_cache_updated_at = 0.0


def _persist_cache_file(body: bytes):
    if not OUTPUT_FILE:
        return

    directory = os.path.dirname(OUTPUT_FILE)
    if directory:
        os.makedirs(directory, exist_ok=True)

    tmp = f"{OUTPUT_FILE}.tmp"
    with open(tmp, "wb") as f:
        f.write(body)
    os.replace(tmp, OUTPUT_FILE)


def fetch_metrics():
    global _cache_body, _cache_content_type, _cache_updated_at
    req = Request(SOURCE_URL, headers={"User-Agent": "metrics-cache/1.0"})
    with urlopen(req, timeout=TIMEOUT) as resp:
        status = resp.getcode()
        body = resp.read()
        if status != 200:
            raise RuntimeError(f"upstream status {status}")
        content_type = resp.headers.get("Content-Type", "text/plain; charset=utf-8")

    with _cache_lock:
        _cache_body = body
        _cache_content_type = content_type
        _cache_updated_at = time.time()

    _persist_cache_file(body)


def poll_loop():
    while True:
        try:
            fetch_metrics()
        except (HTTPError, URLError, RuntimeError, TimeoutError):
            pass
        except Exception:
            pass
        time.sleep(POLL_INTERVAL)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"ok")
            return

        if self.path != "/api/monitor/metrics":
            self.send_response(404)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"not found")
            return

        with _cache_lock:
            body = _cache_body
            content_type = _cache_content_type
            updated_at = _cache_updated_at

        if body is None:
            self.send_response(503)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"Service Unavailable")
            return

        age = max(0, int(time.time() - updated_at))
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-cache")
        self.send_header("X-Metrics-Cache", "HIT")
        self.send_header("X-Metrics-Cache-Age", str(age))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return


if __name__ == "__main__":
    t = threading.Thread(target=poll_loop, daemon=True)
    t.start()
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    server.serve_forever()
