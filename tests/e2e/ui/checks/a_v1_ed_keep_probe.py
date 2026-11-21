"""Where a_v1_ed_keep.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Each entry is typed into a cell of a new Calc document (setFormula, as the input line takes it); Calc's stored
value and its input-line text (getFormula) are written to a_v1_ed_keep.json. Run: python3 a_v1_ed_keep_probe.py
"""
import json, os, subprocess, tempfile, time, uno
d = tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/p",
                      "--accept=socket,host=127.0.0.1,port=2315;urp;"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    ctx = uno.getComponentContext()
    res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
    for _ in range(60):
        try: c = res.resolve("uno:socket,host=127.0.0.1,port=2315;urp;StarOffice.ComponentContext"); break
        except Exception: time.sleep(0.5)
    doc = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c).loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    sh = doc.Sheets.getByIndex(0); out = {}
    for i, t in enumerate(["123456789012", "3.141592653589793", "'123", "'TRUE"]):
        x = sh.getCellByPosition(0, i); x.setFormula(t)
        out[t] = {"number": x.getValue()} if x.getType().value == "VALUE" else {"text": x.getString()}
        out[t]["input_line"] = x.getFormula()
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "a_v1_ed_keep.json"), "w") as f:
        f.write(json.dumps({"source": "LibreOffice Calc 26.8.1.1 headless, by a_v1_ed_keep_probe.py", "typed": out}) + "\n")
    doc.close(True)
finally:
    p.kill()
