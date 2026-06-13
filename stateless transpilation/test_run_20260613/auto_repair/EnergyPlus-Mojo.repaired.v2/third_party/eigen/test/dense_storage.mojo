from main import main, VERIFY_IS_EQUAL
from Eigen.Core import DenseStorage, Dynamic

def dense_storage_copy[T: AnyRegType, Rows: Int, Cols: Int]():
    alias Size: Int = ((Rows == Dynamic or Cols == Dynamic) ? Dynamic : Rows * Cols)
    alias DenseStorageType = DenseStorage[T, Size, Rows, Cols, 0]
    var rows: Int = (Rows == Dynamic) ? 4 : Rows
    var cols: Int = (Cols == Dynamic) ? 3 : Cols
    var size: Int = rows * cols
    var reference = DenseStorageType(size, rows, cols)
    var raw_reference = reference.data()
    for i in range(size):
        raw_reference[i] = T(i)
    var copied_reference = DenseStorageType(reference)
    var raw_copied_reference = copied_reference.data()
    for i in range(size):
        VERIFY_IS_EQUAL(raw_reference[i], raw_copied_reference[i])

def dense_storage_assignment[T: AnyRegType, Rows: Int, Cols: Int]():
    alias Size: Int = ((Rows == Dynamic or Cols == Dynamic) ? Dynamic : Rows * Cols)
    alias DenseStorageType = DenseStorage[T, Size, Rows, Cols, 0]
    var rows: Int = (Rows == Dynamic) ? 4 : Rows
    var cols: Int = (Cols == Dynamic) ? 3 : Cols
    var size: Int = rows * cols
    var reference = DenseStorageType(size, rows, cols)
    var raw_reference = reference.data()
    for i in range(size):
        raw_reference[i] = T(i)
    var copied_reference = DenseStorageType()
    copied_reference = reference
    var raw_copied_reference = copied_reference.data()
    for i in range(size):
        VERIFY_IS_EQUAL(raw_reference[i], raw_copied_reference[i])

def test_dense_storage():
    dense_storage_copy[Int, Dynamic, Dynamic]()
    dense_storage_copy[Int, Dynamic, 3]()
    dense_storage_copy[Int, 4, Dynamic]()
    dense_storage_copy[Int, 4, 3]()
    dense_storage_copy[Float64, Dynamic, Dynamic]()
    dense_storage_copy[Float64, Dynamic, 3]()
    dense_storage_copy[Float64, 4, Dynamic]()
    dense_storage_copy[Float64, 4, 3]()
    dense_storage_assignment[Int, Dynamic, Dynamic]()
    dense_storage_assignment[Int, Dynamic, 3]()
    dense_storage_assignment[Int, 4, Dynamic]()
    dense_storage_assignment[Int, 4, 3]()
    dense_storage_assignment[Float64, Dynamic, Dynamic]()
    dense_storage_assignment[Float64, Dynamic, 3]()
    dense_storage_assignment[Float64, 4, Dynamic]()
    dense_storage_assignment[Float64, 4, 3]()