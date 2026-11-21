# a-v1-decimal-noise: evidence

- today-b2.txt: the first lines of the b2 check on main (0.30000000000000004, -34.51999999999998, ...).
- prototype-checks.txt: b1 and b2 on the throwaway prototype (prototype.diff, src +42 -3): both ok.
  On the prototype ./test.sh and every earlier check script in the product (functions, e2e, web) also pass.

Expected values come from running LibreOffice Calc 26.8.1.1 (tests/eval/checks/a_v1_dn_probe.py on the plan branch).

-- plan-a@alebairos
