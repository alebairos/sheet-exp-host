#!/bin/sh
# b1: README.md tells a new user how to start the browser UI and which URL to open, and following it
# from a clean clone shows the app page (the grid with the formula bar, computed by the engine).
# The check reads the command and the URL from README.md as written, runs them in a fresh copy, and
# loads the page. web/grid/README.md must send the reader to the same start (not only to its demo).
set -eu
cd "$(dirname "$0")/../../.."
. tests/web/checks/a_v1_sd_common.sh
fail() { echo "FAIL b1: $*"; exit 1; }
CMD=$(grep -E '^[[:space:]]*python3 web/io/serve\.py' README.md | head -1 | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//') || true
[ -n "$CMD" ] || fail "README.md has no command line starting the UI (python3 web/io/serve.py ...)"
URL=$(grep -oE 'https?://(127\.0\.0\.1|localhost):[0-9]+/[^ )>`"]*' README.md | head -1) || true
[ -n "$URL" ] || fail "README.md names no URL to open (http://127.0.0.1:<port>/...)"
grep -q 'web/io/serve\.py' web/grid/README.md || fail "web/grid/README.md does not point to the app's start (web/io/serve.py)"
TMP=$(mktemp -d); PID=
trap '[ -n "$PID" ] && kill $PID 2>/dev/null; rm -rf "$TMP"' EXIT
fresh_copy "$TMP/clone"
PORT=$(echo "$URL" | sed -E 's#^[a-z]+://[^:]+:([0-9]+)/.*#\1#')
if python3 -c "import socket,sys; s=socket.socket(); sys.exit(s.connect_ex(('127.0.0.1',$PORT))!=0)"; then
  # The documented port is taken on this machine: give another the way serve.py takes it.
  NEW=$(python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1',0)); print(s.getsockname()[1])")
  CMD="$CMD $NEW"; URL=$(echo "$URL" | sed "s#:$PORT/#:$NEW/#"); PORT=$NEW
fi
echo "README: $CMD  ->  $URL"
(cd "$TMP/clone" && exec sh -c "exec $CMD") >"$TMP/serve.log" 2>&1 &
PID=$!
python3 - "$URL" <<'PY' || { cat "$TMP/serve.log"; fail "following README.md does not show the app page"; }
import json, sys, time, urllib.request
url = sys.argv[1]
for _ in range(50):
    try:
        page = urllib.request.urlopen(url, timeout=2).read().decode(); break
    except OSError:
        time.sleep(0.2)
else:
    sys.exit("nothing answers at " + url)
for need in ('id="grid"', 'id="formula-bar"', 'io.js'):
    if need not in page: sys.exit("the page at %s is not the app (no %s)" % (url, need))
base = url.split("/", 3)[:3]
req = urllib.request.Request("/".join(base) + "/compute", method="POST",
      data=json.dumps({"sheets": {"Sheet1": {"A1": 2, "A2": "=A1*3"}}}).encode(),
      headers={"Content-Type": "application/json"})
got = json.load(urllib.request.urlopen(req, timeout=10))["sheets"]["Sheet1"]["A2"]
if got != 6: sys.exit("the page's engine computed =A1*3 with A1=2 as %r, not 6" % (got,))
print("page ok: grid, formula bar, engine (=A1*3 -> 6)")
PY
echo "ok b1"
