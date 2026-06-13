from memory import Pointer, allocate, free
from math import log, pow, round
from builtin import Int, UInt8, UInt16, UInt, Bool, Float64

# Import the miniz and binary data modules
from lib_miniz import tinfl_decompress_mem_to_mem, TINFL_FLAG_PARSE_ZLIB_HEADER, TINFL_DECOMPRESS_MEM_TO_MEM_FAILED
from DB8_vmpp_impp_uint8_bin import pCmp_data

type db_type = Int
let VMPP: db_type = 0
let IMPP: db_type = 1

@value
struct ShadeDB8_mpp:
    var p_vmpp: Pointer[UInt8] = Pointer[UInt8]()
    var p_impp: Pointer[UInt8] = Pointer[UInt8]()
    var p_warning_msg: String = ""
    var p_error_msg: String = ""
    var p_vmpp_uint8_size: Int = 0
    var p_impp_uint8_size: Int = 0
    var p_compressed_size: Int = 0

    def __init__(inout self):
        self.p_vmpp = Pointer[UInt8]()
        self.p_impp = Pointer[UInt8]()

    def __del__(owned self):
        if self.p_vmpp:
            self.p_vmpp.free()
        if self.p_impp:
            self.p_impp.free()

    def init(inout self):
        self.p_error_msg = ""
        self.p_warning_msg = ""
        self.p_vmpp_uint8_size = 12091680
        self.p_impp_uint8_size = 12091680
        self.p_vmpp = allocate[UInt8](self.p_vmpp_uint8_size)
        self.p_impp = allocate[UInt8](self.p_impp_uint8_size)
        self.p_compressed_size = 3133517
        self.decompress_file_to_uint8()

    def get_vmpp(self, i: Int) -> Int16:
        if i >= 0 and i < 6045840:
            return Int16((Int(self.p_vmpp[2 * i + 1]) << 8) | Int(self.p_vmpp[2 * i]))
        else:
            return -1

    def get_impp(self, i: Int) -> Int16:
        if i >= 0 and i < 6045840:
            return Int16((Int(self.p_impp[2 * i + 1]) << 8) | Int(self.p_impp[2 * i]))
        else:
            return -1

    def n_choose_k(self, n: Int, k: Int) -> Int:
        if k > n:
            return 0
        if k * 2 > n:
            k = n - k
        if k == 0:
            return 1
        var result: Int = n
        for i in range(2, k + 1):
            result *= (n - i + 1)
            result //= i
        return result

    def get_index(self, N: Int, d: Int, t: Int, S: Int, db_type: Int, ret_ndx: Pointer[Int]) -> Bool:
        var ret_val: Bool = False
        var length: Int = 0
        var offset: Int = 0
        var length_t: Int = 10
        var length_d: Int = 10
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
        if db_type == VMPP:
            length = 8
            offset = 0
        elif db_type == IMPP:
            length = 8
            offset = self.p_vmpp_uint8_size // 2
        else:
            length = 0
        if length == 0:
            return ret_val
        ret_ndx[0] = 0
        var t_ub: Int = 11
        var d_ub: Int = 10
        # loop expects do-while -> while True with break condition at end
        while True:
            iN += 1
            d_ub = d if iN == N else 10
            id = 0
            while True:
                id += 1
                t_ub = t if (iN == N and id == d) else 11
                for it in range(1, t_ub):
                    size_s = self.n_choose_k(it + iN - 1, it)
                    ret_ndx[0] += size_s * length
                if id >= d_ub:
                    break
            if iN >= N:
                break
        ret_ndx[0] += (S - 1) * length
        ret_val = True
        return ret_val

    def get_vector(self, N: Int, d: Int, t: Int, S: Int, db_type: Int) -> List[Float64]:
        var ret_vec: List[Float64] = List[Float64]()
        var length: Int = 0
        if db_type == VMPP:
            length = 8
        elif db_type == IMPP:
            length = 8
        if length == 0:
            return ret_vec
        var ndx: Int = 0
        var ndx_ptr: Pointer[Int] = Pointer[Int](address_of(ndx))
        if self.get_index(N, d, t, S, db_type, ndx_ptr):
            for i in range(length):
                if db_type == VMPP:
                    ret_vec.append(Float64(self.get_vmpp(ndx + i)) / 1000.0)
                elif db_type == IMPP:
                    ret_vec.append(Float64(self.get_impp(ndx + i)) / 1000.0)
        return ret_vec

    def decompress_file_to_uint8(self) -> Bool:
        var mem_size: Int = self.p_vmpp_uint8_size + self.p_impp_uint8_size
        var pTmp_data: Pointer[UInt8] = allocate[UInt8](mem_size)
        var status: Int = tinfl_decompress_mem_to_mem(pTmp_data, mem_size, pCmp_data, self.p_compressed_size, TINFL_FLAG_PARSE_ZLIB_HEADER)
        # memcpy: copy pTmp_data to self.p_vmpp
        for i in range(self.p_vmpp_uint8_size):
            self.p_vmpp[i] = pTmp_data[i]
        # memcpy: copy pTmp_data + p_vmpp_uint8_size to self.p_impp
        for i in range(self.p_impp_uint8_size):
            self.p_impp[i] = pTmp_data[self.p_vmpp_uint8_size + i]
        pTmp_data.free()
        if status == TINFL_DECOMPRESS_MEM_TO_MEM_FAILED:
            var outm: String = "tinfl_decompress_mem_to_mem() failed with status " + String(status)
            self.p_error_msg = outm
            return False
        return True

    def get_shade_loss(self, gpoa: Float64, dpoa: Float64, shade_frac: List[Float64], use_pv_cell_temp: Bool = False, pv_cell_temp: Float64 = 0.0, mods_per_str: Int = 0, str_vmp_stc: Float64 = 0.0, mppt_lo: Float64 = 0.0, mppt_hi: Float64 = 0.0) -> Float64:
        var shade_loss: Float64 = 0.0
        var num_strings: Int = shade_frac.size
        if dpoa > gpoa:
            dpoa = gpoa
        if num_strings > 0:
            # sort descending
            var sorted_shade: List[Float64] = List[Float64](shade_frac)  # copy
            sorted_shade.sort(descending=True)
            for i in range(num_strings):
                sorted_shade[i] /= 10.0
            # convert to int
            var str_shade: List[Int] = List[Int]()
            for i in range(num_strings):
                str_shade.append(Int(round(sorted_shade[i])))
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
                            counter += 1
                            var cur_case: List[Int] = List[Int]([s_max, i2])
                            if str_shade == cur_case:
                                found = True
                        else:
                            for i3 in range(i2 + 1):
                                if num_strings == 3:
                                    counter += 1
                                    var cur_case: List[Int] = List[Int]([s_max, i2, i3])
                                    if str_shade == cur_case:
                                        found = True
                                else:
                                    for i4 in range(i3 + 1):
                                        if num_strings == 4:
                                            counter += 1
                                            var cur_case: List[Int] = List[Int]([s_max, i2, i3, i4])
                                            if str_shade == cur_case:
                                                found = True
                                        else:
                                            for i5 in range(i4 + 1):
                                                if num_strings == 5:
                                                    counter += 1
                                                    var cur_case: List[Int] = List[Int]([s_max, i2, i3, i4, i5])
                                                    if str_shade == cur_case:
                                                        found = True
                                                else:
                                                    for i6 in range(i5 + 1):
                                                        if num_strings == 6:
                                                            counter += 1
                                                            var cur_case: List[Int] = List[Int]([s_max, i2, i3, i4, i5, i6])
                                                            if str_shade == cur_case:
                                                                found = True
                                                        else:
                                                            for i7 in range(i6 + 1):
                                                                if num_strings == 7:
                                                                    counter += 1
                                                                    var cur_case: List[Int] = List[Int]([s_max, i2, i3, i4, i5, i6, i7])
                                                                    if str_shade == cur_case:
                                                                        found = True
                                                                else:
                                                                    for i8 in range(i7 + 1):
                                                                        if num_strings == 8:
                                                                            counter += 1
                                                                            var cur_case: List[Int] = List[Int]([s_max, i2, i3, i4, i5, i6, i7, i8])
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
                var vmpp: List[Float64] = self.get_vector(num_strings, diffuse_frac, s_max, counter, VMPP)
                var impp: List[Float64] = self.get_vector(num_strings, diffuse_frac, s_max, counter, IMPP)
                var p_max_frac: Float64 = 0.0
                var p_max_ind: Int = 0
                var pmp_fracs: List[Float64] = List[Float64]()
                for i in range(min(vmpp.size, impp.size)):
                    var pmp: Float64 = vmpp[i] * impp[i]
                    if use_pv_cell_temp:
                        pmp_fracs.append(pmp)
                    if pmp > p_max_frac:
                        p_max_frac = pmp
                        if use_pv_cell_temp:
                            p_max_ind = i
                if use_pv_cell_temp:
                    # comment block preserved
                    var n: Float64 = 1.263
                    var BetaVmp: Float64 = -0.137 * Float64(mods_per_str)
                    var Ns: Float64 = 60.0 * Float64(mods_per_str)
                    var C2: Float64 = -0.05871
                    var C3: Float64 = 8.35334
                    var k: Float64 = 1.38066E-23
                    var q: Float64 = 1.60218E-19
                    var Tc: Float64 = pv_cell_temp
                    var deltaTc: Float64 = n * k * (Tc + 273.15) / q
                    var VMaxSTCStrUnshaded: Float64 = str_vmp_stc
                    var scale_g: Float64 = gpoa / 1000.0
                    var TcVmpMax: Float64 = vmpp[p_max_ind] * VMaxSTCStrUnshaded + C2 * Ns * deltaTc * log(scale_g) + C3 * Ns * pow((deltaTc * log(scale_g)), 2) + BetaVmp * (Tc - 25)
                    var TcVmpScale: Float64 = TcVmpMax / vmpp[p_max_ind] / VMaxSTCStrUnshaded
                    var TcVmps: List[Float64] = List[Float64]()
                    for i in range(vmpp.size):
                        TcVmps.append(vmpp[i] * VMaxSTCStrUnshaded + C2 * Ns * deltaTc * log(scale_g) + C3 * Ns * pow((deltaTc * log(scale_g)), 2) + BetaVmp * (Tc - 25))
                    var Veemax: Float64 = TcVmps[p_max_ind]
                    if (Veemax >= mppt_lo) and (Veemax <= mppt_hi):
                        shade_loss = 1.0 - p_max_frac
                    else:
                        var p_frac: Float64 = 0.0
                        for i in range(min(TcVmps.size, pmp_fracs.size)):
                            if (TcVmps[i] >= mppt_lo) and (TcVmps[i] <= mppt_hi):
                                if pmp_fracs[i] > p_frac:
                                    p_frac = pmp_fracs[i]
                        shade_loss = 1.0 - p_frac
                else:
                    shade_loss = 1.0 - p_max_frac
            else:
                if s_sum <= 0:
                    shade_loss = 0.0
                else:
                    shade_loss = 0.0
        return shade_loss

    def vmpp(self, ndx: Int) -> Int16:
        return self.get_vmpp(ndx)

    def impp(self, ndx: Int) -> Int16:
        return self.get_impp(ndx)

    def get_warning(self) -> String:
        return self.p_warning_msg

    def get_error(self) -> String:
        return self.p_error_msg