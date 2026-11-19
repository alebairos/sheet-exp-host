# Intent `a-i11-open-save`

## 1. Outcome

> In the browser I open and save a workbook as CSV and as SPEC.md's JSON

Kind: Feature · State: Met · 1 work item · 2 bullets

## 2. What you will see

Run python3 web/io/serve.py and open http://127.0.0.1:8000/io/index.html: a page with Open (pick a .json or .csv file), Save JSON and Save CSV, a message line and the grid. Opening shows the file's first sheet in the grid with the engine's computed values; a file that is not a workbook leaves the open one alone and says why ("Could not open broken.json: ..."). Typing into a cell changes only that cell of your workbook and recomputes: open {A1: 2, B1: "=A1*2"}, type 7 into A1, and the grid shows B1 = 14 while Save JSON still has B1 = "=A1*2" (formulas you did not touch stay formulas, never replaced by their values). Save JSON downloads the workbook as typed, every cell kept (numbers, text, TRUE/FALSE, formulas like =SUM(A1:A2), errors, empty sheets, sheet order), with your edits; opening it again gives the same workbook. Save CSV downloads the current sheet's computed values from A1 to its last used cell, numbers as Calc shows them (0.3, not 0.30000000000000004), TRUE/FALSE, errors by name. Opening a CSV types each field the way the grid types what you enter and handles quoted fields with commas, quotes and line breaks. The prototype in the media is this page (io/index.html, io/io.js with edit(ref, text), io/serve.py and the landed grid).

- [io/index.html](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/io/index.html)
- [io/io.js](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/io/io.js)
- [io/serve.py](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/io/serve.py)
- [grid/grid.js](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/grid/grid.js)
- [README.md](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/README.md)
- [a-i11-open-save/sample.json](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/a-i11-open-save/sample.json)
- [a-i11-open-save/sample-saved.csv](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/a-i11-open-save/sample-saved.csv)

## 3. Approach

Three pieces in web/io, no build and no libraries. (1) io.js, pure text functions Node tests: parseJSON(text) (rejects anything that is not {"sheets": {...}} with an Error whose message the page shows) and toJSON(workbook), a lossless pair over SPEC.md's JSON; parseCSV(text, sheet = "Sheet1"), an RFC 4180 reader (quotes, doubled quotes, separators and newlines inside quotes, CRLF or LF) that types fields like the grid's input; toCSV(computed, sheet), values from A1 as a rectangle, LF, 15 significant digits, quoting only where needed. (2) createController({compute}) in io.js, the page's logic without the DOM: openText(fileName, text) / openFile(file) load JSON or CSV by extension, keep the workbook as typed, ask compute for the computed one and set a message, or return {ok: false, message} and keep the open workbook; edit(ref, text) writes only that cell into the stored workbook's current sheet (typed by the grid's rules, "" clears it) and recomputes, so the stored workbook never takes computed values; saveJSON() and saveCSV() return {name, text, type} for download(name, text, type). (3) index.html, the page: #open file input, #save-json, #save-csv, #message and #grid; it creates the controller with compute = POST /compute and mounts the grid (../grid/grid.js from a-i9) on the computed workbook; on each grid change it finds the cell the user typed into and calls controller.edit(ref, text) with the grid's inputText, then redraws from the controller. It never passes the grid's book back (the change from the rejected plan, whose setBook(book) turned every formula into its value). serve.py (Python standard library, like the engine) serves web/ with JavaScript's MIME type and answers POST /compute with src.cli.compute, so the page always shows exactly what ./engine computes (constants today, formulas once a-i4 lands). Checks: a11_b1_json and a11_b2_csv pin the formats; a11_b3_page pins the controller including the HITL's case (open {A1: 2, B1: "=A1*2"}, edit A1 to 7: Save JSON has A1 = 7 and B1 = "=A1*2", Save CSV shows 7,14, the engine is sent the formula), that index.html calls .edit( and never setBook(, and the server against ./engine, under Node.js and python3 on the land runner image.

- **Reuses:** The web/io directory from a-i0-skeleton; the grid's mount, createState and inputText (a-i9-grid, a dependency) as the page's view and the text of an edit; src/cli.py's compute for POST /compute, so the browser and ./engine agree; SPEC.md's workbook JSON; the grid's typed-input and number display rules.
- **Removes:** The placeholder web/io/README.md content, replaced by a short note on the module's API; the rejected plan's setBook(book) path from the page.
- **Rejected:** Passing the grid's whole book back through setBook (the rejected plan): the grid holds computed values, so saving would replace formulas with numbers. Changing the grid to report edits by cell: outside this intent's scope (web/grid is a-i9's); the page finds the edited cell itself. Computing in the browser with a second engine in JavaScript: two engines would drift from what ./engine (and so the hidden suite) computes; the page asks the one engine through serve.py. A web framework or bundler (and Flask for the server): needs npm or pip in every clean clone. A CSV library (Papa Parse): npm for a reader of about 30 lines. Writing formulas into CSV: CSV holds values in Calc too. Several sheets in one CSV: the format has no sheets; Save CSV writes the current one. Locale-dependent separators: the SPEC's JSON is locale-free.

## 4. Work items

### `wi-a-i11-open-save-1`: Open and save in the browser

Add web/io: a page with Open, Save JSON and Save CSV over the grid, a small controller that opens a file into the workbook (or a message for a bad file), takes each grid edit as one typed cell so formulas stay formulas, and saves it as SPEC.md's JSON or as CSV values, plus a standard-library server that serves the page and computes workbooks with the engine.

Status: landed (`6ce5b2aadde5`)

**The passing review noted:** > PASS (attempt 2). The defect from attempt 1 is fixed.
> 
> Verify rerun on 54b8e85 (host wi/wi-a-i11-open-save-1): a11_b1_json "ok b1", a11_b2_csv "ok b2", a11_b3_page "ok page and controller / ok serve.py". All were red on the plan commit 08ce178 at attempt 1. ./test.sh: 36 tests OK. node --test tests/web/io/io.test.mjs: 9 pass, 0 fail. No check file is touched, and every path is inside exp-a:web/io/** and exp-a:tests/web/io/**.
> 
> The fix (web/io/index.html:44-66): the grid is mounted once (`grid = mount(...)` on the first show) and later redraws go through grid.setState. onChange reads `shown` from a variable that show() updates. A new test in tests/web/io/io.test.mjs pins it: over a stand-in DOM, one Delete is one compute and only one keydown listener exists.
> 
> Independent re-check in jsdom with the page's own module script:
> - Six Deletes, A1..A6: each keypress made exactly 1 engine call (attempt 1: 1, 5, 17, 53, 161, 485).
> - The HITL case through the real grid: open {A1: 2, B1: "=A1*2"}, click A1, type 7, Enter. The book became {A1: 7, B1: "=A1*2"}, the grid shows B1 = 14, and there were 2 computes (open plus edit).
> 
> Per AC:
> - ac-a11-b1 (b1, JSON keeps every cell): met. parseJSON/toJSON at web/io/io.js:11-28; check a11_b1_json.
> - ac-a11-b2 (b2, CSV opens and saves values): met. web/io/io.js:31-98; check a11_b2_csv.
> - ac-a11-b3 (b1, b2 in the page): met. The controller is at io.js:114-167, and the page wiring at index.html:44-66 sends one cell per edit through controller.edit and never uses setBook. serve.py answers POST /compute with src.cli.compute. Check a11_b3_page.
> 
> Note (non-blocking, the grid's design and outside this scope): double-clicking a formula cell opens the editor with its computed value, so retyping replaces the formula. a-i10's formula bar is the place for that.
> 
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a11-b1` | b1 | `tests/web/io/checks/a11_b1_json.sh` | red | pass |
| `ac-a11-b2` | b2 | `tests/web/io/checks/a11_b2_csv.sh` | red | pass |
| `ac-a11-b3` | b1, b2 | `tests/web/io/checks/a11_b3_page.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | opening then saving a JSON workbook keeps every cell | `tests/web/io/checks/a11_b1_json.sh` pass, `tests/web/io/checks/a11_b3_page.sh` pass |
| PASS | b2 | CSV opens and saves values | `tests/web/io/checks/a11_b2_csv.sh` pass, `tests/web/io/checks/a11_b3_page.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** other formats; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:web/io/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i11-open-save-1` | `impl-a1@alebairos`, `impl-a2@alebairos` |
| Reviewed `wi-a-i11-open-save-1` | `rev-a@alebairos` (passed attempt 2) |
| Verdict (Met) | `alebairos` |

Product checks:

- `tests/web/io/checks/a11_b1_json.sh`: pass
- `tests/web/io/checks/a11_b2_csv.sh`: pass
- `tests/web/io/checks/a11_b3_page.sh`: pass

Outcome report:

- **Built:** Landed on exp-a main (6ce5b2a, merged in PR #7): web/io/index.html (Open .json/.csv, Save JSON, Save CSV, a message line and the a-i9 grid), web/io/io.js (parseJSON/toJSON over SPEC.md's workbook, an RFC 4180 parseCSV/toCSV, and createController with openText/openFile/edit(ref, text)/saveJSON/saveCSV), and web/io/serve.py (serves web/ and answers POST /compute with ./engine). The replan's fix is in: each grid edit goes to controller.edit(ref, text), which writes only that cell into the stored workbook, and the page never calls setBook with computed values. I re-ran the three checks on landed main: a11_b1_json, a11_b2_csv and a11_b3_page all pass, including your case: open {A1: 2, B1: "=A1*2"}, edit A1 to 7, and Save JSON keeps B1 = "=A1*2". serve.py serves the page (200, text/html) and io.js (text/javascript). The WI landed on attempt 2 of 3 after one failed attempt. One limit today: ./engine does not evaluate formulas yet, so POST /compute returns {A1: 7, B1: "=A1*2"} unchanged (I checked it live). In the real page B1 shows the formula text, not 14, until a-i4-recalc (still parked) wires evaluation into the engine. The b3 check tests the 14 through the controller with a stand-in compute.
- **Advice:** Try it: in a clone of exp-a, run python3 web/io/serve.py and open http://127.0.0.1:8000/io/index.html. Open a SPEC.md JSON workbook or a CSV, type into a cell, then Save JSON and reopen the file: every cell and formula should come back the same. Save CSV gives the current sheet's values. Expect formulas to show as text in the grid and in Save CSV until a-i4-recalc lands; that is outside this intent's scope (b1 and b2 hold), not a defect here. Met fits if open/save round-trips for you; choose PartiallyMet if you want the 14 shown in the live page counted before a-i4.
- [io/index.html](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/io/index.html)
- [io/io.js](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/io/io.js)
- [io/serve.py](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/io/serve.py)
- [a-i11-open-save/sample.json](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/a-i11-open-save/sample.json)
- [a-i11-open-save/sample-saved.csv](https://github.com/alebairos/sheet-exp-host/blob/60a586cc3762d23f8dc99a87cd9ae44144e484b0/a-i11-open-save/sample-saved.csv)

Files landed by `wi-a-i11-open-save-1`:

- `web/io/io.js` +169 −0
- `tests/web/io/checks/a11_b3_page.sh` +111 −0 (plan check)
- `tests/web/io/io.test.mjs` +111 −0 (test)
- `web/io/index.html` +85 −0
- `web/io/serve.py` +64 −0
- `tests/web/io/checks/a11_b1_json.sh` +41 −0 (plan check)
- `tests/web/io/checks/a11_b2_csv.sh` +40 −0 (plan check)
- `tests/web/io/test_io.py` +21 −0 (test)
- `web/io/README.md` +16 −1
- `tests/web/io/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #7](https://github.com/alebairos/sheet-exp-a/pull/7)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 20 h 43 min
- Loops: 4 (D1 spec 1, D2 plan 2, D5 review 1)
- Waste: 3 h 48 min
- Size: 335 lines (+334 −1, 7 files, ≤400; tests 132 lines); plan check files laid over by land, not in the size: +192 −0, 3 files
