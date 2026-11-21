"""Where a_v1_ed_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

entry: each of TYPED entered into a cell as a user types it (XCell.setFormula on text = Calc's input rule),
and the same fields read by Calc's default CSV import: type and value. shown: each number of NUMBERS in a
General-format cell of the standard column width (Calc's default, 2.258 cm), as Calc draws it: the sheet is
exported to PDF and read back with pdftotext -layout. Run: python3 a_v1_ed_probe.py /tmp/x (soffice, uno, poppler).
"""
import json, os, subprocess, sys, tempfile, time
import uno
from com.sun.star.beans import PropertyValue

TYPED = ["50%", "1e3", "-2.5", "'abc"]
NUMBERS = [1000000000000001, 1234567890123456, 1e-07, 1 / 3, 2 / 3, 1e20, -1234567.891, 123456.789, 0.000123456,
           99999999999, 12345678901, 123456789012, 0.30000000000000004, 123456789, -0.000001234, 1e-20, 3.141592653589793,
           1e15, 1e100, -1e-100, 0.5, 1000, -2.5, 1234.5678, 98765.4321, 0.1, 1e-05, 0.00001234567, 1e10, 123456789.123,
           -98765432.1, 1.5e-08, 7, -0.25]
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2307;urp;"])
ctx = uno.getComponentContext()
res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
for _ in range(60):
    try:
        c = res.resolve("uno:socket,host=127.0.0.1,port=2307;urp;StarOffice.ComponentContext"); break
    except Exception:
        time.sleep(0.5)
desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
def pv(n, v):
    x = PropertyValue(); x.Name = n; x.Value = v; return x
def kind(x):
    return {"text": x.getString()} if x.getType().value == "TEXT" else {"number": x.getValue()}
doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
sh = doc.Sheets.getByIndex(0)
for i, t in enumerate(TYPED): sh.getCellByPosition(0, i).setFormula(t)
out = {"entry": {"typed": {t: kind(sh.getCellByPosition(0, i)) for i, t in enumerate(TYPED)}}}
for i, x in enumerate(NUMBERS):
    sh.getCellByPosition(1, i).setValue(float(x)); sh.getCellByPosition(2, i).setString("#%d#" % i)
doc.calculateAll()
doc.storeToURL(uno.systemPathToFileUrl(os.path.join(d, "shown.pdf")), (pv("FilterName", "calc_pdf_Export"),))
doc.close(True)
text = subprocess.run(["pdftotext", "-layout", os.path.join(d, "shown.pdf"), "-"], capture_output=True, text=True).stdout
shown = {}
for line in text.splitlines():
    parts = line.split()
    if len(parts) >= 2 and parts[-1].startswith("#") and parts[-1].endswith("#"): shown[int(parts[-1][1:-1])] = parts[-2]
out["shown"] = [[repr(x), shown.get(i)] for i, x in enumerate(NUMBERS)]
csv = os.path.join(d, "entry.csv")
open(csv, "w").write(",".join(TYPED) + "\n")
doc = desk.loadComponentFromURL(uno.systemPathToFileUrl(csv), "_blank", 0, (pv("Hidden", True), pv("FilterName", "Text - txt - csv (StarCalc)"), pv("FilterOptions", "44,34,76,1")))
sh = doc.Sheets.getByIndex(0)
out["entry"]["csv"] = {t: kind(sh.getCellByPosition(i, 0)) for i, t in enumerate(TYPED)}
print(json.dumps(out))
doc.close(True)
try: desk.terminate()
except Exception: pass
p.wait(timeout=30)
