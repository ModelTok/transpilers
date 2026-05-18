# Linear search with explicit found-flag. Exercises list iteration via
# range(len(...)) and an early-return pattern that targets must emit
# faithfully.


def find_first(xs: list[int], target: int) -> int:
    """Returns the index of `target` in `xs`, or -1 if absent."""
    for i in range(len(xs)):
        if xs[i] == target:
            return i
    return -1


def count_occurrences(xs: list[int], target: int) -> int:
    count: int = 0
    for i in range(len(xs)):
        if xs[i] == target:
            count = count + 1
    return count


def main():
    xs: list[int] = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]
    print(find_first(xs, 5))
    print(count_occurrences(xs, 1))
