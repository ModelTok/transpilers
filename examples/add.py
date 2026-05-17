def add(a: int, b: int) -> int:
    return a + b


def max2(a: int, b: int) -> int:
    if a > b:
        return a
    else:
        return b


def factorial(n: int) -> int:
    result: int = 1
    i: int = 1
    while i <= n:
        result = result * i
        i = i + 1
    return result


def sum_list(xs: list[int]) -> int:
    total: int = 0
    for i in range(len(xs)):
        total = total + xs[i]
    return total
