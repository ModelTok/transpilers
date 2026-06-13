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
/* from GetShadeLoss.m:
GetShadeLoss(G,D,Tc,ModsPerString,StrShade,VMaxSTCStrUnshaded,VStrMPPT,ShadeDB )
% This searches the shade database and returns the %loss from partial shading
% G is the global POA irradiance, D is the diffuse irradiance, Tc is PV cell
% temperature, StrShade is a vector with each string's shaded fraction (like 24, 55, 12, etc preferably in terms of byp diode substrs),
%gammaPmp is the temperature coefficient of max power,
% reported in datasheet, VMaxSTCStrUnshaded is the unshaded Vmp of the string at STC,
% VStrMPPT is the lower and upper bounds of the inverter's MPPT range, and
% Shade DB is the database of shading losses (created by the DBX scripts at NREL)
*/
from core import *
from lib_util import *
from lib_pv_shade_loss_mpp import *

var _cm_vtab_pv_get_shade_loss_mpp: StaticArray[var_info, 13] = [
/*   VARTYPE           DATATYPE         NAME                           LABEL                                UNITS     META                      GROUP                      REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	var_info(SSC_INPUT, SSC_ARRAY, "global_poa_irrad", "Global POA irradiance", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_INPUT, SSC_ARRAY, "diffuse_irrad", "Diffuse irradiance", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_INPUT, SSC_MATRIX, "str_shade_fracs", "Shading fractions for each string", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_INPUT, SSC_ARRAY, "pv_cell_temp", "PV cell temperature", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_INPUT, SSC_ARRAY, "mods_per_string", "Modules per string", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_INPUT, SSC_ARRAY, "str_vmp_stc", "Unshaded Vmp of the string at STC", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_INPUT, SSC_ARRAY, "v_mppt_low", "Lower bound of inverter MPPT range", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_INPUT, SSC_ARRAY, "v_mppt_high", "Upper bound of inverter MPPT range", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_OUTPUT, SSC_ARRAY, "N", "N", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_OUTPUT, SSC_ARRAY, "d", "d", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_OUTPUT, SSC_ARRAY, "t", "t", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info(SSC_OUTPUT, SSC_ARRAY, "S", "S", "", "", "PV Shade Loss DB", "*", "", ""),
	/*  hourly or sub hourly shading for each string*/
	var_info(SSC_OUTPUT, SSC_ARRAY, "shade_loss", "Shade loss fraction", "", "", "PV Shade Loss DB", "*", "", ""),
	var_info_invalid()
]

class cm_pv_get_shade_loss_mpp(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_pv_get_shade_loss_mpp)

    def exec(self) raises:
        var nrec: size_t
        var count: size_t
        var global_poa_irrad = self.as_array("global_poa_irrad", &nrec)
        var step_per_hour = nrec / 8760
        if step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != nrec:
            raise exec_error("pv_get_shade_loss_mpp", util.format("invalid number of global POA records (%d): must be an integer multiple of 8760", int(nrec)))
        var diffuse_irrad = self.as_array("diffuse_irrad", &count)
        if count != nrec:
            raise exec_error("pv_get_shade_loss_mpp", util.format("invalid number of diffuse records (%d): must be equal to other input array sizes (%d)", int(count), int(nrec)))
        var str_shade_fracs = self.as_matrix("str_shade_fracs")
        count = str_shade_fracs.nrows()
        var num_strings = str_shade_fracs.ncols()
        if count != nrec:
            raise exec_error("pv_get_shade_loss_mpp", util.format("invalid number of mocules per string records (%d): must be equal to other input array sizes (%d)", int(count), int(nrec)))
        var pv_cell_temp = self.as_array("pv_cell_temp", &count)
        if count != nrec:
            raise exec_error("pv_get_shade_loss", util.format("invalid number of pv cell temp records (%d): must be equal to other input array sizes (%d)", int(count), int(nrec)))
        var mods_per_string = self.as_array("mods_per_string", &count)
        if count != nrec:
            raise exec_error("pv_get_shade_loss", util.format("invalid number of modules per string records (%d): must be equal to other input array sizes (%d)", int(count), int(nrec)))
        var str_vmp_stc = self.as_array("str_vmp_stc", &count)
        if count != nrec:
            raise exec_error("pv_get_shade_loss", util.format("invalid number of Vmp at STC records (%d): must be equal to other input array sizes (%d)", int(count), int(nrec)))
        var v_mppt_low = self.as_array("v_mppt_low", &count)
        if count != nrec:
            raise exec_error("pv_get_shade_loss", util.format("invalid number of MPPT low records (%d): must be equal to other input array sizes (%d)", int(count), int(nrec)))
        var v_mppt_high = self.as_array("v_mppt_high", &count)
        if count != nrec:
            raise exec_error("pv_get_shade_loss", util.format("invalid number of MPPT high records (%d): must be equal to other input array sizes (%d)", int(count), int(nrec)))
        var N = self.allocate("N", nrec)
        var d = self.allocate("d", nrec)
        var t = self.allocate("t", nrec)
        var S = self.allocate("S", nrec)
        var shade_loss = self.allocate("shade_loss", nrec)
        if num_strings > 0:
            var db8 = ShadeDB8_mpp()
            db8.init()
            for irec in range(nrec):
                shade_loss[irec] = 0
                var dbl_str_shade = List[Float64]()
                for ins in range(num_strings):
                    dbl_str_shade.append(str_shade_fracs.at(irec, ins))
                dbl_str_shade.sort(reverse=True)
                for i in range(num_strings):
                    dbl_str_shade[i] /= 10.0
                var str_shade = List[Int32]()
                for i in range(num_strings):
                    str_shade.append(Int32(round(dbl_str_shade[i])))
                var s_max = -1
                var s_sum = 0
                for i in range(num_strings):
                    if str_shade[i] > s_max:
                        s_max = str_shade[i]
                    s_sum += str_shade[i]
                if (s_sum > 0) and (global_poa_irrad[irec] > 0):
                    var diffuse_frac = Int32(round(diffuse_irrad[irec] * 10.0 / global_poa_irrad[irec]))
                    if diffuse_frac < 1:
                        diffuse_frac = 1
                    var counter = 1
                    var found = False
                    var cur_case = List[Int32]()
                    if num_strings > 1:
                        counter = 0
                        for i2 in range(s_max + 1):
                            if num_strings == 2:
                                counter += 1
                                cur_case.clear()
                                cur_case.append(s_max)
                                cur_case.append(i2)
                                if str_shade == cur_case:
                                    found = True
                            else:
                                for i3 in range(i2 + 1):
                                    if num_strings == 3:
                                        counter += 1
                                        cur_case.clear()
                                        cur_case.append(s_max)
                                        cur_case.append(i2)
                                        cur_case.append(i3)
                                        if str_shade == cur_case:
                                            found = True
                                    else:
                                        for i4 in range(i3 + 1):
                                            if num_strings == 4:
                                                counter += 1
                                                cur_case.clear()
                                                cur_case.append(s_max)
                                                cur_case.append(i2)
                                                cur_case.append(i3)
                                                cur_case.append(i4)
                                                if str_shade == cur_case:
                                                    found = True
                                            else:
                                                for i5 in range(i4 + 1):
                                                    if num_strings == 5:
                                                        counter += 1
                                                        cur_case.clear()
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
                                                                counter += 1
                                                                cur_case.clear()
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
                                                                        counter += 1
                                                                        cur_case.clear()
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
                                                                                counter += 1
                                                                                cur_case.clear()
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
                    N[irec] = ssc_number_t(num_strings)
                    d[irec] = ssc_number_t(diffuse_frac)
                    t[irec] = ssc_number_t(s_max)
                    S[irec] = ssc_number_t(counter)
                    var vmpp = db8.get_vector(num_strings, diffuse_frac, s_max, counter, ShadeDB8_mpp.VMPP)
                    var impp = db8.get_vector(num_strings, diffuse_frac, s_max, counter, ShadeDB8_mpp.IMPP)
                    var p_max_frac = 0.0
                    var p_max_ind = 0
                    var pmp_fracs = List[Float64]()
                    for i in range(min(vmpp.size(), impp.size())):
                        var pmp = vmpp[i] * impp[i]
                        pmp_fracs.append(pmp)
                        if pmp > p_max_frac:
                            p_max_frac = pmp
                            p_max_ind = int(i)
                    /*
                    %Try scaling the voltages using the Sandia model.Taking numbers from
                    %their database for the Yingli YL230.It's a similar module (mc-si,60 cell, etc)to the
                    %Trina 250 PA05 which the database was build from.But user may need more
                    %input into this!!!
                    */
                    var n = 1.263
                    var BetaVmp = -0.137 * mods_per_string[irec]
                    var Ns = 60 * mods_per_string[irec]
                    var C2 = -0.05871
                    var C3 = 8.35334
                    var k = 1.38066E-23
                    var q = 1.60218E-19
                    var Tc = pv_cell_temp[irec]
                    var deltaTc = n * k * (Tc + 273.15) / q
                    var VMaxSTCStrUnshaded = str_vmp_stc[irec]
                    var scale_g = global_poa_irrad[irec] / 1000.0
                    var TcVmps = List[Float64]()
                    for i in range(vmpp.size()):
                        TcVmps.append(vmpp[i] * VMaxSTCStrUnshaded + C2 * Ns * deltaTc * log(scale_g) + C3 * Ns * pow((deltaTc * log(scale_g)), 2) + BetaVmp * (Tc - 25))
                    /*
                    %Now want to choose the point with a V in range and highest power
                    %First, figure out which max power point gives lowest loss
                    */
                    var Veemax = TcVmps[p_max_ind]
                    if (Veemax >= v_mppt_low[irec]) and (Veemax <= v_mppt_high[irec]):
                        shade_loss[irec] = ssc_number_t(1 - p_max_frac)
                    else:
                        var p_frac = 0.0
                        for i in range(min(TcVmps.size(), pmp_fracs.size())):
                            if (TcVmps[i] >= v_mppt_low[irec]) and (TcVmps[i] <= v_mppt_high[irec]):
                                if pmp_fracs[i] > p_frac:
                                    p_frac = pmp_fracs[i]
                        shade_loss[irec] = ssc_number_t(1 - p_frac)
                else:
                    if s_sum <= 0:
                        shade_loss[irec] = 0
                    else:
                        shade_loss[irec] = 0
        else:
            self.log(util.format("no DB loaded num strings = %d", num_strings), SSC_WARNING)
        /*
            Veemax = TcVmps(Pmaxind);
        if and(VStrMPPT(1) <= Veemax, VStrMPPT(2) >= Veemax)
            % The global max power point is in range!
            ShadeLoss = 1 - PmaxFrac;
        elseif isempty(PFracs(and(TcVs >= VStrMPPT(1), TcVs <= VStrMPPT(2))))
            ShadeLoss = 1;
        else
            %    %The global max power point is NOT in range
            ShadeLoss = 1 - max(PFracs(and(TcVs >= VStrMPPT(1), TcVs <= VStrMPPT(2))));
        end
        */

DEFINE_MODULE_ENTRY(pv_get_shade_loss_mpp, "PV get shade loss fraction for strings", 1)