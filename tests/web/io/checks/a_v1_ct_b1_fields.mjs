// Shared by the a-v1-csv-text checks.
// RFC 4180 fields of each line, quotes undone: what a spreadsheet reads back from the saved file.
export function fields(text) {
  const rows = []; let row = [], f = "", q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) { if (c !== '"') f += c; else if (text[i + 1] === '"') { f += '"'; i++; } else q = false; }
    else if (c === '"') q = true;
    else if (c === ",") { row.push(f); f = ""; }
    else if (c === "\n") { row.push(f); rows.push(row); row = []; f = ""; }
    else f += c;
  }
  if (f !== "" || row.length) { row.push(f); rows.push(row); }
  return rows;
}
