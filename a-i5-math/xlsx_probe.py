import subprocess, time, uno, sys
from com.sun.star.beans import PropertyValue
def pv(n, v):
    p = PropertyValue(); p.Name = n; p.Value = v; return p
proc = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file:///tmp/lo-tools/profile",
                         '--accept=socket,host=localhost,port=2299;urp;'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    local = uno.getComponentContext()
    res = local.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", local)
    for _ in range(60):
        try:
            ctx = res.resolve("uno:socket,host=localhost,port=2299;urp;StarOffice.ComponentContext"); break
        except Exception: time.sleep(0.5)
    desktop = ctx.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
    doc = desktop.loadComponentFromURL("private:factory/scalc", "_blank", 0, (pv("Hidden", True),))
    sh = doc.Sheets.getByIndex(0)
    fs = ["=B1+1", "=A1+1", "=SQRT(-1)", "=MIN(\"x\")", "=1/0", "=NA()", "=\"a\"+1", "=FOO()", "=POWER(10;400)", "=MEDIAN(5;\"1\";3)"]
    for i, f in enumerate(fs):
        sh.getCellByPosition(i, 0).setFormula(f)
    doc.calculateAll()
    doc.storeToURL("file:///tmp/lo-tools/errs.xlsx", (pv("FilterName", "Calc MS Excel 2007 XML"),))
    doc.storeToURL("file:///tmp/lo-tools/errs.csv", (pv("FilterName", "Text - txt - csv (StarCalc)"),))
    doc.close(True)
finally:
    proc.terminate()
