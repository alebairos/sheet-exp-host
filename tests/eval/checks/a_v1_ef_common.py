"""Shared by the a-v1-engine-failure checks: the probe's workbook and Calc's answers (a_v1_ef_calc.json)."""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CALC = json.load(open(os.path.join(HERE, "a_v1_ef_calc.json")))
OTHER = {"A1": 2, "A2": "=A1*3", "C1": "=SUM(A1:A2)"}
LONG = {"B1": "=" + "+".join(["1"] * 1000), "B2": "=" + "+".join(["1"] * 5000),
        "B3": "=" + "+".join(["A1"] * 1000), "B4": "=" + "-".join(["A1"] * 2000), "B5": "=B1+B2",
        "B6": "=" + "+".join(["1"] * 4096), "B7": "=" + "+".join(["1"] * 4097), "B8": "=" + "+".join(["1"] * 4095)}


def calc_json(ref):
    """Calc's result for a cell as ./engine writes it: a number, or {"error": "Err:512"}."""
    r = CALC["results"][ref]
    return {"error": r["error"]} if "error" in r else r["value"]
