def fib_recursive(n: int) -> int:
    if n <= 1:
        return n
    return fib_recursive(n - 1) + fib_recursive(n - 2)


def fib_iterative(n: int) -> int:
    a: int = 0
    b: int = 1
    i: int = 0
    while i < n:
        c: int = a + b
        a = b
        b = c
        i = i + 1
    return a


def main():
    print(fib_iterative(20), fib_recursive(10))
