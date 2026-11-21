"""Where a_v1_ct_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Opens a_v1_ct_bank.csv with Calc's default CSV import (comma, double quote, UTF-8), adds the checks' formulas
in column G (FORMULAS), recalculates and prints what Calc shows for them and for the imported cells, then
sets C3 to 5 as the checks' edit does and prints column G again.
Run: python3 a_v1_ct_probe.py /tmp/somewhere (needs soffice and python3-uno).
"""
import json, os, subprocess, sys, tempfile, time
import uno
from com.sun.star.beans import PropertyValue

FORMULAS = {"G2": "=E2+1", "G3": "=C2+C3", "G4": "=SUM(C2:C6)", "G5": "=E3*2", "G6": "=C5*10"}
HERE = os.path.dirname(os.path.abspath(__file__))
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2304;urp;"])
ctx = uno.getComponentContext()
res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
for _ in range(60):
    try:
        c = res.resolve("uno:socket,host=127.0.0.1,port=2304;urp;StarOffice.ComponentContext"); break
    except Exception:
        time.sleep(0.5)
desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
def pv(n, v):
    x = PropertyValue(); x.Name = n; x.Value = v; return x
url = uno.systemPathToFileUrl(os.path.join(HERE, "a_v1_ct_bank.csv"))
doc = desk.loadComponentFromURL(url, "_blank", 0, (pv("Hidden", True), pv("FilterName", "Text - txt - csv (StarCalc)"),
                                                   pv("FilterOptions", "44,34,76,1")))
cell = doc.Sheets.getByIndex(0).getCellRangeByName
for ref, f in FORMULAS.items(): cell(ref).setFormula(f)
doc.calculateAll()
shown = {f"{c}{r}": cell(f"{c}{r}").getString() for r in range(2, 7) for c in "CE"}
out = {"formulas": FORMULAS, "shown": {ref: cell(ref).getString() for ref in FORMULAS},
       "values": {ref: cell(ref).getValue() for ref in FORMULAS}, "imported": shown}
cell("C3").setValue(5); doc.calculateAll()  # then the checks' edit: C3 typed as 5
out["after_C3_5"] = {ref: cell(ref).getString() for ref in FORMULAS}
print(json.dumps(out))
doc.close(True)
try: desk.terminate()
except Exception: pass
p.wait(timeout=30)
