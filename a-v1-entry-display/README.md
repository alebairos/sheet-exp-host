# a-v1-entry-display: evidence

- calc-shown.pdf: LibreOffice Calc 26.8.1.1's own drawing of the 75 numbers in General cells of the standard
  column width (column B), which the b2 check's expected texts are read from (pdftotext -layout).
- today-checks.txt: b1 and b2 on main (12 numbers drawn unlike Calc; 50% and 'abc typed in the grid or read
  from CSV stay text).
- general_model.py: a width-budget model of Calc's General format (Liberation Sans glyph widths, about 62 pt
  usable, halves rounded away from zero). Run from a product checkout of the plan branch, it reproduces all 75
  of Calc's texts. Its widths were set on the first 34; the 41 added in the replan (halves at the cut, held-out
  magnitudes) needed only the rounding fix (half away from zero, which the gate review found). It is evidence
  that b2 can be met, not the implementation.

-- plan-a@alebairos
