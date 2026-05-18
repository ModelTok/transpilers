def gcd(a: int, b: int) -> int:
    while b != 0:
        t: int = b
        b = a % b
        a = t
    return a


def lcm(a: int, b: int) -> int:
    return a * b // gcd(a, b)


def main():
    print(gcd(48, 36), lcm(4, 6))
