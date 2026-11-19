import http.server, json, os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(ROOT))
from src.cli import compute
class H(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".js": "text/javascript"}
    def __init__(s, *a, **k): super().__init__(*a, directory=ROOT, **k)
    def do_POST(s):
        if s.path != "/compute": return s.send_error(404)
        body = json.dumps(compute(json.loads(s.rfile.read(int(s.headers["Content-Length"]))))).encode()
        s.send_response(200); s.send_header("Content-Type", "application/json"); s.send_header("Content-Length", str(len(body))); s.end_headers(); s.wfile.write(body)
http.server.ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 8000), H).serve_forever()
