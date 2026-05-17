# Interprocedural inference: no annotations, types flow across the call graph.

def square(x):
    return x * x


def sum_of_squares(n):
    total = 0
    for i in range(n):
        total = total + square(i)
    return total


def fact(n):
    if n <= 1:
        return 1
    return n * fact(n - 1)
