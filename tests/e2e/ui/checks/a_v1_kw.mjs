// a-v1-keep-work checks in a real browser with real keys and clicks, on web/io/index.html as web/io/serve.py
// serves it, budget.json {A1: 1} opened. Run with b1, b2 or b3; prints FAIL lines or ok.
import { openPage, cellText, sleep } from "./a_v1_kw_page.mjs";

const which = process.argv[2];
const pg = await openPage("budget.json", JSON.stringify({ sheets: { Sheet1: { A1: 1 } } }), ["A1", "1"]);
const fails = [];
const typeCell = async (ref, text) => { await pg.click(ref); await pg.key(text[0]); if (text.length > 1) await pg.type(text.slice(1)); await pg.key("Enter"); await sleep(400); };
const shows = async (cells, what) => { for (const [ref, t] of Object.entries(cells)) await pg.until(`${what}: ${ref}`, cellText(ref), t, 30); };
try {
  if (which === "b1") {
    await typeCell("A1", "2"); await typeCell("A2", "3"); await pg.click("B1"); await pg.inBar("x"); await sleep(400);
    await shows({ A1: "2", A2: "3", B1: "x" }, "after three edits");
    await pg.click("C5");
    await pg.ctrl("z"); await shows({ B1: "", A2: "3" }, "Ctrl+Z once undoes the bar edit");
    await pg.ctrl("z"); await shows({ A2: "", A1: "2" }, "Ctrl+Z twice undoes A2");
    await pg.ctrl("z"); await shows({ A1: "1" }, "Ctrl+Z three times restores A1 = 1");
    await pg.ctrl("y"); await shows({ A1: "2", A2: "" }, "Ctrl+Y redoes A1");
    await pg.ctrl("y"); await pg.ctrl("y"); await shows({ A2: "3", B1: "x" }, "Ctrl+Y three times redoes all");
    const cells = await pg.savedSheet();
    if (JSON.stringify(cells) !== JSON.stringify({ A1: 2, A2: 3, B1: "x" })) fails.push("after undo and redo, Save JSON writes " + JSON.stringify(cells));
  } else if (which === "b2") {
    const dialogs = [];
    pg.b.on("Page.javascriptDialogOpening", (p) => { dialogs.push(p.type); pg.b.send("Page.handleJavaScriptDialog", { accept: false }); });
    await pg.click("C3"); await pg.b.send("Page.reload"); await sleep(1500);
    if (dialogs.length) fails.push("reloading a page with no edits asked for confirmation (" + dialogs.join(",") + ")");
    const again = await openPage("budget.json", JSON.stringify({ sheets: { Sheet1: { A1: 1 } } }), ["A1", "1"]);
    const seen = [];
    again.b.on("Page.javascriptDialogOpening", (p) => { seen.push(p.type); again.b.send("Page.handleJavaScriptDialog", { accept: false }); });
    await again.click("A1"); await again.key("7"); await again.key("Enter"); await sleep(500);
    await again.b.send("Page.reload"); await sleep(1500);
    if (!seen.includes("beforeunload")) fails.push("reloading with an unsaved edit did not ask for confirmation (dialogs: " + JSON.stringify(seen) + ")");
    else {
      await again.until("after the user stays, the edit is still there", cellText("A1"), "7", 30);
      await again.savedSheet(); seen.length = 0;
      await again.b.send("Page.reload"); await sleep(1500);
      if (seen.length) fails.push("reloading right after Save JSON still asked for confirmation");
    }
    again.b.close();
  } else if (which === "b3") {
    const name = `document.getElementById("save-name")`;
    if (!(await pg.js(`!!${name} && ${name}.value`))) fails.push("the page has no file name field (#save-name) holding the opened name");
    else {
      await pg.js(`(() => { const e = ${name}; e.focus(); e.select(); })()`); await pg.type("my-budget"); await sleep(200);
      const json = await pg.savedSheet("my-budget.json");
      if (JSON.stringify(json) !== JSON.stringify({ A1: 1 })) fails.push("Save JSON as my-budget.json writes " + JSON.stringify(json));
      const csv = await pg.savedSheet("my-budget.csv", "save-csv");
      if (csv !== "1\n") fails.push("Save CSV as my-budget.csv writes " + JSON.stringify(csv));
    }
  }
} catch (e) { fails.push(String(e.stack || e)); }
for (const f of fails) console.log("FAIL " + f);
if (!fails.length) console.log(`ok ${which}`);
pg.done(fails.length ? 1 : 0);
