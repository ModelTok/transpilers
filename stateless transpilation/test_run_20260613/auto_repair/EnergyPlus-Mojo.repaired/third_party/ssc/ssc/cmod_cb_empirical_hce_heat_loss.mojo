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
from core import *

var _cm_vtab_cb_empirical_hce_heat_loss: StaticArray[var_info] = StaticArray[
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCEFrac",           "Fraction of field that is this type of HCE",  "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "PerfFac",           "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "RefMirrAper",       "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCE_A0",            "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCE_A1",            "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCE_A2",            "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCE_A3",            "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCE_A4",            "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCE_A5",            "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_ARRAY,   "HCE_A6",            "label",                                       "",     "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_INPUT,   SSC_NUMBER,  "ui_reference_wind_speed",              "Wind speed for design heat loss",     "m/s",  "",   "hce",   "*",     "",           "" ),
    var_info(
        SSC_INPUT,   SSC_NUMBER,  "SfOutTempD",                           "Solar Field Outlet Temp at design",   "C",    "",   "hce",   "*",     "",           "" ),
    var_info(
        SSC_INPUT,   SSC_NUMBER,  "SfInTempD",                            "Solar Field Inlet Temp at design",    "C",    "",   "hce",   "*",     "",           "" ),
    var_info(
        SSC_INPUT,   SSC_NUMBER,  "ui_reference_ambient_temperature",     "Ambient temp at design heat loss",    "C",    "",   "hce",   "*",     "",           "" ),
    var_info(
        SSC_INPUT,   SSC_NUMBER,  "ui_reference_direct_normal_irradiance","DNI at design",                       "W/m2", "",   "hce",   "*",     "",           "" ),
    var_info(
        SSC_OUTPUT,  SSC_ARRAY,   "HL",                "HCE Heat Losses",                             "W/m",  "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_OUTPUT,  SSC_NUMBER,  "HL_weighted",       "Weighted HCE Heat Loss",                 	    "W/m",  "",   "hce",   "*",     "",           "" ), 
    var_info(
        SSC_OUTPUT,  SSC_NUMBER,  "HL_weighted_m2",    "Weighted HCE Heat Loss per Aperture Area",    "W/m2", "",   "hce",   "*",     "",           "" ), 
    var_info_invalid
]

@value
struct cm_cb_empirical_hce_heat_loss(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_cb_empirical_hce_heat_loss)

    def exec(inout self) raises:
        var PerfFac: List[Float64] = List[Float64]()
        var n_PerfFac: Int = 0
        var p_PerfFac: Pointer[ssc_number_t] = self.as_array("PerfFac", &n_PerfFac)
        var HCE_A0: List[Float64] = List[Float64]()
        var n_HCE_A0: Int = 0
        var p_HCE_A0: Pointer[ssc_number_t] = self.as_array("HCE_A0", &n_HCE_A0)
        var HCE_A1: List[Float64] = List[Float64]()
        var n_HCE_A1: Int = 0
        var p_HCE_A1: Pointer[ssc_number_t] = self.as_array("HCE_A1", &n_HCE_A1)
        var HCE_A2: List[Float64] = List[Float64]()
        var n_HCE_A2: Int = 0
        var p_HCE_A2: Pointer[ssc_number_t] = self.as_array("HCE_A2", &n_HCE_A2)
        var HCE_A3: List[Float64] = List[Float64]()
        var n_HCE_A3: Int = 0
        var p_HCE_A3: Pointer[ssc_number_t] = self.as_array("HCE_A3", &n_HCE_A3)
        var HCE_A4: List[Float64] = List[Float64]()
        var n_HCE_A4: Int = 0
        var p_HCE_A4: Pointer[ssc_number_t] = self.as_array("HCE_A4", &n_HCE_A4)
        var HCE_A5: List[Float64] = List[Float64]()
        var n_HCE_A5: Int = 0
        var p_HCE_A5: Pointer[ssc_number_t] = self.as_array("HCE_A5", &n_HCE_A5)
        var HCE_A6: List[Float64] = List[Float64]()
        var n_HCE_A6: Int = 0
        var p_HCE_A6: Pointer[ssc_number_t] = self.as_array("HCE_A6", &n_HCE_A6)
        var HCEFrac: List[Float64] = List[Float64]()
        var n_HCEFrac: Int = 0
        var p_HCEFrac: Pointer[ssc_number_t] = self.as_array("HCEFrac", &n_HCEFrac)
        var RefMirrAper: List[Float64] = List[Float64]()
        var n_RefMirrAper: Int = 0
        var p_RefMirrAper: Pointer[ssc_number_t] = self.as_array("RefMirrAper", &n_RefMirrAper)
        if n_PerfFac != n_HCE_A0 or n_PerfFac != n_HCE_A1 or n_PerfFac != n_HCE_A2 or n_PerfFac != n_HCE_A3
            or n_PerfFac != n_HCE_A4 or n_PerfFac != n_HCE_A5 or n_PerfFac != n_HCE_A6 or n_PerfFac != n_HCEFrac
            or n_PerfFac != n_RefMirrAper:
            raise Error("Empirical trough HCE heat loss", "Not all HCE input arrays are the same length")
        PerfFac.resize(n_PerfFac)
        HCE_A0.resize(n_PerfFac)
        HCE_A1.resize(n_PerfFac)
        HCE_A2.resize(n_PerfFac)
        HCE_A3.resize(n_PerfFac)
        HCE_A4.resize(n_PerfFac)
        HCE_A5.resize(n_PerfFac)
        HCE_A6.resize(n_PerfFac)
        HCEFrac.resize(n_PerfFac)
        RefMirrAper.resize(n_PerfFac)
        for i in range(n_HCE_A0):
            PerfFac[i] = Float64(p_PerfFac[i])
            HCE_A0[i] = Float64(p_HCE_A0[i])
            HCE_A1[i] = Float64(p_HCE_A1[i])
            HCE_A2[i] = Float64(p_HCE_A2[i])
            HCE_A3[i] = Float64(p_HCE_A3[i])
            HCE_A4[i] = Float64(p_HCE_A4[i])
            HCE_A5[i] = Float64(p_HCE_A5[i])
            HCE_A6[i] = Float64(p_HCE_A6[i])
            HCEFrac[i] = Float64(p_HCEFrac[i])
            RefMirrAper[i] = Float64(p_RefMirrAper[i])
        var HLWind: Float64 = self.as_double("ui_reference_wind_speed")
        var T_amb: Float64 = self.as_double("ui_reference_ambient_temperature")
        var I_bn: Float64 = self.as_double("ui_reference_direct_normal_irradiance")
        var SfTo: Float64 = self.as_double("SfOutTempD")
        var SfTi: Float64 = self.as_double("SfInTempD")
        var HL: List[Float64] = List[Float64](n_HCE_A0)
        var Rec_HL: Float64 = 0.0		#[W/m]
        var Rec_HL_m2: Float64 = 0.0		#[W/m2]
        for i in range(n_HCE_A0):
            if SfTi >= SfTo:
                SfTo = SfTi + 0.1		#HP: Keeps HL curve fits from blowing up
            var HLTerm1: Float64 = (HCE_A0[i] + HCE_A5[i]*sqrt(HLWind))*(SfTo - SfTi)
            var HLTerm2: Float64 = (HCE_A1[i] + HCE_A6[i]*sqrt(HLWind))*((pow(SfTo,2)-pow(SfTi,2))/2.0 - T_amb*(SfTo-SfTi))
            var HLTerm3: Float64 = (HCE_A2[i] + HCE_A4[i]*I_bn)/3.0*(pow(SfTo,3)-pow(SfTi,3))
            var HLTerm4: Float64 = HCE_A3[i]/4.0*(pow(SfTo,4)-pow(SfTi,4))
            HL[i] = (HLTerm1 + HLTerm2 + HLTerm3 + HLTerm4)/(SfTo - SfTi)	#[W/m]
            Rec_HL += PerfFac[i] * HCEFrac[i] * HL[i]		#[W/m]
            Rec_HL_m2 += PerfFac[i] * HCEFrac[i] * HL[i] / RefMirrAper[i]	#[W/m2]
        var p_HL: Pointer[ssc_number_t] = self.allocate("HL", n_HCE_A0)
        for i in range(n_HCE_A0):
            p_HL[i] = ssc_number_t(HL[i])
        self.assign("HL_weighted", ssc_number_t(Rec_HL))
        self.assign("HL_weighted_m2", ssc_number_t(Rec_HL_m2))

def DEFINE_MODULE_ENTRY_cb_empirical_hce_heat_loss():
    return DEFINE_MODULE_ENTRY(cb_empirical_hce_heat_loss, "Empirical HCE Heat Loss", 0)