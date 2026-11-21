"""Where a_v1_st_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

BOOK (Prices and Order, each reading the other) is entered into Calc; the probe records what Calc shows for every
formula, then sets Order!B1 to 5 (the checks' edit), recalculates and records them again.
Run: python3 a_v1_st_probe.py /tmp/x (needs soffice and python3-uno).
"""
import json, subprocess, sys, tempfile, time
import uno

BOOK = {"Prices": {"A1": "Pen", "B1": 10.5, "A2": "Pad", "B2": 3.25, "C1": "Ordered", "D1": "=SUM(Order!B1:B2)"},
        "Order": {"A1": "Pens", "B1": 2, "A2": "Pads", "B2": 4, "A3": "Total", "B3": "=B1*Prices!B1+B2*Prices!B2"}}
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2312;urp;"])
try:
    ctx = uno.getComponentContext()
    res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
    for _ in range(60):
        try:
            c = res.resolve("uno:socket,host=127.0.0.1,port=2312;urp;StarOffice.ComponentContext"); break
        except Exception:
            time.sleep(0.5)
    desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
    doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    doc.Sheets.getByIndex(0).setName("Prices"); doc.Sheets.insertNewByName("Order", 1)
    cell = lambda s, r: doc.Sheets.getByName(s).getCellRangeByName(r)
    for s, cells in BOOK.items():
        for r, v in cells.items():
            if isinstance(v, str) and v.startswith("="): cell(s, r).setFormula(v.replace("Order!", "$Order.").replace("Prices!", "$Prices."))
            elif isinstance(v, str): cell(s, r).setString(v)
            else: cell(s, r).setValue(float(v))
    doc.calculateAll()
    shown = lambda: {s: {r: cell(s, r).getString() for r, v in cells.items() if isinstance(v, str) and v.startswith("=")} for s, cells in BOOK.items()}
    out = {"book": BOOK, "before": shown()}
    cell("Order", "B1").setValue(5.0); doc.calculateAll()
    out["after_Order_B1_5"] = shown()
    print(json.dumps(out))
    doc.close(True)
finally:
    if p.poll() is None: p.kill()
