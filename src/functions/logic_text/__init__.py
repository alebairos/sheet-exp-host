"""Text functions for intent i6-logic-text.

wi-i6-logic-text-2 owns CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM.
Logic and information callables land in wi-i6-logic-text-1 on the same package.
"""

from __future__ import annotations

import math

from src.values import (
    VALUE,
    Number,
    Text,
    is_error,
    to_number,
    to_text,
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


def _nonneg_int(v, default=None):
    """A string-function count: truncated toward zero, or #VALUE! if negative."""
    if v is None:
        return default
    n = to_number(_scalar(v))
    if is_error(n):
        return n
    i = math.trunc(n.value)
    if i < 0:
        return VALUE
    return i


def CONCATENATE(*args):
    if not args:
        return VALUE
    parts = []
    for arg in args:
        t = to_text(_scalar(arg))
        if is_error(t):
            return t
        parts.append(t.value)
    return Text("".join(parts))


def LEFT(text, count=None):
    t = to_text(_scalar(text))
    if is_error(t):
        return t
    n = _nonneg_int(count, 1)
    if is_error(n):
        return n
    return Text(t.value[:n])


def RIGHT(text, count=None):
    t = to_text(_scalar(text))
    if is_error(t):
        return t
    n = _nonneg_int(count, 1)
    if is_error(n):
        return n
    if n == 0:
        return Text("")
    return Text(t.value[-n:])


def MID(text, start, length):
    t = to_text(_scalar(text))
    if is_error(t):
        return t
    s = to_number(_scalar(start))
    if is_error(s):
        return s
    start_i = math.trunc(s.value)
    if start_i < 1:
        return VALUE
    n = _nonneg_int(length)
    if is_error(n):
        return n
    begin = start_i - 1
    return Text(t.value[begin : begin + n])


def LEN(text):
    t = to_text(_scalar(text))
    if is_error(t):
        return t
    return Number(float(len(t.value)))


def UPPER(text):
    t = to_text(_scalar(text))
    if is_error(t):
        return t
    return Text(t.value.upper())


def LOWER(text):
    t = to_text(_scalar(text))
    if is_error(t):
        return t
    return Text(t.value.lower())


def TRIM(text):
    t = to_text(_scalar(text))
    if is_error(t):
        return t
    # Calc TRIM: strip leading/trailing ASCII spaces, collapse internal runs.
    s = t.value.strip(" ")
    while "  " in s:
        s = s.replace("  ", " ")
    return Text(s)


FUNCTIONS = {
    "CONCATENATE": CONCATENATE,
    "LEFT": LEFT,
    "RIGHT": RIGHT,
    "MID": MID,
    "LEN": LEN,
    "UPPER": UPPER,
    "LOWER": LOWER,
    "TRIM": TRIM,
}
