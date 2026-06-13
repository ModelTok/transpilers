from main import main

alias ColMatrixXd = Matrix[Float64, Dynamic, Dynamic, ColMajor]

def test_is_same_dense():
    var m1 = ColMatrixXd(10, 10)
    var ref_m1 = Ref[ColMatrixXd](m1)
    var const_ref_m1 = Ref[const ColMatrixXd](m1)
    VERIFY(is_same_dense(m1, m1))
    VERIFY(is_same_dense(m1, ref_m1))
    VERIFY(is_same_dense(const_ref_m1, m1))
    VERIFY(is_same_dense(const_ref_m1, ref_m1))
    VERIFY(is_same_dense(m1.block(0, 0, m1.rows(), m1.cols()), m1))
    VERIFY(!is_same_dense(m1.row(0), m1.col(0)))
    var const_ref_m1_row = Ref[const ColMatrixXd](m1.row(1))
    VERIFY(!is_same_dense(m1.row(1), const_ref_m1_row))
    var const_ref_m1_col = Ref[const ColMatrixXd](m1.col(1))
    VERIFY(is_same_dense(m1.col(1), const_ref_m1_col))