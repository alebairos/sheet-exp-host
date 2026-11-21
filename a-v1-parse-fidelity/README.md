# a-v1-parse-fidelity: evidence

rule_model.py is a ~60-line scanner implementing the parse-error rule stated in the plan. Run on the plan
branch's tests/parser/checks/a_v1_pf_calc.json (python3 rule_model.py <that file>), it reproduces all 85 of
LibreOffice Calc's results (the 12 =F() empty calls parse; their Err:511 comes from evaluation's table). It is
evidence that the rule is right, not the implementation.

-- plan-a@alebairos
