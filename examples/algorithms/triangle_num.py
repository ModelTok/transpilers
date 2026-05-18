# Triangular numbers two ways: closed-form `n*(n+1)/2` and the
# loop-summation. The example doubles as a tiny correctness check —
# both functions should agree for every positive `n`.


def triangle_closed(n: int) -> int:
    return n * (n + 1) // 2


def triangle_loop(n: int) -> int:
    total: int = 0
    i: int = 1
    while i <= n:
        total = total + i
        i = i + 1
    return total


def main():
    print(triangle_closed(10))
    print(triangle_loop(10))
