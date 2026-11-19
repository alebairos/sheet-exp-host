# a-i4-recalc: evidence for the plan

- `circular.fods` / `circular-libreoffice.csv`: a sheet with a circular reference, converted by
  LibreOffice headless. Row: A1 =B1+1, B1 =A1+1 (the cycle), C1 =A1*2, D1 5, E1 =D1+1, F1 =F1,
  G1 =ISERROR(A1), H1 =IFERROR(A1;"x"), I1 =A1&"t", J1 =1/0+A1, K1 =A1+1/0.
  LibreOffice gives Err:522 on the cycle and on every formula reading it (C1, I1); D1 and E1
  compute normally; ISERROR/IFERROR see it as an error. (J1 and K1 give #DIV/0!: not pinned.)
- `sample-in.json` -> `sample-out.json`: what `./engine` will print, produced by the planner's
  throwaway prototype (not landed) that passes the four plan checks: cells written in any order
  compute in dependency order, across sheets; the C1/D1 cycle and E1 that reads it are
  {"error": "Err:522"}; F1/G1 are unaffected.
