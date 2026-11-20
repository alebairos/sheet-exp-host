"""Math and statistics functions (intent i5-math).

This WI (wi-i5-math-2) owns the scalar/rounding callables. Aggregates and
criteria ops land in the sibling work items on the same FUNCTIONS table.
"""

from __future__ import annotations

import math
from decimal import Decimal, ROUND_DOWN, ROUND_HALF_UP, ROUND_UP

from src.values import DIV0, NUM, VALUE, Number, is_error, to_number

__all__ = ["FUNCTIONS"]


def _scalar(v):
    """Collapse a one-cell Range the way operators do; leave Values alone."""
    values = getattr(v, "values", None)
    if callable(values):
        cells = values()
        if len(cells) == 1:
            return cells[0]
        return VALUE
    return v


def _as_number(v):
    n = to_number(_scalar(v))
    if is_error(n):
        return n
    return n


def _digits(v, default=0):
    if v is None:
        return Number(float(default))
    return _as_number(v)


def _quantize(x, digits, mode):
    """Scale ``x`` to ``digits`` places with the given decimal rounding mode."""
    try:
        d = int(digits)
    except (OverflowError, ValueError):
        return NUM
    # Decimal(str(float)) keeps the binary float's decimal form Calc sees.
    val = Decimal(str(x))
    quant = Decimal(1).scaleb(-d)
    try:
        out = val.quantize(quant, rounding=mode)
    except Exception:
        return NUM
    f = float(out)
    if not math.isfinite(f):
        return NUM
    return Number(f)


def ROUND(x, digits):
    a = _as_number(x)
    if is_error(a):
        return a
    b = _as_number(digits)
    if is_error(b):
        return b
    return _quantize(a.value, b.value, ROUND_HALF_UP)


def ROUNDUP(x, digits=None):
    a = _as_number(x)
    if is_error(a):
        return a
    b = _digits(digits, 0)
    if is_error(b):
        return b
    return _quantize(a.value, b.value, ROUND_UP)


def ROUNDDOWN(x, digits=None):
    a = _as_number(x)
    if is_error(a):
        return a
    b = _digits(digits, 0)
    if is_error(b):
        return b
    return _quantize(a.value, b.value, ROUND_DOWN)


def INT(x):
    a = _as_number(x)
    if is_error(a):
        return a
    return Number(math.floor(a.value))


def MOD(n, d):
    a = _as_number(n)
    if is_error(a):
        return a
    b = _as_number(d)
    if is_error(b):
        return b
    if b.value == 0:
        return DIV0
    # Calc: n - d * INT(n/d)
    q = math.floor(a.value / b.value)
    return Number(a.value - b.value * q)


def ABS(x):
    a = _as_number(x)
    if is_error(a):
        return a
    return Number(abs(a.value))


def POWER(x, y):
    a = _as_number(x)
    if is_error(a):
        return a
    b = _as_number(y)
    if is_error(b):
        return b
    try:
        z = a.value ** b.value
    except ZeroDivisionError:
        return DIV0
    except (OverflowError, ValueError):
        return NUM
    if isinstance(z, complex) or not math.isfinite(z):
        return NUM
    return Number(z)


def SQRT(x):
    a = _as_number(x)
    if is_error(a):
        return a
    if a.value < 0:
        return NUM
    return Number(math.sqrt(a.value))


FUNCTIONS = {
    "ROUND": ROUND,
    "ROUNDUP": ROUNDUP,
    "ROUNDDOWN": ROUNDDOWN,
    "INT": INT,
    "MOD": MOD,
    "ABS": ABS,
    "POWER": POWER,
    "SQRT": SQRT,
}
