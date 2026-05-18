# Collatz conjecture step count. Exercises a divergent-magnitude while
# loop with conditional branching and integer mod.


def collatz_length(n: int) -> int:
    steps: int = 0
    while n != 1:
        if n % 2 == 0:
            n = n // 2
        else:
            n = 3 * n + 1
        steps = steps + 1
    return steps


def max_collatz_under(limit: int) -> int:
    best: int = 0
    i: int = 1
    while i < limit:
        c: int = collatz_length(i)
        if c > best:
            best = c
        i = i + 1
    return best


def main():
    print(collatz_length(27))
    print(max_collatz_under(100))
