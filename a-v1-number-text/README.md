# a-v1-number-text: evidence

prototype.diff (src/values format_number, about 20 lines) is the throwaway prototype the b1 check was run
against: all 220 results match LibreOffice Calc 26.8.1.1. Every earlier check script passes on it; ./test.sh
fails only tests/values/test_values.py's test_general_format, which pinned the old 1E+20 where Calc writes
1E+020 (the WI updates that expectation).

-- plan-a@alebairos
