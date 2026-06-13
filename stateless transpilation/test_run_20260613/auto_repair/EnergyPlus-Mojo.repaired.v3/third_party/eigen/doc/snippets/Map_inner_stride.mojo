from memory import Array, Pointer

struct InnerStride[stride: Int]:
    alias inner_stride = stride

struct VectorXi:

struct Map[VecType, alignment: Int, StrideType: InnerStride]:
    var data: Pointer[Int]
    var size: Int
    def __init__(inout self, data: Pointer[Int], size: Int):
        self.data = data
        self.size = size
    def __repr__(self) -> String:
        var result = String()
        for i in range(self.size):
            if i > 0:
                result += " "
            result += str(self.data[i * StrideType.inner_stride])
        return result

def main():
    var array = Array[Int](12)
    for i in range(12):
        array[i] = i
    var ptr = Pointer[Int](array.data)
    print(Map[VectorXi, 0, InnerStride[2]](ptr, 6))  # the inner stride has already been passed as template parameter