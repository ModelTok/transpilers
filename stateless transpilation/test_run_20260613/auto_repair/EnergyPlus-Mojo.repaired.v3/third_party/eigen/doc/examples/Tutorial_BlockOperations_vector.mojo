
struct SegmentView:
    var parent: Pointer[ArrayXf]
    var start: Int
    var count: Int

    def __init__(inout self, parent: Pointer[ArrayXf], start: Int, count: Int):
        self.parent = parent
        self.start = start
        self.count = count

    def __imul__(inout self, factor: Float32):
        var p = self.parent.load()
        for i in range(self.count):
            p.data[self.start + i] *= factor

struct ArrayXf:
    var data: List[Float32]

    def __init__(inout self, n: Int):
        self.data = List[Float32](n)

    def head(self, n: Int) -> ArrayXf:
        var out = ArrayXf(n)
        for i in range(n):
            out.data[i] = self.data[i]
        return out

    def tail[K: Int](self) -> ArrayXf:
        var n = self.data.size
        var out = ArrayXf(K)
        for i in range(K):
            out.data[i] = self.data[n - K + i]
        return out

    def segment(self, start: Int, count: Int) -> SegmentView:
        var ptr = Pointer[ArrayXf](address_of(self))
        return SegmentView(ptr, start, count)

    def __str__(self) -> String:
        var s = String()
        for i in range(self.data.size):
            s += str(self.data[i])
            if i < self.data.size - 1:
                s += " "
        return s

def main():
    var v = ArrayXf(6)
    v.data[0] = 1.0
    v.data[1] = 2.0
    v.data[2] = 3.0
    v.data[3] = 4.0
    v.data[4] = 5.0
    v.data[5] = 6.0

    print("v.head(3) =")
    print(v.head(3))
    print()
    print("v.tail<3>() = ")
    print(v.tail[3]())
    print()
    v.segment(1,4) *= 2.0
    print("after 'v.segment(1,4) *= 2', v =")
    print(v)