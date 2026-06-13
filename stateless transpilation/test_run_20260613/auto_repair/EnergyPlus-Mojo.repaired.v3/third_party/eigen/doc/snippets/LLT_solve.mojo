from tensor import Tensor
alias DType = DType.float32
alias DataMatrix = Tensor[DType]

var samples = DataMatrix.rand(12, 2)
var elevations = 2.0 * samples[:, 0] + 3.0 * samples[:, 1] + 0.1 * Tensor[DType].rand(12)
var xy: Tensor[DType, shape=(2,1)] = (samples.T @ samples).llt().solve(samples.T @ elevations)
print(xy)