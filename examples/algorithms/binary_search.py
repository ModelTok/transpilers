def binary_search(xs: list[int], target: int) -> int:
    """Returns the index of target in sorted xs, or -1 if not found."""
    lo: int = 0
    hi: int = len(xs) - 1
    while lo <= hi:
        mid: int = (lo + hi) // 2
        if xs[mid] == target:
            return mid
        if xs[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1


def main():
    xs: list[int] = [1, 3, 5, 7, 9, 11, 13, 15]
    print(binary_search(xs, 7), binary_search(xs, 8))
