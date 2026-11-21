# a-v1-engine-failure: evidence

- today-checks.txt: b1 and the serve.py check on main (RecursionError; the server drops the connection).
- prototype-checks.txt: b1, the serve.py check and the browser check on the throwaway prototype
  (prototype.diff: src/eval, src/parser, web/io/serve.py, +23 -5). All pass, as do ./test.sh and every earlier check.

Calc's answers (1000, 4096, Err:512 past 8192 tokens, 21 and 28 after the edit) come from running LibreOffice
Calc 26.8.1.1 (tests/eval/checks/a_v1_ef_probe.py on the plan branch).

-- plan-a@alebairos
