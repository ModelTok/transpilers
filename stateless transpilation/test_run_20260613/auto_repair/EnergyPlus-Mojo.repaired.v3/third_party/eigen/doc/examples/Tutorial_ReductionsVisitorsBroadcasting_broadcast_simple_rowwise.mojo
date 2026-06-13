from tensor import Tensor, DType

def main():
    var mat = Tensor[DType.float32]([[1., 2., 6., 9.],
                                      [3., 1., 7., 2.]])
    let v = Tensor[DType.float32]([0., 1., 2., 3.])
    let v_row = v.reshape((1, 4))
    mat += v_row
    print("Broadcasting result:")
    print(mat)