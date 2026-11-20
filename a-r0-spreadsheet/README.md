# a-r0-spreadsheet: evidence

The plan's three workbooks, opened in today's app page (`python3 web/io/serve.py`, then `/io/index.html`) on
exp-a main (b0011f6). The page shows a workbook's first sheet, so each workbook is ordered with its most
telling sheet first:

- `1-budget.png`: the household budget's Summary (it reads the Income and Expenses sheets).
- `2-grades.png`: the grade sheet (weighted averages, letter grades from the Scale sheet, class statistics).
- `3-orders.png`: the order sheet (each line looks its SKU up in the Catalog sheet; one SKU is unknown).

Calc's answers (`checks/a_r0_calc.json` on plan/a-r0-spreadsheet) come from LibreOffice headless:
`python3 bookprobe.py a_r0_books.json out.json` (needs soffice and python3-uno). Re-run on 2026-11-20: every
cell of the three workbooks matches the stored answers. The engine and the page already show these values
on main; what the plan adds is the product's own e2e suite for them, so they stay that way.
