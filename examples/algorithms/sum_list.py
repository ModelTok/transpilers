def sum_list(xs: list[int]) -> int:
    total: int = 0
    for i in range(len(xs)):
        total = total + xs[i]
    return total


def max_element(xs: list[int]) -> int:
    """Returns the max — assumes non-empty list. Empty input behavior
    isn't defined here; the type lattice would need Optional<int> to
    represent the absence."""
    best: int = xs[0]
    for i in range(len(xs)):
        if xs[i] > best:
            best = xs[i]
    return best


def main():
    xs: list[int] = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
    print(sum_list(xs), max_element(xs))
