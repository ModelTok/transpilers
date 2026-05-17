# Unannotated Python — algorithmic inference fills the holes from literals.

def add_one(x):
    return x + 1


def is_positive(x):
    return x > 0


def sum_to(n):
    total = 0
    for i in range(n):
        total = total + i
    return total
