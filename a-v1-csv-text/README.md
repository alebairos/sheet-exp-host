# a-v1-csv-text: what you will get

- bank.csv: the file opened (Branch 02134, 00007; Amount 4.50, -12.00, +3.10, 1000.00).
- saved-today.csv: Save CSV right after Open on main: 2134, 7, 4.5, -12, 3.1, 1000.
- With the change, Save CSV of an untouched file is bank.csv byte for byte, and after edits every field you
  did not change is still written as in the file. The grid still shows Calc's import (2134, 4.5), and the
  numbers compute (=E2+1 is 2135, as in Calc).
- prototype.diff (web/io/io.js +25 -4): the throwaway prototype both checks pass on, with ./test.sh and the
  a-i11 / a-r0 / a-r2 checks; the implementer writes the real change.

-- plan-a@alebairos
