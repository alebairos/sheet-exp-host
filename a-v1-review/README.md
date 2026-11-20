Review of sheet-exp-a (engine CLI + browser UI), clone at /home/alebairos/Work/sheet-exp-run/ws/gm-a/review-a (HEAD 5ed792b)
Reference: LibreOffice 26.8.1.1, run headless. Formulas went into .fods files with explicit calculation settings (case-sensitive=true, wildcards=true, regex=false, which are Calc's new-document defaults) and were converted to CSV. A probe sheet captured each value's type and its full-precision value. Browser: headless Chrome over CDP, using real Input.dispatchKey/MouseEvent, driven from the repo's own tests/e2e/ui/browser.mjs helpers.

./test.sh from a clean clone: OK. 75 tests in 5.1 s, and the browser walk-throughs ran (not skipped). Not run by ./test.sh: tests/web/grid/grid.test.mjs. It has no Python wrapper; run by hand it gives 7/7 pass.

Fidelity sample: about 470 formulas across 4 workbooks covering every SPEC area. Harness artefacts were removed: lowercase refs, the intersection operator, and Sheet!A1:Sheet!A2 translation; the last one was rechecked by hand. Out-of-scope functions (CHAR, REPT, TRUE(), FALSE()) are not counted. About 26 real mismatches remain, listed below.

======================================================================
A. USEFULNESS FINDINGS (UI and CLI as an ordinary user)
======================================================================

G1  Editing a formula in-cell (F2 / Enter) opens the value, not the formula, and destroys the formula
    kind: usefulness   severity: major   prior: S12 (still present)
    repro: A1 10, A2 20, A3 =A1+A2 (shows 30). Select A3, press F2, then End, type +1, press Enter.
    observed: the editor opens with "30". A3 becomes the text "30+1" and the formula is gone.
      Only the formula bar can edit a formula.
    expected: the editor opens with =A1+A2, as in Calc, and A3 becomes =A1+A2+1 = 31.
    files: web/grid/grid.js (startEdit uses inputText(computed value)), web/io/index.html (the grid is fed computed values)

G2  Opening a cell's editor and pressing Enter without typing silently replaces or deletes its content
    kind: usefulness   severity: major   prior: new (same root cause as S12)
    repro: (a) C1 =1/0 shows #DIV/0!. Select C1, press Enter (the editor opens empty), press Enter.
      (b) D1 =0.1+0.2. Select D1, press F2, press Enter.
      (c) In the bar, type '007 into D2 and set D3 =ISTEXT(D2). Select D2, press F2, press Enter.
    observed: (a) C1 is deleted: the cell and the bar are empty and the formula is lost.
      (b) D1's formula becomes the constant 0.3.
      (c) D2 becomes the number 7 and D3 flips to FALSE.
    expected: Calc leaves the cell unchanged when you edit without typing. In Calc, Enter on a selection moves down; it does not edit.
    files: web/grid/grid.js (Enter/F2 to startEdit, inputText, parseInput), web/io/index.html (changedRefs compares against computed values)

G3  Double-click does not open the editor in a real browser
    kind: usefulness   severity: minor (major in combination with G1)   prior: related to S12
    repro: click a cell, then double-click it with real mouse events (CDP mousePressed/Released with clickCount 1 then 2).
    observed: Chrome fires mousedown, click, mousedown, click (detail 2) but never fires dblclick. The click handler
      redraws the whole table (innerHTML) on every click, so the two clicks hit different elements. No editor opens.
      Typing afterwards replaces the cell (`+1` typed this way stores the number 1).
      A synthetic dblclick event does open the editor, with the value (G1).
    expected: double-click edits the cell, as the grid README says.
    files: web/grid/grid.js (onClick to update to draw on every click; onDblClick)

G4  Keystrokes typed while the previous edit is still computing are lost and focus drops to the page
    kind: usefulness   severity: major   prior: S14 (still present; now reproduced deterministically)
    repro: open a workbook that takes about 2.7 s to compute (20,000-cell chain). Type 1 then Enter in D1, then at once type
      `=SUM(1,2,3)+SUM(4,5,6)+SUM(7,8,9)+100` at 120 ms per key, then Enter.
    observed: when the D1 recompute returns, show() calls grid.setState(), which redraws and removes the open editor.
      The partly typed D2 formula is lost, D2 stays empty and document.activeElement is BODY. With a shorter formula
      that finishes before the recompute returns, it works (6/6 at 40 ms/key on a fast workbook). That is why the
      prior reviewer saw it only sometimes.
    expected: no input is lost, and a redraw keeps the open editor.
    files: web/io/index.html (show(), busy queue), web/grid/grid.js (setState to draw() clears `editing`)

G5  Only 20 rows x 8 columns are ever visible; a 2000-row CSV cannot be scrolled or navigated
    kind: usefulness   severity: major   prior: S17 (still present)
    repro: Open big.csv (header plus 2000 rows). Scroll, then from A20 press ArrowDown and PageDown.
    observed: 20 rows and 8 columns are rendered, the page scrollHeight equals the viewport, the selection stays on A20,
      and rows 21-2001 and columns I and beyond cannot be seen or edited. The data is intact: =SUM(B2:B2001) is right and
      Save CSV writes 2001 lines.
    expected: the grid scrolls and the arrows move past the visible area.
    files: web/grid/grid.js (renderHTML/mount default rows=20, cols=8; `inside()` blocks moves), web/io/index.html

G6  A multi-sheet workbook shows only its first sheet; the other sheets cannot be reached
    kind: usefulness   severity: major   prior: S20 (still present)
    repro: Open order.json with the sheets Prices and Order. Type 5 in B1.
    observed: only Prices is shown. The page has no tabs, select or other control (its only buttons are Save JSON and
      Save CSV), and the word "Order" appears nowhere. The edit changes Prices!B1. Save JSON keeps the Order sheet and
      its formulas.
    expected: SPEC: "A grid that renders, selects and edits cells" of the workbook, which includes Sheet2 references.
      Users need a sheet switcher.
    files: web/io/index.html, web/io/io.js (controller.state.sheet is fixed at open), web/grid/grid.js

G7  Tab does not move right; focus leaves the grid
    kind: usefulness   severity: minor   prior: S13 (still present)
    repro: select A1 and press Tab. Also type 77 in B1 and press Tab.
    observed: the selection stays on A1 (or B1 after the commit) and activeElement is BODY, so the next keys go nowhere.
    expected: Tab commits and moves right.
    files: web/grid/grid.js (onKey/startEdit have no Tab case)

G8  Clicking another cell while editing commits the edit but does not select the clicked cell
    kind: usefulness   severity: minor   prior: new in review, known a-i9 follow-up
    repro: type 5 in E1 (do not press Enter), then click E3.
    observed: E1 = 5 and the selection stays on E1.
    expected: E3 is selected.
    files: web/grid/grid.js (blur, then update, then redraw before the click lands)

G9  Text typed in the formula bar is silently discarded when you click elsewhere
    kind: usefulness   severity: minor   prior: new
    repro: select E2, click the bar, type hello, then click E4.
    observed: E2 stays empty and nothing warns. Only Enter commits.
    expected: Calc keeps the edit when you click into the grid.
    files: web/formula_bar/formula_bar.js (mount: no blur/commit)

G10 No undo
    kind: usefulness   severity: minor   prior: S22 (still present)
    repro: in H1 type 1, Enter, then type 2, Enter, then Ctrl+Z.   observed: H1 = 2.   expected: 1.
    files: web/io/index.html, web/io/io.js

G11 Reload loses all work without warning
    kind: usefulness   severity: minor   prior: S21 (still present)
    repro: type values and reload.   observed: the grid is empty, there is no beforeunload prompt and no message.
    files: web/io/index.html

G12 50% is text when typed in the grid but 0.5 when typed in the bar; CSV 50% is imported as text
    kind: usefulness   severity: minor   prior: S23 (still present)
    repro: grid B1 50%, B2 =B1*2. Bar C1 50%, C2 =C1*2. Open a CSV with the field 50%.
    observed: B1 "50%" with B2 #VALUE!. C1 0.5 shown as 0.5, C2 1. In the CSV, "50%" is text.
    expected: one rule everywhere; Calc gives 0.5, shown as 50%.
    files: web/grid/grid.js (parseInput has no percent), web/formula_bar/formula_bar.js (PERCENT), web/io/io.js (parseCSV uses the grid's rule)

G13 Errors give no explanation; parse failures are indistinguishable from #VALUE!
    kind: usefulness   severity: minor   prior: S15, S7, S5 (still present)
    repro: in the UI: =(1+, =D2 / =D1 (a cycle), =SQRT(-1), = SUM( A1 : A2 ).
    observed: #VALUE! (the bar shows the formula and #VALUE!, and the message line is empty), Err:522, Err:502, #VALUE!.
      Nothing says "syntax error", "circular reference" or "invalid argument".
    expected: some hint. Calc shows a status-bar text, for example "Error: Circular reference".
    files: web/formula_bar/formula_bar.js, web/io/index.html, src/eval, src/recalc

G14 Opened file names are reused on save; there is no Save As or choice of name
    kind: usefulness   severity: minor   prior: S18 (still present)
    repro: open bank.csv, edit it, click Save CSV.   observed: it downloads bank.csv; Save JSON downloads bank.json.
    files: web/io/io.js (saveJSON/saveCSV use state.name), web/io/index.html

G15 CSV import drops leading zeros, and CSV export reformats numbers
    kind: usefulness   severity: minor (matches Calc's default import)   prior: S16, S19 (still present)
    repro: bank.csv with Branch 02134 and Amount 4.50, then Save CSV.
    observed: E2 is 2134 and the saved CSV has 2134 and 4.5.
    files: web/io/io.js (parseCSV, toCSV), web/grid/grid.js (parseInput)

G16 Grid number display differs from Calc for large and small numbers
    kind: usefulness   severity: minor   prior: S25 (still present)
    repro: =10^15+1, 1234567890123456, 0.0000001.
    observed: 1E+15, 1.23456789012346E+15, 1E-07. The CLI returns 1000000000000001. Calc's text form of 1E15 is
      1000000000000000 and of 1E-7 is 0.0000001 (see G23).
    files: web/grid/grid.js (formatNumber)

G17 The CLI prints raw binary floating-point noise
    kind: usefulness   severity: minor   prior: S2, S8 (still present)
    repro: =0.1+0.2, =3*1.1, =17.5*0.15-style budget sums.
    observed: 0.30000000000000004, 3.3000000000000003, -34.51999999999998. The grid shows 0.3. Calc's stored double is
      the same, so this is not a fidelity error, but users read it as wrong.
    files: src/cli.py, src/values (to_json)

G18 One crashing formula freezes the whole UI
    kind: robustness   severity: minor   prior: new
    repro: in the bar, enter =1+1+...+1 with 1000 terms (the CLI crashes with RecursionError at 1000 or more terms).
      Then type 5 in B1 and =B1*2 in B2.
    observed: serve.py drops the connection with no HTTP status, and the message reads "Could not compute: Failed to
      fetch". Every later edit fails the same way, and B1 and B2 stay blank, because the bad formula remains in the book.
    expected: the cell gets an error value and the rest of the workbook keeps working.
    files: src/eval (recursive _eval), src/recalc, web/io/serve.py (no exception handling in do_POST)

======================================================================
B. FIDELITY FINDINGS (./engine vs LibreOffice 26.8.1.1, values actually computed)
======================================================================

G19 Equality and subtraction do not use Calc's approximate comparison
    kind: fidelity   severity: major (common in user sheets)   prior: new
    repro: =0.1+0.2=0.3 ; =(0.1+0.2)-0.3
    observed engine: false ; 5.551115123125783e-17      LibreOffice: TRUE ; 0
    files: src/eval (comparison and subtraction operators), src/values

G20 Implicit intersection is not supported
    kind: fidelity   severity: minor   prior: new (rejected in a-i3)
    repro: Data!G2 =C2:C3 (the same row as C2) ; T!A1 =Data!G2
    observed engine: #VALUE! ; #VALUE!      LibreOffice: 3 ; 3
    files: src/eval

G21 Text-to-number coercion is narrower than Calc's
    kind: fidelity   severity: minor   prior: new
    repro: =" 5 "+0 ; ="TRUE"+0 ; ="$5"+0 ; ="1,000"+0 ; ="50%"+0 ; ="1/2"+0
    observed engine: #VALUE! for all six      LibreOffice: 5 ; 1 ; 5 ; 1000 ; 0.5 ; 46024 (a date, outside SPEC's "no dates")
    files: src/values (to_number)

G22 Cycle detection is static: a cycle through an unevaluated branch is still an error
    kind: fidelity   severity: minor   prior: new (a-i4 note)
    repro: A16 =IF(TRUE,1,A16) ; B7 =IF(FALSE,B7,2) ; B8 =IFERROR(B9,0) with B9 =B8
    observed engine: Err:522 ; Err:522 ; Err:522      LibreOffice: 1 ; 2 ; B8 0 (B9 Err:522)
    files: src/recalc

G23 Number-to-text conversion (&, CONCATENATE, LEN) uses Python exponent style
    kind: fidelity   severity: minor   prior: a-i6 defect, still open
    repro: ="x"&1E-7 ; ="x"&1E15 ; =CONCATENATE(1E21) ; ="x"&123456789012345678 ; =LEN(123456789012345678) ; =LEN(1E-20)
    observed engine: x1E-07 ; x1E+15 ; 1E+21 ; x1.23456789012346E+17 ; 20 ; 5
    LibreOffice: x0.0000001 ; x1000000000000000 ; 1E+021 ; x1.23456789012346E+017 ; 21 ; 6
    files: src/values (format_number)

G24 Parse errors are #VALUE!, where Calc gives Err:5xx; a missing closing paren is an error, where Calc computes it
    kind: fidelity (see also conflict G30)   severity: minor   prior: S15, S24 (still present)
    repro: =(1+ ; =1+*2 ; =SUM(1,2 ; =1E400 ; = SUM( A1 : A2 ) ; =SUM(A1 :A2) ; =SUM( 'My Sheet'!A1 : A2 ) ; =SUM(S2!A1:S2!A2)
    observed engine: #VALUE! for every one      LibreOffice: Err:511 ; Err:510 ; 3 ; Err:502 ; 3 ; 3 ; 11 ; 7
    note: the spaces case (S24) and the sheet-qualified range end are user-visible gaps, not only error-name gaps.
    files: src/parser

G25 Empty-argument functions
    kind: fidelity   severity: minor   prior: new
    repro: =MAX() ; =MEDIAN()
    observed engine: 0 ; #VALUE!      LibreOffice: Err:511 ; Err:511
    files: src/functions/math

G26 Comparison of text is case-insensitive, while Calc's default document is case-sensitive
    kind: fidelity   severity: minor (depends on the document's setting)   prior: new
    repro: ="a"="A"
    observed engine: TRUE      LibreOffice: FALSE with Calc's default (case-sensitive on); TRUE when case-sensitive is off.
      COUNTIF and MATCH are case-insensitive in both settings, and the engine matches that.
    files: src/eval (comparison), src/values

G27 Text ordering is code-point, not locale collation
    kind: fidelity   severity: minor   prior: a-i2 note
    repro: ="é">"f"      observed engine: TRUE      LibreOffice: FALSE
    files: src/values

======================================================================
C. ROBUSTNESS (CLI)
======================================================================

G28 Bad input gives a Python traceback instead of a message
    kind: robustness   severity: minor   prior: S6 (still present)
    repro: echo '{"sheets": {' | ./engine - ; printf '' | ./engine - ; echo '{"sheets": []}' | ./engine - ;
      ./engine /nonexistent.json ; ./engine /tmp ; a formula of 1000 or more chained terms (=1+1+...+1).
    observed: tracebacks: JSONDecodeError, AttributeError, FileNotFoundError, IsADirectoryError and RecursionError.
      The RecursionError aborts the whole workbook. Exit status is 1 in every case.
    expected: a one-line error and a non-zero exit; for a too-deep formula, an error value in that cell only.
    files: src/cli.py, src/eval

G29 Odd input is accepted silently or produces invalid JSON; --cell variants
    kind: robustness   severity: minor   prior: new (a-i0 note on case)
    repro and observed:
      `[]` and `{"foo":1}` give {"sheets": {}} with exit 0.
      {"A1": NaN, "A2": 1e999} prints NaN and Infinity, which is not valid JSON.
      A lowercase key {"a2": 5} is echoed, but =A2 sees a blank (0).
      --cell sheet1!a1 gives #REF! (Calc sheet names are case-insensitive).
      --cell Sheet1!$A$1 gives null.
      --cell Nope!A1 gives {"error":"#REF!"} with exit 0.
      --cell=Sheet1!A1 gives a usage message.
      A constant 1e3 is echoed as 1000.0.
    files: src/cli.py

======================================================================
D. CONFLICT (usefulness and SPEC wording vs fidelity)
======================================================================

G30 Error names outside SPEC's six
    kind: conflict   severity: minor   prior: S5, S7
    SPEC: "Errors and their propagation: #DIV/0!, #VALUE!, #REF!, #NAME?, #N/A, #NUM!" and "Errors are {"error": "#DIV/0!"}".
    The engine emits, among others:
      Err:502 for =SQRT(-1), =MID("hello",0,2) and =POWER(-8,1/3)
      Err:522 for cycles
      Err:511 and Err:504 (in functions)
    LibreOffice gives exactly these, so they are faithful, and the hidden suite, being "computed by LibreOffice
    headless", will expect them. A user and SPEC's list expect #NUM! and a named circular-reference error.
    Fidelity says keep Err:5xx; SPEC's wording and usefulness say map them or explain them.
    For parse errors the engine satisfies neither side: it gives #VALUE!, where Calc gives Err:510/511/509 (G24).
    Recommendation: keep Calc's codes in the CLI and explain them in the UI (G13).
    files: src/functions/*, src/recalc, src/parser, web/formula_bar

======================================================================
E. DOCS
======================================================================

G31 The top-level README does not say how to start the UI; the grid README points to a demo page with no engine
    kind: docs   severity: minor   prior: S1 (still present)
    observed: README.md documents only ./test.sh and ./engine. The real UI is started with `python3 web/io/serve.py`,
      then http://127.0.0.1:8000/io/index.html, which only web/io/README.md says. web/grid/README.md says
      `python3 -m http.server` and /web/grid/, which is a demo where formulas stay as text.
    files: README.md, web/grid/README.md, web/io/README.md

G32 The grid's Node tests are not part of ./test.sh
    kind: docs/process   severity: minor   prior: a-i9 follow-up
    observed: tests/web/grid has no Python wrapper, so unittest discovery skips it. They pass when run by hand (7/7).
    files: tests/web/grid, scripts/test

======================================================================
F. PRIOR SURPRISES: STATUS
======================================================================
Major:
  S12 present (G1, G2, G3)
  S14 present (G4)
  S16 present (G15)
  S17 present (G5)
  S20 present (G6)
Minor:
  S1 present (G31)
  S2 present (G17)
  S5 present (G30; Calc gives the same Err:502)
  S6 present (G28)
  S7 present (G13/G30)
  S8 present (G17)
  S13 present (G7)
  S15 present (G13/G24)
  S18 present (G14)
  S21 present (G11)
  S22 present (G10)
  S23 present (G12)
  S24 present (G24; Calc computes 3 and 11)
  S25 present (G16)
No prior surprise has been fixed.

======================================================================
G. CHECKED AND FINE
======================================================================
- ./test.sh passes from a clean clone (75 tests), including both headless-browser walk-throughs.
- Matches LibreOffice:
  - References A1, $A$1, A$2/$A2, ranges, Sheet!A1, 'My Sheet'!A1; an unknown sheet gives #REF!; =A1000, =XFD1 and an
    out-of-range column behave as in Calc.
  - Every operator; precedence -2^2=4, 2^3^2=64, -A1^2, 2*3^2, 10-2-3, & vs +; % including 50%*2, -50%, 200%% and -5%^2.
  - Booleans in arithmetic; blank as 0 and ""; "12"+1; ""+1 gives #VALUE!; " "+0; numeric text in comparisons.
  - All six SPEC errors, their propagation and the literals (#N/A+1, ISERROR(#REF!)); a reference to an error cell.
  - Circular A1<->B1 gives Err:522 with dependants propagating; a self-reference; IFERROR around a cycle.
  - All 40 functions over about 300 cases each matched LibreOffice:
    - SUM, AVERAGE, MIN, MAX, COUNT, COUNTA with text, booleans, blanks and errors in ranges and as arguments.
    - ROUND, ROUNDUP and ROUNDDOWN half-away cases (1.005, 0.285, 1E15+0.5), negative digits.
    - INT, MOD with negative, fractional, zero and huge arguments; POWER(0,0), POWER(0,-1); SQRT; PRODUCT().
    - SUMIF, COUNTIF and AVERAGEIF criteria: operators, "", "=", "<>", wildcards * ? ~, regex characters, numeric text,
      TRUE, an error criterion, a short sum range.
    - MEDIAN, STDEV.
    - IF with missing arguments, IFERROR, AND/OR/NOT with text and ranges, the IS* functions.
    - CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM edge cases.
    - VLOOKUP exact, approximate and wildcard, numeric text against a number, a bad column.
    - INDEX with 0 row or column, out of range, fractional index.
    - MATCH 0, 1 and -1.
- Output shape: integers as JSON ints, text, true/false, {"error": ...}; constants echoed; sheet order kept.
- --cell Sheet1!B1, A1 (no sheet), quoted sheet names, an empty cell (null), usage on a missing argument.
- Speed: 22,000 cells (a 20,000-cell chain plus 2,000 SUMs) compute in 2.7 s.
- UI:
  - Typing numbers and formulas, Enter moving down, arrow keys, Delete and Escape all work.
  - Fixing an error through the formula bar works (=1/0 to =1/4 gives 0.25, and the red error clears).
  - The bar shows the formula and the error name.
  - Opening CSV works: RFC 4180 quotes, embedded commas and doubled quotes, and a =SUM formula in the CSV computes.
  - A bad JSON file shows "Could not open bad.json: ..." and keeps the open workbook.
  - Save JSON keeps formulas and every sheet; Save CSV writes computed values, with all 2001 rows for big.csv.
  - Lowercase =sum(a1:a2) works, an unknown function gives #NAME?, and typed "true" becomes TRUE.
  - No page exceptions were thrown in any session.
