# Intent `a-v1-csv-text`

## 1. Outcome

> Opening and saving a CSV changes my data. Observed: bank.csv's Branch 02134 becomes 2134 in the grid and in the saved CSV; Amount 4.50 saves as 4.5 (G15; prior S16, S19). Conflict: LibreOffice's default import does the same, so fidelity and usefulness disagree; the human settles it at spec accept. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: accepted · 2 work items · 1 bullet

## 2. What you will see

Open a bank CSV whose Branch column holds 02134 and whose Amount holds 4.50, and Save CSV: the file comes back exactly as it was. Add formulas or change some cells: the fields you did not touch are still written as in the file (02134 stays 02134, 4.50 stays 4.50, +3.10 stays +3.10). Changed cells and formulas are written as computed. In the grid nothing changes: 02134 shows as 2134 and computes as a number (=E2+1 is 2135), as in Calc. Evidence: bank.csv against saved-today.csv.

- [a-v1-csv-text/README.md](https://github.com/alebairos/sheet-exp-host/blob/c6480a1debf3bfc6f38e25200ba37aac578f17a6/a-v1-csv-text/README.md)
- [a-v1-csv-text/bank.csv](https://github.com/alebairos/sheet-exp-host/blob/c6480a1debf3bfc6f38e25200ba37aac578f17a6/a-v1-csv-text/bank.csv)
- [a-v1-csv-text/saved-today.csv](https://github.com/alebairos/sheet-exp-host/blob/c6480a1debf3bfc6f38e25200ba37aac578f17a6/a-v1-csv-text/saved-today.csv)
- [a-v1-csv-text/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/c6480a1debf3bfc6f38e25200ba37aac578f17a6/a-v1-csv-text/prototype.diff)

## 3. Approach

Cause, as read in web/io/io.js and run on main. parseCSV types each field the way the grid types input, so 02134 becomes the number 2134 and 4.50 becomes 4.5, and the text as written is dropped. toCSV then writes display() of the computed value. That is Calc's default import, but the saved file no longer matches the opened one (G15/S16/S19).
Fix (WI 1, web/io/io.js only, about 30 lines, as in the evidence prototype). On opening a .csv, the controller keeps state.opened = {sheet, text: each field as written, value: each cell as opened}. A new export csvText(text) reads the field texts with the same RFC 4180 reader, the BOM handled. toCSV(computed, sheet, asWritten = {}) writes a cell found in asWritten as that text (quoted where needed) and every other cell as today. saveCSV() passes asWritten = the opened fields whose cell in state.book still holds the value it opened with, on the opened sheet. So untouched fields round-trip byte for byte, while edited cells and new formulas are written as computed. parseCSV and the grid's display do not change: E2 is still the number 2134, shown as Calc shows it, and it computes. WI 2 adds the product's test tests/e2e/ui/test_csv_text.py.

Beliefs:
- ran: on main, Save CSV right after opening bank.csv writes 2134, 7, 4.5, -12, 3.1 and 1000 (evidence saved-today.csv). Settled by a_v1_ct_b1_roundtrip.sh and a_v1_ct_b1_page.sh, both red on main.
- ran: LibreOffice Calc 26.8.1.1's default CSV import (a_v1_ct_probe.py, read from a_v1_ct_calc.json) shows 02134 as 2134 and 4.50 as 4.5 and computes with them: =E2+1 2135, =C2+C3 -7.5, =SUM(C2:C6) 2195.6, =E3*2 14, =C5*10 31, and after C3 := 5, G3 9.5 and G4 2212.6. A 1E3 field took a scientific format in Calc, so the file uses 1000.00 to keep the comparison in General format. Settled by both b1 checks.
- human: the conflict the outcome names (Calc's import also drops the zero) is settled by the bullet as parked: the saved file keeps untouched values as written, while the grid keeps Calc's display and numbers. Settled by SpecAccept.
- ran: on the prototype (io.js +25 -4) both b1 checks, the suite check with a stand-in test, ./test.sh, a11_b1/b2/b3, a_r2_b1 and a_r0_b2 pass. Settled by the land test.
- ran: tests/web has no __init__.py, so ./test.sh discovers nothing under tests/web (test_io.py and io.test.mjs never run in land). The product's test therefore goes in tests/e2e/ui, which is in scope and discovered. Registering tests/web is a-i9/a-i10's old follow-up, not this intent. Settled by a_v1_ct_suite.sh.
- code: a field that reads as blank (empty) is not a cell and is written as an empty field, as today. Settled by b1 (E5).

Learned from RECORD.md and the overlapping pages: S16 was tagged conflict-with-spec?, and the addendum says a fidelity/usefulness conflict goes to the human. The parked bullet is that decision, so the plan keeps fidelity where Calc is the judge (display and computation) and usefulness where the file is the user's (the saved text). a-i11 rejected formulas in CSV and CSV dialects, which stay out (dialects are out of scope here too). a-i11's replan was about keeping formulas on save; the same idea, write back what the user did not change, is applied to CSV fields. The record found the web Node tests never registered, and this run confirmed that is still true. Checks go through the controller with the real ./engine and through the page with real input, not through parseCSV alone. Overlapping open intents in web/io: a-v1-keep-work (Save As) and a-v1-sheet-tabs touch saveCSV's callers, not its text.

- **Reuses:** io.js's RFC 4180 reader (csvRows), parseCSV's typing, toCSV's quoting and display(), the controller's state.book as typed; the engine through serve.py; a_r2_cdp.mjs for the browser check.
- **Removes:** The rewriting of untouched CSV fields on save (leading zeros, trailing decimals and + signs dropped).
- **Rejected:** Importing number-like fields with leading zeros as text: Calc imports them as numbers, and they would stop computing (=E2+1 would be #VALUE! or text). Formatting numbers on save with the decimals they were typed with: 02134 is not a decimal format, and a cell edited to 5 should save as 5. Keeping the raw text in the workbook JSON: it changes SPEC's workbook shape and Save JSON. CSV dialects, encodings and locale separators: out of scope.

## 4. Work items

### `wi-a-v1-csv-text-1`: Save CSV keeps untouched fields as written

web/io/io.js remembers each field of an opened CSV as written, and Save CSV writes a cell the user did not change back as that text (02134, 4.50), while edited cells and formulas are written as computed and the grid still computes the numbers.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ct-b1` | b1 | `tests/web/io/checks/a_v1_ct_b1_roundtrip.sh` | red | — |
| `ac-ct-b1-page` | b1 | `tests/e2e/ui/checks/a_v1_ct_b1_page.sh` | red | — |

### `wi-a-v1-csv-text-2`: Product test for the CSV round trip

Adds tests/e2e/ui/test_csv_text.py, run by ./test.sh, which opens a CSV with 02134 and 4.50, saves it untouched and after edits, and finds every untouched field as written, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-csv-text-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ct-suite` | b1 | `tests/e2e/ui/checks/a_v1_ct_suite.sh` | red | — |
| `ac-ct-judge` | b1 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user open a real CSV such as a bank export with codes like 02134 and amounts like 4.50, work with it (sum a column, add a formula, change a value), Save CSV and find that every value they did not change is written back as it was, while the numbers still added up correctly? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | opening a CSV and saving it again without edits writes back every untouched value exactly as it was in the file (02134 stays 02134, 4.50 stays 4.50), while numbers still compute as numbers | no landed check |

## 5. Out of scope and risks

- **Out of scope:** CSV dialects and encodings
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/io/io.js`, `exp-a:tests/web/io/**`, `exp-a:tests/e2e/ui/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-csv-text-1` | — |
| Reviewed `wi-a-v1-csv-text-1` | — |
| Implemented `wi-a-v1-csv-text-2` | — |
| Reviewed `wi-a-v1-csv-text-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 11 h 36 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
