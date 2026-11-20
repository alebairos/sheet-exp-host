// b1 in a real browser with real keys and mouse: F2 on A3 (=A1+A2, shows 30) opens the in-cell editor with the
// formula as typed; End, "+1", Enter stores =A1+A2+1 and A3 shows Calc's 31. Then a real double-click on A3
// opens it with =A1+A2+1; End, Backspace twice, "*2", Enter stores =A1+A2*2 and A3 shows Calc's 50.
// Save JSON writes the edited formula each time and the rest of the workbook unchanged.
import { CALC, fail, openPage, cellText } from "./a_v1_ce_page.mjs";

const { until, done, click, key, type, savedSheet, editor } = await openPage();
const want = (a3) => JSON.stringify({ ...CALC.book, A3: a3 });
try {
  await click("A3");
  await key("F2");
  await until("F2 on A3 opens the in-cell editor with its formula as typed", editor, CALC.book.A3, 30);
  await key("End");
  await type("+1");
  await key("Enter");
  await until(`after editing A3 to =A1+A2+1, A3 shows Calc's ${CALC.edits["=A1+A2+1"]}`, cellText("A3"), CALC.edits["=A1+A2+1"]);
  let saved = await savedSheet();
  if (JSON.stringify(saved) !== want("=A1+A2+1")) fail("after the F2 edit, Save JSON writes " + JSON.stringify(saved) + ", wanted " + want("=A1+A2+1"));
  await click("A3", 2);
  await until("a double-click on A3 opens the in-cell editor with its formula as typed", editor, "=A1+A2+1", 30);
  await key("End");
  await key("Backspace");
  await key("Backspace");
  await type("*2");
  await key("Enter");
  await until(`after editing A3 to =A1+A2*2, A3 shows Calc's ${CALC.edits["=A1+A2*2"]}`, cellText("A3"), CALC.edits["=A1+A2*2"]);
  saved = await savedSheet();
  if (JSON.stringify(saved) !== want("=A1+A2*2")) fail("after the double-click edit, Save JSON writes " + JSON.stringify(saved) + ", wanted " + want("=A1+A2*2"));
  for (const ref of Object.keys(CALC.shown)) if (ref !== "A3") await until(`${ref} still shows Calc's value`, cellText(ref), CALC.shown[ref], 10);
  console.log("ok b1: F2 and double-click open A3's formula; edits store =A1+A2+1 (31) and =A1+A2*2 (50) as in Calc");
  done(0);
} catch (e) { console.log("FAIL " + (e.stack || e)); done(1); }
