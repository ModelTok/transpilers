def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n < 4:
        return True
    if n % 2 == 0:
        return False
    i: int = 3
    while i * i <= n:
        if n % i == 0:
            return False
        i = i + 2
    return True


def count_primes_below(n: int) -> int:
    count: int = 0
    i: int = 2
    while i < n:
        if is_prime(i):
            count = count + 1
        i = i + 1
    return count


def main():
    print(count_primes_below(100))
