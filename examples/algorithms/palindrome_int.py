# Reverse an integer digit-by-digit using `//` and `%`, then check
# whether the reversed value equals the original. Pure integer
# arithmetic — no list/string subset features.


def is_palindrome(n: int) -> bool:
    if n < 0:
        return False
    x: int = n
    rev: int = 0
    while x > 0:
        rev = rev * 10 + x % 10
        x = x // 10
    return rev == n


def main():
    print(is_palindrome(12321))
    print(is_palindrome(12345))
