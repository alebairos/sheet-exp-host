"""Where a_v1_pf_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Each formula of CASES (as a user types it, Excel-style sheet references and commas) is entered on Sheet1 next to
data on Sheet1, 'My Sheet' and S2; the probe translates only what Calc's API needs (Sheet!A1 to $Sheet.A1, ',' to
';' outside strings) and records Calc's result: a number, a text, or the error Calc shows (Err:5xx, #VALUE!, ...).
Run: python3 a_v1_pf_probe.py /tmp/x (needs soffice and python3-uno).
"""
import json, re, subprocess, sys, tempfile, time
import uno

DATA = {"Sheet1": {"A1": 1, "A2": 2}, "My Sheet": {"A1": 5, "A2": 6}, "S2": {"A1": 3, "A2": 4}}
CASES = ["= SUM( A1 : A2 )", "=SUM( 'My Sheet'!A1 : A2 )", "=SUM(S2!A1:S2!A2)", "=SUM(1,2", "=(1+2", "=SUM(A1:A2",
         "=1 + 2", "= A1 * A2", "=SUM(A1 :A2)", "=( 1 + 2 ) * 3", "=SUM('My Sheet'!A1:'My Sheet'!A2)", "=S2!A1 + S2!A2",
         "=SUM(1,,2)", "=IF(A1=1,\"one\",\"other\"", "=(1+", "=1+*2", "=1E400", "=1+", "=*2", "=1 2", "=SUM(", "=)",
         "=(1+2))", "=SUM(1,2))", "=A1 A2", "=1++2", "=1E-400", "=MAX()", "=MEDIAN()", "=SUM()", "=MIN()", "=AVERAGE()",
         "=COUNT()", "=CONCATENATE()", "=AND()", "=IF()", "=LEN()", "=ROUND()", "=ABS()", "=VLOOKUP()", "=COUNTA()",
         "=OR()", "=NOT()", "=PRODUCT()", "=UPPER()",
         # replan: held-out malformed forms (the gate review's 27 and more), to pin the rule, not a list
         "=SUM(1,", "=MAX(1,)", "=((1", "=(1*", "=2*(3+", "=1+(", "=SUM(1+", "=SUM(A1:", "=IF(1,2,", "=ABS(-", "=()",
         "=1-", "=A1+", "=-", "=1^", "=A1:", "=1&", "=(1+2)+", "=1*/2", "=/2", "=1 (2)", "=2 3+4", "=SUM(1 2)",
         "=1)(2", "=1+2)", "=(1", "=SUM(1,2,", "=((1+2)", "=1+2*", "=(2)3", "=1<>", "=A1 1", "=SUM())", "=+", "=1+-",
         "=MIN(1,", "=(((", "=1/(2-", "=&1", "=SUM(A1:A2"]
def api(f):
    f = re.sub(r"'([^']+)'!", lambda m: "$'%s'." % m.group(1), f)
    f = re.sub(r"\b([A-Za-z_][A-Za-z0-9_]*)!", r"$\1.", f)
    parts = f.split('"')
    return '"'.join(p.replace(",", ";") if i % 2 == 0 else p for i, p in enumerate(parts))
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2311;urp;"])
try:
    ctx = uno.getComponentContext()
    res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
    for _ in range(60):
        try:
            c = res.resolve("uno:socket,host=127.0.0.1,port=2311;urp;StarOffice.ComponentContext"); break
        except Exception:
            time.sleep(0.5)
    desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
    doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    doc.Sheets.getByIndex(0).setName("Sheet1")
    for i, name in enumerate(["My Sheet", "S2"]): doc.Sheets.insertNewByName(name, i + 1)
    for name, cells in DATA.items():
        for ref, v in cells.items(): doc.Sheets.getByName(name).getCellRangeByName(ref).setValue(float(v))
    sh = doc.Sheets.getByName("Sheet1")
    for i, f in enumerate(CASES): sh.getCellByPosition(2, i).setFormula(api(f))
    doc.calculateAll()
    out = []
    for i, f in enumerate(CASES):
        x = sh.getCellByPosition(2, i)
        r = {"error": x.getString()} if x.getError() else ({"text": x.getString()} if x.FormulaResultType2 == 2 else {"number": x.getValue()})
        out.append({"formula": f, **r})
    print(json.dumps({"data": DATA, "cases": out}))
    doc.close(True)
finally:
    if p.poll() is None: p.kill()
