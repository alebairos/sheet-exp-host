"""Where a_v1_ce_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Puts the checks' workbook (BOOK below, as typed) into a new Calc sheet, reads what Calc shows for each cell,
then replaces A3's formula by each edit the checks type and reads A3 again.
Run: python3 a_v1_ce_probe.py /tmp/somewhere (needs soffice and python3-uno).
"""
import json, subprocess, sys, tempfile, time
import uno

BOOK = {"A1": 10, "A2": 20, "A3": "=A1+A2", "C1": "=1/0", "D1": "=0.1+0.2", "D2": "007", "D3": "=ISTEXT(D2)",
        "E1": 12.5, "E2": "hello", "F1": "=D1*10"}
EDITS = ["=A1+A2+1", "=A1+A2*2"]
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2302;urp;"])
ctx = uno.getComponentContext()
res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
for _ in range(60):
    try:
        c = res.resolve("uno:socket,host=127.0.0.1,port=2302;urp;StarOffice.ComponentContext"); break
    except Exception:
        time.sleep(0.5)
desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
cell = doc.Sheets.getByIndex(0).getCellRangeByName
for ref, v in BOOK.items():
    if isinstance(v, str) and v.startswith("="): cell(ref).setFormula(v)
    elif isinstance(v, str): cell(ref).setString(v)  # text as typed, '007 stays the text 007
    else: cell(ref).setValue(v)
doc.calculateAll()
out = {"book": BOOK, "shown": {ref: cell(ref).getString() for ref in BOOK}, "edits": {}}
for f in EDITS:
    cell("A3").setFormula(f); doc.calculateAll(); out["edits"][f] = cell("A3").getString()
print(json.dumps(out))
doc.close(True)
try: desk.terminate()
except Exception: pass
p.wait(timeout=30)
