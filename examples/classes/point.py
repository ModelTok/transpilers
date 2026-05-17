# Equivalent Python class demonstrating the same fields + methods +
# instantiation pattern. Note that the Python frontend's class support is
# narrower than the C++ frontend's — methods are recognized but the
# `@dataclass` -style construction would need explicit `__init__`. For now
# this file demonstrates the Python frontend's reach; the C++ version is
# the canonical demo.

class Point:
    x: int
    y: int

    def sum(self) -> int:
        return self.x + self.y

    def scale(self, factor: int) -> int:
        return self.x * factor + self.y * factor
