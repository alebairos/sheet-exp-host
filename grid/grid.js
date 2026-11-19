// The spreadsheet grid (intent a-i9-grid): a plain ES module, no build step.
//
// Everything but mount() is a pure function over the workbook JSON of SPEC.md
// ({sheets: {Sheet1: {A1: 1, ...}}}), so it runs and is tested under Node.js.
// mount() is the only code that touches the DOM.

/** Column index (0-based) to its letters: 0 -> A, 25 -> Z, 26 -> AA. */
export function colName(i) {
  let s = "";
  for (let n = i + 1; n > 0; n = Math.floor((n - 1) / 26)) {
    s = String.fromCharCode(65 + ((n - 1) % 26)) + s;
  }
  return s;
}

/** Letters to a column index (0-based): A -> 0, AA -> 26. */
export function colIndex(letters) {
  let n = 0;
  for (const ch of letters.toUpperCase()) n = n * 26 + (ch.charCodeAt(0) - 64);
  return n - 1;
}

/** "B12" -> {col: 1, row: 12}; null if it is not a cell reference. */
export function parseRef(ref) {
  const m = /^([A-Za-z]+)([1-9]\d*)$/.exec(ref);
  return m ? { col: colIndex(m[1]), row: Number(m[2]) } : null;
}

/** A number in Calc's general format: up to 15 significant digits, 1E+20, 1E-07. */
export function formatNumber(x) {
  if (!Number.isFinite(x)) return "#NUM!";
  if (x === 0) return "0";
  const exp = Math.floor(Math.log10(Math.abs(Number(x.toPrecision(15)))));
  if (exp < -4 || exp >= 15) {
    let [mant, e] = x.toExponential(14).split("e");
    if (mant.includes(".")) mant = mant.replace(/0+$/, "").replace(/\.$/, "");
    const sign = e[0] === "-" ? "-" : "+";
    return `${mant}E${sign}${e.replace(/^[+-]/, "").padStart(2, "0")}`;
  }
  return String(Number(x.toPrecision(15)));
}

/** The text a cell shows for a computed JSON value. */
export function display(v) {
  if (v === null || v === undefined) return "";
  if (typeof v === "boolean") return v ? "TRUE" : "FALSE";
  if (typeof v === "number") return formatNumber(v);
  if (typeof v === "object") return typeof v.error === "string" ? v.error : "";
  return String(v);
}

const escapeHTML = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

const cellsOf = (state) => (state.book.sheets && state.book.sheets[state.sheet]) || {};

/** The grid's state: the workbook, the sheet shown and the selected cell. */
export function createState(book, sheet) {
  const b = book && book.sheets ? book : { sheets: {} };
  const name = sheet ?? Object.keys(b.sheets)[0] ?? "Sheet1";
  return { book: b, sheet: name, selected: "A1" };
}

export function select(state, ref) {
  return { ...state, selected: String(ref).toUpperCase() };
}

/** The selected cell moved by (dc, dr), never past A1. */
export function move(state, dc, dr) {
  const p = parseRef(state.selected) || { col: 0, row: 1 };
  return select(state, colName(Math.max(0, p.col + dc)) + Math.max(1, p.row + dr));
}

const NUMBER_TEXT = /^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/;

/** Typed text as a cell value: a number, TRUE/FALSE, text; undefined for "" (a blank). */
export function parseInput(text) {
  if (text === "") return undefined;
  if (NUMBER_TEXT.test(text)) {
    const x = Number(text);
    if (Number.isFinite(x)) return x;
  }
  if (/^true$/i.test(text)) return true;
  if (/^false$/i.test(text)) return false;
  return text;
}

/** The text an editor starts with for a cell: its value as typed back. */
export function inputText(v) {
  if (v === null || v === undefined || typeof v === "object") return "";
  return display(v);
}

/** The state whose sheet holds `text` typed into `ref`. */
export function edit(state, ref, text) {
  const key = String(ref).toUpperCase();
  const cells = { ...cellsOf(state) };
  const v = parseInput(text);
  if (v === undefined) delete cells[key];
  else cells[key] = v;
  return { ...state, book: { ...state.book, sheets: { ...state.book.sheets, [state.sheet]: cells } } };
}

/** The grid as an HTML table; every cell carries data-ref, the selected one class "selected". */
export function renderHTML(state, { rows = 20, cols = 8 } = {}) {
  const cells = cellsOf(state);
  const out = ['<table class="grid"><thead><tr><th class="corner"></th>'];
  for (let c = 0; c < cols; c++) out.push(`<th class="col">${colName(c)}</th>`);
  out.push("</tr></thead><tbody>");
  for (let r = 1; r <= rows; r++) {
    out.push(`<tr><th class="row">${r}</th>`);
    for (let c = 0; c < cols; c++) {
      const ref = colName(c) + r;
      const v = cells[ref];
      const cls = [];
      if (ref === state.selected) cls.push("selected");
      if (typeof v === "number" || typeof v === "boolean") cls.push("num");
      if (v && typeof v === "object") cls.push("err");
      const attr = cls.length ? ` class="${cls.join(" ")}"` : "";
      out.push(`<td data-ref="${ref}"${attr}>${escapeHTML(display(v))}</td>`);
    }
    out.push("</tr>");
  }
  out.push("</tbody></table>");
  return out.join("");
}

const ARROWS = { ArrowUp: [0, -1], ArrowDown: [0, 1], ArrowLeft: [-1, 0], ArrowRight: [1, 0] };

/**
 * Draws the grid into `container` and wires it: click selects; double-click, Enter, F2 or
 * typing edits; Enter commits, Escape cancels; arrows move. onChange(state) runs on every
 * selection and edit. Returns {state, setState(state), destroy()}.
 */
export function mount(container, state, { rows = 20, cols = 8, onChange = () => {} } = {}) {
  let s = state;
  let editing = null;
  const doc = container.ownerDocument;
  const tdOf = (ref) => container.querySelector(`td[data-ref="${ref}"]`);
  const draw = () => {
    editing = null;
    container.innerHTML = renderHTML(s, { rows, cols });
  };
  const update = (next) => {
    s = next;
    draw();
    onChange(s);
  };
  const inside = (ref) => {
    const p = parseRef(ref);
    return p && p.col < cols && p.row <= rows;
  };

  const startEdit = (ref, initial) => {
    const td = tdOf(ref);
    if (!td) return;
    const input = doc.createElement("input");
    input.value = initial ?? inputText(cellsOf(s)[ref]);
    td.textContent = "";
    td.appendChild(input);
    editing = input;
    input.focus();
    if (initial === undefined) input.select();
    input.addEventListener("keydown", (e) => {
      e.stopPropagation();
      if (e.key === "Enter") {
        e.preventDefault();
        const next = edit(s, ref, input.value);
        update(inside(move(next, 0, 1).selected) ? move(next, 0, 1) : next);
        container.focus();
      } else if (e.key === "Escape") {
        e.preventDefault();
        draw();
        container.focus();
      }
    });
    input.addEventListener("blur", () => {
      if (editing === input) update(edit(s, ref, input.value));
    });
  };

  const onClick = (e) => {
    const td = e.target.closest("td[data-ref]");
    if (td && !td.contains(editing)) update(select(s, td.dataset.ref));
  };
  const onDblClick = (e) => {
    const td = e.target.closest("td[data-ref]");
    if (td) {
      if (s.selected !== td.dataset.ref) update(select(s, td.dataset.ref));
      startEdit(td.dataset.ref);
    }
  };
  const onKey = (e) => {
    if (editing) return;
    if (ARROWS[e.key]) {
      const next = move(s, ...ARROWS[e.key]);
      if (inside(next.selected)) update(next);
      e.preventDefault();
    } else if (e.key === "Enter" || e.key === "F2") {
      startEdit(s.selected);
      e.preventDefault();
    } else if (e.key === "Delete" || e.key === "Backspace") {
      update(edit(s, s.selected, ""));
      e.preventDefault();
    } else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
      startEdit(s.selected, e.key);
      e.preventDefault();
    }
  };

  container.tabIndex = 0;
  container.addEventListener("click", onClick);
  container.addEventListener("dblclick", onDblClick);
  container.addEventListener("keydown", onKey);
  draw();
  return {
    get state() { return s; },
    setState(next) { s = next; draw(); },
    destroy() {
      container.removeEventListener("click", onClick);
      container.removeEventListener("dblclick", onDblClick);
      container.removeEventListener("keydown", onKey);
      container.innerHTML = "";
    },
  };
}
