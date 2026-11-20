"""Workbook recalculation in dependency order (intent i4-recalc)."""

from __future__ import annotations

import copy
from collections import defaultdict, deque

import src.eval as eval_mod
from src.parser import (
    Binary,
    Call,
    ParseError,
    Percent,
    Range as RangeNode,
    Ref,
    Unary,
    parse,
)
from src.values import REF, to_json

__all__ = ["recalculate"]


def recalculate(book, changed=None, previous=None):
    """Compute every formula cell. Cycles become #REF!; the rest still run.

    ``changed`` / ``previous`` select an incremental dirty closure (wi-i4-recalc-2).
    Without them, the whole workbook is recomputed.
    """
    if not isinstance(book, dict):
        raise TypeError("book must be a workbook dict")

    formulas = _formula_cells(book)
    deps = {cell: _cell_deps(formula, sheet) for cell, (sheet, formula) in formulas.items()}

    if changed is not None:
        changed_keys = {(item[0], item[1]) for item in changed}
        dirty = _dirty_closure(formulas, deps, changed_keys)
        working = _seed_previous(book, previous, dirty | changed_keys)
        order_cells = dirty
    else:
        working = copy.deepcopy(book)
        order_cells = set(formulas)

    formula_subset = {c: deps[c] for c in order_cells if c in formulas}
    cyclic = _cyclic_formulas(formula_subset, formulas)
    for cell in cyclic:
        sheet, addr = cell
        working.setdefault("sheets", {}).setdefault(sheet, {})[addr] = to_json(REF)

    todo = [c for c in order_cells if c in formulas and c not in cyclic]
    for sheet, addr in _topo_order(todo, deps, formulas):
        formula = formulas[(sheet, addr)][1]
        value = eval_mod.evaluate(formula, working, sheet)
        working.setdefault("sheets", {}).setdefault(sheet, {})[addr] = to_json(value)

    return working


def _formula_cells(book):
    out = {}
    sheets = book.get("sheets") or {}
    if not isinstance(sheets, dict):
        return out
    for sheet, cells in sheets.items():
        if not isinstance(cells, dict):
            continue
        for addr, value in cells.items():
            if isinstance(value, str) and value.startswith("="):
                out[(sheet, addr)] = (sheet, value)
    return out


def _cell_deps(formula, sheet):
    try:
        node = parse(formula)
    except ParseError:
        return set()
    found = set()
    _walk_deps(node, sheet, found)
    return found


def _walk_deps(node, sheet, found):
    if isinstance(node, Ref):
        found.add((_sheet_of(node, sheet), _addr(node)))
        return
    if isinstance(node, RangeNode):
        found.update(_expand_range(node, sheet))
        return
    if isinstance(node, Unary) or isinstance(node, Percent):
        _walk_deps(node.expr, sheet, found)
        return
    if isinstance(node, Binary):
        _walk_deps(node.left, sheet, found)
        _walk_deps(node.right, sheet, found)
        return
    if isinstance(node, Call):
        for arg in node.args:
            _walk_deps(arg, sheet, found)


def _sheet_of(ref, sheet):
    if ref.sheet is not None:
        return ref.sheet
    return sheet


def _addr(ref):
    return "%s%d" % (ref.col, ref.row)


def _expand_range(node, sheet):
    left = _sheet_of(node.start, sheet)
    right = node.end.sheet if node.end.sheet is not None else left
    if left != right:
        # Cross-sheet ranges are not a dependency we can enumerate cleanly.
        return {(_sheet_of(node.start, sheet), _addr(node.start)),
                (_sheet_of(node.end, sheet) if node.end.sheet else left, _addr(node.end))}
    c1 = _col(node.start.col)
    c2 = _col(node.end.col)
    r1, r2 = node.start.row, node.end.row
    if c1 > c2:
        c1, c2 = c2, c1
    if r1 > r2:
        r1, r2 = r2, r1
    cells = set()
    for row in range(r1, r2 + 1):
        for col in range(c1, c2 + 1):
            cells.add((left, "%s%d" % (_col_name(col), row)))
    return cells


def _col(letters):
    n = 0
    for ch in letters:
        n = n * 26 + ord(ch) - 64
    return n


def _col_name(n):
    chars = []
    while n > 0:
        n, rem = divmod(n - 1, 26)
        chars.append(chr(65 + rem))
    return "".join(reversed(chars))


def _cyclic_formulas(deps, formulas):
    """Formula cells that do not appear in a dependency topo-order (cycles).

    Iterative (Kahn leftovers) so a long acyclic chain does not blow the stack.
    """
    nodes = [c for c in deps if c in formulas]
    ordered = set(_topo_order(nodes, deps, formulas))
    return set(nodes) - ordered


def _topo_order(cells, deps, formulas):
    """Yield formula cells so each runs after its formula dependencies."""
    cells = set(cells)
    incoming = defaultdict(int)
    reverse = defaultdict(set)
    for cell in cells:
        for dep in deps.get(cell, ()):
            if dep in cells and dep in formulas:
                reverse[dep].add(cell)
                incoming[cell] += 1

    ready = deque(sorted(c for c in cells if incoming[c] == 0))
    seen = 0
    while ready:
        cell = ready.popleft()
        seen += 1
        yield cell
        for child in sorted(reverse[cell]):
            incoming[child] -= 1
            if incoming[child] == 0:
                ready.append(child)
    if seen != len(cells):
        # Residual cycle pieces already marked; skip leftovers.
        return


def _dirty_closure(formulas, deps, changed):
    """Formulas that are changed or transitively depend on a changed cell."""
    dependents = defaultdict(set)
    for cell, cell_deps in deps.items():
        for dep in cell_deps:
            dependents[dep].add(cell)

    dirty = set()
    stack = []
    for item in changed:
        sheet, addr = item[0], item[1]
        key = (sheet, addr)
        stack.append(key)
        if key in formulas:
            dirty.add(key)
    while stack:
        cell = stack.pop()
        for child in dependents.get(cell, ()):
            if child not in dirty:
                dirty.add(child)
                stack.append(child)
    return dirty


def _seed_previous(book, previous, dirty):
    working = copy.deepcopy(book)
    if not isinstance(previous, dict):
        return working
    prev_sheets = previous.get("sheets") or {}
    sheets = working.setdefault("sheets", {})
    for sheet, cells in list(sheets.items()):
        if not isinstance(cells, dict):
            continue
        prev_cells = prev_sheets.get(sheet) or {}
        for addr in list(cells):
            key = (sheet, addr)
            if key in dirty:
                continue
            if addr in prev_cells:
                cells[addr] = copy.deepcopy(prev_cells[addr])
    return working
