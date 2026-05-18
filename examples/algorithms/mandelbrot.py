# Mandelbrot escape-time count for a single point. Exercises:
#   - nested float arithmetic with squaring
#   - early loop exit on a magnitude threshold
#   - explicit int/float interplay


def mandelbrot_iters(cx: float, cy: float, max_iter: int) -> int:
    x: float = 0.0
    y: float = 0.0
    i: int = 0
    while i < max_iter:
        x2: float = x * x
        y2: float = y * y
        if x2 + y2 > 4.0:
            return i
        y = 2.0 * x * y + cy
        x = x2 - y2 + cx
        i = i + 1
    return max_iter


def in_mandelbrot(cx: float, cy: float) -> bool:
    return mandelbrot_iters(cx, cy, 100) == 100


def main():
    print(mandelbrot_iters(0.0, 0.0, 100))
    print(in_mandelbrot(0.5, 0.5))
