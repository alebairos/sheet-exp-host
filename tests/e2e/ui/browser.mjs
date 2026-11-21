// Headless Chrome/Chromium for the product's browser tests, Node's standard library only: the app as
// web/io/serve.py serves it, the browser driven over the DevTools protocol on a pipe (--remote-debugging-pipe).
import { spawn, execFileSync } from "node:child_process";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import net from "node:net";

export const sleep = (ms) => new Promise((ok) => setTimeout(ok, ms));

// $CHROME first, then google-chrome, google-chrome-stable, chromium, chromium-browser on PATH; null if none.
export function findBrowser() {
  for (const name of [process.env.CHROME, "google-chrome", "google-chrome-stable", "chromium", "chromium-browser"]) {
    if (!name) continue;
    try {
      const path = execFileSync("sh", ["-c", 'command -v "$0"', name], { encoding: "utf8" }).trim();
      if (path) return path;
    } catch {}
  }
  return null;
}

const freePort = () => new Promise((ok) => {
  const s = net.createServer().listen(0, "127.0.0.1", () => { const { port } = s.address(); s.close(() => ok(port)); });
});

// python3 web/io/serve.py on a free port, from the repo root; resolves once it prints "Serving".
export async function serve(root) {
  const port = await freePort();
  const p = spawn("python3", [join(root, "web", "io", "serve.py"), String(port)], { cwd: root, stdio: ["ignore", "pipe", "ignore"] });
  await new Promise((ok, no) => {
    p.stdout.on("data", (d) => { if (/Serving/.test(String(d))) ok(); });
    p.on("exit", (c) => no(new Error("serve.py exited " + c)));
  });
  return { url: `http://127.0.0.1:${port}`, close: () => p.kill() };
}

// Starts the browser headless and attaches to its page: send(method, params) -> result, on(event, fn), close(),
// targetId (the attached page's).
export async function launch(browser) {
  const profile = mkdtempSync(join(tmpdir(), "e2e-ui-profile-"));
  const proc = spawn(browser, ["--headless=new", "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage",
    "--no-first-run", "--disable-extensions", "--remote-debugging-pipe", `--user-data-dir=${profile}`, "--window-size=1200,900", "about:blank"],
  { stdio: ["ignore", "ignore", "ignore", "pipe", "pipe"] });
  const toBrowser = proc.stdio[3], fromBrowser = proc.stdio[4];
  let id = 0, buf = "";
  const waiting = new Map(), handlers = [];
  fromBrowser.on("data", (d) => {
    buf += d;
    for (let i; (i = buf.indexOf("\0")) >= 0;) {
      const m = JSON.parse(buf.slice(0, i));
      buf = buf.slice(i + 1);
      if (m.id && waiting.has(m.id)) {
        const [ok, no] = waiting.get(m.id);
        waiting.delete(m.id);
        if (m.error) no(new Error(JSON.stringify(m.error))); else ok(m.result);
      } else if (m.method) {
        for (const [ev, fn] of handlers) if (ev === m.method) fn(m.params);
      }
    }
  });
  const call = (method, params = {}, sessionId) => new Promise((ok, no) => {
    const msg = { id: ++id, method, params, ...(sessionId ? { sessionId } : {}) };
    waiting.set(msg.id, [ok, no]);
    toBrowser.write(JSON.stringify(msg) + "\0");
  });
  let pages = [];
  for (let t = 0; t < 100 && !pages.length; t++) {
    pages = (await call("Target.getTargets")).targetInfos.filter((x) => x.type === "page");
    if (!pages.length) await sleep(100);
  }
  if (!pages.length) { proc.kill(); throw new Error("the browser opened no page"); }
  const targetId = pages[0].targetId;
  const { sessionId } = await call("Target.attachToTarget", { targetId, flatten: true });
  return {
    targetId,
    // Browser.* and Target.* go to the browser itself, everything else to the attached page.
    send: (method, params) => call(method, params, /^(Browser|Target)\./.test(method) ? undefined : sessionId),
    on: (ev, fn) => handlers.push([ev, fn]),
    close: () => proc.kill(),
  };
}
