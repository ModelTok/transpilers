from Eigen.Core import *
from iostream import *
using Eigen

struct indexing_functor[ArgType: AnyType, RowIndexType: AnyType, ColIndexType: AnyType]:
    var m_arg: ArgType
    var m_rowIndices: RowIndexType
    var m_colIndices: ColIndexType

    alias MatrixType = Matrix[
        ArgType.Scalar,
        RowIndexType.SizeAtCompileTime,
        ColIndexType.SizeAtCompileTime,
        (ArgType.Flags & RowMajorBit) ? RowMajor : ColMajor,
        RowIndexType.MaxSizeAtCompileTime,
        ColIndexType.MaxSizeAtCompileTime
    ]

    def __init__(inout self, arg: ArgType, row_indices: RowIndexType, col_indices: ColIndexType):
        self.m_arg = arg
        self.m_rowIndices = row_indices
        self.m_colIndices = col_indices

    def __call__(self, row: Index, col: Index) -> ArgType.Scalar:
        return self.m_arg[self.m_rowIndices[row], self.m_colIndices[col]]

def indexing[ArgType: AnyType, RowIndexType: AnyType, ColIndexType: AnyType](
    arg: Eigen.MatrixBase[ArgType],
    row_indices: RowIndexType,
    col_indices: ColIndexType
) -> indexing_functor[ArgType, RowIndexType, ColIndexType].MatrixType:
    alias Func = indexing_functor[ArgType, RowIndexType, ColIndexType]
    alias MatrixType = Func.MatrixType
    return MatrixType.NullaryExpr(row_indices.size(), col_indices.size(), Func(arg.derived(), row_indices, col_indices))

def main():
    print("[main1]")
    var A = Eigen.MatrixXi.Random(4, 4)
    var ri = Array3i(1, 2, 1)
    var ci = ArrayXi(6)
    ci << 3, 2, 1, 0, 0, 2
    var B = indexing(A, ri, ci)
    print("A =")
    print(A)
    print()
    print("A([" + ri.transpose() + "], [" + ci.transpose() + "]) =")
    print(B)
    print("[main1]")
    print("[main2]")
    B = indexing(A, ri + 1, ci)
    print("A(ri+1,ci) =")
    print(B)
    print()
    #if __cplusplus >= 201103L
    B = indexing(A, ArrayXi.LinSpaced(13, 0, 12).unaryExpr(lambda x: x % 4), ArrayXi.LinSpaced(4, 0, 3))
    print("A(ArrayXi::LinSpaced(13,0,12).unaryExpr([](int x){return x%4;}), ArrayXi::LinSpaced(4,0,3)) =")
    print(B)
    print()
    #endif
    print("[main2]")