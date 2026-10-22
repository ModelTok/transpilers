

def gcd(a: int, b: int) -> int:
    while b != 0:
        t: int = b
        b = a % b
        a = t
    return a


def lcm(a: int, b: int) -> int:
    return a // gcd(a, b) * b


def main():
    print(lcm(12, 18))
    print(lcm(7, 5))
