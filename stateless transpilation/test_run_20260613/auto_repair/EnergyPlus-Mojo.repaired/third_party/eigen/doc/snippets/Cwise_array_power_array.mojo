from memory import List

struct Array:
    var data: List[Float64]

    def __init__(inout self, a: Float64, b: Float64, c: Float64):
        self.data = List[Float64](a, b, c)

    def __str__(self) -> String:
        return "[" + str(self.data[0]) + " " + str(self.data[1]) + " " + str(self.data[2]) + "]"

    def pow(self, other: Array) -> Array:
        return Array(self.data[0] ** other.data[0], self.data[1] ** other.data[1], self.data[2] ** other.data[2])

def pow(a: Array, b: Array) -> Array:
    return a.pow(b)

def main():
    var x = Array(8.0, 25.0, 3.0)
    var e = Array(1.0 / 3.0, 0.5, 2.0)
    print("[" + str(x) + "]^[" + str(e) + "] = " + str(x.pow(e)))
    print("[" + str(x) + "]^[" + str(e) + "] = " + str(pow(x, e)))