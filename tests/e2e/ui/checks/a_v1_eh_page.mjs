// b1 in a real browser (plan a-v1-error-help): on web/io/index.html as web/io/serve.py serves it, Open book.json
// (a_v1_eh_calc.json "book": one formula per error in A1:A11, numbers in A20:A21). Click each error cell: the
// grid shows the error as Calc does, and beside the formula bar an explanation line (#formula-bar .error-help)
// is visible, one line, and holds the error's name and Calc's own explanation (its long text without "Error: ",
// case-insensitive: Err:522 -> "circular reference"). Click A20 (a number): no explanation is shown.
import { mkdtempSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { findBrowser, serve, launch, sleep } from "./a_r2_cdp.mjs";

const CALC = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "a_v1_eh_calc.json"), "utf8"));
const fail = (m) => { console.log("FAIL " + m); process.exit(1); };
const browser = findBrowser();
if (!browser) fail("no browser: set CHROME or put google-chrome or chromium on PATH");
const file = join(mkdtempSync(join(tmpdir(), "a-v1-eh-")), "book.json");
writeFileSync(file, JSON.stringify({ sheets: { Sheet1: CALC.book } }));
const server = await serve();
const b = await launch(browser);
const errors = [], fails = [];
b.on("Runtime.exceptionThrown", (p) => errors.push(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text));
const done = (code) => { b.close(); server.close(); process.exit(code); };
try {
  await b.send("Runtime.enable"); await b.send("Page.enable");
  const js = async (e) => (await b.send("Runtime.evaluate", { expression: e, returnByValue: true, awaitPromise: true })).result.value;
  const until = async (what, e, want, tries = 100) => { let got; for (let t = 0; t < tries; t++) { got = await js(e); if (got === want) return true; await sleep(100); } fails.push(`${what}: wanted ${JSON.stringify(want)}, the page shows ${JSON.stringify(got)}`); return false; };
  const cell = (ref) => `document.querySelector('#grid td[data-ref="${ref}"]')?.textContent.trim() ?? null`;
  const help = `(() => { const e = document.querySelector("#formula-bar .error-help"); if (!e) return null; const r = e.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && getComputedStyle(e).visibility !== "hidden" ? e.innerText : ""; })()`;
  const click = async (ref) => {
    const r = await js(`(() => { const e = document.querySelector('#grid td[data-ref="${ref}"]'); const r = e.getBoundingClientRect(); return {x: r.x + r.width / 2, y: r.y + r.height / 2}; })()`);
    for (const type of ["mousePressed", "mouseReleased"]) await b.send("Input.dispatchMouseEvent", { type, ...r, button: "left", clickCount: 1 });
    await until(`clicking ${ref} selects it`, `document.querySelector('#formula-bar .ref')?.textContent.trim() ?? ""`, ref, 30);
  };
  await b.send("Page.navigate", { url: server.url + "/io/index.html" });
  await until("the page loads with its grid", `!!document.querySelector('#grid td[data-ref="A1"]')`, true);
  const doc = await b.send("DOM.getDocument");
  const input = await b.send("DOM.querySelector", { nodeId: doc.root.nodeId, selector: "#open" });
  await b.send("DOM.setFileInputFiles", { nodeId: input.nodeId, files: [file] });
  if (!(await until("after Open, A1 shows #DIV/0!", cell("A1"), "#DIV/0!"))) fail(fails.join("; "));
  await sleep(1500); await b.send("Page.bringToFront");  // an extension tab on some desktop builds hides the page
  for (const [ref, { shown }] of Object.entries(CALC.errors)) {
    await until(`${ref} (${CALC.book[ref]}) shows Calc's error`, cell(ref), shown, 20);
    await click(ref);
    const text = (await js(help)) ?? null, want = CALC.long[shown].replace(/^Error: /, "");
    if (!text) fails.push(`selecting ${ref} (${shown}) shows no explanation beside the formula bar (#formula-bar .error-help)`);
    else if (/\n/.test(text.trim())) fails.push(`the explanation for ${shown} is more than one line: ${JSON.stringify(text)}`);
    else if (!text.includes(shown) || !text.toLowerCase().includes(want.toLowerCase())) fails.push(`the explanation for ${shown} is ${JSON.stringify(text)}: it should name ${shown} and say "${want}" (Calc's text)`);
  }
  await click("A20");
  if (await js(help)) fails.push("selecting A20 (a number) still shows an explanation: " + JSON.stringify(await js(help)));
  if (errors.length) fails.push("the page threw: " + errors.join(" | "));
  for (const f of fails) console.log("FAIL " + f);
  if (!fails.length) console.log("ok b1: each of the 10 errors explains itself beside the formula bar in Calc's words");
  done(fails.length ? 1 : 0);
} catch (e) { console.log("FAIL " + (e.stack || e)); done(1); }
