"""Logic, information, and text functions (intent i6-logic-text).

wi-i6-logic-text-1 owns the logic/information callables. Text ops land in
wi-i6-logic-text-2 on the same FUNCTIONS table.
"""

from __future__ import annotations

from src.values import (
    VALUE,
    Blank,
    Bool,
    Error,
    Number,
    Text,
    is_error,
    to_bool,
)

__all__ = ["FUNCTIONS"]


def _scalar(v):
    values = getattr(v, "values", None)
    if callable(values):
        cells = values()
        if len(cells) == 1:
            return cells[0]
        return VALUE
    return v


def IF(cond, then, otherwise=None):
    c = to_bool(_scalar(cond))
    if is_error(c):
        return c
    if c.value:
        return _scalar(then)
    if otherwise is None:
        return Bool(False)
    return _scalar(otherwise)


def IFERROR(value, fallback):
    v = _scalar(value)
    if is_error(v):
        return _scalar(fallback)
    return v


def AND(*args):
    if not args:
        return VALUE
    bools = []
    for arg in args:
        b = to_bool(_scalar(arg))
        if is_error(b):
            return b
        bools.append(b.value)
    return Bool(all(bools))


def OR(*args):
    if not args:
        return VALUE
    bools = []
    for arg in args:
        b = to_bool(_scalar(arg))
        if is_error(b):
            return b
        bools.append(b.value)
    return Bool(any(bools))


def NOT(x):
    b = to_bool(_scalar(x))
    if is_error(b):
        return b
    return Bool(not b.value)


def ISBLANK(x):
    return Bool(isinstance(_scalar(x), Blank))


def ISNUMBER(x):
    # Calc treats TRUE/FALSE as 1/0, so booleans count as numbers (clarification).
    v = _scalar(x)
    return Bool(isinstance(v, (Number, Bool)))


def ISTEXT(x):
    return Bool(isinstance(_scalar(x), Text))


def ISERROR(x):
    return Bool(isinstance(_scalar(x), Error))


FUNCTIONS = {
    "IF": IF,
    "IFERROR": IFERROR,
    "AND": AND,
    "OR": OR,
    "NOT": NOT,
    "ISBLANK": ISBLANK,
    "ISNUMBER": ISNUMBER,
    "ISTEXT": ISTEXT,
    "ISERROR": ISERROR,
}
