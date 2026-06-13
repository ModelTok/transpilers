from main import *
from internal import random, aligned_new, aligned_delete

var ptr: Pointer[float32]
var const_ptr: Pointer[float32]

@value
struct mapstaticmethods_impl[PlainObjectType: AnyType, IsDynamicSize: Bool = PlainObjectType.SizeAtCompileTime == Dynamic, IsVector: Bool = PlainObjectType.IsVectorAtCompileTime]:

@value
struct mapstaticmethods_impl[PlainObjectType: AnyType, IsVector: Bool](mapstaticmethods_impl[PlainObjectType, False, IsVector]):
    @staticmethod
    def run(m: PlainObjectType):
        mapstaticmethods_impl[PlainObjectType, True, IsVector].run(m)
        var i: Int32 = random[Int32](2,5)
        var j: Int32 = random[Int32](2,5)
        PlainObjectType.Map(ptr).setZero()
        PlainObjectType.MapAligned(ptr).setZero()
        PlainObjectType.Map(const_ptr).sum()
        PlainObjectType.MapAligned(const_ptr).sum()
        PlainObjectType.Map(ptr, InnerStride[Int32](i)).setZero()
        PlainObjectType.MapAligned(ptr, InnerStride[Int32](i)).setZero()
        PlainObjectType.Map(const_ptr, InnerStride[Int32](i)).sum()
        PlainObjectType.MapAligned(const_ptr, InnerStride[Int32](i)).sum()
        PlainObjectType.Map(ptr, InnerStride[2]()).setZero()
        PlainObjectType.MapAligned(ptr, InnerStride[3]()).setZero()
        PlainObjectType.Map(const_ptr, InnerStride[4]()).sum()
        PlainObjectType.MapAligned(const_ptr, InnerStride[5]()).sum()
        PlainObjectType.Map(ptr, OuterStride[Int32](i)).setZero()
        PlainObjectType.MapAligned(ptr, OuterStride[Int32](i)).setZero()
        PlainObjectType.Map(const_ptr, OuterStride[Int32](i)).sum()
        PlainObjectType.MapAligned(const_ptr, OuterStride[Int32](i)).sum()
        PlainObjectType.Map(ptr, OuterStride[2]()).setZero()
        PlainObjectType.MapAligned(ptr, OuterStride[3]()).setZero()
        PlainObjectType.Map(const_ptr, OuterStride[4]()).sum()
        PlainObjectType.MapAligned(const_ptr, OuterStride[5]()).sum()
        PlainObjectType.Map(ptr, Stride[Dynamic, Dynamic](i,j)).setZero()
        PlainObjectType.MapAligned(ptr, Stride[2,Dynamic](2,i)).setZero()
        PlainObjectType.Map(const_ptr, Stride[Dynamic,3](i,3)).sum()
        PlainObjectType.MapAligned(const_ptr, Stride[Dynamic, Dynamic](i,j)).sum()
        PlainObjectType.Map(ptr, Stride[2,3]()).setZero()
        PlainObjectType.MapAligned(ptr, Stride[3,4]()).setZero()
        PlainObjectType.Map(const_ptr, Stride[2,4]()).sum()
        PlainObjectType.MapAligned(const_ptr, Stride[5,3]()).sum()

@value
struct mapstaticmethods_impl[PlainObjectType: AnyType](mapstaticmethods_impl[PlainObjectType, True, False]):
    @staticmethod
    def run(m: PlainObjectType):
        var rows: Index = m.rows()
        var cols: Index = m.cols()
        var i: Int32 = random[Int32](2,5)
        var j: Int32 = random[Int32](2,5)
        PlainObjectType.Map(ptr, rows, cols).setZero()
        PlainObjectType.MapAligned(ptr, rows, cols).setZero()
        PlainObjectType.Map(const_ptr, rows, cols).sum()
        PlainObjectType.MapAligned(const_ptr, rows, cols).sum()
        PlainObjectType.Map(ptr, rows, cols, InnerStride[Int32](i)).setZero()
        PlainObjectType.MapAligned(ptr, rows, cols, InnerStride[Int32](i)).setZero()
        PlainObjectType.Map(const_ptr, rows, cols, InnerStride[Int32](i)).sum()
        PlainObjectType.MapAligned(const_ptr, rows, cols, InnerStride[Int32](i)).sum()
        PlainObjectType.Map(ptr, rows, cols, InnerStride[2]()).setZero()
        PlainObjectType.MapAligned(ptr, rows, cols, InnerStride[3]()).setZero()
        PlainObjectType.Map(const_ptr, rows, cols, InnerStride[4]()).sum()
        PlainObjectType.MapAligned(const_ptr, rows, cols, InnerStride[5]()).sum()
        PlainObjectType.Map(ptr, rows, cols, OuterStride[Int32](i)).setZero()
        PlainObjectType.MapAligned(ptr, rows, cols, OuterStride[Int32](i)).setZero()
        PlainObjectType.Map(const_ptr, rows, cols, OuterStride[Int32](i)).sum()
        PlainObjectType.MapAligned(const_ptr, rows, cols, OuterStride[Int32](i)).sum()
        PlainObjectType.Map(ptr, rows, cols, OuterStride[2]()).setZero()
        PlainObjectType.MapAligned(ptr, rows, cols, OuterStride[3]()).setZero()
        PlainObjectType.Map(const_ptr, rows, cols, OuterStride[4]()).sum()
        PlainObjectType.MapAligned(const_ptr, rows, cols, OuterStride[5]()).sum()
        PlainObjectType.Map(ptr, rows, cols, Stride[Dynamic, Dynamic](i,j)).setZero()
        PlainObjectType.MapAligned(ptr, rows, cols, Stride[2,Dynamic](2,i)).setZero()
        PlainObjectType.Map(const_ptr, rows, cols, Stride[Dynamic,3](i,3)).sum()
        PlainObjectType.MapAligned(const_ptr, rows, cols, Stride[Dynamic, Dynamic](i,j)).sum()
        PlainObjectType.Map(ptr, rows, cols, Stride[2,3]()).setZero()
        PlainObjectType.MapAligned(ptr, rows, cols, Stride[3,4]()).setZero()
        PlainObjectType.Map(const_ptr, rows, cols, Stride[2,4]()).sum()
        PlainObjectType.MapAligned(const_ptr, rows, cols, Stride[5,3]()).sum()

@value
struct mapstaticmethods_impl[PlainObjectType: AnyType](mapstaticmethods_impl[PlainObjectType, True, True]):
    @staticmethod
    def run(v: PlainObjectType):
        var size: Index = v.size()
        var i: Int32 = random[Int32](2,5)
        PlainObjectType.Map(ptr, size).setZero()
        PlainObjectType.MapAligned(ptr, size).setZero()
        PlainObjectType.Map(const_ptr, size).sum()
        PlainObjectType.MapAligned(const_ptr, size).sum()
        PlainObjectType.Map(ptr, size, InnerStride[Int32](i)).setZero()
        PlainObjectType.MapAligned(ptr, size, InnerStride[Int32](i)).setZero()
        PlainObjectType.Map(const_ptr, size, InnerStride[Int32](i)).sum()
        PlainObjectType.MapAligned(const_ptr, size, InnerStride[Int32](i)).sum()
        PlainObjectType.Map(ptr, size, InnerStride[2]()).setZero()
        PlainObjectType.MapAligned(ptr, size, InnerStride[3]()).setZero()
        PlainObjectType.Map(const_ptr, size, InnerStride[4]()).sum()
        PlainObjectType.MapAligned(const_ptr, size, InnerStride[5]()).sum()

def mapstaticmethods[PlainObjectType: AnyType](m: PlainObjectType):
    mapstaticmethods_impl[PlainObjectType].run(m)
    VERIFY(True)

def test_mapstaticmethods():
    ptr = aligned_new[float32](1000)
    for i in range(1000):
        ptr[i] = float32(i)
    const_ptr = ptr
    CALL_SUBTEST_1(( mapstaticmethods(Matrix[float32, 1, 1]()) ))
    CALL_SUBTEST_1(( mapstaticmethods(Vector2f()) ))
    CALL_SUBTEST_2(( mapstaticmethods(Vector3f()) ))
    CALL_SUBTEST_2(( mapstaticmethods(Matrix2f()) ))
    CALL_SUBTEST_3(( mapstaticmethods(Matrix4f()) ))
    CALL_SUBTEST_3(( mapstaticmethods(Array4f()) ))
    CALL_SUBTEST_4(( mapstaticmethods(Array3f()) ))
    CALL_SUBTEST_4(( mapstaticmethods(Array33f()) ))
    CALL_SUBTEST_5(( mapstaticmethods(Array44f()) ))
    CALL_SUBTEST_5(( mapstaticmethods(VectorXf(1)) ))
    CALL_SUBTEST_5(( mapstaticmethods(VectorXf(8)) ))
    CALL_SUBTEST_6(( mapstaticmethods(MatrixXf(1,1)) ))
    CALL_SUBTEST_6(( mapstaticmethods(MatrixXf(5,7)) ))
    CALL_SUBTEST_7(( mapstaticmethods(ArrayXf(1)) ))
    CALL_SUBTEST_7(( mapstaticmethods(ArrayXf(5)) ))
    CALL_SUBTEST_8(( mapstaticmethods(ArrayXXf(1,1)) ))
    CALL_SUBTEST_8(( mapstaticmethods(ArrayXXf(8,6)) ))
    aligned_delete(ptr, 1000)