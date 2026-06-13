"""
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

from tcskernel import tcskernel
from core import compute_module

struct tcKernel(tcskernel):
    # nested dataitem struct
    struct dataitem:
        var sval: String
        var dval: Float64

        def __init__(s: String):
            self.sval = s
            self.dval = 0.0

        def __init__(s: String):
            self.sval = s
            self.dval = 0.0

        def __init__(d: Float64):
            self.sval = ""
            self.dval = d

    # nested dataset struct
    struct dataset:
        var u: unit
        var uidx: Int
        var idx: Int
        var name: String
        var units: String
        var group: String
        var type: Int
        var values: List[dataitem]

    # private members
    var m_storeArrMatData: Bool
    var m_storeAllParameters: Bool
    var m_results: List[dataset]
    var m_start: Float64
    var m_end: Float64
    var m_step: Float64
    var m_dataIndex: Int

    def __init__(prov: tcstypeprovider):
        # call base constructor
        self.__init__tcskernel(prov)
        self.m_storeArrMatData = False
        self.m_storeAllParameters = False
        self.m_start = 0.0
        self.m_end = 0.0
        self.m_step = 0.0
        self.m_results = List[dataset]()
        self.m_dataIndex = 0

    def __del__():

    def message(self, text: String, msgtype: Int):
        var ssctype: Int = SSC_ERROR
        if msgtype == TCS_WARNING:
            ssctype = SSC_WARNING
        elif msgtype == TCS_NOTICE:
            ssctype = SSC_NOTICE
        compute_module.log(text, ssctype, Float64(tcskernel.current_time()) / 8760.0)

    def progress(self, percent: Float32, status: String) -> Bool:
        return compute_module.update(status, percent)

    def converged(self, time: Float64) -> Bool:
        if self.m_step != 0.0:
            var istep: Int = Int((time - self.m_start) / self.m_step)
            var nstep: Int = Int((self.m_end - self.m_start) / self.m_step)
            var nnsteps: Int = nstep // 200
            if nnsteps == 0:
                nnsteps = 1
            if istep % nnsteps == 0:
                var percent: Float64 = 100.0 * (Float64(istep) / Float64(nstep))
                if not compute_module.update("", Float32(percent), Float32(istep)):
                    return False
        var buf: String = ""
        var ibuf: String
        var j: Int
        var k: Int
        for i in range(len(self.m_results)):
            var v: tcsvalue = self.m_results[i].u.values[self.m_results[i].idx]
            if self.m_results[i].type == TCS_NUMBER:
                self.m_results[i].values[self.m_dataIndex].dval = v.data.value
            elif self.m_results[i].type == TCS_STRING:
                self.m_results[i].values[self.m_dataIndex].sval = v.data.cstr
            elif self.m_results[i].type == TCS_ARRAY:
                if self.m_storeArrMatData:
                    buf = "[ "
                    for j in range(v.data.array.length):
                        ibuf = f"{v.data.array.values[j]}{',' if j < v.data.array.length - 1 else ' '}"
                        buf += ibuf
                    buf += "]"
                    self.m_results[i].values[self.m_dataIndex].sval = buf
            elif self.m_results[i].type == TCS_MATRIX:
                if self.m_storeArrMatData:
                    ibuf = f"{{ {v.data.matrix.nrows}x{v.data.matrix.ncols} "
                    buf = ibuf
                    for j in range(v.data.matrix.nrows):
                        buf += " ["
                        for k in range(v.data.matrix.ncols):
                            ibuf = f"{TCS_MATRIX_INDEX(v, j, k)}{',' if k < v.data.matrix.ncols - 1 else ' '}"
                            buf += ibuf
                        buf += "]"
                    buf += " }"
                    self.m_results[i].values[self.m_dataIndex].sval = buf
        self.m_dataIndex += 1
        return True

    def simulate(self, start: Float64, end: Float64, step: Float64, max_iter: Int = 100) -> Int:
        self.m_start = start
        self.m_end = end
        self.m_step = step
        self.m_dataIndex = 0
        if end <= start or step <= 0:
            return -77
        var nsteps: Int = Int((end - start) / step) + 1
        var ndatasets: Int = 0
        for i in range(len(self.m_units)):
            var vars: tcsvarinfo = self.m_units[i].type.variables
            var idx: Int = 0
            while vars[idx].var_type != TCS_INVALID:
                if is_ssc_array_output(vars[idx].name) or self.m_storeAllParameters:
                    ndatasets += 1
                idx += 1
        if ndatasets < 1:
            return -88
        self.m_results.resize(ndatasets)
        var idataset: Int = 0
        for i in range(len(self.m_units)):
            var vars: tcsvarinfo = self.m_units[i].type.variables
            var idx: Int = 0
            while vars[idx].var_type != TCS_INVALID:
                if is_ssc_array_output(vars[idx].name) or self.m_storeAllParameters:
                    var d: dataset = self.m_results[idataset]
                    idataset += 1
                    var buf: String = f"{i}"
                    d.u = self.m_units[i]
                    d.uidx = i
                    d.idx = idx
                    d.group = "Unit " + buf + " (" + String(self.m_units[i].type.name) + ")"  # + ": " + m_units[i].name;
                    d.name = vars[idx].name
                    d.units = vars[idx].units
                    d.type = vars[idx].data_type
                    d.values.resize(nsteps, dataitem(0.0))
                idx += 1
        tcskernel.set_max_iterations(max_iter, True)
        return tcskernel.simulate(self, start, end, step)

    def set_store_array_matrix_data(self, b: Bool):
        self.m_storeArrMatData = b

    def set_store_all_parameters(self, b: Bool):
        self.m_storeAllParameters = b

    def get_results(self, idx: Int) -> dataset?:
        if idx >= len(self.m_results):
            return None
        else:
            return self.m_results[idx]

    def set_unit_value_ssc_string(id: Int, name: String):
        set_unit_value(id, name, as_string(name))

    def set_unit_value_ssc_string(id: Int, tcs_name: String, ssc_name: String):
        set_unit_value(id, tcs_name, as_string(ssc_name))

    def set_unit_value_ssc_double(id: Int, name: String):
        set_unit_value(id, name, as_double(name))

    def set_unit_value_ssc_double(id: Int, tcs_name: String, ssc_name: String):
        set_unit_value(id, tcs_name, as_double(ssc_name))

    def set_unit_value_ssc_double(id: Int, name: String, x: Float64):
        set_unit_value(id, name, x)

    def set_unit_value_ssc_array(id: Int, name: String):
        var len: Int
        var p: Pointer[ssc_number_t] = as_array(name, &len)
        var pt: List[Float64] = List[Float64](len)
        for i in range(len):
            pt[i] = Float64(p[i])
        set_unit_value(id, name, pt.data, len)
        return

    def set_unit_value_ssc_array(id: Int, tcs_name: String, ssc_name: String):
        var len: Int
        var p: Pointer[ssc_number_t] = as_array(ssc_name, &len)
        var pt: List[Float64] = List[Float64](len)
        for i in range(len):
            pt[i] = Float64(p[i])
        set_unit_value(id, tcs_name, pt.data, len)
        return

    def set_unit_value_ssc_matrix(id: Int, name: String):
        var nr: Int
        var nc: Int
        var p: Pointer[ssc_number_t] = as_matrix(name, &nr, &nc)
        var total: Int = nr * nc
        var pt: List[Float64] = List[Float64](total)
        for i in range(total):
            pt[i] = Float64(p[i])
        set_unit_value(id, name, pt.data, nr, nc)
        return

    def set_unit_value_ssc_matrix(id: Int, tcs_name: String, ssc_name: String):
        var nr: Int
        var nc: Int
        var p: Pointer[ssc_number_t] = as_matrix(ssc_name, &nr, &nc)
        var total: Int = nr * nc
        var pt: List[Float64] = List[Float64](total)
        for i in range(total):
            pt[i] = Float64(p[i])
        set_unit_value(id, tcs_name, pt.data, nr, nc)
        return

    def set_unit_value_ssc_matrix_transpose(id: Int, name: String):
        var nr: Int
        var nc: Int
        var p: Pointer[ssc_number_t] = as_matrix(name, &nr, &nc)
        var total: Int = nr * nc
        var pt: List[Float64] = List[Float64](total)
        var i: Int = 0
        for c in range(nc):
            for r in range(nr):
                pt[i] = Float64(p[r * nc + c])
                i += 1
        set_unit_value(id, name, pt.data, nc, nr)
        return

    def set_unit_value_ssc_matrix_transpose(id: Int, tcs_name: String, ssc_name: String):
        var nr: Int
        var nc: Int
        var p: Pointer[ssc_number_t] = as_matrix(ssc_name, &nr, &nc)
        var total: Int = nr * nc
        var pt: List[Float64] = List[Float64](total)
        var i: Int = 0
        for c in range(nc):
            for r in range(nr):
                pt[i] = Float64(p[r * nc + c])
                i += 1
        set_unit_value(id, tcs_name, pt.data, nc, nr)
        return

    def set_output_array(output_name: String, len: Int, scaling: Float64 = 1.0) -> Bool:
        return set_output_array(output_name, output_name, len, scaling)

    def set_output_array(ssc_output_name: String, tcs_output_name: String, len: Int, scaling: Float64 = 1.0) -> Bool:
        var idx: Int = 0
        var output_array: Pointer[ssc_number_t] = allocate(ssc_output_name, len)
        var d: dataset? = get_results(idx)
        while d:
            if d.type == TCS_NUMBER and d.name == tcs_output_name and len(d.values) == len:
                for i in range(len):
                    output_array[i] = ssc_number_t(d.values[i].dval * scaling)
                return True
            idx += 1
            d = get_results(idx)
        return False

    def set_all_output_arrays() -> Bool:
        var idx: Int = 0
        var d: dataset? = get_results(idx)
        while d:
            if d.type == TCS_NUMBER and is_ssc_array_output(d.name):
                var output_array: Pointer[ssc_number_t] = allocate(d.name, len(d.values))
                for i in range(len(d.values)):
                    output_array[i] = ssc_number_t(d.values[i].dval)
            idx += 1
            d = get_results(idx)
        return True