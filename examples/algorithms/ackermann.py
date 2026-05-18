# Ackermann function — recursion stress test. Even small inputs blow up
# fast; we keep arguments modest.


def ackermann(m: int, n: int) -> int:
    if m == 0:
        return n + 1
    if n == 0:
        return ackermann(m - 1, 1)
    return ackermann(m - 1, ackermann(m, n - 1))


def main():
    print(ackermann(2, 3))
    print(ackermann(3, 3))
