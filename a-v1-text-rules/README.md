# a-v1-text-rules: evidence for the plan

- `today.txt`: main (f101426) with the plan's checks: b1 166 cases and b2 173 cases differ from Calc.
  Text compares case-insensitively by code point ("a"="A" TRUE, "é">"f" TRUE, "Zürich">"Zuse"), and only a
  bare signed decimal reads as a number (" 5 ", "TRUE", "$5", "1,000", "50%" are #VALUE!).
- `prototype.diff`: about 120 lines of product code (src/values/text_rules.py, a few lines in src/values and
  src/eval) plus tests. With it: b1, b2 and the suite check pass, ./test.sh runs 82 tests, all OK, and every other
  plan check in the repo gives what it gave on main, except a-i2's a2_b2_coercion.sh (see the plan: conflict).
- How the rules were found (all LibreOffice Calc 26.8.1.1, headless, new document):
  1. 35,156 pairwise comparisons of 188 single characters: one consistent total order, no ties.
  2. 169 + 442 formulas of comparisons and coercion; a model of the rules was written from them.
  3. 265 held-out formulas, predicted by the model before Calc ran them: 261 right. The 4 misses
     ("2e3$" is #VALUE!, "-1e309" gives +1.79E+308, ß differs from ss at the accent level, not the case
     level) were folded in, and every case then matched.
  4. The checks' own layout (texts in cells) re-run in Calc: e + combining acute against é is not = but
     both <= and >=, so = and <> compare text exactly; a no-break space reads like a space in numbers.
     Earlier, CHAR(160) was U+FFFD in Calc, not a no-break space; the data uses the real character.
- Not matched, on purpose: text Calc reads as a date or fraction ("1/2" is a date serial, "1 1/2" is 1.5);
  dates are out of scope and these stay #VALUE!. No check holds them.
