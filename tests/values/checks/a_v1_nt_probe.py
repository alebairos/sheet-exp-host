"""Where a_v1_nt_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

For each number expression of NUMBERS (the review's cases, the boundaries where Calc switches between decimal
and E notation, halves at the 15th digit, and held-out values), Calc computes ="x"&(n), =LEN(n),
=CONCATENATE(n) and =LEFT(n,40); the probe records the text or number Calc gives for each.
Run: python3 a_v1_nt_probe.py /tmp/x (needs soffice and python3-uno).
"""
import json, subprocess, sys, tempfile, time
import uno

NUMBERS = ["1E-7", "1E15", "1E21", "123456789012345678", "1E-20", "0.1", "1/3", "2/3", "1E14", "999999999999999",
           "1234567890123456", "0.000123456", "1E-5", "0.00001234", "1.5E-8", "123456.789", "-1234567.891", "1E100",
           "1E-100", "-1E-7", "12345678901234.5", "0.5", "1000", "1E20", "3.14159265358979", "0.1+0.2", "2^53",
           "1E16", "1E17", "1E19", "1E-4", "1E-10", "1E-15", "1E-18", "1E-19", "1.23456789E-12", "0.1234567890123455",
           "123456789012345.5", "9.99999999999999E-10", "-0", "7", "-2.5", "1E300", "4.5E-15", "98765432109876543210",
           # the edges the first run showed: decimal down to E-14?, exact integers below 2^53, the 3-digit exponent
           "1E-14", "1.5E-14", "9.99999999999999E-15", "2^53-1", "2^53+2", "5E15", "1E15+0.5", "-9007199254740991",
           "1E15*9", "0.000000000000012345678901234"]
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2310;urp;"])
try:
    ctx = uno.getComponentContext()
    res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
    for _ in range(60):
        try:
            c = res.resolve("uno:socket,host=127.0.0.1,port=2310;urp;StarOffice.ComponentContext"); break
        except Exception:
            time.sleep(0.5)
    desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
    doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    sh = doc.Sheets.getByIndex(0)
    FORMS = {"amp": '="x"&({})', "len": "=LEN({})", "concat": "=CONCATENATE({})", "left": "=LEFT({};40)"}
    for i, n in enumerate(NUMBERS):
        for j, f in enumerate(FORMS.values()): sh.getCellByPosition(j, i).setFormula(f.format(n))
    doc.calculateAll()
    out = []
    for i, n in enumerate(NUMBERS):
        row = {"n": n}
        for j, k in enumerate(FORMS):
            x = sh.getCellByPosition(j, i)
            row[k] = x.getValue() if k == "len" else x.getString()
        out.append(row)
    print(json.dumps({"cases": out}))
    doc.close(True)
finally:
    if p.poll() is None: p.kill()
