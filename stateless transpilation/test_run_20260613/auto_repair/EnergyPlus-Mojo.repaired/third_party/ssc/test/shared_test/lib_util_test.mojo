from testing import test
from ......shared.lib_util import util
from ......sscapi import *

@test
def testFormat_lib_util():
    var str: String = "invalid number of data records (43): must be an integer multiple of 8760"
    assert(util.format("invalid number of data records (%d): must be an integer multiple of 8760", 43) == str)
    str = "query point (301.3, 10.4) is too far out of convex hull of data (dist=4.3)... estimating value from 5 parameter modele at (2.2, 2.1)=2.4"
    assert(util.format("query point (%lg, %lg) is too far out of convex hull of data (dist=%lg)... estimating value from 5 parameter modele at (%lg, %lg)=%lg",
        301.3, 10.4, 4.3, 2.2, 2.1, 2.4) == str)

@test
def SSC_DATARR_test():
    var vd = Array[ssc_var_t](2)
    for i in range(2):
        vd[i] = ssc_var_create()
        ssc_var_set_number(vd[i], 2.0 + i)
    var data = ssc_data_create()
    ssc_data_set_data_array(data, "array", vd.data, 2)
    var n: Int = 0
    var data_arr = ssc_data_get_data_array(data, "array", Pointer[Int].address_of(n))
    ssc_var_size(data_arr, Pointer[Int].address_of(n), Pointer[Int]())
    assert(n == 2)
    for i in range(n):
        var var_val = ssc_var_get_number(ssc_var_get_var_array(data_arr, i))
        assert(var_val == 2.0 + i)
    for i in range(2):
        ssc_var_free(vd[i])
    ssc_data_free(data)

@test
def SSC_DATMAT_test():
    var vd = Array[ssc_var_t](4)
    for i in range(4):
        vd[i] = ssc_var_create()
        ssc_var_set_number(vd[i], 2.0 + i)
    var data = ssc_data_create()
    ssc_data_set_data_matrix(data, "matrix", vd.data, 2, 2)
    var n: Int = 0
    var m: Int = 0
    var data_mat = ssc_data_get_data_matrix(data, "matrix", Pointer[Int].address_of(n), Pointer[Int].address_of(m))
    ssc_var_size(data_mat, Pointer[Int].address_of(n), Pointer[Int].address_of(m))
    assert(n == 2)
    assert(m == 2)
    for i in range(n):
        for j in range(m):
            var var_val = ssc_var_get_number(ssc_var_get_var_matrix(data_mat, i, j))
            assert(var_val == 2.0 + i * n + j)
    for i in range(4):
        ssc_var_free(vd[i])
    ssc_data_free(data)