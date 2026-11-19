# a-i5-math: evidence for the plan

What the 20 functions will return: `calc-answers.md` lists the 230 formulas of the plan checks with
LibreOffice Calc's own answer for each (sample output, Calc's side).

- `math.py` builds the fixture (one sheet: mixed values, blanks, text, TRUE/FALSE, an error, criteria
  data) and the formulas; `probe.py` loads them into LibreOffice headless through UNO and records
  each result (`math.out.json`). The checks embed these answers.
- Calc quirks the checks pin, all straight from Calc: a TRUE cell counts as 1 in SUM/COUNT/AVERAGE
  ranges (Calc stores booleans as numbers); SUM("3",1) is #VALUE! but COUNT(1,"2") counts the "2";
  MIN/MAX/MEDIAN/STDEV with a text literal give Err:504; SQRT(-1) is Err:502 while POWER(-1,0.5)
  is #NUM!; ROUND(1.005,2) is 1.01 and ROUNDUP(0.1+0.2,1) is 0.3 (decimal, not binary, rounding).
- Open question for the human: Calc has no #-name for Err:502/504/522. Through xlsx export
  (`xlsx_probe.py`, `errs.csv` is the same cells as displayed) LibreOffice writes all three as
  #VALUE!; displayed or exported as text they stay Err:NNN. SPEC's six names suggest the hidden
  suite avoids them; the plan keeps Calc's displayed names (as a-i4-recalc does with Err:522).
