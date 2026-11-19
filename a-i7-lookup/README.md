# a-i7-lookup: evidence for the plan

`calc-answers.md`: the 104 formulas of the plan checks with LibreOffice Calc's own answer for each,
over one fixture: a sorted numeric table (A1:C5, with a #N/A and a blank inside), a sorted text
table (E1:F5), a mixed column (G1:G7), a horizontal row (I1:L2), duplicate keys (M1:N5) and a table
on Sheet2. `lk.py` builds it, `probe.py` runs it in LibreOffice headless (UNO), `gencheck.py`
writes the checks from `lk.out.json`.

Calc behaviors the checks pin: VLOOKUP("30",...) finds the number 30 and MATCH("3",...) the number
3 (numeric text matches numbers); approximate lookups take the last of equal keys (VLOOKUP(2,...,1)
is "d", exact is "b"); a VLOOKUP column index outside the table is Err:502 (Excel says #REF!),
INDEX outside its range is #REF!; INDEX(A1:C5,2) with no column is #VALUE! in one cell; MATCH on a
two-dimensional range, or with type 2, is Err:504; any non-zero VLOOKUP mode is approximate.
