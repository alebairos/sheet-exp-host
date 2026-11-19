# a-i6-logic-text: evidence for the plan

`calc-answers.md`: the 205 formulas of the plan checks with LibreOffice Calc's own answer for each.
`lt.py` builds the fixture and formulas, `probe.py` runs them in LibreOffice headless (UNO; a
boolean result is told apart from 1/0 by =ISLOGICAL on the result cell), `gencheck.py` writes the
checks from `lt.out.json`.

Calc behaviors the checks pin: IF returns a reference as a reference (ISBLANK(IF(1,A5)) is TRUE) and a
missing branch as FALSE; AND/OR skip text in ranges, #VALUE! with no logical value; NOT("TRUE") is
FALSE; ISNUMBER of a TRUE cell is TRUE (Calc stores booleans as 1/0); CONCATENATE of a TRUE cell is
"1"; LEFT("hello",-1) is Err:502 and MID("hello",2) Err:511; UPPER("straße") is "STRAẞE".

Found while probing, outside this intent's scope (src/values, a-i2): number-to-text differs from
Calc for very large and very small numbers. Calc gives 1E+20 -> "1E+020", 1E-7 -> "0.0000001",
1E+15 -> "1000000000000000", 2^53 -> "9.00719925474099E+015"; src.values.format_number gives
"1E+20", "1E-07", "1E+15", "9.00719925474099E+15". It affects & and CONCATENATE alike; those cases
are left out of these checks. Worth a Defect intent on src/values.
