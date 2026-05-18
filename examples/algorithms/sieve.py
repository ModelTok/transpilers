# Sieve of Eratosthenes — count primes below n. Exercises list mutation
# (write into an index), an outer/inner loop pattern, and the `// 2`
# upper-bound trick that closed-form integer arithmetic needs.


def count_primes_below(n: int) -> int:
    if n < 2:
        return 0
    sieve: list[bool] = [True, True, True, True]  # placeholder; size adjusted at run time
    # We can't construct `[False] * n` portably in our subset; build the
    # array via a loop instead.
    flags: list[bool] = []
    i: int = 0
    while i < n:
        flags = flags + [True]
        i = i + 1
    flags[0] = False
    if n > 1:
        flags[1] = False

    p: int = 2
    while p * p < n:
        if flags[p]:
            k: int = p * p
            while k < n:
                flags[k] = False
                k = k + p
        p = p + 1

    count: int = 0
    j: int = 2
    while j < n:
        if flags[j]:
            count = count + 1
        j = j + 1
    return count


def main():
    print(count_primes_below(100))
