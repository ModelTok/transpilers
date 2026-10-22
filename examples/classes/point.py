
class Point:
    x: int
    y: int

    def sum(self) -> int:
        return self.x + self.y

    def scale(self, factor: int) -> int:
        return self.x * factor + self.y * factor
