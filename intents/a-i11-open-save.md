# Intent `a-i11-open-save`

## 1. Outcome

> In the browser I open and save a workbook as CSV and as SPEC.md's JSON

Kind: Feature · State: planned · 1 work item · 2 bullets

## 2. What you will see

In the browser: Open takes a .json or .csv file from your computer; Save JSON downloads the workbook in SPEC.md's shape with every cell as it was (numbers, text, TRUE/FALSE, formulas like =SUM(A1:A2), errors, empty sheets, sheet order), so opening it again gives the same workbook; Save CSV downloads the current sheet's computed values from A1 to its last used cell, numbers as Calc shows them (0.3, not 0.30000000000000004), TRUE/FALSE, errors by name. Opening a CSV types each field the way the grid types what you enter (3 is a number, TRUE a boolean, an empty field a blank cell) and handles quoted fields with commas, quotes and line breaks. A file that is not a workbook gives a message, not a broken page. The prototype in the media does this with sample.json; sample-saved.csv is what Save CSV writes for it once computed.

- [a-i11-open-save/prototype.html](https://github.com/alebairos/sheet-exp-host/blob/a069c099118d321f3d102a5e598787f9831a6389/a-i11-open-save/prototype.html)
- [a-i11-open-save/io.js](https://github.com/alebairos/sheet-exp-host/blob/a069c099118d321f3d102a5e598787f9831a6389/a-i11-open-save/io.js)
- [a-i11-open-save/sample.json](https://github.com/alebairos/sheet-exp-host/blob/a069c099118d321f3d102a5e598787f9831a6389/a-i11-open-save/sample.json)
- [a-i11-open-save/sample-saved.csv](https://github.com/alebairos/sheet-exp-host/blob/a069c099118d321f3d102a5e598787f9831a6389/a-i11-open-save/sample-saved.csv)

## 3. Approach

One plain ES module, web/io/io.js, no build and no libraries, pure text functions first so Node tests them: parseJSON(text) (rejects anything that is not {"sheets": {...}} with an Error whose message the page shows) and toJSON(workbook), a lossless pair over SPEC.md's JSON; parseCSV(text, sheet = "Sheet1") an RFC 4180 reader (quotes, doubled quotes, separators and newlines inside quotes, CRLF or LF, no final newline) that types fields like the grid's input (number, TRUE/FALSE any case, empty is no cell, else text); toCSV(computed, sheet) writes the computed values of one sheet as a rectangle from A1, LF line ends, 15 significant digits, quoting only where a field has a comma, quote or line break. Two small DOM helpers, openFile(file) -> text and download(name, text, type), are the only browser code. CSV is values only: Save CSV takes the computed workbook (./engine's output), Save JSON the workbook as typed. The plan checks (tests/web/io/checks) run under Node.js, on the land runner image.

- **Reuses:** The web/io directory from a-i0-skeleton; SPEC.md's workbook JSON; the grid's typed-input rules from a-i9-grid for CSV fields; the number and error display rules the grid and formula bar use.
- **Removes:** The placeholder web/io/README.md content, replaced by a short note on the module's API.
- **Rejected:** A CSV library (Papa Parse) or a bundler: needs npm in every clean clone, for a reader of about 30 lines. Writing formulas into CSV: CSV holds values in Calc too, and a formula string in a CSV would be reopened as text that looks like a formula. Several sheets in one CSV: the format has no sheets; Save CSV writes the current one. Locale-dependent separators (;, decimal comma): the SPEC's JSON is locale-free and the hidden suite does not test CSV.

## 4. Work items

### `wi-a-i11-open-save-1`: Open and save JSON and CSV

Add web/io: a dependency-free JavaScript module that opens and saves a workbook as SPEC.md's JSON (every cell kept, formulas included) and a sheet as CSV (values), with the browser's file picker and download, so work in the UI can be loaded and kept.

Status: planned

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a11-b1` | b1 | `tests/web/io/checks/a11_b1_json.sh` | — | — |
| `ac-a11-b2` | b2 | `tests/web/io/checks/a11_b2_csv.sh` | — | — |

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
| Certified | — |
| Implemented `wi-a-i11-open-save-1` | — |
| Reviewed `wi-a-i11-open-save-1` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 8 h 33 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
