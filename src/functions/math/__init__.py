"""Math functions: aggregates (wi-i5-math-1) and criteria ops (wi-i5-math-3).

Aggregates: a range yields numbers, with blanks and text left out and booleans
as 1 and 0. The first error in that walk is the result. COUNTA counts every
non-blank.

Criteria: a criterion is a comparison. Prefixes are >=, <=, <>, >, <, and =.
A number matches numbers and booleans. Text that is a number, with no
relational prefix, matches that number and that text. Other text matches
text, ignoring case. * and ? are wildcards, and ~ escapes the next character.
"""

import math
import re

from src.values import (
    BLANK,
    DIV0,
    NUM,
    VALUE,
    Blank,
    Bool,
    Number,
    Text,
    is_error,
    to_number,
)


def _cells(arg):
    values = getattr(arg, "values", None)
    if callable(values):
        return list(values())
    return [arg]


def _numbers(args):
    """Floats from args and ranges, or the first error."""
    nums = []
    for arg in args:
        for cell in _cells(arg):
            if isinstance(cell, (Blank, Text)):
                continue
            if is_error(cell):
                return cell
            if isinstance(cell, Bool):
                nums.append(1.0 if cell.value else 0.0)
            elif isinstance(cell, Number):
                if not math.isfinite(cell.value):
                    return NUM
                nums.append(cell.value)
            else:
                return VALUE
    return nums


def _finite(x):
    if not math.isfinite(x):
        return NUM
    return Number(x)


def _apply(empty, reduce):
    def fn(*args):
        nums = _numbers(args)
        if is_error(nums):
            return nums
        if not nums:
            return empty
        return reduce(nums)

    return fn


def _sum(nums):
    return _finite(math.fsum(nums))


def _average(nums):
    return _finite(math.fsum(nums) / len(nums))


def _min(nums):
    return Number(min(nums))


def _max(nums):
    return Number(max(nums))


def _count_nums(nums):
    return Number(len(nums))


def _product(nums):
    product = 1.0
    for x in nums:
        product *= x
    return _finite(product)


def _median(nums):
    ordered = sorted(nums)
    mid = len(ordered) // 2
    if len(ordered) % 2:
        return Number(ordered[mid])
    return _finite((ordered[mid - 1] + ordered[mid]) / 2.0)


def _stdev(nums):
    if len(nums) < 2:
        return DIV0
    mean = math.fsum(nums) / len(nums)
    acc = math.fsum((x - mean) ** 2 for x in nums)
    return _finite(math.sqrt(acc / (len(nums) - 1)))


def _counta(*args):
    n = 0
    for arg in args:
        for cell in _cells(arg):
            if not isinstance(cell, Blank):
                n += 1
    return Number(n)


_OPS = {
    "=": lambda order: order == 0,
    "<>": lambda order: order != 0,
    "<": lambda order: order < 0,
    ">": lambda order: order > 0,
    "<=": lambda order: order <= 0,
    ">=": lambda order: order >= 0,
}

_PREFIXES = (">=", "<=", "<>", ">", "<", "=")


class _Criterion:
    """One parsed criterion. number and text together mean equality on both."""

    __slots__ = ("op", "number", "text", "pattern")

    def __init__(self, op, number, text, pattern):
        self.op = op
        self.number = number
        self.text = text
        self.pattern = pattern


def _one(arg):
    cells = _cells(arg)
    if len(cells) != 1:
        return VALUE
    return cells[0]


def _sign(left, right):
    return (left > right) - (left < right)


def _wildcard(pattern):
    parts = []
    i = 0
    text = pattern.casefold()
    while i < len(text):
        ch = text[i]
        if ch == "~" and i + 1 < len(text):
            parts.append(re.escape(text[i + 1]))
            i += 2
            continue
        if ch == "*":
            parts.append(".*")
        elif ch == "?":
            parts.append(".")
        else:
            parts.append(re.escape(ch))
        i += 1
    return re.compile("".join(parts))


def _parse(criteria):
    """A Value or one-cell range as a criterion, or an Error."""
    criteria = _one(criteria)
    if is_error(criteria):
        return criteria
    if isinstance(criteria, Blank):
        return _Criterion("=", None, "", None)
    if isinstance(criteria, Bool):
        return _Criterion("=", 1.0 if criteria.value else 0.0, None, None)
    if isinstance(criteria, Number):
        if not math.isfinite(criteria.value):
            return NUM
        return _Criterion("=", criteria.value, None, None)
    if not isinstance(criteria, Text):
        return VALUE
    op, rest = "=", criteria.value
    for prefix in _PREFIXES:
        if criteria.value.startswith(prefix):
            op, rest = prefix, criteria.value[len(prefix) :]
            break
    number = None
    if rest != "":
        parsed = to_number(Text(rest))
        if isinstance(parsed, Number):
            number = parsed.value
    if number is not None:
        text = rest if op == "=" else None
        return _Criterion(op, number, text, None)
    pattern = _wildcard(rest) if op in ("=", "<>") else None
    return _Criterion(op, None, rest, pattern)


def _cell_number(cell):
    if isinstance(cell, Number):
        if not math.isfinite(cell.value):
            return NUM
        return cell.value
    if isinstance(cell, Bool):
        return 1.0 if cell.value else 0.0
    return None


def _match_text(value, crit):
    if crit.pattern is not None:
        hit = crit.pattern.fullmatch(value.casefold()) is not None
        return hit if crit.op == "=" else not hit
    return _OPS[crit.op](_sign(value.casefold(), crit.text.casefold()))


def _match(cell, crit):
    if is_error(cell):
        return cell
    if crit.number is not None:
        number = _cell_number(cell)
        if is_error(number):
            return number
        if number is not None and _OPS[crit.op](_sign(number, crit.number)):
            return True
        if crit.text is None or not isinstance(cell, Text):
            return False
        return cell.value.casefold() == crit.text.casefold()
    if isinstance(cell, Text):
        return _match_text(cell.value, crit)
    return False


def _matched(criteria_range, criteria, sum_range):
    """Sum-range cells at positions whose criteria cell matches, or an Error."""
    crit = _parse(criteria)
    if is_error(crit):
        return crit
    left = _cells(criteria_range)
    right = left if sum_range is None else _cells(sum_range)
    chosen = []
    for i, cell in enumerate(left):
        hit = _match(cell, crit)
        if is_error(hit):
            return hit
        if not hit:
            continue
        if sum_range is None:
            summed = cell
        elif i < len(right):
            summed = right[i]
        else:
            summed = BLANK
        if is_error(summed):
            return summed
        chosen.append(summed)
    return chosen


def _addends(cells):
    nums = []
    for cell in cells:
        if isinstance(cell, Number):
            if not math.isfinite(cell.value):
                return NUM
            nums.append(cell.value)
        elif isinstance(cell, Bool):
            nums.append(1.0 if cell.value else 0.0)
    return nums


def _sum_of(cells):
    nums = _addends(cells)
    if is_error(nums):
        return nums
    if not nums:
        return Number(0.0)
    return _finite(math.fsum(nums))


def _average_of(cells):
    nums = _addends(cells)
    if is_error(nums):
        return nums
    if not nums:
        return DIV0
    return _finite(math.fsum(nums) / len(nums))


def _conditional(finish, max_args):
    def fn(*args):
        if len(args) < 2 or len(args) > max_args:
            return VALUE
        sum_range = args[2] if len(args) == 3 else None
        matched = _matched(args[0], args[1], sum_range)
        if is_error(matched):
            return matched
        return finish(matched)

    return fn


def _count_matched(cells):
    return Number(len(cells))


FUNCTIONS = {
    "SUM": _apply(Number(0.0), _sum),
    "AVERAGE": _apply(DIV0, _average),
    "MIN": _apply(Number(0.0), _min),
    "MAX": _apply(Number(0.0), _max),
    "COUNT": _apply(Number(0.0), _count_nums),
    "COUNTA": _counta,
    "PRODUCT": _apply(Number(0.0), _product),
    "MEDIAN": _apply(VALUE, _median),
    "STDEV": _apply(DIV0, _stdev),
    "SUMIF": _conditional(_sum_of, 3),
    "COUNTIF": _conditional(_count_matched, 2),
    "AVERAGEIF": _conditional(_average_of, 3),
}
