#!/usr/bin/env python3

import json
import os
import signal
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCRIPT = ROOT / "start-stream-lowlatency-player.sh"
LOG_DIR = ROOT / "lab" / "logs"
CONTROL_LOG = LOG_DIR / "control-server.log"

process = None


def stream_status():
    global process
    if process and process.poll() is None:
        return {"running": True, "pid": process.pid}

    process = None
    return {"running": False, "pid": None}


def write_json(handler, status, payload):
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    handler.send_header("Access-Control-Allow-Headers", "Content-Type")
    handler.end_headers()
    handler.wfile.write(body)


class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        write_json(self, 204, {})

    def do_GET(self):
        if self.path == "/api/stream/status":
            write_json(self, 200, stream_status())
            return

        write_json(self, 404, {"error": "not_found"})

    def do_POST(self):
        global process

        if self.path == "/api/stream/start":
            if process and process.poll() is None:
                write_json(self, 200, {"running": True, "pid": process.pid})
                return

            LOG_DIR.mkdir(parents=True, exist_ok=True)
            log_file = CONTROL_LOG.open("ab", buffering=0)
            process = subprocess.Popen(
                ["bash", str(SCRIPT)],
                cwd=str(ROOT),
                stdout=log_file,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
            write_json(self, 202, {"running": True, "pid": process.pid})
            return

        if self.path == "/api/stream/stop":
            if process and process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                process.wait(timeout=10)

            process = None
            write_json(self, 200, {"running": False, "pid": None})
            return

        write_json(self, 404, {"error": "not_found"})

    def log_message(self, fmt, *args):
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 8090), Handler)
    print("Control server em http://127.0.0.1:8090")
    server.serve_forever()
