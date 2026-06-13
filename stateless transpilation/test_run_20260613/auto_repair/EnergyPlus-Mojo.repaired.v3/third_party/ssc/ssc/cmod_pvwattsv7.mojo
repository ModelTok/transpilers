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

from core import compute_module, var_info, var_data, ssc_number_t, SSC_INPUT, SSC_OUTPUT, SSC_INOUT, SSC_STRING, SSC_NUMBER, SSC_ARRAY, SSC_TABLE, SSC_MATRIX, SSC_WARNING, SSC_ERROR, SSC_NOTICE, exec_error, as_double, as_string, as_array, as_boolean, as_integer, as_unsigned_long, as_vector_double, lookup, allocate, assign, add_var_info, adjustment_factors, vtab_technology_outputs, vtab_adjustment_factors, var_info_invalid
from common import util
from lib_weatherfile import weather_data_provider, weatherfile, weatherdata, weather_header, weather_record
from lib_irradproc import irrad, IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET, POA_MIN
from lib_pvwatts import pvwatts_celltemp, PVWATTS_HEIGHT
from lib_pvshade import shading_factor_calculator, ssinputs, ssoutputs, ss_exec, ssSkyDiffuseTable, shadeFraction1x
from lib_pvmodel import air_mass_modifier, calculateIrradianceThroughCoverDeSoto, AOI_MIN, AOI_MAX
from lib_snowmodel import pvsnowmodel
from lib_pv_incidence_modifier import iam  # unused but kept for compatibility
from lib_sandia import sandia_celltemp_t  # unused but kept for compatibility
from lib_cec6par import openvoltage_5par_rec, maxpower_5par_rec  # used in sdmml_power
from math import isfinite, pow, exp, sqrt, ceil, fabs, cosd, sind  # add cosd/sind if not already

# Helper for quiet_NaN
alias FloatNaN = Float64.NaN

class lossdiagram:
    struct loss_item:
        var name: String
        var baseline: Bool
        def __init__(inout self, _n: String, _b: Bool):
            self.name = _n
            self.baseline = _b

    var m_map: Dict[String, Float64]
    var m_error: String
    var m_items: List[loss_item]

    def __init__(inout self):
        self.m_map = Dict[String, Float64]()
        self.m_error = String("")
        self.m_items = List[loss_item]()

    def errormsg(self) -> String:
        return self.m_error

    def add(inout self, name: String, baseline: Bool):
        self.m_items.append(loss_item(name, baseline))
        self.m_map[name] = 0.0

    def assign(inout self, cm: compute_module, prefix: String) -> Bool:
        self.m_error = String("")
        var last_baseline: Float64 = 0.0
        for i in range(len(self.m_items)):
            if self.m_items[i].name not in self.m_map:
                self.m_error = "could not locate loss accumulation value '" + self.m_items[i].name + "'"
            if self.m_items[i].baseline:
                last_baseline = self.m_map[self.m_items[i].name]
            else:
                var value: Float64 = self.m_map[self.m_items[i].name]
                var percent: Float64 = value / last_baseline * 100.0
                cm.assign(prefix + self.m_items[i].name + "_percent", ssc_number_t(percent))
        for it in self.m_map:
            cm.assign(prefix + it.key, var_data(ssc_number_t(it.value)))
        return len(self.m_error) == 0

    # Overload subscript to mimic operator() (since Mojo doesn't support __call__ on objects)
    def __getitem__(self, name: String) -> Float64:
        return self.m_map.get(name, 0.0)

    def __setitem__(inout self, name: String, value: Float64):
        self.m_map[name] = value

# Use subscript notation ld["poa_nominal"] instead of ld("poa_nominal")
# All uses of ld(...) are replaced with ld[...] accordingly.

var _cm_vtab_pvwattsv7: List[var_info] = [
    # VARTYPE           DATATYPE          NAME                              LABEL                                          UNITS        META                                            GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS
    var_info(SSC_INPUT,        SSC_STRING,      "solar_resource_file",            "Weather file path",                          "",           "",                                             "Solar Resource",      "?",                       "",                              ""),
    var_info(SSC_INPUT,        SSC_TABLE,       "solar_resource_data",            "Weather data",                               "",           "dn,df,tdry,wspd,lat,lon,tz,elev",              "Solar Resource",      "?",                       "",                              ""),
    var_info(SSC_INPUT,        SSC_ARRAY,       "albedo",                         "Albedo",                                     "frac",       "if provided, will overwrite weather file albedo","Solar Resource",    "",                        "",                              ""),
    var_info(SSC_INOUT,        SSC_NUMBER,      "system_use_lifetime_output",     "Run lifetime simulation",                    "0/1",        "",                                             "Lifetime",            "?=0",                        "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "analysis_period",                "Analysis period",                            "years",      "",                                             "Lifetime",            "system_use_lifetime_output=1", "",                          ""),
    var_info(SSC_INPUT,        SSC_ARRAY,       "dc_degradation",                 "Annual DC degradation for lifetime simulations","%/year",  "",                                             "Lifetime",            "system_use_lifetime_output=1", "",                          ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "system_capacity",                "System size (DC nameplate)",                  "kW",        "",											   "System Design",      "*",                       "",                      ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "module_type",                    "Module type",                                 "0/1/2",     "Standard,Premium,Thin film",                   "System Design",      "?=0",                     "MIN=0,MAX=2,INTEGER",           ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "dc_ac_ratio",                    "DC to AC ratio",                              "ratio",     "",                                             "System Design",      "?=1.1",                   "POSITIVE",                      ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "bifaciality",                    "Module bifaciality factor",                   "0 or ~0.65","",                                             "System Design",      "?=0",                       "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "ac_plant_max_f",                 "Plant controller max output (as f(ac_size))", "ratio",     "",                                             "System Design",      "?=1.0",                   "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "array_type",                     "Array type",                                  "0/1/2/3/4", "Fixed Rack,Fixed Roof,1Axis,Backtracked,2Axis","System Design",      "*",                       "MIN=0,MAX=4,INTEGER",           ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "tilt",                           "Tilt angle",                                  "deg",       "H=0,V=90",                                     "System Design",      "array_type<4",            "MIN=0,MAX=90",                  ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "azimuth",                        "Azimuth angle",                               "deg",       "E=90,S=180,W=270",                             "System Design",      "array_type<4",            "MIN=0,MAX=360",                 ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "gcr",                            "Ground coverage ratio",                       "0..1",      "",                                             "System Design",      "?=0.4",                   "MIN=0.01,MAX=0.99",             ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rotlim",                         "Tracker rotation angle limit",                "deg",       "",                                             "System Design",      "?=45.0",                  "",                              ""),
    var_info(SSC_INPUT,        SSC_ARRAY,       "soiling",                        "Soiling loss",                                "%",         "",                                             "System Design",      "?",                       "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "losses",						   "Other DC losses",                             "%",         "Total system losses",                          "System Design",      "*",                       "MIN=-5,MAX=99",                 ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "enable_wind_stow",               "Enable tracker stow at high wind speeds",     "0/1",       "",                                             "System Design",      "?=0",                     "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "stow_wspd",                      "Tracker stow wind speed threshold",           "m/s",       "",                                             "System Design",      "?=10",                    "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "gust_factor",                    "Wind gust estimation factor",                 "",          "",                                             "System Design",      "?",                       "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "wind_stow_angle",                "Tracker angle for wind stow",                 "deg",       "",                                             "System Design",      "?=30.0",                  "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "en_snowloss",                    "Enable snow loss model",                      "0/1",       "",                                             "System Design",      "?=0",                     "BOOLEAN",                       ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "inv_eff",                        "Inverter efficiency at rated power",          "%",         "",                                             "System Design",      "?=96",                    "MIN=90,MAX=99.5",               ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "xfmr_nll",                       "GSU transformer no load loss (iron core)",    "%(ac)",     "",                                             "System Design",      "?=0.0",                   "",                              ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "xfmr_ll",                        "GSU transformer load loss (resistive)",       "%(ac)",     "",                                             "System Design",      "?=0.0",                   "",                              ""),
    var_info(SSC_INPUT,        SSC_MATRIX,      "shading:timestep",               "Time step beam shading loss",                 "%",         "",                                             "System Design",      "?",                        "",                             ""),
    var_info(SSC_INPUT,        SSC_MATRIX,      "shading:mxh",                    "Month x Hour beam shading loss",              "%",         "",                                             "System Design",      "?",                        "",                             ""),
    var_info(SSC_INPUT,        SSC_MATRIX,      "shading:azal",                   "Azimuth x altitude beam shading loss",        "%",         "",                                             "System Design",      "?",                        "",                             ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "shading:diff",                   "Diffuse shading loss",                        "%",         "",                                             "System Design",      "?",                        "",                             ""),
    var_info(SSC_INPUT,        SSC_NUMBER,      "batt_simple_enable",             "Enable Battery",                              "0/1",       "",                                             "System Design",     "?=0",                     "BOOLEAN",                        ""),
    # outputs
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "gh",                             "Weather file global horizontal irradiance",                "W/m2",      "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "dn",                             "Weather file beam irradiance",                             "W/m2",      "",											   "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "df",                             "Weather file diffuse irradiance",                          "W/m2",      "",											   "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "tamb",                           "Weather file ambient temperature",                         "C",         "",										       "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "wspd",                           "Weather file wind speed",                                  "m/s",       "",											   "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "snow",                           "Weather file snow depth",                                  "cm",        "",										       "Time Series",      "",                        "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "sunup",                          "Sun up over horizon",                         "0/1",       "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "shad_beam_factor",               "Shading factor for beam radiation",           "",          "",                                             "Time Series",      "*",                       "",                                     ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "aoi",                            "Angle of incidence",                          "deg",       "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "poa",                            "Plane of array irradiance",                   "W/m2",      "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "tpoa",                           "Transmitted plane of array irradiance",       "W/m2",      "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "tcell",                          "Module temperature",                          "C",         "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "dcsnowderate",                   "DC power loss due to snow",            "%",         "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "dc",                             "DC inverter input power",                              "W",         "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "ac",                             "AC inverter output power",                           "W",         "",                                             "Time Series",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "poa_monthly",                    "Plane of array irradiance",                   "kWh/m2",    "",                                             "Monthly",          "",                       "LENGTH=12",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "solrad_monthly",                 "Daily average solar irradiance",              "kWh/m2/day","",                                             "Monthly",          "",                       "LENGTH=12",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "dc_monthly",                     "DC output",                             "kWh",       "",                                             "Monthly",          "",                       "LENGTH=12",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "ac_monthly",                     "AC output",                            "kWh",       "",                                             "Monthly",          "",                       "LENGTH=12",                          ""),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "monthly_energy",                 "Monthly energy",                              "kWh",       "",                                             "Monthly",          "",                       "LENGTH=12",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "solrad_annual",                  "Daily average solar irradiance",              "kWh/m2/day","",                                             "Annual",      "",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "ac_annual",                      "Annual AC output",                     "kWh",       "",                                             "Annual",      "",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "annual_energy",                  "Annual energy",                               "kWh",       "",                                             "Annual",      "",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "capacity_factor",                "Capacity factor",                             "%",         "",                                             "Annual",        "",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "kwh_per_kw",                     "Energy yield",                           "kWh/kW",          "",                                             "Annual",        "",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_STRING,      "location",                       "Location ID",                                 "",          "",                                             "Location",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_STRING,      "city",                           "City",                                        "",          "",                                             "Location",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_STRING,      "state",                          "State",                                       "",          "",                                             "Location",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "lat",                            "Latitude",                                    "deg",       "",                                             "Location",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "lon",                            "Longitude",                                   "deg",       "",                                             "Location",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "tz",                             "Time zone",                                   "hr",        "",                                             "Location",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "elev",                           "Site elevation",                              "m",         "",                                             "Location",      "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "inverter_efficiency",            "Inverter efficiency at rated power",          "%",         "",                                             "PVWatts",      "",                        "",                              ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "estimated_rows",				   "Estimated number of rows in the system",	  "",          "",                                             "PVWatts",      "",                        "",                              ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "ts_shift_hours",                 "Time offset for interpreting time series outputs", "hours","",                                             "Miscellaneous", "*",                       "",                          ""),
    var_info(SSC_OUTPUT,       SSC_NUMBER,      "percent_complete",               "Estimated percent of total completed simulation", "%",     "",                                             "Miscellaneous", "",                        "",                          ""),
    var_info_invalid  # sentinel
]

class cm_pvwattsv7(compute_module):
    protected:
    enum module_type: STANDARD, PREMIUM, THINFILM
    enum module_orientation: PORTRAIT, LANDSCAPE
    enum array_type: FIXED_RACK, FIXED_ROOF, ONE_AXIS, ONE_AXIS_BACKTRACKING, TWO_AXIS, AZIMUTH_AXIS //azimuth axis not enabled in inputs?
    const bifacialTransmissionFactor: Float64 = 0.013
    var module: (type: module_type, stc_watts: Float64, stc_eff: Float64, ff: Float64, aspect_ratio: Float64, width: Float64, length: Float64, area: Float64, vmp: Float64, ndiode: Int, gamma: Float64, ar_glass: Bool, bifaciality: Float64)
    var pv: (type: array_type, dc_nameplate: Float64, dc_ac_ratio: Float64, ac_nameplate: Float64, xfmr_rating: Float64, ac_plant_max: Float64, inv_eff_percent: Float64, dc_loss_percent: Float64, tilt: Float64, azimuth: Float64, rotlim: Float64, xfmr_nll_f: Float64, xfmr_ll_f: Float64, inoct: Float64, nmodules: Float64, nmodperstr: Float64, nmodx: Int, nmody: Int, nrows: Int, row_spacing: Float64, gcr: Float64)
    struct sdmml:
        var Area: Float64
        var Vmp: Float64
        var Imp: Float64
        var Voc: Float64
        var Isc: Float64
        var n_0: Float64
        var mu_n: Float64
        var N_series: Float64
        var alpha_isc: Float64
        var E_g: Float64
        var R_shexp: Float64
        var R_sh0: Float64
        var R_shref: Float64
        var R_s: Float64
        var D2MuTau: Float64
    var sdm: sdmml
    var ld: lossdiagram

    def __init__(inout self):
        self.add_var_info(vtab_technology_outputs)
        self.add_var_info(_cm_vtab_pvwattsv7)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)
        self.ld.add("poa_nominal", true)
        self.ld.add("poa_loss_tracker_stow", false)
        self.ld.add("poa_loss_ext_beam_shade", false)
        self.ld.add("poa_loss_ext_diff_shade", false)
        self.ld.add("poa_loss_self_beam_shade", false)
        self.ld.add("poa_loss_self_diff_shade", false)
        self.ld.add("poa_loss_soiling", false)
        self.ld.add("poa_loss_bifacial", false)
        self.ld.add("dc_nominal", true)
        self.ld.add("dc_loss_cover", false)
        self.ld.add("dc_loss_spectral", false)
        self.ld.add("dc_loss_thermal", false)
        self.ld.add("dc_loss_nonlinear", false)
        self.ld.add("dc_loss_snow", false)
        self.ld.add("dc_loss_other", false)
        self.ld.add("ac_nominal", true)
        self.ld.add("ac_loss_efficiency", false)
        self.ld.add("ac_loss_inverter_clipping", false)
        self.ld.add("ac_loss_adjustments", false)
        self.ld.add("ac_loss_plant_clipping", false)
        self.ld.add("ac_loss_transformer", false)
        self.ld.add("ac_delivered", true)

    def sdmml_power(inout self, m: sdmml, S: Float64, T_cell: Float64) -> Float64:
        const S_ref: Float64 = 1000
        const T_ref: Float64 = 25
        const k: Float64 = 1.38064852e-23
        const q: Float64 = 1.60217662e-19
        const T_0: Float64 = 273.15
        if S > 1:
            var R_sh_STC: Float64 = m.R_shref + (m.R_sh0 - m.R_shref) * exp(-m.R_shexp * (S_ref / S_ref))
            var nVT: Float64 = m.N_series * m.n_0 * k * (T_ref + T_0) / q
            var I_0ref: Float64 = (m.Isc + (m.Isc * m.R_s - m.Voc) / R_sh_STC) / ((exp(m.Voc / nVT) - 1) - (exp((m.Isc * m.R_s) / nVT) - 1))
            var I_Lref: Float64 = I_0ref * (exp(m.Voc / nVT) - 1) + m.Voc / R_sh_STC
            var Vbi: Float64 = 0.9 * m.N_series
            var n: Float64 = m.n_0 + m.mu_n * (T_cell - T_ref)
            var a: Float64 = m.N_series * k * (T_cell + T_0) * n / q
            var I_L: Float64 = (S / S_ref) * (I_Lref + m.alpha_isc * (T_cell - T_ref))
            var I_0: Float64 = I_0ref * pow(((T_cell + T_0) / (T_ref + T_0)), 3) * exp((q * m.E_g) / (n * k) * (1 / (T_ref + T_0) - 1 / (T_cell + T_0)))
            var R_sh: Float64 = m.R_shref + (m.R_sh0 - m.R_shref) * exp(-m.R_shexp * (S / S_ref))
            var V_oc: Float64 = openvoltage_5par_rec(m.Voc, a, I_L, I_0, R_sh, m.D2MuTau, Vbi)
            var V: Float64; var I: Float64
            return maxpower_5par_rec(V_oc, a, I_L, I_0, m.R_s, R_sh, m.D2MuTau, Vbi, &V, &I)
        else:
            return 0.0

    def exec(inout self):
        var wdprov: weather_data_provider
        if self.is_assigned("solar_resource_file"):
            var file: String = self.as_string("solar_resource_file")
            wdprov = weatherfile(file)
            var wfile: weatherfile = weatherfile(wdprov) # cast? Need dynamic_cast equivalent? Assume weather_data_provider has ok() and message()
            if not wfile.ok():
                self.throw_exec_error("pvwattsv7", wfile.message())
            if wfile.has_message():
                self.log(wfile.message(), SSC_WARNING)
        elif self.is_assigned("solar_resource_data"):
            wdprov = weatherdata(self.lookup("solar_resource_data"))
        else:
            self.throw_exec_error("pvwattsv7", "No weather data supplied.")

        self.pv.dc_nameplate = self.as_double("system_capacity") * 1000
        self.pv.dc_ac_ratio = self.as_double("dc_ac_ratio")
        self.pv.ac_nameplate = self.pv.dc_nameplate / self.pv.dc_ac_ratio
        self.pv.xfmr_rating = self.pv.ac_nameplate
        self.pv.inv_eff_percent = self.as_double("inv_eff")
        var soiling_len: Int = 0
        var soiling: Pointer[ssc_number_t] = none
        if self.is_assigned("soiling"):
            soiling = self.as_array("soiling", &soiling_len)
        var albedo_len: Int = 0
        var albedo: Pointer[ssc_number_t] = none
        if self.is_assigned("albedo"):
            albedo = self.as_array("albedo", &albedo_len)
        self.pv.dc_loss_percent = self.as_double("losses")
        self.pv.tilt = self.pv.azimuth = Float64.NaN
        self.pv.rotlim = 45.0
        if self.is_assigned("tilt"): self.pv.tilt = self.as_double("tilt")
        if self.is_assigned("azimuth"): self.pv.azimuth = self.as_double("azimuth")
        if self.is_assigned("rotlim"): self.pv.rotlim = self.as_double("rotlim")
        self.pv.xfmr_ll_f = self.as_double("xfmr_ll") * 0.01
        self.pv.xfmr_nll_f = self.as_double("xfmr_nll") * 0.01
        var enable_wind_stow: Bool = self.as_boolean("enable_wind_stow")
        if enable_wind_stow and not wdprov.annualSimulation():
            self.log("Using the wind stow model with weather data that is not continuous over one year may result in over-estimation of stow losses.", SSC_WARNING)
        var wstow: Float64 = Float64.NaN
        if self.is_assigned("stow_wspd"): wstow = self.as_double("stow_wspd")
        var wind_stow_angle_deg: Float64
        if self.is_assigned("wind_stow_angle"): wind_stow_angle_deg = self.as_double("wind_stow_angle")
        var en_sdm: Int = self.is_assigned("en_sdm") ? self.as_integer("en_sdm") : 0
        self.module.type = module_type(self.as_integer("module_type"))
        match self.module.type:
            case STANDARD:
                self.module.gamma = -0.0037
                self.module.ar_glass = true
                self.module.ff = 0.778
                self.module.stc_eff = 0.19
                self.sdm.Area = 1.940
                self.sdm.Vmp = 37.8
                self.sdm.Imp = 8.73
                self.sdm.Voc = 46.2
                self.sdm.Isc = 9.27
                self.sdm.n_0 = 0.92
                self.sdm.mu_n = 0
                self.sdm.N_series = 72
                self.sdm.alpha_isc = 0.0046
                self.sdm.E_g = 1.12
                self.sdm.R_shexp = 20
                self.sdm.R_sh0 = 2000
                self.sdm.R_shref = 550
                self.sdm.R_s = 0.382
                self.sdm.D2MuTau = 0.0
            case PREMIUM:
                self.module.gamma = -0.0035
                self.module.ar_glass = true
                self.module.ff = 0.780
                self.module.stc_eff = 0.21
                self.sdm.Area = 1.630
                self.sdm.Vmp = 59.5
                self.sdm.Imp = 5.49
                self.sdm.Voc = 70.0
                self.sdm.Isc = 5.84
                self.sdm.n_0 = 1.17
                self.sdm.mu_n = 0
                self.sdm.N_series = 96
                self.sdm.alpha_isc = 0.0025
                self.sdm.E_g = 1.12
                self.sdm.R_shexp = 5.5
                self.sdm.R_sh0 = 14000
                self.sdm.R_shref = 3444
                self.sdm.R_s = 0.4
                self.sdm.D2MuTau = 0.0
            case THINFILM:
                self.module.gamma = -0.0032
                self.module.ar_glass = true
                self.module.ff = 0.777
                self.module.stc_eff = 0.18
                self.sdm.Area = 0.72
                self.sdm.Vmp = 68.5
                self.sdm.Imp = 1.64
                self.sdm.Voc = 87.0
                self.sdm.Isc = 1.83
                self.sdm.n_0 = 1.5
                self.sdm.mu_n = 0.002
                self.sdm.N_series = 108
                self.sdm.alpha_isc = 0.0007
                self.sdm.E_g = 1.12
                self.sdm.R_shexp = 6
                self.sdm.R_sh0 = 12000
                self.sdm.R_shref = 3500
                self.sdm.R_s = 4.36
                self.sdm.D2MuTau = 0.95
        self.module.aspect_ratio = 1.7
        self.module.stc_watts = 300
        self.module.area = self.module.stc_watts / self.module.stc_eff / 1000.0
        self.module.width = sqrt((self.module.area / self.module.aspect_ratio))
        self.module.length = self.module.width * self.module.aspect_ratio
        self.module.vmp = 60.0
        self.module.ndiode = 3
        self.module.bifaciality = 0.0
        if self.is_assigned("bifaciality"):
            self.module.bifaciality = self.as_double("bifaciality")
        var AMdesoto: StaticArray[Float64, 5] = [0.918093, 0.086257, -0.024459, 0.002816, -0.000126]
        var module_m2: Float64 = self.pv.dc_nameplate / self.module.stc_eff / 1000
        self.pv.type = array_type(self.as_integer("array_type"))
        match self.pv.type:
            case FIXED_ROOF:
                self.pv.inoct = 49
            case _:
                self.pv.inoct = 45
        if (self.pv.type == ONE_AXIS or self.pv.type == ONE_AXIS_BACKTRACKING) and self.pv.tilt > 0:
            self.log(util.format("The tilt angle is %f degrees with one-axis tracking. Large one-axis tracking arrays typically have a tilt angle of zero.", self.pv.tilt), SSC_WARNING)
        if not (self.pv.type == FIXED_RACK or self.pv.type == FIXED_ROOF) and self.module.bifaciality > 0.0:
            self.log("The bifacial model is designed for fixed arrays and may not produce reliable results for tracking arrays.", SSC_WARNING)
        self.pv.gcr = self.as_double("gcr")
        var en_self_shading: Bool = (self.pv.type == FIXED_RACK or self.pv.type == ONE_AXIS or self.pv.type == ONE_AXIS_BACKTRACKING)
        if en_self_shading:
            if self.pv.gcr < 0.01 or self.pv.gcr >= 1.0:
                self.throw_exec_error("pvwattsv7", "invalid gcr for fixed rack or one axis tracking system")
            self.pv.nmodperstr = 7
            self.pv.nmodules = ceil(self.pv.dc_nameplate / self.module.stc_watts)
            if self.pv.nmodules < 1: self.pv.nmodules = 1
            self.pv.nrows = Int(ceil(sqrt(self.pv.nmodules)))
            self.assign("estimated_rows", var_data(ssc_number_t(self.pv.nrows)))
            if self.pv.type == ONE_AXIS:
                self.pv.nmody = 1
            else:
                self.pv.nmody = 2
            self.pv.nmodx = self.pv.nrows / self.pv.nmody
            if self.pv.nmodx < 1: self.pv.nmodx = 1
            self.pv.row_spacing = self.module.length * Float64(self.pv.nmody) / self.pv.gcr
        var snowmodel: pvsnowmodel
        var en_snowloss: Bool = self.as_boolean("en_snowloss")
        if en_snowloss:
            if not wdprov.annualSimulation():
                self.log("Using the snow model with weather data that is not continuous over one year may result in over-estimation of snow losses.", SSC_WARNING)
            if snowmodel.setup(self.pv.nmody, Float32(self.pv.tilt), self.pv.type == FIXED_RACK or self.pv.type == FIXED_ROOF):
                if not snowmodel.good:
                    self.log(snowmodel.msg, SSC_ERROR)
        var haf: adjustment_factors = adjustment_factors(self, "adjust")
        if not haf.setup():
            self.throw_exec_error("pvwattsv7", "Failed to set up adjustment factors: " + haf.error())
        if self.is_assigned("shading:timestep") and not wdprov.annualSimulation():
            self.throw_exec_error("pvwattsv7", "Timeseries beam shading inputs cannot be used for a simulation period that is not continuous over one or more years.")
        var shad: shading_factor_calculator
        if not shad.setup(self, ""):
            self.throw_exec_error("pvwattsv7", shad.get_error())
        var ssSkyDiffuseTable: ssskydiffuse_table
        if en_self_shading:
            ssSkyDiffuseTable.init(self.pv.tilt, self.pv.gcr)
        var hdr: weather_header
        wdprov.header(&hdr)
        var ts_shift_hours: Float64 = 0.0
        var instantaneous: Bool = true
        if wdprov.has_data_column(weather_data_provider.MINUTE):
            var rec: weather_record
            if wdprov.read(&rec):
                ts_shift_hours = rec.minute / 60.0
            wdprov.rewind()
        elif wdprov.nrecords() == 8760:
            instantaneous = false
            ts_shift_hours = 0.5
        else:
            self.throw_exec_error("pvwattsv7", "Minute column required in weather data for subhourly data or data that is not continuous over one year.")
        self.assign("ts_shift_hours", var_data(ssc_number_t(ts_shift_hours)))
        var wf: weather_record
        var nyears: Int = 1
        var degradationFactor: List[Float64]
        if self.as_boolean("system_use_lifetime_output"):
            if not wdprov.annualSimulation():
                self.throw_exec_error("pvwattsv7", "Simulation cannot be run over analysis period for weather data that is not continuous over one year. Set system_use_lifetime_output to 0 to resolve this issue.")
            nyears = self.as_unsigned_long("analysis_period")
            var dc_degradation: List[Float64] = self.as_vector_double("dc_degradation")
            if len(dc_degradation) == 1:
                degradationFactor.append(1.0)
                for y in range(1, nyears):
                    degradationFactor.append(pow((1.0 - dc_degradation[0] / 100.0), y))
            else:
                if len(dc_degradation) != nyears:
                    self.throw_exec_error("pvwattsv7", "Length of degradation array must be equal to analysis period.")
                for y in range(nyears):
                    degradationFactor.append(1.0 - dc_degradation[y] / 100.0)
        else:
            degradationFactor.append(1.0)
        var nrec: Int = wdprov.nrecords()
        var nlifetime: Int = nrec * nyears
        var step_per_hour: Int = 1
        if wdprov.annualSimulation():
            step_per_hour = nrec / 8760
        if wdprov.annualSimulation() and (step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != nrec):
            self.throw_exec_error("pvwattsv7", util.format("Invalid number of data records (%d): must be an integer multiple of 8760.", nrec))
        var ts_hour: Float64 = 1.0 / Float64(step_per_hour)
        var wm2_to_wh: Float64 = module_m2 * ts_hour
        var gustf: Float64 = Float64.NaN
        if self.is_assigned("gust_factor"): gustf = self.as_double("gust_factor")
        var gf: Float64 = gustf
        if not isfinite(gf):
            var ts_sec: Float64 = ts_hour * 3600.0
            if ts_sec >= 600:
                gf = 1.28
            elif ts_sec >= 180:
                gf = 1.21
            elif ts_sec >= 120:
                gf = 1.15
            elif ts_sec >= 60:
                gf = 1.13
            else:
                gf = 1.0
        var p_gh: Pointer[ssc_number_t] = self.allocate("gh", nrec)
        var p_dn: Pointer[ssc_number_t] = self.allocate("dn", nrec)
        var p_df: Pointer[ssc_number_t] = self.allocate("df", nrec)
        var p_tamb: Pointer[ssc_number_t] = self.allocate("tamb", nrec)
        var p_wspd: Pointer[ssc_number_t] = self.allocate("wspd", nrec)
        var p_snow: Pointer[ssc_number_t] = self.allocate("snow", nrec)
        var p_sunup: Pointer[ssc_number_t] = self.allocate("sunup", nrec)
        var p_aoi: Pointer[ssc_number_t] = self.allocate("aoi", nrec)
        var p_shad_beam: Pointer[ssc_number_t] = self.allocate("shad_beam_factor", nrec)
        var p_stow: Pointer[ssc_number_t] = self.allocate("tracker_stowing", nrec)
        var p_tmod: Pointer[ssc_number_t] = self.allocate("tcell", nrec)
        var p_dcshadederate: Pointer[ssc_number_t] = self.allocate("dcshadederate", nrec)
        var p_dcsnowderate: Pointer[ssc_number_t] = self.allocate("dcsnowderate", nrec)
        var p_poa: Pointer[ssc_number_t] = self.allocate("poa", nrec)
        var p_tpoa: Pointer[ssc_number_t] = self.allocate("tpoa", nrec)
        var p_dc: Pointer[ssc_number_t] = self.allocate("dc", nrec)
        var p_ac: Pointer[ssc_number_t] = self.allocate("ac", nrec)
        var p_gen: Pointer[ssc_number_t] = self.allocate("gen", nlifetime)
        var tccalc: pvwatts_celltemp = pvwatts_celltemp(self.pv.inoct + 273.15, PVWATTS_HEIGHT, ts_hour)
        var annual_kwh: Float64 = 0
        var idx_life: Int = 0
        var percent: Float32 = 0.0
        const NSTATUS_UPDATES: Int = 50
        for y in range(nyears):
            for idx in range(nrec):
                if not wdprov.read(&wf):
                    self.throw_exec_error("pvwattsv7", util.format("could not read data line %d of %d in weather file", idx + 1, nrec))
                var hour_of_year: Int = util.hour_of_year(wf.month, wf.day, wf.hour)
                if nrec > 50:
                    if idx % (nrec / NSTATUS_UPDATES) == 0:
                        percent = 100.0 * (Float32(idx_life) + 1) / Float32(nlifetime)
                        if percent > 100.0: percent = 99.0
                        if not self.update("", percent, Float32(hour_of_year)):
                            self.throw_exec_error("pvwattsv7", "Simulation stopped at hour " + util.to_string(hour_of_year + 1.0))
                var tracker_stowing: Bool = false
                p_gh[idx] = ssc_number_t(wf.gh)
                p_dn[idx] = ssc_number_t(wf.dn)
                p_df[idx] = ssc_number_t(wf.df)
                p_tamb[idx] = ssc_number_t(wf.tdry)
                p_wspd[idx] = ssc_number_t(wf.wspd)
                p_snow[idx] = ssc_number_t(wf.snow)
                p_tmod[idx] = ssc_number_t(wf.tdry)
                var alb: Float64 = 0.2
                if isfinite(wf.snow) and wf.snow > 0.5 and wf.snow < 999 and en_snowloss:
                    alb = 0.6
                if albedo_len == 1:
                    alb = albedo[0]
                elif albedo_len == 12:
                    alb = albedo[wf.month - 1]
                elif albedo_len == nrec:
                    alb = albedo[idx]
                elif self.is_assigned("albedo"):
                    self.log(util.format("Albedo array was assigned but is not the correct length (1, 12, or %d entries). Using default value.", nrec), SSC_WARNING)
                if isfinite(wf.alb) and wf.alb > 0 and wf.alb < 1 and albedo_len == 0:
                    alb = wf.alb
                var irr: irrad = irrad()
                irr.set_time(wf.year, wf.month, wf.day, wf.hour, wf.minute, instantaneous ? IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET : ts_hour)
                irr.set_location(hdr.lat, hdr.lon, hdr.tz)
                irr.set_optional(hdr.elev, wf.pres, wf.tdry)
                irr.set_sky_model(2, alb)
                irr.set_beam_diffuse(wf.dn, wf.df)
                var track_mode: Int = 0
                match self.pv.type:
                    case FIXED_RACK, FIXED_ROOF: track_mode = 0
                    case ONE_AXIS, ONE_AXIS_BACKTRACKING: track_mode = 1
                    case TWO_AXIS: track_mode = 2
                    case AZIMUTH_AXIS: track_mode = 3
                irr.set_surface(track_mode, self.pv.tilt, self.pv.azimuth, self.pv.rotlim, self.pv.type == ONE_AXIS_BACKTRACKING, self.pv.gcr, false, 0.0)
                var code: Int = irr.calc()
                var solazi: Float64; var solzen: Float64; var solalt: Float64; var aoi: Float64; var stilt: Float64; var sazi: Float64; var rot: Float64; var btd: Float64
                var sunup: Int
                var ibeam: Float64 = 0.0; var iskydiff: Float64 = 0.0; var ignddiff: Float64 = 0.0; var irear: Float64 = 0.0
                var poa: Float64 = 0; var tpoa: Float64 = 0; var tmod: Float64 = 0; var dc: Float64 = 0; var ac: Float64 = 0
                irr.get_sun(&solazi, &solzen, &solalt, none, none, none, &sunup, none, none, none)
                irr.get_angles(&aoi, &stilt, &sazi, &rot, &btd)
                irr.get_poa(&ibeam, &iskydiff, &ignddiff, none, none, none)
                if self.module.bifaciality > 0:
                    irr.calc_rear_side(bifacialTransmissionFactor, 1, self.module.length * Float64(self.pv.nmody))
                    irear = irr.get_poa_rear() * self.module.bifaciality
                if -1 == code:
                    self.log(util.format("Beam irradiance exceeded extraterrestrial value at record [y:%d m:%d d:%d h:%d].", wf.year, wf.month, wf.day, wf.hour))
                elif 0 != code:
                    self.throw_exec_error("pvwattsv7", util.format("Failed to process irradiation on surface (code: %d) [y:%d m:%d d:%d h:%d].", code, wf.year, wf.month, wf.day, wf.hour))
                p_sunup[idx] = ssc_number_t(sunup)
                p_aoi[idx] = ssc_number_t(aoi)
                var shad_beam: Float64 = 1.0
                if shad.fbeam(hour_of_year, wf.minute, solalt, solazi):
                    shad_beam = shad.beam_shade_factor()
                p_shad_beam[idx] = ssc_number_t(shad_beam)
                if sunup > 0:
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["poa_nominal"] += (ibeam + iskydiff + ignddiff) * wm2_to_wh
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["poa_loss_bifacial"] += (-irear) * wm2_to_wh
                    if (self.pv.type == ONE_AXIS or self.pv.type == ONE_AXIS_BACKTRACKING or self.pv.type == TWO_AXIS) and isfinite(wf.wspd) and wf.wspd > 0 and isfinite(wstow) and enable_wind_stow:
                        var gust: Float64 = gf * wf.wspd
                        if gust > wstow:
                            var poa_no_stow: Float64 = ibeam + iskydiff + ignddiff
                            if self.pv.type == TWO_AXIS:
                                irr.set_surface(0,  # tracking 0=fixed
                                    0, 180,  # tilt, azimuth
                                    0, 0, 0.4, false, 0.0)
                            else:
                                var stow_angle: Float64 = fabs(wind_stow_angle_deg)
                                if rot < 0: stow_angle = -stow_angle
                                irr.set_surface(1, self.pv.tilt, self.pv.azimuth,
                                    stow_angle,
                                    false,
                                    self.pv.gcr,
                                    true, stow_angle)
                            irr.calc()
                            var irear_stow: Float64 = 0.0
                            if self.module.bifaciality > 0:
                                irr.calc_rear_side(bifacialTransmissionFactor, 1, self.module.length * Float64(self.pv.nmody))
                                irear_stow = irr.get_poa_rear() * self.module.bifaciality
                            irr.get_angles(&aoi, &stilt, &sazi, &rot, &btd)
                            irr.get_poa(&ibeam, &iskydiff, &ignddiff, none, none, none)
                            var poa_stow: Float64 = ibeam + iskydiff + ignddiff
                            var stow_loss: Float64 = (poa_no_stow - poa_stow) + (irear - irear_stow)
                            if y == 0 and wdprov.annualSimulation():
                                self.ld["poa_loss_tracker_stow"] += stow_loss * wm2_to_wh
                            irear = irear_stow
                            tracker_stowing = true
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["poa_loss_ext_beam_shade"] += ibeam * (1.0 - shad_beam) * wm2_to_wh
                    ibeam *= shad_beam
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["poa_loss_ext_diff_shade"] += (iskydiff + ignddiff) * (1.0 - shad.fdiff()) * wm2_to_wh
                    iskydiff *= shad.fdiff()
                    irear *= shad.fdiff()
                    var ibeam_unselfshaded: Float64 = ibeam
                    var f_nonlinear: Float64 = 1.0
                    var Fskydiff: Float64 = 1.0
                    var Fgnddiff: Float64 = 1.0
                    if en_self_shading:
                        var shad1xf: Float64 = 0.0
                        if self.pv.type == ONE_AXIS:
                            shad1xf = shadeFraction1x(solazi, solzen, self.pv.tilt, self.pv.azimuth, self.pv.gcr, rot)
                        var ssin: ssinputs = ssinputs()
                        ssin.nstrx = Int(Float64(self.pv.nmodx) / self.pv.nmodperstr)
                        ssin.nmodx = self.pv.nmodx
                        ssin.nmody = self.pv.nmody
                        ssin.nrows = self.pv.nrows
                        ssin.length = self.module.length
                        ssin.width = self.module.width
                        ssin.mod_orient = 0
                        ssin.str_orient = 1
                        ssin.row_space = self.pv.row_spacing
                        ssin.ndiode = self.module.ndiode
                        ssin.Vmp = self.module.vmp
                        ssin.mask_angle_calc_method = 0
                        ssin.FF0 = self.module.ff
                        var ssout: ssoutputs = ssoutputs()
                        if not ss_exec(ssin, stilt, sazi, solzen, solazi, wf.dn, wf.df, ibeam * (1.0 - shad1xf), iskydiff, ignddiff, alb, self.pv.type == ONE_AXIS, self.module.type == THINFILM, shad1xf, ssSkyDiffuseTable, ssout):
                            self.throw_exec_error("pvwattsv7", util.format("Self-shading calculation failed at %d.", idx_life))
                        if self.pv.type == FIXED_RACK:
                            if y == 0 and wdprov.annualSimulation():
                                self.ld["poa_loss_self_beam_shade"] += ibeam * ssout.m_shade_frac_fixed * wm2_to_wh
                            ibeam *= (1 - ssout.m_shade_frac_fixed)
                        elif self.pv.type == ONE_AXIS:
                            if y == 0 and wdprov.annualSimulation():
                                self.ld["poa_loss_self_beam_shade"] += ibeam * shad1xf * wm2_to_wh
                            ibeam *= (1 - shad1xf)
                        Fskydiff = ssout.m_diffuse_derate
                        Fgnddiff = ssout.m_reflected_derate
                    if Fskydiff >= -0.00001 and Fskydiff <= 1.00001:
                        if y == 0 and wdprov.annualSimulation():
                            self.ld["poa_loss_self_diff_shade"] += (1.0 - Fskydiff) * (iskydiff + irear) * wm2_to_wh
                        iskydiff *= Fskydiff
                        irear *= Fskydiff
                    else:
                        self.log(util.format("Sky diffuse reduction factor invalid at time %lg: fskydiff=%lg, stilt=%lg.", idx, Fskydiff, stilt), SSC_NOTICE, Float32(idx))
                    if Fgnddiff >= -0.00001 and Fgnddiff <= 1.00001:
                        if y == 0 and wdprov.annualSimulation():
                            self.ld["poa_loss_self_diff_shade"] += (1.0 - Fgnddiff) * ignddiff * wm2_to_wh
                        ignddiff *= Fgnddiff
                    else:
                        self.log(util.format("Ground diffuse reduction factor invalid at time %lg: fgnddiff=%lg, stilt=%lg.", idx, Fgnddiff, stilt), SSC_NOTICE, Float32(idx))
                    if self.is_assigned("soiling"):
                        var soiling_f: Float64 = 0.0
                        if soiling_len == 1:
                            soiling_f = Float64(soiling[0]) * 0.01
                        elif soiling_len == 12:
                            soiling_f = Float64(soiling[wf.month - 1]) * 0.01
                        elif soiling_len == nrec:
                            soiling_f = Float64(soiling[idx]) * 0.01
                        else:
                            self.throw_exec_error("pvwattsv7", "Soiling input array must have 1, 12, or nrecords values.")
                        if y == 0 and wdprov.annualSimulation():
                            self.ld["poa_loss_soiling"] += (ibeam + iskydiff + ignddiff) * soiling_f * wm2_to_wh
                        ibeam *= (1.0 - soiling_f)
                        iskydiff *= (1.0 - soiling_f)
                        ignddiff *= (1.0 - soiling_f)
                    else:
                        if y == 0 and wdprov.annualSimulation():
                            self.ld["poa_loss_soiling"] = 0
                    var poa_front: Float64 = ibeam + iskydiff + ignddiff
                    poa = poa_front + irear
                    var dc_nom: Float64 = self.pv.dc_nameplate * poa / 1000
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["dc_nominal"] += dc_nom * ts_hour
                    var f_cover: Float64 = 1.0
                    if aoi > AOI_MIN and aoi < AOI_MAX and poa_front > 0:
                        tpoa = calculateIrradianceThroughCoverDeSoto(aoi, solzen, stilt, ibeam, iskydiff, ignddiff, en_sdm == 0 and self.module.ar_glass)
                        if tpoa < 0.0: tpoa = 0.0
                        if tpoa > poa: tpoa = poa_front
                        f_cover = tpoa / poa_front
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["dc_loss_cover"] += (1 - f_cover) * dc_nom * ts_hour
                    var f_AM: Float64 = air_mass_modifier(solzen, hdr.elev, AMdesoto)
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["dc_loss_spectral"] += (1 - f_AM) * dc_nom * ts_hour
                    var wspd_corr: Float64 = wf.wspd if wf.wspd >= 0 else 0
                    tmod = tccalc(poa, wspd_corr, wf.tdry)
                    var f_temp: Float64 = (1.0 + self.module.gamma * (tmod - 25.0))
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["dc_loss_thermal"] += dc_nom * (1.0 - f_temp) * ts_hour
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["dc_loss_nonlinear"] += dc_nom * (1.0 - f_nonlinear) * ts_hour
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["dc_loss_other"] += dc_nom * self.pv.dc_loss_percent * 0.01 * ts_hour
                    var f_losses: Float64 = (1 - self.pv.dc_loss_percent * 0.01)
                    var f_snow: Float64 = 1.0
                    if en_snowloss:
                        var smLoss: Float32 = 0.0
                        if not snowmodel.getLoss(Float32(poa), Float32(stilt), Float32(wf.wspd), Float32(wf.tdry), Float32(wf.snow), sunup, Float32(ts_hour), smLoss):
                            if not snowmodel.good:
                                self.throw_exec_error("pvwattsv7", snowmodel.msg)
                        f_snow = (1.0 - smLoss)
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["dc_loss_snow"] += dc_nom * (1.0 - f_snow) * ts_hour
                    var poa_for_power: Float64 = (f_nonlinear < 1.0 and poa > 0.0) ? (ibeam_unselfshaded + iskydiff + ignddiff) : (ibeam + iskydiff + ignddiff)
                    poa_for_power *= f_cover * f_AM
                    poa_for_power += irear * f_AM
                    if en_sdm:
                        var P_single_module_sdm: Float64 = self.sdmml_power(self.sdm, poa_for_power, tmod)
                        dc = P_single_module_sdm * self.pv.dc_nameplate / (self.sdm.Vmp * self.sdm.Imp)
                    else:
                        dc = self.pv.dc_nameplate * (poa_for_power / 1000) * f_temp
                    dc *= f_nonlinear * f_snow * f_losses
                    dc *= degradationFactor[y]
                    var etanom: Float64 = self.pv.inv_eff_percent * 0.01
                    var etaref: Float64 = 0.9637
                    var A: Float64 = -0.0162
                    var B: Float64 = -0.0059
                    var C: Float64 = 0.9858
                    var pdc0: Float64 = self.pv.ac_nameplate / etanom
                    var plr: Float64 = dc / pdc0
                    ac = 0
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["ac_nominal"] += dc * ts_hour
                    if plr > 0:
                        var eta: Float64 = (A * plr + B / plr + C) * etanom / etaref
                        ac = dc * eta
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["ac_loss_efficiency"] += (dc - ac) * ts_hour
                    var cliploss: Float64 = ac > self.pv.ac_nameplate ? ac - self.pv.ac_nameplate : 0.0
                    if y == 0 and wdprov.annualSimulation():
                        self.ld["ac_loss_inverter_clipping"] += cliploss * ts_hour
                    ac -= cliploss
                    if ac < 0: ac = 0
                    p_dcshadederate[idx] = ssc_number_t(f_nonlinear)
                    p_dcsnowderate[idx] = ssc_number_t(f_snow)
                else:
                    poa = 0
                    tpoa = 0
                    tmod = wf.tdry
                    dc = 0
                    ac = 0
                var iron_loss: Float64 = self.pv.xfmr_nll_f * self.pv.xfmr_rating
                var winding_loss: Float64 = self.pv.xfmr_ll_f * ac * (ac / self.pv.xfmr_rating)
                var xfmr_loss: Float64 = iron_loss + winding_loss
                if y == 0 and wdprov.annualSimulation():
                    self.ld["ac_loss_transformer"] += xfmr_loss * ts_hour
                ac -= xfmr_loss
                p_stow[idx] = 1.0 if tracker_stowing else 0.0
                p_shad_beam[idx] = ssc_number_t(shad_beam)
                p_poa[idx] = ssc_number_t(poa)
                p_tpoa[idx] = ssc_number_t(tpoa)
                p_tmod[idx] = ssc_number_t(tmod)
                p_dc[idx] = ssc_number_t(dc)
                p_ac[idx] = ssc_number_t(ac)
                p_gen[idx_life] = ssc_number_t(ac * haf.haf(hour_of_year) * util.watt_to_kilowatt)  # need to check haf method name
                if y == 0 and wdprov.annualSimulation():
                    annual_kwh += p_gen[idx] / Float64(step_per_hour)
                if y == 0 and wdprov.annualSimulation():
                    self.ld["ac_loss_adjustments"] += ac * (1.0 - haf.haf(hour_of_year)) * ts_hour
                if y == 0 and wdprov.annualSimulation():
                    self.ld["ac_delivered"] += ac * haf.haf(hour_of_year) * ts_hour
                idx_life += 1
            wdprov.rewind()
        if wdprov.annualSimulation():
            self.accumulate_monthly_for_year("gen", "monthly_energy", ts_hour, step_per_hour)
            self.accumulate_annual_for_year("gen", "annual_energy", ts_hour, step_per_hour)
            self.accumulate_monthly("dc", "dc_monthly", 0.001 * ts_hour)
            self.accumulate_monthly("ac", "ac_monthly", 0.001 * ts_hour)
            var poam: Pointer[ssc_number_t] = self.accumulate_monthly("poa", "poa_monthly", 0.001 * ts_hour)
            var solrad: Pointer[ssc_number_t] = self.allocate("solrad_monthly", 12)
            var solrad_ann: Float64 = 0
            for m in range(12):
                solrad[m] = poam[m] / util.nday[m]
                solrad_ann += solrad[m]
            self.assign("solrad_annual", var_data(ssc_number_t(solrad_ann / 12)))
            self.accumulate_annual("ac", "ac_annual", 0.001 * ts_hour)
            var kWhperkW: Float64 = util.kilowatt_to_watt * annual_kwh / self.pv.dc_nameplate
            self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
            self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
        self.assign("location", var_data(hdr.location))
        self.assign("city", var_data(hdr.city))
        self.assign("state", var_data(hdr.state))
        self.assign("lat", var_data(ssc_number_t(hdr.lat)))
        self.assign("lon", var_data(ssc_number_t(hdr.lon)))
        self.assign("tz", var_data(ssc_number_t(hdr.tz)))
        self.assign("elev", var_data(ssc_number_t(hdr.elev)))
        self.assign("percent_complete", var_data(ssc_number_t(percent)))
        var gcr_for_land: Float64 = self.pv.gcr
        if gcr_for_land < 0.01: gcr_for_land = 1.0
        var landf: Float64 = self.is_assigned("landf") ? self.as_number("landf") : 1.0
        self.assign("land_acres", var_data(ssc_number_t(landf * module_m2 / gcr_for_land * 0.0002471)))
        self.assign("inverter_efficiency", var_data(ssc_number_t(self.as_double("inv_eff"))))
        if en_snowloss and snowmodel.badValues > 0:
            self.log(util.format("The snow model has detected %d bad snow depth values (less than 0 or greater than 610 cm). These values have been set to zero.", snowmodel.badValues), SSC_WARNING)
        if wdprov.annualSimulation():
            if not self.ld.assign(self, "lossd_"):
                self.log(self.ld.errormsg(), SSC_WARNING)

# Module entry point (equivalent to DEFINE_MODULE_ENTRY macro)
def define_module_entry(module_class: type, name: String, desc: String, version: Int) -> None:
    # Registration logic would go here; assume it's handled by framework

define_module_entry(cm_pvwattsv7, "PVWatts V7 - integrated hourly weather reader and PV system simulator.", 3)