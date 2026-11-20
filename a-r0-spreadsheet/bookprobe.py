"""bookprobe.py BOOKS.json OUT.json: load each workbook into LibreOffice Calc (UNO), recalc, read every cell."""
import json, re, subprocess, sys, time
import uno
from com.sun.star.beans import PropertyValue
from com.sun.star.lang import Locale

ERR = {532: "#DIV/0!", 519: "#VALUE!", 524: "#REF!", 525: "#NAME?", 32767: "#N/A", 503: "#NUM!"}

def calcf(f):
    out, q = [], False
    for ch in f:
        if ch == '"': q = not q
        out.append(';' if ch == ',' and not q else ch)
    s = "".join(out)
    # Sheet!A1 -> $Sheet.A1 outside strings
    parts = s.split('"')
    for k in range(0, len(parts), 2):
        parts[k] = re.sub(r"(?<![A-Za-z0-9_$.])([A-Za-z_][A-Za-z0-9_]*)!", r"$\1.", parts[k])
    return '"'.join(parts)

def connect():
    local = uno.getComponentContext()
    res = local.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", local)
    for _ in range(60):
        try:
            return res.resolve("uno:socket,host=localhost,port=2299;urp;StarOffice.ComponentContext")
        except Exception:
            time.sleep(0.5)
    raise SystemExit("no soffice")

books = json.load(open(sys.argv[1]))
proc = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file:///tmp/lo-tools/profile",
                         '--accept=socket,host=localhost,port=2299;urp;'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
result = {}
try:
    ctx = connect()
    desktop = ctx.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
    for bname, book in books.items():
        p = PropertyValue(); p.Name = "Hidden"; p.Value = True
        doc = desktop.loadComponentFromURL("private:factory/scalc", "_blank", 0, (p,))
        sheets = doc.Sheets
        names = list(book["sheets"])
        sheets.getByIndex(0).setName(names[0])
        for n in names[1:]:
            sheets.insertNewByName(n, sheets.Count)
        boolfmt = doc.NumberFormats.getStandardFormat(1024, Locale())
        for n, cells in book["sheets"].items():
            sh = sheets.getByName(n)
            for a, v in cells.items():
                c = sh.getCellRangeByName(a)
                if isinstance(v, bool):
                    c.setValue(1 if v else 0); c.NumberFormat = boolfmt
                elif isinstance(v, (int, float)):
                    c.setValue(v)
                elif v.startswith("="):
                    c.setFormula(calcf(v))
                else:
                    c.setString(v)
        doc.calculateAll()
        # probe sheet for ISLOGICAL
        sheets.insertNewByName("Probe__", sheets.Count)
        pr = sheets.getByName("Probe__")
        cells_list = [(n, a) for n, cells in book["sheets"].items() for a, v in cells.items() if isinstance(v, str) and v.startswith("=")]
        for i, (n, a) in enumerate(cells_list):
            pr.getCellRangeByName("A%d" % (i + 1)).setFormula("=ISLOGICAL($%s.%s)" % (n, a))
        doc.calculateAll()
        out = {n: {} for n in names}
        for n, cells in book["sheets"].items():
            for a, v in cells.items():
                out[n][a] = v
        for i, (n, a) in enumerate(cells_list):
            c = sheets.getByName(n).getCellRangeByName(a)
            e = c.getError()
            if e:
                r = {"error": ERR.get(e, "Err:%d" % e)}
            else:
                t = c.FormulaResultType2
                if t == 2:
                    r = c.getString()
                else:
                    r = c.getValue()
                    if pr.getCellRangeByName("A%d" % (i + 1)).getValue() == 1:
                        r = bool(r)
                    elif r == int(r) and abs(r) < 2**53:
                        r = int(r)
            out[n][a] = r
        result[bname] = {"sheets": out}
        doc.close(True)
finally:
    proc.terminate()
json.dump(result, open(sys.argv[2], "w"), indent=1, sort_keys=False)
