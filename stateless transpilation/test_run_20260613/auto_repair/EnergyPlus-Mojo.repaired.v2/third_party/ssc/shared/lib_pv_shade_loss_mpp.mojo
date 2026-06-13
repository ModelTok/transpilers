/**
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
*/
/* Originally from: lib_pv_shade_loss_mpp.cpp */

from builtin import malloc, free, memcpy, Pointer
from math import log, pow, round
from lib_miniz import tinfl_decompress_mem_to_mem, TINFL_FLAG_PARSE_ZLIB_HEADER, TINFL_DECOMPRESS_MEM_TO_MEM_FAILED

extern var pCmp_data: Pointer[UInt8]

let SHADE_DB_DEBUG: Bool = False

alias uint8 = UInt8
alias uint16 = UInt16
alias uint = UInt32

class ShadeDB8_mpp:
    enum db_type:
        VMPP = 0
        IMPP = 1

    var p_vmpp: Pointer[UInt8]
    var p_impp: Pointer[UInt8]
    var p_vmpp_uint8_size: Int
    var p_impp_uint8_size: Int
    var p_compressed_size: Int
    var p_warning_msg: String
    var p_error_msg: String

    def __init__(inout self):
        self.p_vmpp = Pointer[UInt8](0)
        self.p_impp = Pointer[UInt8](0)
        self.p_warning_msg = ""
        self.p_error_msg = ""
        self.p_vmpp_uint8_size = 0
        self.p_impp_uint8_size = 0
        self.p_compressed_size = 0

    def __del__(owned self):
        if self.p_vmpp.is_valid():
            free(self.p_vmpp)
        if self.p_impp.is_valid():
            free(self.p_impp)

    def vmpp(borrowed self, ndx: Int) -> Int16:
        return self.get_vmpp(ndx)

    def impp(borrowed self, ndx: Int) -> Int16:
        return self.get_impp(ndx)

    def get_vector(borrowed self, N: Int, d: Int, t: Int, S: Int, DB_TYPE: db_type) -> List[Double]:
        var ret_vec = List[Double]()
        var length: Int = 0
        if DB_TYPE == self.db_type.VMPP:
            length = 8
        elif DB_TYPE == self.db_type.IMPP:
            length = 8
        if length == 0:
            return ret_vec
        var ndx: Int
        var tmp_ndx = Pointer[Int](addressof(ndx))
        if self.get_index(N, d, t, S, DB_TYPE, tmp_ndx):
            for i in range(length):
                if DB_TYPE == self.db_type.VMPP:
                    ret_vec.append(Double(self.get_vmpp(ndx + i)) / 1000.0)
                elif DB_TYPE == self.db_type.IMPP:
                    ret_vec.append(Double(self.get_impp(ndx + i)) / 1000.0)
        return ret_vec

    def n_choose_k(borrowed self, n: Int, k: Int) -> Int:
        if k > n:
            return 0
        if k * 2 > n:
            k = n - k
        if k == 0:
            return 1
        var result: Int = n
        for i in range(2, k + 1):
            result = result * (n - i + 1)
            result = result // i
        return result

    def get_index(borrowed self, N: Int, d: Int, t: Int, S: Int, DB_TYPE: db_type, inout ret_ndx: Int) -> Bool:
        var ret_val: Bool = False
        var length: Int = 0
        var iN: Int = 0
        var id: Int = 0
        var it: Int = 0
        if (N < 1) or (N > 8):
            return ret_val
        if (d < 1) or (d > 10):
            return ret_val
        if (t < 1) or (t > 10):
            return ret_val
        var size_s: Int = self.n_choose_k(t + N - 1, t)
        if (S < 1) or (S > size_s):
            return ret_val
        if DB_TYPE == self.db_type.VMPP:
            length = 8
        elif DB_TYPE == self.db_type.IMPP:
            length = 8
        if length == 0:
            return ret_val
        ret_ndx = 0
        var t_ub: Int = 11
        var d_ub: Int = 10
        loop:
            iN = iN + 1
            d_ub = 10 if iN == N else 10  # Note: original: d_ub = ((iN == N) ? d : 10);
            if iN == N:
                d_ub = d
            id = 0
            loop:
                id = id + 1
                if (iN == N) and (id == d):
                    t_ub = t
                else:
                    t_ub = 11
                for it in range(1, t_ub):
                    size_s = self.n_choose_k(it + iN - 1, it)
                    ret_ndx = ret_ndx + size_s * length
                if id < d_ub:
                    continue
                break
            if iN < N:
                continue
            break
        ret_ndx = ret_ndx + (S - 1) * length
        ret_val = True
        return ret_val

    def init(inout self):
        self.p_error_msg = ""
        self.p_warning_msg = ""
        self.p_vmpp_uint8_size = 12091680
        self.p_impp_uint8_size = 12091680
        self.p_vmpp = malloc[UInt8](self.p_vmpp_uint8_size).to_pointer()
        self.p_impp = malloc[UInt8](self.p_impp_uint8_size).to_pointer()
        self.p_compressed_size = 3133517
        self.decompress_file_to_uint8()

    def decompress_file_to_uint8(inout self) -> Bool:
        var status: Int
        var pTmp_data: Pointer[UInt8]
        var mem_size: Int = self.p_vmpp_uint8_size + self.p_impp_uint8_size
        pTmp_data = malloc[UInt8](mem_size).to_pointer()
        status = tinfl_decompress_mem_to_mem(pTmp_data, mem_size, pCmp_data, self.p_compressed_size, TINFL_FLAG_PARSE_ZLIB_HEADER)
        memcpy(self.p_vmpp, pTmp_data, self.p_vmpp_uint8_size)
        memcpy(self.p_impp, pTmp_data + self.p_vmpp_uint8_size, self.p_impp_uint8_size)
        free(pTmp_data)
        if status == TINFL_DECOMPRESS_MEM_TO_MEM_FAILED:
            var outm: String = ""
            outm += "tinfl_decompress_mem_to_mem() failed with status "
            outm += String(status)
            self.p_error_msg = outm
            return False  # EXIT_FAILURE equivalent
        return True

    def get_vmpp(borrowed self, i: Int) -> Int16:
        if i < 6045840:
            return Int16((Int(self.p_vmpp[2 * i + 1]) << 8) | Int(self.p_vmpp[2 * i]))
        else:
            return -1

    def get_impp(borrowed self, i: Int) -> Int16:
        if i < 6045840:
            return Int16((Int(self.p_impp[2 * i + 1]) << 8) | Int(self.p_impp[2 * i]))
        else:
            return -1

    def get_shade_loss(inout self, inout gpoa: Double, inout dpoa: Double, inout shade_frac: List[Double], use_pv_cell_temp: Bool = False, pv_cell_temp: Double = 0.0, mods_per_str: Int = 0, str_vmp_stc: Double = 0.0, mppt_lo: Double = 0.0, mppt_hi: Double = 0.0) -> Double:
        var shade_loss: Double = 0.0
        var num_strings: Int = len(shade_frac)
        if dpoa > gpoa:
            dpoa = gpoa
        if num_strings > 0:
            shade_frac.sort(fn(a: Double, b: Double) -> Bool: return a > b)
            for i in range(num_strings):
                shade_frac[i] /= 10.0
            var str_shade = List[Int]()
            for i in range(num_strings):
                str_shade.append(Int(round(shade_frac[i])))
            var s_max: Int = -1
            var s_sum: Int = 0
            for i in range(num_strings):
                if str_shade[i] > s_max:
                    s_max = str_shade[i]
                s_sum += str_shade[i]
            if (s_sum > 0) and (gpoa > 0):
                var diffuse_frac: Int = Int(round(dpoa * 10.0 / gpoa))
                if diffuse_frac < 1:
                    diffuse_frac = 1
                var counter: Int = 1
                var found: Bool = False
                if num_strings > 1:
                    counter = 0
                    for i2 in range(s_max + 1):
                        if num_strings == 2:
                            counter = counter + 1
                            var cur_case = List[Int]()
                            cur_case.append(s_max)
                            cur_case.append(i2)
                            if str_shade == cur_case:
                                found = True
                        else:
                            for i3 in range(i2 + 1):
                                if num_strings == 3:
                                    counter = counter + 1
                                    var cur_case = List[Int]()
                                    cur_case.append(s_max)
                                    cur_case.append(i2)
                                    cur_case.append(i3)
                                    if str_shade == cur_case:
                                        found = True
                                else:
                                    for i4 in range(i3 + 1):
                                        if num_strings == 4:
                                            counter = counter + 1
                                            var cur_case = List[Int]()
                                            cur_case.append(s_max)
                                            cur_case.append(i2)
                                            cur_case.append(i3)
                                            cur_case.append(i4)
                                            if str_shade == cur_case:
                                                found = True
                                        else:
                                            for i5 in range(i4 + 1):
                                                if num_strings == 5:
                                                    counter = counter + 1
                                                    var cur_case = List[Int]()
                                                    cur_case.append(s_max)
                                                    cur_case.append(i2)
                                                    cur_case.append(i3)
                                                    cur_case.append(i4)
                                                    cur_case.append(i5)
                                                    if str_shade == cur_case:
                                                        found = True
                                                else:
                                                    for i6 in range(i5 + 1):
                                                        if num_strings == 6:
                                                            counter = counter + 1
                                                            var cur_case = List[Int]()
                                                            cur_case.append(s_max)
                                                            cur_case.append(i2)
                                                            cur_case.append(i3)
                                                            cur_case.append(i4)
                                                            cur_case.append(i5)
                                                            cur_case.append(i6)
                                                            if str_shade == cur_case:
                                                                found = True
                                                        else:
                                                            for i7 in range(i6 + 1):
                                                                if num_strings == 7:
                                                                    counter = counter + 1
                                                                    var cur_case = List[Int]()
                                                                    cur_case.append(s_max)
                                                                    cur_case.append(i2)
                                                                    cur_case.append(i3)
                                                                    cur_case.append(i4)
                                                                    cur_case.append(i5)
                                                                    cur_case.append(i6)
                                                                    cur_case.append(i7)
                                                                    if str_shade == cur_case:
                                                                        found = True
                                                                else:
                                                                    for i8 in range(i7 + 1):
                                                                        if num_strings == 8:
                                                                            counter = counter + 1
                                                                            var cur_case = List[Int]()
                                                                            cur_case.append(s_max)
                                                                            cur_case.append(i2)
                                                                            cur_case.append(i3)
                                                                            cur_case.append(i4)
                                                                            cur_case.append(i5)
                                                                            cur_case.append(i6)
                                                                            cur_case.append(i7)
                                                                            cur_case.append(i8)
                                                                            if str_shade == cur_case:
                                                                                found = True
                                                                        else:
                                                                            counter = 0
                                                                    if found:
                                                                        break
                                                                if found:
                                                                    break
                                                            if found:
                                                                break
                                                        if found:
                                                            break
                                                    if found:
                                                        break
                                                if found:
                                                    break
                                            if found:
                                                break
                                        if found:
                                            break
                                    if found:
                                        break
                                if found:
                                    break
                            if found:
                                break
                        if found:
                            break
                var vmpp = self.get_vector(num_strings, diffuse_frac, s_max, counter, self.db_type.VMPP)
                var impp = self.get_vector(num_strings, diffuse_frac, s_max, counter, self.db_type.IMPP)
                var p_max_frac: Double = 0.0
                var p_max_ind: Int = 0
                var pmp_fracs = List[Double]()
                for i in range(min(len(vmpp), len(impp))):
                    var pmp: Double = vmpp[i] * impp[i]
                    if use_pv_cell_temp:
                        pmp_fracs.append(pmp)
                    if pmp > p_max_frac:
                        p_max_frac = pmp
                        if use_pv_cell_temp:
                            p_max_ind = i
                if use_pv_cell_temp:
                    # /*
                    # %Try scaling the voltages using the Sandia model.Taking numbers from
                    # %their database for the Yingli YL230.It's a similar module (mc-si,60 cell, etc)to the
                    # %Trina 250 PA05 which the database was build from.But user may need more
                    # %input into this!!!
                    # */
                    var n: Double = 1.263
                    var BetaVmp: Double = -0.137 * Double(mods_per_str)
                    var Ns: Double = 60.0 * Double(mods_per_str)
                    var C2: Double = -0.05871
                    var C3: Double = 8.35334
                    var k: Double = 1.38066e-23
                    var q: Double = 1.60218e-19
                    var Tc: Double = pv_cell_temp
                    var deltaTc: Double = n * k * (Tc + 273.15) / q
                    var VMaxSTCStrUnshaded: Double = str_vmp_stc
                    var scale_g: Double = gpoa / 1000.0
                    var TcVmps = List[Double]()
                    for i in range(len(vmpp)):
                        TcVmps.append(vmpp[i] * VMaxSTCStrUnshaded + C2 * Ns * deltaTc * log(scale_g) + C3 * Ns * pow((deltaTc * log(scale_g)), 2.0) + BetaVmp * (Tc - 25.0))
                    # /*
                    # %Now want to choose the point with a V in range and highest power
                    # %First, figure out which max power point gives lowest loss
                    # */
                    var Veemax: Double = TcVmps[p_max_ind]
                    if (Veemax >= mppt_lo) and (Veemax <= mppt_hi):
                        shade_loss = 1.0 - p_max_frac
                    else:
                        var p_frac: Double = 0.0
                        for i in range(min(len(TcVmps), len(pmp_fracs))):
                            if (TcVmps[i] >= mppt_lo) and (TcVmps[i] <= mppt_hi):
                                if pmp_fracs[i] > p_frac:
                                    p_frac = pmp_fracs[i]
                        shade_loss = 1.0 - p_frac
                    if SHADE_DB_DEBUG:
                        var outm: String = ""
                        outm += "\ni,Vmpp,Impp,pmp_fracs,TcVmps\n"
                        for i in range(min(len(TcVmps), len(pmp_fracs))):
                            outm += String(i) + "," + String(vmpp[i]) + "," + String(impp[i]) + "," + String(pmp_fracs[i]) + "," + String(TcVmps[i]) + "\n"
                        outm += "\nshade loss = " + String(shade_loss) + "\n"
                        self.p_warning_msg = outm
                else:
                    shade_loss = 1.0 - p_max_frac
            else:
                if s_sum <= 0:
                    shade_loss = 0.0
                else:
                    shade_loss = 0.0
                if SHADE_DB_DEBUG:
                    var outm: String = ""
                    outm += "\nglobal = " + String(gpoa) + " and shade fraction = " + String(s_sum) + " and shade loss = " + String(shade_loss) + "\n"
                    self.p_warning_msg = outm
        return shade_loss