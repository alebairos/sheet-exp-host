// a-v1-grid-keys checks in a real browser with real keys and clicks, on web/io/index.html as web/io/serve.py
// serves it, a workbook {H1: "x"} opened. Run with b1, b2 or b3; prints FAIL lines or ok.
import { openPage, selectedRef, cellText, sleep } from "./a_v1_gk_page.mjs";

const which = process.argv[2];
const pg = await openPage("keys.json", JSON.stringify({ sheets: { Sheet1: { H1: "x" } } }), ["H1", "x"]);
const fails = [];
const inGrid = `(() => { const a = document.activeElement, g = document.getElementById("grid"); return !!a && (a === g || g.contains(a)); })()`;
const sel = async (want, what) => pg.until(`${what}: the selection`, selectedRef, want, 30).catch((e) => fails.push(String(e)));
const focus = async (what) => { if (!(await pg.js(inGrid))) fails.push(`${what}: keyboard focus left the grid (activeElement ${await pg.js("document.activeElement.tagName")})`); };
const typeCell = async (text) => { await pg.key(text[0]); if (text.length > 1) await pg.type(text.slice(1)); };
const want = async (cells, what) => {
  await sleep(600);
  const saved = await pg.savedSheet();
  for (const [ref, v] of Object.entries(cells)) if (JSON.stringify(saved?.[ref]) !== JSON.stringify(v)) fails.push(`${what}: ${ref} holds ${JSON.stringify(saved?.[ref])}, wanted ${JSON.stringify(v)}`);
};
try {
  if (which === "b1") {
    await pg.click("A1");
    await pg.key("Tab"); await sel("B1", "Tab on A1"); await focus("after Tab");
    await pg.key("Tab", { shift: true }); await sel("A1", "Shift+Tab on B1"); await focus("after Shift+Tab");
    await typeCell("77"); await pg.key("Tab"); await sel("B1", "77 then Tab in A1"); await focus("after 77, Tab");
    await typeCell("5"); await pg.key("Tab"); await sel("C1", "5 then Tab in B1");
    await typeCell("9"); await pg.key("Tab", { shift: true }); await sel("B1", "9 then Shift+Tab in C1"); await focus("after 9, Shift+Tab");
    await pg.key("ArrowDown"); await sel("B2", "ArrowDown after the Tabs (keys still reach the grid)");
    await want({ A1: 77, B1: 5, C1: 9 }, "after the Tabs");
  } else if (which === "b2") {
    await pg.click("E1"); await typeCell("5"); await pg.click("E3"); await sel("E3", "typing 5 in E1 then clicking E3");
    await typeCell("6"); await pg.click("G5"); await sel("G5", "typing 6 in E3 then clicking G5");
    await pg.until("E1 shows the committed 5", cellText("E1"), "5", 30).catch((e) => fails.push(String(e)));
    await want({ E1: 5, E3: 6 }, "after clicking away while editing");
  } else if (which === "b3") {
    await pg.click("E2"); await pg.inBarNoEnter("hello"); await pg.click("E4"); await sel("E4", "typing hello in the bar for E2 then clicking E4");
    await pg.click("E5"); await pg.inBarNoEnter("=1+1"); await pg.click("F6"); await sel("F6", "typing =1+1 in the bar for E5 then clicking F6");
    await pg.until("E5 shows =1+1 computed", cellText("E5"), "2", 30).catch((e) => fails.push(String(e)));
    await want({ E2: "hello", E5: "=1+1" }, "after leaving the bar by a click");
  }
} catch (e) { fails.push(String(e.stack || e)); }
for (const f of fails) console.log("FAIL " + f);
if (!fails.length) console.log(`ok ${which}`);
pg.done(fails.length ? 1 : 0);
