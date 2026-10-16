

def count_primes_below(n: int) -> int:
    if n < 2:
        return 0
    sieve: list[bool] = [True, True, True, True]
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
