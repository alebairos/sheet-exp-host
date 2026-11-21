"""Where a_v1_dn_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Puts CASES (column A of "Cases", reading B1 = =0.1+0.2 and B2 = 0.3) and the budget into a new document,
recalculates and records each formula's result as Calc holds it: a number (its full double, repr) or a
boolean (TRUE/FALSE as shown), plus the text Calc shows. Run: python3 a_v1_dn_probe.py /tmp/x (soffice, uno).
"""
import json, subprocess, sys, tempfile, time
import uno

CASES = ["=0.1+0.2=0.3", "=0.1+0.2<>0.3", "=0.1+0.2>0.3", "=0.1+0.2>=0.3", "=0.1+0.2<0.3", "=0.1+0.2<=0.3",
         "=0.3=0.1+0.2", "=(0.1+0.2)-0.3", "=0.3-(0.1+0.2)", "=1.1*3-3.3", "=1.1*3=3.3", "=1-0.9-0.1",
         "=0.7+0.1-0.8", "=(0.1+0.2)+(-0.3)", "=-0.3+(0.1+0.2)", "=1=1+1E-15", "=1=1+1E-14", "=(1+1E-15)-1",
         "=(1+1E-14)-1", "=100.1-100", "=IF(0.1+0.2=0.3,\"same\",\"different\")", "=B1-B2", "=B1=B2", "=B1>B2",
         "=0.1*3=0.3", "=0.1*3-0.3", "=2.675*100-267.5", "=0.15+0.15+0.1-0.4", "=(0.1+0.7)*10-8",
         "=-(0.1+0.2)+0.3", "=0.1+0.2", "=1.1*3", "=3*1.1", "=1E-20-1E-20", "=5-4.999999999999999"]
BUDGET = {"B2": 1200, "B3": 850.5, "B4": 384.02, "B5": "=B2-B3-B4"}
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2305;urp;"])
ctx = uno.getComponentContext()
res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
for _ in range(60):
    try:
        c = res.resolve("uno:socket,host=127.0.0.1,port=2305;urp;StarOffice.ComponentContext"); break
    except Exception:
        time.sleep(0.5)
desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
doc.Sheets.getByIndex(0).setName("Cases")
doc.Sheets.insertNewByName("Budget", 1)
cs, bs = doc.Sheets.getByName("Cases"), doc.Sheets.getByName("Budget")
cs.getCellRangeByName("B1").setFormula("=0.1+0.2"); cs.getCellRangeByName("B2").setValue(0.3)
for i, f in enumerate(CASES): cs.getCellRangeByName(f"A{i + 1}").setFormula(f.replace(",", ";"))  # the API's separator
for ref, v in BUDGET.items():
    (bs.getCellRangeByName(ref).setFormula if isinstance(v, str) else bs.getCellRangeByName(ref).setValue)(v)
doc.calculateAll()
def result(cell):
    s = cell.getString()
    if s in ("TRUE", "FALSE"): return {"bool": s == "TRUE", "shown": s}
    if cell.getError(): return {"error": cell.getError(), "shown": s}
    if s and not s.lstrip("-").replace(".", "", 1).replace("E", "").replace("+", "").replace("-", "").isdigit(): return {"text": s}
    return {"number": repr(cell.getValue()), "shown": s}
out = {"cases": [{"formula": f, **result(cs.getCellRangeByName(f"A{i + 1}"))} for i, f in enumerate(CASES)],
       "budget": {"book": BUDGET, "B5": result(bs.getCellRangeByName("B5"))}}
print(json.dumps(out))
doc.close(True)
try: desk.terminate()
except Exception: pass
p.wait(timeout=30)
