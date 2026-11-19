// Prototype for plan i10-formula-bar (not the implementation).
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const cellOf = (book, sheet, ref) => ((book && book.sheets && book.sheets[sheet]) || {})[ref];
export function barText(raw, sheet, ref) {
  const v = cellOf(raw, sheet, ref);
  if (v === null || v === undefined) return "";
  if (typeof v === "boolean") return v ? "TRUE" : "FALSE";
  if (typeof v === "number") return String(Number(v.toPrecision(15))).replace("e+", "E+").replace("e-", "E-");
  if (typeof v === "object" && v.error) return v.error;
  return String(v);
}
export function errorText(computed, sheet, ref) {
  const v = cellOf(computed, sheet, ref);
  return v && typeof v === "object" && typeof v.error === "string" ? v.error : "";
}
function parseText(text) {
  if (text === "") return undefined;
  if (text.startsWith("=")) return text;
  if (/^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/.test(text.trim())) return Number(text);
  if (/^true$/i.test(text)) return true;
  if (/^false$/i.test(text)) return false;
  return text;
}
export function commit(raw, sheet, ref, text) {
  const cells = { ...((raw.sheets || {})[sheet] || {}) };
  const v = parseText(text);
  if (v === undefined) delete cells[ref]; else cells[ref] = v;
  return { ...raw, sheets: { ...raw.sheets, [sheet]: cells } };
}
export function renderHTML({ raw, computed, sheet, ref }) {
  const err = errorText(computed, sheet, ref);
  return `<div class="formula-bar"><span class="ref">${esc(ref)}</span><span class="fx">fx</span>` +
    `<input class="text" value="${esc(barText(raw, sheet, ref))}">` +
    (err ? `<span class="error">${esc(err)}</span>` : "") + `</div>`;
}
export function mount(container, state, { onCommit = () => {} } = {}) {
  let s = state;
  const draw = () => {
    container.innerHTML = renderHTML(s);
    const input = container.querySelector("input");
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") { s = { ...s, raw: commit(s.raw, s.sheet, s.ref, input.value) }; onCommit(s.raw, s.ref); draw(); }
      if (e.key === "Escape") draw();
    });
  };
  draw();
  return { update(next) { s = { ...s, ...next }; draw(); }, get state() { return s; } };
}
