# Bubble sort — in-place. Exercises subscript assignment (`xs[i] = ...`),
# nested loops, and the common "swap" idiom across targets.


def bubble_sort(xs: list[int]) -> int:
    """Sort `xs` in place and return the number of swaps done."""
    n: int = len(xs)
    swaps: int = 0
    i: int = 0
    while i < n:
        j: int = 0
        while j < n - i - 1:
            if xs[j] > xs[j + 1]:
                tmp: int = xs[j]
                xs[j] = xs[j + 1]
                xs[j + 1] = tmp
                swaps = swaps + 1
            j = j + 1
        i = i + 1
    return swaps


def main():
    xs: list[int] = [5, 3, 8, 1, 4]
    print(bubble_sort(xs))
