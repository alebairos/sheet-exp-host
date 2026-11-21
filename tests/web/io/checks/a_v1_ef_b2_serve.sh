#!/bin/sh
# b2, the server side (plan a-v1-engine-failure): when computing a workbook fails inside web/io/serve.py's
# POST /compute (its compute raises, simulated here by replacing serve.compute with a function that raises
# RuntimeError("engine broke")), the server answers an HTTP error status (4xx/5xx), not a dropped connection,
# with a body that names the failure ("engine broke"), and keeps serving: the next POST /compute of
# {"sheets": {"S": {"A1": 2, "A2": "=A1*3"}}}, with the real compute back, answers 200 with A2 = 6.
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
exec python3 - <<'PY'
import importlib.util, json, sys, threading, urllib.error, urllib.request
spec = importlib.util.spec_from_file_location("serve", "web/io/serve.py")
serve = importlib.util.module_from_spec(spec); spec.loader.exec_module(serve)
real = serve.compute
def broken(book): raise RuntimeError("engine broke")
server = serve.http.server.ThreadingHTTPServer(("127.0.0.1", 0), serve.Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
url = "http://127.0.0.1:%d/compute" % server.server_address[1]
post = lambda book: urllib.request.urlopen(urllib.request.Request(url, json.dumps(book).encode(), {"Content-Type": "application/json"}), timeout=30)
fails = []
serve.compute = broken
try:
    r = post({"sheets": {"S": {"A1": 1}}}); fails.append("a failing compute answered %d, wanted an error status" % r.status)
except urllib.error.HTTPError as e:
    body = e.read().decode("utf-8", "replace")
    if not (400 <= e.code < 600) or "engine broke" not in body: fails.append("a failing compute answered %d %r, wanted 4xx/5xx naming 'engine broke'" % (e.code, body[:120]))
except Exception as e:
    fails.append("a failing compute dropped the request (%s: %s), wanted an HTTP error status with a message" % (type(e).__name__, e))
serve.compute = real
try:
    out = json.load(post({"sheets": {"S": {"A1": 2, "A2": "=A1*3"}}}))
    if out["sheets"]["S"].get("A2") != 6: fails.append("after the failure, POST /compute gives %r, wanted A2 = 6" % out)
except Exception as e:
    fails.append("after the failure, the server no longer computes: %s: %s" % (type(e).__name__, e))
server.shutdown()
for f in fails: print("FAIL " + f)
if not fails: print("ok b2 serve: a compute failure answers an HTTP error with its message, and the server keeps computing")
sys.exit(1 if fails else 0)
PY
