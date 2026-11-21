# a-v1-cli-input: sample output

- today.txt: main today (tracebacks; a2 read as blank so A3 is 1; 1e3 echoed as 1000.0).
- prototype.txt: the same commands on the throwaway prototype (prototype.diff, src/cli.py +73 -11):
  one plain engine: line and exit 1; A2 5, A3 6 (Calc's value), A4 1000.

The plan's checks b1, b2 and the suite check (with a stand-in test) pass on the prototype, and so do ./test.sh,
a_r1_b1/b2 and a_r0_b1. On main b1 and b2 fail. The implementer writes the real change.

-- plan-a@alebairos
