"""The e2e workbooks for a-r1-engine (inputs only; Calc computes the answers)."""
import json, sys

def mixed():
    data = {"A1": "Item", "B1": "Category", "C1": "Qty", "D1": "Price", "E1": "Total"}
    rows = [("apple", "fruit", 12, 0.5), ("Banana", "fruit", 7, 0.25), ("carrot", "veg", 20, 0.1),
            ("dill", "herb", 3, 1.75), ("eggplant", "veg", 4, 1.2), ("fig", "fruit", 9, 0.8),
            ("garlic", "herb", 15, 0.3), ("  kale  ", "veg", "6", 2)]
    for i, (a, b, c, d) in enumerate(rows, start=2):
        data.update({"A%d" % i: a, "B%d" % i: b, "C%d" % i: c, "D%d" % i: d, "E%d" % i: "=C%d*D%d" % (i, i)})
    data["G1"] = "Category"; data["H1"] = "Discount"
    data.update({"G2": "fruit", "H2": 0.1, "G3": "herb", "H3": 0.05, "G4": "veg", "H4": 0})
    data["F1"] = "Net"
    for i in range(2, 10):
        data["F%d" % i] = "=ROUND(E%d*(1-VLOOKUP(B%d,$G$2:$H$4,2,0)),2)" % (i, i)
    data["A11"] = True; data["B11"] = "=IF(A11,\"on\",\"off\")"
    summ = {
        "A1": "=SUM(Data!E2:E9)", "A2": "=SUM(Data!F2:F9)", "A3": "=AVERAGE(Data!C2:C9)",
        "A4": "=COUNT(Data!C2:C9)", "A5": "=COUNTA(Data!A1:A12)", "A6": "=MIN(Data!D2:D9)",
        "A7": "=MAX(Data!E2:E9)", "A8": "=MEDIAN(Data!C2:C9)", "A9": "=ROUND(STDEV(Data!C2:C9),4)",
        "A10": "=SUMIF(Data!B2:B9,\"fruit\",Data!E2:E9)", "A11": "=COUNTIF(Data!B2:B9,\"veg\")",
        "A12": "=AVERAGEIF(Data!C2:C9,\">5\")", "A13": "=SUMIF(Data!C2:C9,\">=10\")",
        "A14": "=PRODUCT(Data!H2:H3)*100", "A15": "=POWER(A4,2)+SQRT(16)-ABS(-3)",
        "A16": "=MOD(A4*7,5)", "A17": "=INT(-A3)", "A18": "=ROUNDUP(A3,1)", "A19": "=ROUNDDOWN(A3,1)",
        "B1": "=INDEX(Data!A2:A9,MATCH(MAX(Data!E2:E9),Data!E2:E9,0))",
        "B2": "=VLOOKUP(\"fig\",Data!A2:F9,6,0)", "B3": "=VLOOKUP(\"zucchini\",Data!A2:F9,6,0)",
        "B4": "=IFERROR(B3,\"none\")", "B5": "=ISERROR(B3)", "B6": "=IF(ISERROR(B3),\"missing\",B3)",
        "B7": "=IF(AND(A1>10,OR(A4=7,A4=8)),\"big\",\"small\")", "B8": "=NOT(ISBLANK(Data!A12))",
        "B9": "=ISNUMBER(Data!C9)", "B10": "=ISTEXT(Data!C9)", "B11": "=Data!C9+1",
        "B12": "=CONCATENATE(UPPER(LEFT(Data!A2,1)),LOWER(MID(Data!A2,2,10)),\": \",A1)",
        "B13": "=LEN(Data!A9)&\"/\"&LEN(TRIM(Data!A9))", "B14": "=RIGHT(B1,3)&\"-\"&B2",
        "B15": "=MATCH(\"herb\",Data!G2:G4,0)", "B16": "=INDEX(Data!G2:H4,B15,2)*A1",
        "B17": "=Data!B11&\" \"&A4", "B18": "=A1/(A4-A4)", "B19": "=IFERROR(B18,-1)+B16",
        "C1": "=Calc!A1*2", "C2": "=SUM(Calc!A1:A3)", "C3": "=COUNTIF(Calc!A1:A5,\"<>x\")",
        "C4": "=Calc!B1", "C5": "=A2>A1", "C6": "=A1-A2&\"\"", "C7": "=-A4^2", "C8": "=2^3^2",
        "C9": "=50%*A4", "C10": "=\"3\"+Data!A11", "C11": "=SUM(Data!A2:A3)", "C12": "=Data!A2+1",
    }
    calc = {"A1": "=Summary!A4+1", "A2": "=Summary!B16", "A3": "=LEN(Summary!B1)", "A4": "x",
            "B1": "=IF(Summary!C5,UPPER(Summary!B12),LOWER(Summary!B12))"}
    return {"sheets": {"Data": data, "Summary": summ, "Calc": calc}}

def chain():
    s1, s2 = {}, {}
    s1["A1"] = 1
    for i in range(2, 101):
        s1["A%d" % i] = "=A%d+1" % (i - 1)
    s1["A40"] = "=A39/(A1-1)"            # #DIV/0! in the middle
    s1["B1"] = "=SUM(A1:A39)"; s1["B2"] = "=SUM(A1:A100)"; s1["B3"] = "=COUNT(A1:A100)"
    s1["B4"] = "=IFERROR(A100,\"caught\")"; s1["B5"] = "=ISERROR(A41)"; s1["B6"] = "=A100"
    s1["B7"] = "=COUNTA(A1:A100)"; s1["B8"] = "=MAX(A1:A39)"; s1["B9"] = "=IF(ISERROR(A60),A39*2,A60)"
    # a reversed chain: each formula reads a cell further down (dependency order, not sheet order)
    for i in range(1, 100):
        s1["C%d" % i] = "=C%d*1+1" % (i + 1)
    s1["C100"] = "=LEN(\"ab\")"
    s1["D1"] = "=C1"
    # a text chain across two sheets carrying #N/A from a failed lookup
    s2["A1"] = "=VLOOKUP(\"nope\",Sheet1!A1:A5,1,0)"
    for i in range(2, 101):
        s2["A%d" % i] = "=CONCATENATE(Sheet2!A%d,\"x\")" % (i - 1) if i % 2 else "=UPPER(A%d)" % (i - 1)
    s2["B1"] = "=ISERROR(A100)"; s2["B2"] = "=IFERROR(LEN(A100),0)"
    s2["C1"] = "start"
    for i in range(2, 101):
        s2["C%d" % i] = "=IF(LEN(C%d)>20,LEFT(C%d,5),C%d&\"+\")" % (i - 1, i - 1, i - 1)
    s2["D1"] = "=C100"; s2["D2"] = "=Sheet1!A100&\"\""; s2["D3"] = "=Sheet1!C1+Sheet1!A39"
    return {"sheets": {"Sheet1": s1, "Sheet2": s2}}

if __name__ == "__main__":
    json.dump({"mixed": mixed(), "chain": chain()}, open(sys.argv[1], "w"), indent=0)
