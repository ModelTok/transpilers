def fizzbuzz_value(n: int) -> int:
    """Returns a discriminator: 0 = neither, 1 = fizz, 2 = buzz, 3 = fizzbuzz.
    Avoids strings since our string-output story varies per target."""
    fizz: bool = (n % 3) == 0
    buzz: bool = (n % 5) == 0
    if fizz and buzz:
        return 3
    if fizz:
        return 1
    if buzz:
        return 2
    return 0


def main():
    i: int = 1
    while i <= 20:
        v: int = fizzbuzz_value(i)
        print(i, v)
        i = i + 1
