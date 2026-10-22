

def sqrt_newton(x: float) -> float:
    if x <= 0.0:
        return 0.0
    guess: float = x
    i: int = 0
    while i < 50:
        guess = 0.5 * (guess + x / guess)
        i = i + 1
    return guess


def main():
    print(sqrt_newton(2.0))
    print(sqrt_newton(144.0))
