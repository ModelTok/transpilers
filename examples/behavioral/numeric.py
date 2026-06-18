"""Annotated leaf functions for the behavioral-equivalence sweep (issue #48).

These are deliberately small, pure, scalar/list functions: the smallest
runnable boundary the harness verifies. The sweep transpiles each to a target,
compiles it, then runs source-vs-target over generated + fuzzed inputs.
"""


def add(a: int, b: int) -> int:
    return a + b


def abs_diff(a: int, b: int) -> int:
    if a > b:
        return a - b
    return b - a


def is_even(n: int) -> bool:
    return n % 2 == 0


def clamp(x: int, lo: int, hi: int) -> int:
    if x < lo:
        return lo
    if x > hi:
        return hi
    return x


def sum_list(xs: list[int]) -> int:
    total = 0
    for x in xs:
        total = total + x
    return total


def max_list(xs: list[int]) -> int:
    best = xs[0]
    for x in xs:
        if x > best:
            best = x
    return best
