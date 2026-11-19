// Prototype for plan i9-grid (not the implementation).
export function colName(i) { let s = ""; i += 1; while (i > 0) { const r = (i - 1) % 26; s = String.fromCharCode(65 + r) + s; i = Math.floor((i - 1) / 26); } return s; }
export function display(v) {
  if (v === null || v === undefined) return "";
  if (typeof v === "boolean") return v ? "TRUE" : "FALSE";
  if (typeof v === "number") { const s = Number(v.toPrecision(15)); return String(s).replace("e+", "E+").replace("e-", "E-"); }
  if (typeof v === "object" && v.error) return v.error;
  return String(v);
}
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
export function createState(book, sheet) { return { book, sheet, selected: "A1" }; }
export function select(state, ref) { return { ...state, selected: ref }; }
export function parseInput(text) {
  if (text === "") return undefined;
  if (/^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/.test(text.trim())) return Number(text);
  if (/^true$/i.test(text)) return true;
  if (/^false$/i.test(text)) return false;
  return text;
}
export function edit(state, ref, text) {
  const cells = { ...(state.book.sheets[state.sheet] || {}) };
  const v = parseInput(text);
  if (v === undefined) delete cells[ref]; else cells[ref] = v;
  return { ...state, book: { ...state.book, sheets: { ...state.book.sheets, [state.sheet]: cells } } };
}
export function renderHTML(state, { rows, cols }) {
  const cells = state.book.sheets[state.sheet] || {};
  let h = '<table class="grid"><thead><tr><th></th>';
  for (let c = 0; c < cols; c++) h += `<th>${colName(c)}</th>`;
  h += "</tr></thead><tbody>";
  for (let r = 1; r <= rows; r++) {
    h += `<tr><th>${r}</th>`;
    for (let c = 0; c < cols; c++) {
      const ref = colName(c) + r, v = cells[ref];
      const cls = [ref === state.selected ? "selected" : "", typeof v === "number" ? "num" : "", v && v.error ? "err" : ""].filter(Boolean).join(" ");
      h += `<td data-ref="${ref}"${cls ? ` class="${cls}"` : ""}>${esc(display(v))}</td>`;
    }
    h += "</tr>";
  }
  return h + "</tbody></table>";
}
export function mount(container, state, { rows = 20, cols = 8, onChange = () => {} } = {}) {
  let s = state;
  const draw = () => { container.innerHTML = renderHTML(s, { rows, cols }); };
  const startEdit = (td, initial) => {
    const input = document.createElement("input");
    const cur = (s.book.sheets[s.sheet] || {})[td.dataset.ref];
    input.value = initial ?? (cur === undefined ? "" : (typeof cur === "object" ? "" : display(cur)));
    td.textContent = ""; td.appendChild(input); input.focus();
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") { s = edit(s, td.dataset.ref, input.value); onChange(s); draw(); }
      if (e.key === "Escape") draw();
      e.stopPropagation();
    });
  };
  container.addEventListener("click", (e) => { const td = e.target.closest("td[data-ref]"); if (td) { s = select(s, td.dataset.ref); draw(); } });
  container.addEventListener("dblclick", (e) => { const td = e.target.closest("td[data-ref]"); if (td) startEdit(td); });
  container.tabIndex = 0;
  container.addEventListener("keydown", (e) => {
    const td = container.querySelector(`td[data-ref="${s.selected}"]`);
    if (td && (e.key === "Enter" || e.key === "F2")) { startEdit(td); e.preventDefault(); }
    else if (td && e.key.length === 1) { startEdit(td, e.key); e.preventDefault(); }
  });
  draw();
  return { get state() { return s; } };
}
