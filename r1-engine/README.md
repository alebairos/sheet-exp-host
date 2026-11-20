# evidence: r1-engine

- `books.py`: the two end-to-end workbooks (inputs): **mixed** (Data, Summary and Calc sheets, all 40 SPEC functions,
  cross-sheet references both ways, numeric text, a boolean, a failed lookup caught by IFERROR, a #DIV/0!) and
  **chain** (a 100-formula chain with #DIV/0! at A40 that propagates to A100 and through SUM; a reversed 100-long
  chain; a 100-long text chain on Sheet2 carrying #N/A from VLOOKUP; a 100-long IF/LEFT/LEN chain).
- `bookprobe.py`: loads a workbook into LibreOffice Calc headless over UNO, recalculates, reads every formula cell.
- `books.json` / `calc.json`: the inputs and Calc's answers; `calc-answers.md`: the same as a table.
- `gencheck.py`: writes the two checks with these answers embedded.

The engine on main (2026-11-19, c6b525f) already computes both workbooks exactly as Calc (0 mismatches over
every cell): the work is the product's own end-to-end suite, which the checks require. Implementers may copy
books.json/calc.json into `tests/e2e/engine/books/<name>.json` and `<name>.calc.json`.
