# Intent `a-i11-open-save`

## 1. Outcome

> In the browser I open and save a workbook as CSV and as SPEC.md's JSON

Kind: Feature · State: certified · 1 work item · 2 bullets

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

Status: planned

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a11-b1` | b1 | `tests/web/io/checks/a11_b1_json.sh` | red | — |
| `ac-a11-b2` | b2 | `tests/web/io/checks/a11_b2_csv.sh` | red | — |
| `ac-a11-b3` | b1, b2 | `tests/web/io/checks/a11_b3_page.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | opening then saving a JSON workbook keeps every cell | no landed check |
| not yet | b2 | CSV opens and saves values | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other formats; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:web/io/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i11-open-save-1` | — |
| Reviewed `wi-a-i11-open-save-1` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

**SpecAccept:a-i11-open-save**: A decision: show your human its options

- Accept the spec: claims freeze, it can be admitted: `cooknship decide --answer SpecAccept:a-i11-open-save --option accept`
- Send the plan back with a reason: `cooknship decide --answer SpecAccept:a-i11-open-save --option reject --text "<reason>"`
- Shelve it; when another intent takes its place, the reason is replaced:<that intent's id>, and what waits on this one waits for it instead: `cooknship decide --answer SpecAccept:a-i11-open-save --option shelve --text "<reason>"`

## 8. Metrics

- Lead time: 12 h 27 min so far
- Loops: 3 (D1 spec 1, D2 plan 2)
- Waste: 3 h 40 min
- Size: nothing landed yet
