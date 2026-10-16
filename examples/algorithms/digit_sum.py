

def digit_sum(n: int) -> int:
    total: int = 0
    while n > 0:
        total = total + n % 10
        n = n // 10
    return total


def is_harshad(n: int) -> bool:
    """A Harshad (Niven) number is divisible by the sum of its digits."""
    s: int = digit_sum(n)
    if s == 0:
        return False
    return n % s == 0


def main():
    print(digit_sum(12345))
    print(is_harshad(18))
