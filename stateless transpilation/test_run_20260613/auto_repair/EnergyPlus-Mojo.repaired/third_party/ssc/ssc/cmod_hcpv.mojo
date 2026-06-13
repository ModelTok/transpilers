///BSD-3-Clause
///Copyright 2019 Alliance for Sustainable Energy, LLC
///Redistribution and use in source and binary forms, with or without modification, are permitted provided
///that the following conditions are met :
///1.	Redistributions of source code must retain the above copyright notice, this list of conditions
///and the following disclaimer.
///2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
///and the following disclaimer in the documentation and/or other materials provided with the distribution.
///3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse
///or promote products derived from this software without specific prior written permission.
///THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
///INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
///ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
///DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
///OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
///LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
///WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
///OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from core import *
from lib_weatherfile import *
from lib_sandia import *
from lib_irradproc import *
from common import *

const M_PI: Float64 = 3.14159265358979323846264338327

var _cm_vtab_hcpv: StaticArray[var_info] = [
    # /*VARTYPE           DATATYPE         NAME                               LABEL                                                              UNITS          META       GROUP            REQUIRED_IF             CONSTRAINTS                      UI_HINTS*/
    { SSC_INPUT,        SSC_STRING,      "file_name",                       "Weather file in TMY2, TMY3, EPW, or SMW.",                        "",            "",        "hcpv",          "*",                    "LOCAL_FILE",                    "" },
    { SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "PVWatts", "*", "", "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_cell_area",                "Single cell area",                                                "cm^2",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_concentration",            "Concentration ratio",                                             "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_optical_error",            "Optical error factor",                                            "0..1",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_alignment_error",          "Alignment loss factor",                                           "0..1",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_flutter_loss_coeff",       "Wind flutter loss factor",                                        "0..1 per m/s","",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_a0",                       "Air mass modifier coefficient 0",                                 "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_a1",                       "Air mass modifier coefficient 1",                                 "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_a2",                       "Air mass modifier coefficient 2",                                 "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_a3",                       "Air mass modifier coefficient 3",                                 "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_a4",                       "Air mass modifier coefficient 4",                                 "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_ncells",                   "Number of cells",                                                 "none",        "",        "hcpv",          "*",                    "INTEGER",                       "" },
    { SSC_INPUT,        SSC_ARRAY,       "module_mjeff",                    "Module junction efficiency array",                                "percent",     "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_ARRAY,       "module_rad",                      "POA irradiance array",                                            "W/m^2",       "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_reference",                "Index in arrays of the reference condition",                      "none",        "",        "hcpv",          "*",                    "INTEGER",                       "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_a",                        "Equation variable (a), at high irradiance & low wind speed",      "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_b",                        "Equation variable (b), rate at which module temp drops",          "none",        "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_dT",                       "Equation variable (dT), temp diff between heat sink & cell",      "C",           "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "module_temp_coeff",               "Temperature coefficient",                                         "%/C",         "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_c0",                      "Parameter defining the curvature (parabolic) of the relationship between ac-power and dc-power at the reference operating condition, default value of zero gives a linear relationship, (1/W)",   "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_c1",                      "Empirical coefficient allowing Pdco to vary linearly with dc-voltage input, default value is zero, (1/V)",                                                                                        "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_c2",                      "Empirical coefficient allowing Pso to vary linearly with dc-voltage input, default value is zero, (1/V)",                                                                                         "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_c3",                      "Empirical coefficient allowing Co to vary linearly with dc-voltage input, default value is zero, (1/V)",                                                                                           "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_paco",                    "W maximum ac-power rating for inverter at reference or nominal operating condition, assumed to be an upper limit value, (W)",                                                                   "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_pdco",                    "W dc-power level at which the ac-power rating is achieved at the reference operating condition, (W)",                                                                                            "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_pnt",                     "W ac-power consumed by inverter at night (night tare) to maintain circuitry required to sense PV array voltage, (W)",                                                                             "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_pso",                     "W dc-power required to start the inversion process, or self-consumption by inverter, strongly influences inverter efficiency at low power levels, (W)",                                           "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_vdco",                    "V (Vnom) dc-voltage level at which the ac-power rating is achieved at the reference operating condition, (V)",                                                                                    "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "inv_snl_vdcmax",                  "V (Vdcmax) dc-voltage maximum operating voltage, (V)",                                                                                                                                            "xxx",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_modules_per_tracker",       "Modules on each tracker",                                         "none",   "",        "hcpv",          "*",                    "INTEGER",                       "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_num_trackers",              "Number of trackers",                                              "none",   "",        "hcpv",          "*",                    "INTEGER",                       "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_num_inverters",             "Number of inverters",                                             "none",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_wind_stow_speed",           "Allowed wind speed before stowing",                               "m/s",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_tracker_power_fraction",    "Single tracker power fraction",                                   "0..1",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_rlim_el_min",               "Tracker minimum elevation angle",                                 "deg",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_rlim_el_max",               "Tracker maximum elevation angle",                                 "deg",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_rlim_az_min",               "Tracker minimum azimuth angle",                                   "deg",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_rlim_az_max",               "Tracker maximum azimuth angle",                                   "deg",    "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_enable_azalt_sf",           "Boolean for irradiance derate",                                   "0-1",    "",        "hcpv",          "*",                    "INTEGER",                       "" },
    { SSC_INPUT,        SSC_MATRIX,      "azaltsf",                         "Azimuth-Altitude Shading Table",                                  "",       "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_ARRAY,       "array_monthly_soiling",           "Monthly soiling factors array",                                   "0..1",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_dc_mismatch_loss",          "DC module mismatch loss factor",                                  "0..1",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_dc_wiring_loss",            "DC Wiring loss factor",                                           "0..1",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_diode_conn_loss",           "Diodes and connections loss factor",                              "0..1",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_ac_wiring_loss",            "AC wiring loss factor",                                           "0..1",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_INPUT,        SSC_NUMBER,      "array_tracking_error",            "General racking error",                                           "0..1",   "",        "hcpv",          "*",                    "",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_solazi",                   "Hourly solar azimuth",                                            "deg",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_solzen",                   "Hourly solar zenith",                                             "deg",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_sazi",                     "Tracker azimuth",                                                 "deg",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_stilt",                    "Tracker tilt",                                                    "deg",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_sunup",                    "Sun up? (0/1)",                                                   "0 or 1", "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_beam",                     "Beam irradiance",                                                 "kW/m2",  "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_tdry",                     "Ambient dry bulb temperature",                                    "C",      "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_windspd",                  "Wind speed",                                                      "m/s",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_airmass",                  "Relative air mass",                                               "none",   "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_shading_derate",           "Shading derate",                                                  "none",   "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_poa",                      "POA on cell",                                                     "W/m2",   "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_input_radiation",          "Input radiation",                                                 "kWh",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_tmod",                     "Module backplate temp",                                           "C",      "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_tcell",                    "Cell temperature",                                                "C",      "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_celleff",                  "Cell efficiency",                                                 "%",      "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_modeff",                   "Module efficiency",                                               "%",      "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_dc",                       "DC gross",                                                        "kWh",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_dc_net",                   "DC net",                                                          "kWh",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "hourly_ac",                       "AC gross",                                                        "kWh",    "",        "Hourly",          "*",                    "LENGTH=8760",                              "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "monthly_energy",                  "Monthly Energy",                                                  "kWh",    "",        "Monthly",          "*",                   "LENGTH=12",                                 "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "monthly_beam",                    "Beam irradiance",                                                 "kW/m2",  "",        "Monthly",          "*",                   "LENGTH=12",                                 "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "monthly_input_radiation",         "Input radiation",                                                 "kWh",    "",        "Monthly",          "*",                   "LENGTH=12",                                 "" },
    { SSC_OUTPUT,        SSC_ARRAY,      "monthly_dc_net",                  "DC net",                                                          "kWh",    "",        "Monthly",          "*",                   "LENGTH=12",                                 "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "annual_energy",                   "Annual Energy",                                                   "kWh",    "",        "Annual",          "*",                   "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "annual_beam",                     "Beam irradiance",                                                 "kW/m2",  "",        "Annual",          "*",                   "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "annual_input_radiation",          "Input radiation",                                                 "kWh",    "",        "Annual",          "*",                   "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "annual_dc",                       "DC gross",                                                        "kWh",    "",        "Annual",          "*",                   "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "annual_dc_net",                   "DC net",                                                          "kWh",    "",        "Annual",          "*",                   "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "annual_ac",                       "AC gross",                                                        "kWh",    "",        "Annual",          "*",                   "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "tracker_nameplate_watts",         "Tracker nameplate",                                               "watts",  "",        "Miscellaneous",          "*",                    "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "modeff_ref",                      "Module efficiency",                                               "-",      "",        "Miscellaneous",          "*",                    "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "dc_loss_stowing_kwh",             "Annual stowing power loss",                                       "kWh",    "",        "Annual",          "*",                    "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "ac_loss_tracker_kwh",             "Annual tracker power loss",                                       "kWh",    "",        "Annual",          "*",                    "",                                         "" },
    { SSC_OUTPUT,        SSC_NUMBER,     "dc_nominal",                      "Annual DC nominal",                                               "kWh",    "",        "Annual",          "*",                    "",                                         "" },
    { SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "*", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "Energy yield", "kWh/kW", "", "", "*", "", "" },
    var_info_invalid ]

struct cm_hcpv: compute_module {
    def __init__(inout self):
        self.add_var_info(_cm_vtab_hcpv)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def eff_interpolate(self, irrad: Float64, rad: Pointer[ssc_number_t], eff: Pointer[ssc_number_t], count: Int) -> Float64:
        if irrad < rad[0]:
            return eff[0]
        elif irrad > rad[count - 1]:
            return eff[count - 1]
        var i: Int = 1
        for i in range(1, count):
            if irrad < rad[i]:
                break()
        var i1 = i - 1
        var wx = (irrad - rad[i1]) / (rad[i] - rad[i1])
        return (1 - wx) * eff[i1] + wx * eff[i]

    def azaltinterp(self, azimuth: Float64, altitude: Float64, azaltvals: util.matrix_t[ssc_number_t]) -> Float64:
        var r = azaltvals.nrows()
        var c = azaltvals.ncols()
        var i: Int = 0
        var j: Int = 0
        var reduc = 1.0
        if azimuth < 0 or azimuth > 360 or altitude < 0 or altitude > 90:
            return reduc
        var alt_l = 1
        var azi_l = 1
        var alt_d = 0.0
        var azi_d = 0.0
        var x = vector[Float64](2)
        var y = vector[Float64](2)
        var fQ: StaticArray[StaticArray[Float64, 2], 2] = [[1.0, 1.0], [1.0, 1.0]]
        for i in range(2):
            x[i] = 1.0
            y[i] = 1.0
        for i in range(1, r):
            if (azaltvals.at(i, 0) - altitude) > 0:
                alt_l = i
                if i == r - 1:
                    alt_d = 0
                else:
                    alt_d = azaltvals.at(i, 0) - altitude
        for i in range(1, c):
            if azimuth - azaltvals.at(0, i) > 0:
                azi_l = i
                if i == c - 1:
                    azi_d = 0
                else:
                    azi_d = azimuth - azaltvals.at(0, i)
        if alt_d == 0 and azi_d == 0:
            reduc = azaltvals.at(alt_l, azi_l)
        elif alt_d == 0:
            reduc = azaltvals.at(alt_l, azi_l) + \
                ((azaltvals.at(alt_l, azi_l + 1) - (azaltvals.at(alt_l, azi_l))) /
                 (azaltvals.at(0, azi_l + 1) - (azaltvals.at(0, azi_l)))) * azi_d
        elif azi_d == 0:
            reduc = azaltvals.at(alt_l, azi_l) + \
                ((azaltvals.at(alt_l + 1, azi_l) - (azaltvals.at(alt_l, azi_l))) /
                 (azaltvals.at(alt_l + 1, 0) - (azaltvals.at(alt_l, 0)))) * alt_d
        else:
            for i in range(2):
                for j in range(2):
                    fQ[i][j] = azaltvals.at(alt_l + i, azi_l + j)
            for i in range(2):
                x.at(i) = azaltvals.at(alt_l + i, 0)
                y.at(i) = azaltvals.at(0, azi_l + i)
            if x.at(1) - x.at(0) == 0 and y.at(1) - y.at(0) == 0:
                reduc = azaltvals.at(alt_l, azi_l)
            elif x.at(1) - x.at(0) == 0:
                reduc = azaltvals.at(alt_l, azi_l) + \
                    ((azaltvals.at(alt_l, azi_l + 1) - (azaltvals.at(alt_l, azi_l))) /
                     (azaltvals.at(0, azi_l + 1) - (azaltvals.at(0, azi_l)))) * azi_d
            elif y.at(1) - y.at(0) == 0:
                reduc = azaltvals.at(alt_l, azi_l) + \
                    ((azaltvals.at(alt_l + 1, azi_l) - (azaltvals.at(alt_l, azi_l))) /
                     (azaltvals.at(alt_l + 1, 0) - (azaltvals.at(alt_l, 0)))) * alt_d
            else:
                reduc = (fQ[0][0] / ((x.at(1) - x.at(0)) * (y.at(1) - y.at(0)))) * (x.at(1) - altitude) * (y.at(1) - azimuth) \
                    + (fQ[1][0] / ((x.at(1) - x.at(0)) * (y.at(1) - y.at(0)))) * (altitude - x.at(0)) * (y.at(1) - azimuth) \
                    + (fQ[0][1] / ((x.at(1) - x.at(0)) * (y.at(1) - y.at(0)))) * (x.at(1) - altitude) * (azimuth - y.at(0)) \
                    + (fQ[1][1] / ((x.at(1) - x.at(0)) * (y.at(1) - y.at(0)))) * (altitude - x.at(0)) * (azimuth - y.at(0))
        return reduc

    def exec(inout self):
        var wFile = weatherfile(self.as_string("file_name"))
        if not wFile.ok():
            throw exec_error("hcpv", wFile.message())
        if wFile.has_message():
            self.log(wFile.message(), SSC_WARNING)
        var wf: weather_record
        if wFile.nrecords() != 8760:
            throw exec_error("hcpv", "pv simulator only accepts hourly weather data")
        var concen = self.as_double("module_concentration")
        var ncells = self.as_integer("module_ncells")
        var cellarea = self.as_double("module_cell_area") * 0.0001 # convert to m2 
        var modarea = concen * cellarea * ncells #* m2 *
        var rad_count: size_t = 0
        var eff_count: size_t = 0
        var dnrad = self.as_array("module_rad", rad_count)
        var mjeff = self.as_array("module_mjeff", eff_count)
        if rad_count != eff_count:
            throw exec_error("hcpv", "hcpv model radiation and efficiency arrays must have the same number of values")
        for i in range(rad_count):
            if i > 0 and dnrad[i] <= dnrad[i-1]:
                throw exec_error("hcpv", "hcpv model radiation levels must increase monotonically")
        var refidx = self.as_integer("module_reference")
        if refidx < 0 or refidx >= rad_count:
            throw exec_error("hcpv", util.format("invalid reference condition, [0..%d] reqd", rad_count-1))
        var Ib_ref = dnrad[refidx]
        var MJeff_ref = mjeff[refidx]
        var a = self.as_double("module_a")
        var b = self.as_double("module_b")
        var dT = self.as_double("module_dT")
        var gamma = self.as_double("module_temp_coeff")
        var a0 = self.as_double("module_a0")
        var a1 = self.as_double("module_a1")
        var a2 = self.as_double("module_a2")
        var a3 = self.as_double("module_a3")
        var a4 = self.as_double("module_a4")
        var optic_error = self.as_double("module_optical_error")
        var align_error = self.as_double("module_alignment_error")
        var flutter_loss = self.as_double("module_flutter_loss_coeff")
        var mam_ref = a0 + a1 * 1.5 + a2 * 2.25 + a3 * 5.0625 + a4 * 7.59375
        var modeff_ref = MJeff_ref * optic_error * align_error * mam_ref * (1 - flutter_loss * 4)
        var modules_per_tracker = self.as_integer("array_modules_per_tracker")
        var ntrackers = self.as_integer("array_num_trackers")
        var ninverters = self.as_double("array_num_inverters")
        var stow_wspd = self.as_double("array_wind_stow_speed")
        var track_pwr_frac = self.as_double("array_tracker_power_fraction")
        var tracker_nameplate_watts = modules_per_tracker * modarea * Ib_ref * modeff_ref / 100.0
        var soil_len: size_t = 0
        var soiling = self.as_array("array_monthly_soiling", soil_len) # monthly soiling array
        if soil_len != 12:
            throw exec_error("hcpv", "soiling derate must have 12 values")
        var mismatch_loss = self.as_double("array_dc_mismatch_loss")
        var dcwiring_loss = self.as_double("array_dc_wiring_loss")
        var diodeconn_loss = self.as_double("array_diode_conn_loss")
        var tracking_err = self.as_double("array_tracking_error")
        var acwiring_loss = self.as_double("array_ac_wiring_loss")
        var azmin = self.as_double("array_rlim_az_min")
        var azmax = self.as_double("array_rlim_az_max")
        var elmin = self.as_double("array_rlim_el_min")
        var elmax = self.as_double("array_rlim_el_max")
        var snlinv: sandia_inverter_t
        snlinv.Paco = self.as_double("inv_snl_paco")
        snlinv.Pdco = self.as_double("inv_snl_pdco")
        snlinv.Vdco = self.as_double("inv_snl_vdco")
        snlinv.Pso = self.as_double("inv_snl_pso")
        snlinv.Pntare = self.as_double("inv_snl_pnt")
        snlinv.C0 = self.as_double("inv_snl_c0")
        snlinv.C1 = self.as_double("inv_snl_c1")
        snlinv.C2 = self.as_double("inv_snl_c2")
        snlinv.C3 = self.as_double("inv_snl_c3")
        var p_solazi = self.allocate("hourly_solazi", 8760)
        var p_solzen = self.allocate("hourly_solzen", 8760)
        var p_sazi = self.allocate("hourly_sazi", 8760)
        var p_stilt = self.allocate("hourly_stilt", 8760)
        var p_sunup = self.allocate("hourly_sunup", 8760)
        var p_beam = self.allocate("hourly_beam", 8760)
        var p_tdry = self.allocate("hourly_tdry", 8760)
        var p_wspd = self.allocate("hourly_windspd", 8760)
        var p_airmass = self.allocate("hourly_airmass", 8760)
        var p_sf = self.allocate("hourly_shading_derate", 8760)
        var p_poa = self.allocate("hourly_poa", 8760)
        var p_inprad = self.allocate("hourly_input_radiation", 8760)
        var p_tmod = self.allocate("hourly_tmod", 8760)
        var p_tcell = self.allocate("hourly_tcell", 8760)
        var p_celleff = self.allocate("hourly_celleff", 8760)
        var p_modeff = self.allocate("hourly_modeff", 8760)
        var p_dc = self.allocate("hourly_dc", 8760)
        var p_dcnet = self.allocate("hourly_dc_net", 8760)
        var p_ac = self.allocate("hourly_ac", 8760)
        var p_enet = self.allocate("gen", 8760) # kWh
        var dc_loss_stowing = 0.0
        var ac_loss_tracker = 0.0
        var haf = adjustment_factors(self, "adjust")
        if not haf.setup():
            throw exec_error("pvwattsv5", "failed to setup adjustment factors: " + haf.error())
        var dTS = 1.0 # hourly timesteps
        var istep = 0
        var nstep = wFile.nrecords()
        while wFile.read(wf) and istep < 8760:
            if istep % (nstep // 20) == 0:
                self.update("", 100.0 * (Float64(istep) / Float64(nstep)), Float64(istep))
            var irr: irrad
            irr.set_time(wf.year, wf.month, wf.day, wf.hour, wf.minute, dTS)
            irr.set_location(wFile.lat(), wFile.lon(), wFile.tz())
            irr.set_optional(wFile.elev(), wf.pres, wf.tdry)
            irr.set_sky_model(0, 0.2) # isotropic sky, 0.2 albedo (doesn't matter for CPV) and diffuse shading factor not enabled (set to 1.0 by default)
            irr.set_beam_diffuse(wf.dn, wf.df)
            irr.set_surface(2, 0, 0, 90, True, -1, False, 0.0) # 2 axis tracking, other parameters don't matter
            var code = irr.calc()
            if code < 0:
                throw exec_error("hcpv", util.format("failed to compute irradiation on surface (code: %d)", code))
            var poa: Float64
            irr.get_poa(poa, 0, 0, 0, 0, 0)
            var midx = wf.month - 1
            if midx >= 0 and midx < 12:
                poa *= soiling[midx]
            var aoi: Float64
            var stilt: Float64
            var sazi: Float64
            irr.get_angles(aoi, stilt, sazi, 0, 0)
            if stilt < elmin:
                stilt = elmin
                poa = 0
            if stilt > elmax:
                stilt = elmax
                poa = 0
            if wFile.lat() < 0: # southern hemisphere
                if sazi < azmin and sazi > azmax:
                    sazi = azmax if (sazi < 180) else azmin
                    poa = 0
            else:
                if sazi < azmin:
                    sazi = azmin
                    poa = 0
                if sazi > azmax:
                    sazi = azmax
                    poa = 0
            var solazi: Float64
            var solzen: Float64
            var solalt: Float64
            var sunup: Int
            irr.get_sun(solazi, solzen, solalt, 0, 0, 0, sunup, 0, 0, 0)
            var shad_derate = 1.0
            var en_azaltsf = (self.as_integer("array_enable_azalt_sf") == 1)
            if sunup > 0:
                var azaltsf: util.matrix_t[ssc_number_t]
                if not self.get_matrix("azaltsf", azaltsf):
                    throw exec_error("hcpv", "could not get the azimuth-altitude shading table from the SSC interface")
                if en_azaltsf:
                    shad_derate = self.azaltinterp(solazi, solalt, azaltsf)
                poa *= shad_derate
                poa *= optic_error
                poa *= align_error
                var air_mass = 1 / (cos(solzen * M_PI / 180) + 0.5057 * pow(96.080 - solzen, -1.634))
                air_mass *= exp(-0.0001184 * wFile.elev()) # correction for elevation (m), as applied in Sandia PV model
                var air_mass_modifier = a0 + a1 * air_mass + a2 * pow(air_mass, 2) + a3 * pow(air_mass, 3) + a4 * pow(air_mass, 4)
                poa *= air_mass_modifier
                var celleff = self.eff_interpolate(wf.dn, dnrad, mjeff, rad_count)
                var cellpwr = (celleff / 100.0 * poa * concen * cellarea)
                var tmod = sandia_celltemp_t.sandia_module_temperature(wf.dn, wf.wspd, wf.tdry, 0, a, b)
                var tcell = sandia_celltemp_t.sandia_tcell_from_tmodule(tmod, wf.dn, 0, dT)
                cellpwr += cellpwr * (gamma / 100.0) * (tcell - 20.0)
                if cellpwr < 0:
                    cellpwr = 0
                cellpwr *= (1 - flutter_loss * wf.wspd)
                var dcgross = cellpwr * ncells * modules_per_tracker * ntrackers
                var dcv = snlinv.Vdco # todo: arbitrary DC voltage.  this is "optimal"
                var modeff = 0.0
                if poa > 0:
                    modeff = 100 * dcgross / (poa * modarea * modules_per_tracker * ntrackers)
                var dcpwr = dcgross
                if wf.wspd >= stow_wspd:
                    dc_loss_stowing += dcpwr
                    dcpwr = 0
                else:
                    dcpwr *= mismatch_loss
                    dcpwr *= dcwiring_loss
                    dcpwr *= diodeconn_loss
                    dcpwr *= tracking_err
                var _par: Float64
                var _plr: Float64
                var acgross: Float64
                var aceff: Float64
                var cliploss: Float64
                var psoloss: Float64
                var pntloss: Float64
                snlinv.acpower(dcpwr / ninverters, dcv, acgross, _par, _plr, aceff, cliploss, psoloss, pntloss)
                acgross *= ninverters
                var acpwr = acgross
                acpwr *= acwiring_loss
                var tracker_power = ntrackers * track_pwr_frac * tracker_nameplate_watts * dTS # dTS is the timestep in hours
                ac_loss_tracker += tracker_power
                acpwr -= tracker_power
                p_solazi[istep] = ssc_number_t(solazi)
                p_solzen[istep] = ssc_number_t(solzen)
                p_sazi[istep] = ssc_number_t(sazi)
                p_stilt[istep] = ssc_number_t(stilt)
                p_sunup[istep] = ssc_number_t(sunup)
                p_airmass[istep] = ssc_number_t(air_mass)
                p_poa[istep] = ssc_number_t(poa)
                p_inprad[istep] = ssc_number_t(wf.dn * modarea * modules_per_tracker * ntrackers * 0.001) # kWh
                p_tmod[istep] = ssc_number_t(tmod)
                p_tcell[istep] = ssc_number_t(tcell)
                p_celleff[istep] = ssc_number_t(celleff)
                p_modeff[istep] = ssc_number_t(modeff)
                p_dc[istep] = ssc_number_t(dcgross * 0.001) # kwh
                p_dcnet[istep] = ssc_number_t(dcpwr * 0.001) # kwh
                p_ac[istep] = ssc_number_t(acgross * 0.001) # kwh
                p_enet[istep] = ssc_number_t(acpwr * 0.001 * haf(istep)) # kwh
            p_beam[istep] = ssc_number_t(wf.dn)
            p_tdry[istep] = ssc_number_t(wf.tdry)
            p_wspd[istep] = ssc_number_t(wf.wspd)
            p_sf[istep] = ssc_number_t(shad_derate)
            istep += 1
        if istep != 8760:
            throw exec_error("hcpv", util.format("failed to simulate all 8760 hours"))
        self.accumulate_annual("gen", "annual_energy")
        self.accumulate_annual("hourly_beam", "annual_beam")
        self.accumulate_annual("hourly_input_radiation", "annual_input_radiation")
        self.accumulate_annual("hourly_dc", "annual_dc")
        self.accumulate_annual("hourly_dc_net", "annual_dc_net")
        self.accumulate_annual("hourly_ac", "annual_ac")
        self.accumulate_monthly("gen", "monthly_energy")
        self.accumulate_monthly("hourly_beam", "monthly_beam")
        self.accumulate_monthly("hourly_input_radiation", "monthly_input_radiation")
        self.accumulate_monthly("hourly_dc_net", "monthly_dc_net")
        self.assign("tracker_nameplate_watts", var_data(ssc_number_t(tracker_nameplate_watts)))
        self.assign("dc_loss_stowing_kwh", var_data(ssc_number_t(dc_loss_stowing * 0.001)))
        self.assign("ac_loss_tracker_kwh", var_data(ssc_number_t(ac_loss_tracker * 0.001)))
        self.assign("modeff_ref", var_data(ssc_number_t(modeff_ref)))
        var inp_rad = self.as_number("annual_input_radiation")
        self.assign("dc_nominal", var_data(ssc_number_t(modeff_ref * inp_rad / 100.0)))
        var kWhperkW = 0.0
        var nameplate = self.as_double("system_capacity")
        var annual_energy = 0.0
        for i in range(8760):
            annual_energy += p_enet[i]
        if nameplate > 0:
            kWhperkW = annual_energy / nameplate
        self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
        self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
}

#=== DEFINE_MODULE_ENTRY(hcpv, "High-X Concentrating PV, SAM component models V.1", 1)