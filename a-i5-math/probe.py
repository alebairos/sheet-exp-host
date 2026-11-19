"""probe.py CASES.json OUT.json: compute formulas in LibreOffice over a fixture (UNO)."""
import json, subprocess, sys, time
import uno
from com.sun.star.beans import PropertyValue

ERR = {532: "#DIV/0!", 519: "#VALUE!", 524: "#REF!", 525: "#NAME?", 32767: "#N/A", 503: "#NUM!", 522: "Err:522"}

def semi(f):
    out, q = [], False
    for ch in f:
        if ch == '"': q = not q
        out.append(';' if ch == ',' and not q else ch)
    return "".join(out)

def connect():
    local = uno.getComponentContext()
    res = local.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", local)
    for _ in range(60):
        try:
            return res.resolve("uno:socket,host=localhost,port=2299;urp;StarOffice.ComponentContext")
        except Exception:
            time.sleep(0.5)
    raise SystemExit("no soffice")

spec = json.load(open(sys.argv[1]))
proc = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file:///tmp/lo-tools/profile",
                         '--accept=socket,host=localhost,port=2299;urp;'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    ctx = connect()
    desktop = ctx.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
    p = PropertyValue(); p.Name = "Hidden"; p.Value = True
    doc = desktop.loadComponentFromURL("private:factory/scalc", "_blank", 0, (p,))
    sheets = doc.Sheets
    names = list(spec["sheets"])
    first = sheets.getByIndex(0); first.setName(names[0])
    for n in names[1:]:
        sheets.insertNewByName(n, sheets.Count)
    fmts = doc.NumberFormats
    from com.sun.star.lang import Locale
    boolfmt = fmts.getStandardFormat(1024, Locale())  # BOOLEAN = 1024
    for n, cells in spec["sheets"].items():
        sh = sheets.getByName(n)
        for a, v in cells.items():
            c = sh.getCellRangeByName(a)
            if isinstance(v, bool):
                c.setValue(1 if v else 0); c.NumberFormat = boolfmt
            elif isinstance(v, (int, float)):
                c.setValue(v)
            elif isinstance(v, dict):
                c.setFormula({"#DIV/0!": "=1/0", "#N/A": "=NA()", "#VALUE!": "=\"a\"+1", "#NUM!": "=SQRT(-1)", "#REF!": "=INDIRECT(\"ZZ\")"}[v["error"]])
            elif v.startswith("="):
                c.setFormula(v)
            else:
                c.setString(v)
    doc.calculateAll()
    sh = sheets.getByName(spec["formula_sheet"])
    out = []
    col = spec.get("col", "Z")
    for i, f in enumerate(spec["formulas"]):
        c = sh.getCellRangeByName("%s%d" % (col, i + 1))
        c.setFormula(semi(f))
    doc.calculateAll()
    from com.sun.star.table.CellContentType import FORMULA
    for i, f in enumerate(spec["formulas"]):
        c = sh.getCellRangeByName("%s%d" % (col, i + 1))
        e = c.getError()
        if e:
            r = {"error": ERR.get(e, "Err:%d" % e)}
        else:
            t = c.FormulaResultType2.value if hasattr(c.FormulaResultType2, "value") else c.FormulaResultType2
            if t == "TEXT" or t == 2:
                r = c.getString()
            else:
                r = c.getValue()
                if r == int(r) and abs(r) < 2**53: r = int(r)
        out.append([f, r, c.getFormula()])
    json.dump(out, open(sys.argv[2], "w"), indent=0)
    doc.close(True)
finally:
    proc.terminate()
