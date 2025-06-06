import http.server
import os
import signal
import socket
import socketserver
import subprocess
import sys
import threading
import time
from http import HTTPStatus

PORT = 1234
EVENT_SCRIPT = b'\n<script>new EventSource("/events").addEventListener("reload", () => location.reload())</script></html>'

clients = set()
clients_lock = threading.Lock()
running = True  # Used to stop event stream threads cleanly

class InjectingHandler(http.server.SimpleHTTPRequestHandler):
    def server_bind(self):
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.bind(self.server_address)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def do_GET(self):
        if self.path == "/events":
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.end_headers()

            with clients_lock:
                clients.add(self.wfile)

            try:
                while running:
                    time.sleep(1)
            except (ConnectionResetError, BrokenPipeError):
                pass
            finally:
                with clients_lock:
                    clients.discard(self.wfile)
        else:
            super().do_GET()

    def send_head(self):
        path = self.translate_path(self.path)
        if path.endswith(".html") and os.path.isfile(path):
            with open(path, "rb") as f:
                content = f.read()

            if b"</html>" in content:
                content = content.replace(b"</html>", EVENT_SCRIPT)
            else:
                content += EVENT_SCRIPT

            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)
            return None
        else:
            return super().send_head()


def broadcast_reload():
    with clients_lock:
        dead_clients = []
        for client in clients:
            try:
                client.write(b"event: reload\ndata: changed\n\n")
                client.flush()
            except Exception:
                dead_clients.append(client)
        for client in dead_clients:
            clients.discard(client)


child_process = None
server_thread = None
server = None

def watch_typst(typst_file):
    global child_process

    watch_command = [
        "typst",
        "--color=always",
        "watch",
        "--features",
        "html",
        "--format",
        "html",
        typst_file,
        "--root",
        ".",
        "--no-serve",
    ]

    child_process = subprocess.Popen(
        watch_command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=1,
        universal_newlines=True,
    )

    print("Started typst watch process...")
    try:
        for line in child_process.stdout:
            print(line.strip())
            if "compiled" in line.strip():
                broadcast_reload()
    except Exception as e:
        print(f"Watch process error: {e}")
    finally:
        print("Cleaning up typst process...")
        if child_process.poll() is None:
            child_process.terminate()
            child_process.wait()
        print("Typst process cleaned up.")


def handle_exit(sig, frame):
    global running
    print("Received signal to exit.")
    running = False

    if child_process and child_process.poll() is None:
        print("Terminating child process...")
        child_process.terminate()
        child_process.wait()

    if server:
        print("Shutting down HTTP server...")
        server.shutdown()

    if server_thread:
        server_thread.join()

    print("Shutdown complete.")
    sys.exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, handle_exit)
    signal.signal(signal.SIGTERM, handle_exit)

    server = socketserver.ThreadingTCPServer(("", PORT), InjectingHandler)
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.start()

    print(f"HTTP server running at http://localhost:{PORT}")
    watch_typst(sys.argv[1])
