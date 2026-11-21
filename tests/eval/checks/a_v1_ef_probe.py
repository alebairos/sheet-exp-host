"""Where a_v1_ef_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Enters the checks' long formulas (FORMULAS: n-term sums =1+1+...+1 and =A1+A1+..., a long chain of
differences) next to ordinary cells and prints what Calc gives for each: its value or its error code
(Err:NNN as Calc shows it), then sets A1 to 7 and reads A2 and C1 again. Run: python3 a_v1_ef_probe.py /tmp/x (needs soffice and python3-uno).
"""
import json, subprocess, sys, tempfile, time
import uno

FORMULAS = {"B1": "=" + "+".join(["1"] * 1000), "B2": "=" + "+".join(["1"] * 5000),
            "B3": "=" + "+".join(["A1"] * 1000), "B4": "=" + "-".join(["A1"] * 2000), "B5": "=B1+B2",
            "B6": "=" + "+".join(["1"] * 4096), "B7": "=" + "+".join(["1"] * 4097), "B8": "=" + "+".join(["1"] * 4095)}
OTHER = {"A1": 2, "A2": "=A1*3", "C1": "=SUM(A1:A2)"}
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2306;urp;"])
ctx = uno.getComponentContext()
res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
for _ in range(60):
    try:
        c = res.resolve("uno:socket,host=127.0.0.1,port=2306;urp;StarOffice.ComponentContext"); break
    except Exception:
        time.sleep(0.5)
desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
cell = doc.Sheets.getByIndex(0).getCellRangeByName
for ref, v in {**OTHER, **FORMULAS}.items():
    (cell(ref).setFormula if isinstance(v, str) else cell(ref).setValue)(v)
doc.calculateAll()
def result(x):
    return {"error": x.getString(), "code": x.getError()} if x.getError() else {"value": x.getValue(), "shown": x.getString()}
out = {"results": {r: result(cell(r)) for r in [*OTHER, *FORMULAS]}}
cell("A1").setValue(7); doc.calculateAll()  # the browser check's edit
out["after_A1_7"] = {r: result(cell(r)) for r in ("A2", "C1")}
print(json.dumps(out))
doc.close(True)
try: desk.terminate()
except Exception: pass
p.wait(timeout=30)
