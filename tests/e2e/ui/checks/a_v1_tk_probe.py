"""Where a_v1_tk_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Calc gets the checks' workbook (A1 1, B1 =A1*2, C1 =A2*10, and A2 5 as the user types it) and each formula the checks type;
it records what Calc shows. Run: python3 a_v1_tk_probe.py cases.json > a_v1_tk_calc.json (needs soffice, python3-uno).
cases.json: ["=1", "=A1*2", "=A2*10", "=A1+2*B1", then "=SUM(A1:A2)+B1" followed by 0 to 40 times "+0"].
"""
import json, subprocess, sys, tempfile, time
import uno
DATA = {"Sheet1": {"A1": 1, "B1": "=A1*2", "C1": "=A2*10", "A2": 5}}
CASES = json.load(open(sys.argv[1]))
def api(f):
    parts = f.split('"')
    return '"'.join(p.replace(",", ";") if i % 2 == 0 else p for i, p in enumerate(parts))
d = tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2313;urp;"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    ctx = uno.getComponentContext()
    res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
    for _ in range(60):
        try:
            c = res.resolve("uno:socket,host=127.0.0.1,port=2313;urp;StarOffice.ComponentContext"); break
        except Exception:
            time.sleep(0.5)
    desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
    doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    sh = doc.Sheets.getByIndex(0); sh.setName("Sheet1")
    for ref, v in DATA["Sheet1"].items(): (sh.getCellRangeByName(ref).setFormula(v) if isinstance(v, str) else sh.getCellRangeByName(ref).setValue(v))
    for i, f in enumerate(CASES): sh.getCellByPosition(6, i).setFormula(api(f))
    doc.calculateAll()
    out = []
    for i, f in enumerate(CASES):
        x = sh.getCellByPosition(6, i)
        r = {"error": x.getString()} if x.getError() else ({"text": x.getString()} if x.FormulaResultType2 == 2 else {"number": x.getValue()})
        if "number" in r and x.getString() in ("TRUE", "FALSE"): r["shown"] = x.getString()
        out.append({"formula": f, **r})
    print(json.dumps({"data": DATA, "cases": out}, ensure_ascii=False))
    doc.close(True)
finally:
    if p.poll() is None: p.kill()
