// b1 through web/io/io.js's controller with the real engine (./engine as serve.py runs it): open
// a_v1_ct_bank.csv and Save CSV without edits gives the file back byte for byte (02134, 00007, 4.50, -12.00,
// +3.10, 1000.00, "Coffee, large", "Say ""hi""" as written). The numbers still compute: formulas G2:G6 over
// them show Calc's values. After the formulas and after typing 5 into C3, every untouched field of the file
// is still saved exactly as it was, C3 saves as 5, and G2:G6 save as Calc shows them.
import { readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "../../../..");
const CALC = JSON.parse(readFileSync(join(HERE, "a_v1_ct_calc.json"), "utf8"));
const FILE = readFileSync(join(HERE, "a_v1_ct_bank.csv"), "utf8");
const { createController, display } = { ...(await import(pathToFileURL(join(ROOT, "web/io/io.js")).href)),
  ...(await import(pathToFileURL(join(ROOT, "web/grid/grid.js")).href)) };
const compute = async (book) => JSON.parse(execFileSync(join(ROOT, "engine"), ["-"], { input: JSON.stringify(book), cwd: ROOT, encoding: "utf8" }));
const { fields } = await import("./a_v1_ct_b1_fields.mjs");
const fails = [];
const fail = (m) => fails.push(m);

const original = fields(FILE);
const untouched = (saved, skip, when) => original.forEach((r, i) => r.forEach((f, c) => {
  const ref = String.fromCharCode(65 + c) + (i + 1);
  if (!skip.includes(ref) && (saved[i]?.[c] ?? "") !== f) fail(`${when}: ${ref} was ${JSON.stringify(f)} in the file, Save CSV writes ${JSON.stringify(saved[i]?.[c] ?? "")}`);
}));

const ctl = createController({ compute });
const opened = await ctl.openText("bank.csv", FILE);
if (!opened.ok) fail("Open bank.csv failed: " + ctl.state.message);
const first = ctl.saveCSV().text;
if (first !== FILE) fail(`Save CSV right after Open is not the file: got ${JSON.stringify(first)}, the file is ${JSON.stringify(FILE)}`);
for (const [ref, f] of Object.entries(CALC.formulas)) await ctl.edit(ref, f);
const shown = (ref) => display(ctl.state.computed.sheets[ctl.state.sheet][ref]);
for (const ref of Object.keys(CALC.formulas)) if (shown(ref) !== CALC.shown[ref]) fail(`${ref} ${CALC.formulas[ref]} shows ${shown(ref)}, Calc shows ${CALC.shown[ref]}`);
let saved = fields(ctl.saveCSV().text);
untouched(saved, [], "after adding formulas in G");
for (const ref of Object.keys(CALC.formulas)) if (saved[Number(ref.slice(1)) - 1]?.[6] !== CALC.shown[ref]) fail(`Save CSV writes ${ref} as ${saved[Number(ref.slice(1)) - 1]?.[6]}, Calc shows ${CALC.shown[ref]}`);
await ctl.edit("C3", "5");
saved = fields(ctl.saveCSV().text);
untouched(saved, ["C3"], "after typing 5 into C3");
if (saved[2]?.[2] !== "5") fail(`after typing 5 into C3, Save CSV writes C3 as ${saved[2]?.[2]}`);
for (const ref of Object.keys(CALC.formulas)) if (saved[Number(ref.slice(1)) - 1]?.[6] !== CALC.after_C3_5[ref]) fail(`after C3 = 5, Save CSV writes ${ref} as ${saved[Number(ref.slice(1)) - 1]?.[6]}, Calc shows ${CALC.after_C3_5[ref]}`);
for (const f of fails) console.log("FAIL " + f);
if (!fails.length) console.log("ok b1: bank.csv saves back byte for byte; untouched fields stay as written after edits; formulas give Calc's values");
process.exit(fails.length ? 1 : 0);
