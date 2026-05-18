# Fast exponentiation via repeated squaring. `O(log n)` instead of
# `O(n)`. Tests bit-like control flow built from `%` and `//`.


def fast_pow(base: int, exp: int) -> int:
    result: int = 1
    b: int = base
    e: int = exp
    while e > 0:
        if e % 2 == 1:
            result = result * b
        b = b * b
        e = e // 2
    return result


def main():
    print(fast_pow(2, 10))
    print(fast_pow(3, 5))
