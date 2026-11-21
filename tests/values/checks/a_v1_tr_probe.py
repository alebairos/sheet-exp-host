"""Where a_v1_tr_b1.json and a_v1_tr_b2.json get their answers: LibreOffice Calc itself, headless, over UNO.

Not run by the checks. It lays the cases out exactly as a_v1_tr_common.py does for ./engine (texts in cells,
formulas next to them) in a new Calc document (default options: case-sensitive, en-US), recalculates, and
writes Calc's results back into the two files. Run: python3 a_v1_tr_probe.py [spec.json] (needs soffice, python3-uno).
"""
import json, os, subprocess, sys, tempfile, time
import uno
from a_v1_tr_common import HERE, layout

def _js(x):
    s = json.dumps(x, ensure_ascii=False)
    for ch in "\u00a0\u00ad\u0301": s = s.replace(ch, "\\u%04x" % ord(ch))  # invisible characters, written out
    return s

def dump(d, path):
    """One key per block, a few cases per line: short lines a reader can scan."""
    lines = ["{"]
    keys = list(d)
    for k in keys:
        v = d[k]
        if isinstance(v, str): lines.append("  %s: %s," % (json.dumps(k), _js(v)))
        else:
            lines.append("  %s: [" % json.dumps(k))
            for i in range(0, len(v), 3):
                lines.append("    " + ", ".join(_js(x) for x in v[i:i + 3]) + ("," if i + 3 < len(v) else ""))
            lines.append("  ],")
    lines[-1] = lines[-1].rstrip(","); lines.append("}")
    open(path, "w").write("\n".join(lines) + "\n")

def calc(book):
    d = tempfile.mkdtemp()
    p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/p",
                          "--accept=socket,host=127.0.0.1,port=2314;urp;"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        ctx = uno.getComponentContext()
        res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
        for _ in range(60):
            try: c = res.resolve("uno:socket,host=127.0.0.1,port=2314;urp;StarOffice.ComponentContext"); break
            except Exception: time.sleep(0.5)
        doc = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c).loadComponentFromURL(
            "private:factory/scalc", "_blank", 0, ())
        names = list(book["sheets"])
        doc.Sheets.getByIndex(0).setName(names[0])
        for i, n in enumerate(names[1:]): doc.Sheets.insertNewByName(n, i + 1)
        for n, cells in book["sheets"].items():
            sh = doc.Sheets.getByName(n)
            for ref, v in cells.items():
                cell = sh.getCellRangeByName(ref)
                if v.startswith("="):
                    parts = v.split('"')  # Calc's API separates arguments with ';'
                    cell.setFormula('"'.join(q.replace(",", ";") if i % 2 == 0 else q for i, q in enumerate(parts)))
                else: cell.setString(v)
        doc.calculateAll()
        out = {}
        for n, cells in book["sheets"].items():
            sh = doc.Sheets.getByName(n)
            for ref, v in cells.items():
                if not v.startswith("="): continue
                x = sh.getCellRangeByName(ref)
                if x.getError(): out[n + "!" + ref] = {"error": x.getString()}
                elif x.FormulaResultType2 == 2: out[n + "!" + ref] = x.getString()
                elif x.getString() in ("TRUE", "FALSE") and ("=" in v[1:] or "<" in v or ">" in v or v.startswith(("=NOT", "=IF"))):
                    out[n + "!" + ref] = x.getString() == "TRUE"
                else: out[n + "!" + ref] = x.getValue()
        doc.close(True)
        return out
    finally:
        if p.poll() is None: p.kill()

if __name__ == "__main__":
    spec = json.load(open(sys.argv[1])) if len(sys.argv) > 1 else None
    b1, b2 = (json.load(open(os.path.join(HERE, f))) for f in ("a_v1_tr_b1.json", "a_v1_tr_b2.json"))
    if spec:  # first run: the inputs
        b1 = {"order": "".join(spec["order"]), "pairs": [p + [None] for p in spec["pairs"]],
              "held_out": [p + [None] for p in spec["pairs_held_out"]],
              "formulas": [[f, None] for f in spec["literals"] if not f.startswith(("=COUNT", "=ROUND", "=ABS", "=MOD", "=LEFT", "=MID", "=IF", "=NOT", "=SQRT", "=POWER", "=INT", "=SUM")) and "+0" not in f]}
        b2 = {"texts": [[t, None] for t in spec["texts"]], "held_out": [[t, None] for t in spec["texts_held_out"]],
              "formulas": [[f, None] for f in spec["literals"] if "+0" in f or f.startswith(("=COUNT", "=ROUND", "=ABS", "=MOD", "=LEFT", "=MID", "=IF", "=NOT", "=SQRT", "=POWER", "=INT", "=SUM"))]}
    for data, name in ((b1, "a_v1_tr_b1.json"), (b2, "a_v1_tr_b2.json")):
        book, fill = layout(data)
        fill(calc(book))
        dump(data, os.path.join(HERE, name))
