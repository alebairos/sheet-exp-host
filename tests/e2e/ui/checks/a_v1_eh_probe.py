"""Where a_v1_eh_calc.json comes from: LibreOffice Calc itself (not run by the checks).

errors: each formula of BOOK entered in Calc headless over UNO, with the error Calc shows (getString) and its
code (getError). long: Calc's own one-line explanation of each error (the STR_LONG_ERR_* texts compiled into
libsclo.so, the status-bar text Calc shows for a selected error cell), read from the installed binary.
Run: python3 a_v1_eh_probe.py /tmp/x (needs soffice, python3-uno and strings).
"""
import json, subprocess, sys, tempfile, time
import uno

BOOK = {"A1": "=1/0", "A2": "=\"a\"+1", "A3": "=INDEX(A20:A21,5)", "A4": "=FOO(1)", "A5": "=MATCH(99,A20:A21,0)",
        "A6": "=1E308*10", "A7": "=SQRT(-1)", "A8": "=MIN(\"x\")", "A9": "=IF()", "A10": "=A11", "A11": "=A10",
        "A20": 1, "A21": 2}
NAMES = {"#DIV/0!": "DIV_ZERO", "#VALUE!": "NO_VALUE", "#REF!": "NO_REF", "#NAME?": "NO_NAME", "#N/A": "NV",
         "#NUM!": "ILL_FPO", "Err:502": "ILL_ARG", "Err:504": "ILL_PAR", "Err:511": "VAR_EXP", "Err:522": "CIRC_REF"}
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
lines = subprocess.run(["strings", "/usr/lib/libreoffice/program/libsclo.so"], capture_output=True, text=True).stdout.splitlines()
long = {e: lines[lines.index("STR_LONG_ERR_" + n) + 1] for e, n in NAMES.items() if n != "CIRC_REF"}
long["Err:522"] = next(l for l in lines if l == "Error: Circular reference")
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2308;urp;"])
try:
    ctx = uno.getComponentContext()
    res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
    for _ in range(60):
        try:
            c = res.resolve("uno:socket,host=127.0.0.1,port=2308;urp;StarOffice.ComponentContext"); break
        except Exception:
            time.sleep(0.5)
    desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
    doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    cell = doc.Sheets.getByIndex(0).getCellRangeByName
    for ref, v in BOOK.items():
        if isinstance(v, str): cell(ref).setFormula(v.replace(",", ";"))
        else: cell(ref).setValue(float(v))
    doc.calculateAll()
    errors = {ref: {"shown": cell(ref).getString(), "code": cell(ref).getError()} for ref, v in BOOK.items() if isinstance(v, str)}
    print(json.dumps({"book": BOOK, "errors": errors, "long": long}))
    doc.close(True)
    try: desk.terminate()
    except Exception: pass
finally:
    if p.poll() is None:
        p.kill()
