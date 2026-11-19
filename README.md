Prototype for plan a-i11-open-save (second replan: grid edits go through controller.edit(ref, text); the page sends only the typed cell, never the computed book back).
- io/index.html: the page (Open, Save JSON, Save CSV, message, grid), as it will sit in web/io.
- io/serve.py: run `python3 io/serve.py 8000` from a clone of exp-a with these files in web/ to open http://127.0.0.1:8000/io/index.html; POST /compute answers with ./engine's computed workbook.
- grid/grid.js: the landed grid from a-i9-grid (web/grid/grid.js), which the page mounts.
- a-i11-open-save/prototype.html and sample files: the open/save behavior alone, as in the first plan.
