// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
from core import (
    compute_module,
    add_var_info,
    as_double,
    as_matrix,
    assign,
    var_info_invalid,
    SSC_INPUT,
    SSC_NUMBER,
    SSC_MATRIX,
    SSC_OUTPUT,
    ssc_number_t,
    util,
    var_info,
)
from htf_props import HTFProperties

static var _cm_vtab_user_htf_comparison: List[var_info] = List[
    var_info(
        vartype=SSC_INPUT,
        datatype=SSC_NUMBER,
        name="HTF_code1",
        label="HTF fluid code: Fluid 1",
        units="-",
        meta="",
        group="",
        required_if="*",
        constraints="",
        ui_hints="",
    ),
    var_info(
        vartype=SSC_INPUT,
        datatype=SSC_MATRIX,
        name="fl_props1",
        label="User defined field fluid property data, Fluid 1",
        units="-",
        meta="7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows",
        group="",
        required_if="*",
        constraints="",
        ui_hints="",
    ),
    var_info(
        vartype=SSC_INPUT,
        datatype=SSC_NUMBER,
        name="HTF_code2",
        label="HTF fluid code: Fluid 2",
        units="-",
        meta="",
        group="",
        required_if="*",
        constraints="",
        ui_hints="",
    ),
    var_info(
        vartype=SSC_INPUT,
        datatype=SSC_MATRIX,
        name="fl_props2",
        label="User defined field fluid property data, Fluid 2",
        units="-",
        meta="7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows",
        group="",
        required_if="*",
        constraints="",
        ui_hints="",
    ),
    var_info(
        vartype=SSC_OUTPUT,
        datatype=SSC_NUMBER,
        name="are_equal",
        label="1: Input tables are equal, 0: not equal",
        units="-",
        meta="",
        group="",
        required_if="*",
        constraints="",
        ui_hints="",
    ),
    var_info_invalid,
]

class cm_user_htf_comparison(compute_module):
    def __init__(self):
        add_var_info(_cm_vtab_user_htf_comparison)

    def exec(self) -> None:
        var htf_code1: Int = Int(as_double("HTF_code1"))
        var htf_code2: Int = Int(as_double("HTF_code2"))
        var htf_user_defined_code: Int = HTFProperties.User_defined
        if htf_code1 != htf_code2:
            assign("are_equal", 0.0)
            return
        if htf_code1 != htf_user_defined_code:
            assign("are_equal", 1.0)
            return
        var htfProps1: HTFProperties = HTFProperties()  // Instance of HTFProperties class for receiver/HX htf
        var nrows: Int = 0
        var ncols: Int = 0
        var fl_props1: util.matrix_t[ssc_number_t] = as_matrix("fl_props1", &nrows, &ncols)
        if fl_props1 != 0 and nrows > 2 and ncols == 7:
            var mat: util.matrix_t[ssc_number_t] = util.matrix_t[ssc_number_t]()
            mat.assign(fl_props1, nrows, ncols)
            var mat_double: util.matrix_t[float64] = util.matrix_t[float64](nrows, ncols)
            for i in range(nrows):
                for j in range(ncols):
                    mat_double[i, j] = float64(mat[i, j])
            if not htfProps1.SetUserDefinedFluid(mat_double):
                assign("are_equal", 0.0)
                return
        else:
            assign("are_equal", 0.0)
            return
        var htfProps2: HTFProperties = HTFProperties()  // Instance of HTFProperties class for receiver/HX htf
        nrows = 0
        ncols = 0
        var fl_props2: util.matrix_t[ssc_number_t] = as_matrix("fl_props2", &nrows, &ncols)
        if fl_props2 != 0 and nrows > 2 and ncols == 7:
            var mat: util.matrix_t[ssc_number_t] = util.matrix_t[ssc_number_t]()
            mat.assign(fl_props2, nrows, ncols)
            var mat_double: util.matrix_t[float64] = util.matrix_t[float64](nrows, ncols)
            for i in range(nrows):
                for j in range(ncols):
                    mat_double[i, j] = float64(mat[i, j])
            if not htfProps2.SetUserDefinedFluid(mat_double):
                assign("are_equal", 0.0)
                return
        else:
            assign("are_equal", 0.0)
            return
        if not htfProps1.equals(&htfProps2):
            assign("are_equal", 0.0)
            return
        else:
            assign("are_equal", 1.0)

def user_htf_comparison() -> compute_module:
    return cm_user_htf_comparison()