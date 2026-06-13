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
from math import *
from common import *
from core import *
from lib_weatherfile import *
from lib_irradproc import *
from lib_time import *
from lib_util import *
/* -------------------------------------
v10a
- deleted commented out code
- moved some comments
3 Mode Model
"SIMPLIFIED SOLAR WATER HEATER SIMULATION
 USING ON A MULTI-MODE TANK MODEL"
Craig Christensen, Jeff Maguire, Jay Burch, Nick DiOrio
Technical reference: Duffie and Beckman (D&B) "Solar Engineering of Thermal Processes" 3rd Edition 2006
Time Marching Method: Implicit Euler
Conduction Between Nodes: Off
SUBHOURLY VERSION !!!
Uses inputs from TRNSYS subhourly outputs for:
1. Irradiation quantities on tilted surface
2. Weather -> Ambient temperature, mains temperature
3. Angle of Incidence
Still outputs hourly quantities
7/7/2015 - Nick DiOrio - modified FprimeUL to use single collector not full system area
-------------------------------------- */

const M_PI: Float64 = 3.141592653589793238462643

type ssc_number_t = Float32

var _cm_vtab_swh: List[VarInfo] = [
	/*   VARTYPE           DATATYPE         NAME                      LABEL                              UNITS     META                                  GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	{ SSC_INPUT,        SSC_STRING,      "solar_resource_file",   "local weather file path",             "",        "",                                  "Solar Resource",   "?",                      "LOCAL_FILE",                         "" },
    { SSC_INPUT,        SSC_TABLE,       "solar_resource_data",   "Weather data",                        "",        "dn,df,tdry,wspd,lat,lon,tz",        "Solar Resource",   "?",                       "",                              "" },
	{ SSC_INPUT,        SSC_ARRAY,       "scaled_draw",           "Hot water draw",                      "kg/hr",   "",                                  "SWH",              "*",                      "LENGTH=8760",						 "" },
	{ SSC_INPUT,        SSC_NUMBER,      "system_capacity",       "Nameplate capacity",                  "kW",      "",                                  "SWH",              "*",                      "", "" },
	{ SSC_INPUT,        SSC_ARRAY,       "load",                  "Electricity load (year 1)",           "kW",      "",                                  "SWH",              "",                       "", "" },
    { SSC_INPUT,        SSC_ARRAY,       "load_escalation",       "Annual load escalation",              "%/year",  "",                                  "SWH",             "?=0",                    "",                              "" },
	{ SSC_INPUT,        SSC_NUMBER,      "tilt",                  "Collector tilt",                      "deg",     "",                                  "SWH",              "*",                      "MIN=0,MAX=90",                       "" },
	{ SSC_INPUT,        SSC_NUMBER,      "azimuth",               "Collector azimuth",                   "deg",     "90=E,180=S",                        "SWH",              "*",                      "MIN=0,MAX=360",                      "" },
	{ SSC_INPUT,        SSC_NUMBER,      "albedo",                "Ground reflectance factor",           "0..1",    "",                                  "SWH",              "*",                      "FACTOR",                             "" },
	{ SSC_INPUT,        SSC_NUMBER,      "irrad_mode",            "Irradiance input mode",               "0/1/2",   "Beam+Diff,Global+Beam,Global+Diff", "SWH",              "?=0",                    "INTEGER,MIN=0,MAX=2",                "" },
	{ SSC_INPUT,        SSC_NUMBER,      "sky_model",             "Tilted surface irradiance model",     "0/1/2",   "Isotropic,HDKR,Perez",  "SWH",      "?=1",                                        "INTEGER,MIN=0,MAX=2",                "" },
	{ SSC_INPUT,        SSC_MATRIX,      "shading:timestep",      "Time step beam shading loss",          "%",      "",                                  "SWH",              "?",                       "",                                  "" },
	{ SSC_INPUT,        SSC_MATRIX,      "shading:mxh",           "Month x Hour beam shading loss",       "%",      "",                                  "SWH",              "?",                       "",                                  "" },
	{ SSC_INPUT,        SSC_MATRIX,      "shading:azal",          "Azimuth x altitude beam shading loss", "%",      "",                                  "SWH",              "?",                       "",                                  "" },
	{ SSC_INPUT,        SSC_NUMBER,      "shading:diff",          "Diffuse shading loss",                 "%",      "",                                  "SWH",              "?",                       "",                                  "" },
	{ SSC_INPUT,        SSC_NUMBER,      "mdot",                  "Total system mass flow rate",          "kg/s",   "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "ncoll",                 "Number of collectors",                 "",       "",                                  "SWH",              "*",                       "POSITIVE,INTEGER",                  "" },
	{ SSC_INPUT,        SSC_NUMBER,      "fluid",			      "Working fluid in system",              "",       "Water,Glycol",                      "SWH",              "*",                       "INTEGER,MIN=0,MAX=1",               "" },
	{ SSC_INPUT,        SSC_NUMBER,      "area_coll",             "Single collector area",                "m2",     "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "FRta",                  "FRta",                                 "",       "",                                  "SWH",              "*",                       "",                                  "" },
	{ SSC_INPUT,        SSC_NUMBER,      "FRUL",                  "FRUL",                                 "",       "",                                  "SWH",              "*",                       "",                                  "" },
	{ SSC_INPUT,        SSC_NUMBER,      "iam",                   "Incidence angle modifier",             "",       "",                                  "SWH",              "*",                       "",                                  "" },
	{ SSC_INPUT,        SSC_NUMBER,      "test_fluid",            "Fluid used in collector test",         "",       "Water,Glycol",                      "SWH",              "*",                       "INTEGER,MIN=0,MAX=1",               "" },
	{ SSC_INPUT,        SSC_NUMBER,      "test_flow",             "Flow rate used in collector test",     "kg/s",   "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "pipe_length",           "Length of piping in system",           "m",      "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "pipe_diam",             "Pipe diameter",                        "m",      "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "pipe_k",                "Pipe insulation conductivity",         "W/m-C", "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "pipe_insul",            "Pipe insulation thickness",            "m",      "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "tank_h2d_ratio",        "Solar tank height to diameter ratio",  "",       "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "U_tank",                "Solar tank heat loss coefficient",     "W/m2K",  "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "V_tank",                "Solar tank volume",                    "m3",     "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "hx_eff",                "Heat exchanger effectiveness",         "0..1",   "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "T_room",                "Temperature around solar tank",        "C",      "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "T_tank_max",            "Max temperature in solar tank",        "C",      "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "T_set",                 "Set temperature",                      "C",      "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "pump_power",            "Pump power",                           "W",      "",                                  "SWH",              "*",                       "POSITIVE",                          "" },
	{ SSC_INPUT,        SSC_NUMBER,      "pump_eff",              "Pumping efficiency",                   "%",      "",                                  "SWH",              "*",                       "PERCENT",                           "" },
	{ SSC_INPUT,        SSC_NUMBER,      "use_custom_mains",      "Use custom mains",                     "%",      "",                                  "SWH",              "*",                       "INTEGER,MIN=0,MAX=1",               "" },
	{ SSC_INPUT,        SSC_ARRAY,       "custom_mains",          "Custom mains",						  "C",      "",                                  "SWH",              "*",                       "LENGTH=8760",                       "" },
	{ SSC_INPUT,        SSC_NUMBER,      "use_custom_set",		  "Use custom set points",                "%",      "",                                  "SWH",              "*",                       "INTEGER,MIN=0,MAX=1",               "" },
	{ SSC_INPUT,        SSC_ARRAY,       "custom_set",            "Custom set points",					  "C",      "",                                  "SWH",              "*",                       "LENGTH=8760",                       "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "beam",                  "Irradiance - Beam",                    "W/m2",   "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "diffuse",               "Irradiance - Diffuse",                 "W/m2",   "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "I_incident",            "Irradiance - Incident",                "W/m2",   "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "I_transmitted",         "Irradiance - Transmitted",             "W/m2",   "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "shading_loss",          "Shading losses",                       "%",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Q_transmitted",         "Q transmitted",                        "kW",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Q_useful",              "Q useful",                             "kW",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Q_deliv",               "Q delivered",                          "kW",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Q_loss",                "Q loss",                               "kW",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Q_aux",                 "Q auxiliary",                          "kW",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Q_auxonly",             "Q auxiliary only",                     "kW",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "P_pump",                "P pump",                               "kW",      "",                                 "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "T_amb",                 "T ambient",						      "C",		"",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "T_cold",                "T cold",                               "C",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "T_deliv",               "T delivered",                          "C",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "T_hot",                 "T hot",                                "C",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "T_mains",               "T mains",						      "C",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "T_tank",                "T tank",                               "C",      "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "V_hot",                 "V hot",                                "m3",     "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "V_cold",                "V cold",                               "m3",     "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "draw",                  "Hot water draw",                       "kg/hr",  "",                                  "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "mode",                  "Operation mode",                       "",       "1,2,3,4",                           "Time Series",      "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "monthly_Q_deliv",		  "Q delivered",                         "kWh",     "",                                  "Monthly",          "*",                        "LENGTH=12",                        "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "monthly_Q_aux",		  "Q auxiliary",                         "kWh",     "",                                  "Monthly",          "*",                        "LENGTH=12",                        "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "monthly_Q_auxonly",	  "Q auxiliary only",                    "kWh",     "",                                  "Monthly",          "*",                        "LENGTH=12",                        "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "monthly_energy",		  "System energy",                       "kWh",     "",                                  "Monthly",          "*",                        "LENGTH=12",                        "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "annual_Q_deliv",		  "Q delivered",                         "kWh",     "",                                  "Annual",           "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "annual_Q_aux",		  "Q auxiliary",                         "kWh",     "",                                  "Annual",           "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "annual_Q_auxonly",	  "Q auxiliary only",                    "kWh",     "",                                  "Annual",           "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "annual_energy",		  "System energy",                       "kWh",     "",                                  "Annual",           "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "solar_fraction",		  "Solar fraction",                      "",        "",                                  "Annual",           "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "capacity_factor",       "Capacity factor",                     "%",       "",                                  "Annual",           "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "kwh_per_kw",            "First year kWh/kW",                   "kWh/kW",  "",                                  "Annual",           "*",                        "",                                 "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "ts_shift_hours",        "Time offset for interpreting time series outputs",  "hours", "",                      "Miscellaneous",    "*",                        "",                                 "" },
	var_info_invalid ]

class cm_swh(compute_module):
	def __init__(self):
		self.add_var_info(_cm_vtab_swh)
		self.add_var_info(vtab_adjustment_factors)
		self.add_var_info(vtab_technology_outputs)

	def exec(self):
		const watt_to_kw: Float64 = 0.001
		var wdprov: weather_data_provider
		if self.is_assigned("solar_resource_file"):
			var file: String = self.as_string("solar_resource_file")
			wdprov = weatherfile(file)
			var wfile: weatherfile = wdprov as weatherfile
			if not wfile.ok():
				raise exec_error("swh", wfile.message())
			if wfile.has_message():
				self.log(wfile.message(), SSC_WARNING)
		elif self.is_assigned("solar_resource_data"):
			wdprov = weatherdata(self.lookup("solar_resource_data"))
		else:
			raise exec_error("swh", "no weather data supplied")
		/* **********************************************************************
		Read user specified system parameters from compute engine
		********************************************************************** */
		var ts_shift_hours: Float64 = 0.0
		var instantaneous: bool = True
		if wdprov.has_data_column(weather_data_provider.MINUTE):
			var rec: weather_record
			if wdprov.read(&rec):
				ts_shift_hours = rec.minute / 60.0
			wdprov.rewind()
		elif wdprov.nrecords() == 8760:
			instantaneous = False
			ts_shift_hours = 0.5
		else:
			raise exec_error("swh", "subhourly weather files must specify the minute for each record")
		self.assign("ts_shift_hours", var_data(ssc_number_t(ts_shift_hours)))
		var haf: adjustment_factors = adjustment_factors(self, "adjust")
		if not haf.setup():
			raise exec_error("swh", "failed to setup adjustment factors: " + haf.error())
		var shad: shading_factor_calculator = shading_factor_calculator()
		if not shad.setup(self, ""):
			raise exec_error("swh", shad.get_error())
		/* constant fluid properties */
		var Cp_water: Float64 = 4182.  # Cp_water@40'C (J/kg.K)
		var rho_water: Float64 = 1000.  # 992.2; // density of water, kg/m3 @ 40'C
		var Cp_glycol: Float64 = 3400  # 3705; // Cp_glycol
		/* sky model properties */
		var albedo: Float64 = self.as_double("albedo")  # ground reflectance fraction
		var tilt: Float64 = self.as_double("tilt")  # collector tilt in degrees
		var azimuth: Float64 = self.as_double("azimuth")  # collector azimuth in degrees  (180=south, 90=east)
		var irrad_mode: Int = self.as_integer("irrad_mode")  # 0=beam&diffuse, 1=total&beam, 2=total&diffuse
		var sky_model: Int = self.as_integer("sky_model")  # 0=isotropic, 1=hdkr, 2=perez
		/* extract arrays */
		var len: size_t
		var draw: Pointer[ssc_number_t] = self.as_array("scaled_draw", &len)
		if len != 8760:
			raise exec_error("swh", "draw profile must have 8760 values")
		var custom_mains: Pointer[ssc_number_t] = self.as_array("custom_mains", &len)
		if len != 8760:
			raise exec_error("swh", "custom mains profile must have 8760 values")
		var custom_set: Pointer[ssc_number_t] = self.as_array("custom_set", &len)
		if len != 8760:
			raise exec_error("swh", "custom set temperature profile must have 8760 values")
		/* working fluid settings */
		var ifluid: Int = self.as_integer("fluid")  # 0=water, 1=glycol
		var fluid_cp: Float64 = Cp_water if ifluid == 0 else Cp_glycol  # working fluid specific heat in J/kgK
		var itest: Int = self.as_integer("test_fluid")  # 0=water, 1=glycol
		var test_cp: Float64 = Cp_water if itest == 0 else Cp_glycol  # test fluid specific heat in J/kgK
		var test_flow: Float64 = self.as_double("test_flow")  # collector test flow rate (kg/s)
		/* collector properties */
		var mdot_total: Float64 = self.as_double("mdot")  # total system mass flow rate (kg/s)
		var ncoll: Int = self.as_integer("ncoll")
		var area_total: Float64 = self.as_double("area_coll") * ncoll  # total solar collector area (m2)
		var area_coll: Float64 = self.as_double("area_coll")
		var FRta: Float64 = self.as_double("FRta")  # FR(ta)_n (D&B pp 291) (dimensionless)
		var FRUL: Float64 = self.as_double("FRUL")  # FRUL (D&B pp 291) (W/m2.C)
		var iam: Float64 = self.as_double("iam")  # incidence angle modifier coefficient (D&B pp 297) (unitless)
		/* pipe properties */
		var pipe_diam: Float64 = self.as_double("pipe_diam")  # pipe diameter in system (m)
		var pipe_k: Float64 = self.as_double("pipe_k")  # pipe insulation conductivity (W/m2.C)
		var pipe_insul: Float64 = self.as_double("pipe_insul")  # pipe insulation thickness (m)
		var pipe_length: Float64 = self.as_double("pipe_length")  # length of piping in system (m)
		/* tank properties */
		var tank_h2d_ratio: Float64 = self.as_double("tank_h2d_ratio")  # ratio of tank height to diameter (dimensionless)
		var U_tank: Float64 = self.as_double("U_tank")  # W/m2.C storage tank heat loss coefficient (U-value)
		var V_tank: Float64 = self.as_double("V_tank")  # solar tank volume (m3)
		var tank_radius: Float64 = pow(V_tank / (2 * M_PI * tank_h2d_ratio), 0.33333333)
		var tank_height: Float64 = tank_radius * 2 * tank_h2d_ratio
		var tank_area: Float64 = 2 * M_PI * tank_radius * tank_radius + 2 * M_PI * tank_radius * tank_height  # 2*pi*R^2 + 2*pi*r*h
		var UA_tank: Float64 = tank_area * U_tank
		var tank_cross_section: Float64 = M_PI * tank_radius * tank_radius
		var m_tank: Float64 = rho_water * V_tank
		/* pipe, and heat exchange properties */
		var Eff_hx: Float64 = self.as_double("hx_eff")  # heat exchanger effectiveness (0..1)
		var pump_watts: Float64 = self.as_double("pump_power")  # pump size in Watts
		var pump_eff: Float64 = self.as_double("pump_eff")  # pumping efficiency
		var pipe_od: Float64 = pipe_diam + pipe_insul * 2
		var U_pipe: Float64 = 2 * pipe_k / (pipe_od * log(pipe_od / pipe_diam))  #  **TODO** CHECK whether should be pipe_diam*log(pipe_od/pipe_diam) in denominator
		var UA_pipe: Float64 = U_pipe * M_PI * pipe_od * pipe_length  # W/'C
		/* temperature properties */
		var T_room: Float64 = self.as_double("T_room")  # ambient temperature in mechanical room or location of storage tank, hx, etc
		var T_tank_max: Float64 = self.as_double("T_tank_max")  # max temp of water in storage tank
		var T_set: Float64 = self.as_double("T_set")  # hot water set point temperature
		/* **********************************************************************
		Initialize data storage, read weather file, set draw profile
		********************************************************************** */
		var hdr: weather_header
		wdprov.header(&hdr)
		var wf: weather_record
		var nrec: size_t = wdprov.nrecords()
		var step_per_hour: size_t = nrec // 8760
		if step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != nrec:
			raise exec_error("swh", util.format("invalid number of data records (%d): must be an integer multiple of 8760", int(nrec)))
		var ts_hour: Float64 = 1.0 / step_per_hour
		var ts_sec: Float64 = 3600.0 / step_per_hour
		var Beam: Pointer[ssc_number_t] = self.allocate("beam", nrec)
		var Diffuse: Pointer[ssc_number_t] = self.allocate("diffuse", nrec)
		var T_amb: Pointer[ssc_number_t] = self.allocate("T_amb", nrec)
		var T_mains: Pointer[ssc_number_t] = self.allocate("T_mains", nrec)
		var out_Draw: Pointer[ssc_number_t] = self.allocate("draw", nrec)
		var I_incident: Pointer[ssc_number_t] = self.allocate("I_incident", nrec)
		var I_transmitted: Pointer[ssc_number_t] = self.allocate("I_transmitted", nrec)
		var shading_loss: Pointer[ssc_number_t] = self.allocate("shading_loss", nrec)
		var out_Q_transmitted: Pointer[ssc_number_t] = self.allocate("Q_transmitted", nrec)
		var out_Q_useful: Pointer[ssc_number_t] = self.allocate("Q_useful", nrec)
		var out_Q_deliv: Pointer[ssc_number_t] = self.allocate("Q_deliv", nrec)
		var out_Q_loss: Pointer[ssc_number_t] = self.allocate("Q_loss", nrec)
		var out_T_tank: Pointer[ssc_number_t] = self.allocate("T_tank", nrec)
		var out_T_deliv: Pointer[ssc_number_t] = self.allocate("T_deliv", nrec)
		var out_P_pump: Pointer[ssc_number_t] = self.allocate("P_pump", nrec)
		var out_Q_aux: Pointer[ssc_number_t] = self.allocate("Q_aux", nrec)
		var out_Q_auxonly: Pointer[ssc_number_t] = self.allocate("Q_auxonly", nrec)
		var out_V_hot: Pointer[ssc_number_t] = self.allocate("V_hot", nrec)
		var out_V_cold: Pointer[ssc_number_t] = self.allocate("V_cold", nrec)
		var out_T_hot: Pointer[ssc_number_t] = self.allocate("T_hot", nrec)
		var out_T_cold: Pointer[ssc_number_t] = self.allocate("T_cold", nrec)
		var out_energy: Pointer[ssc_number_t] = self.allocate("gen", nrec)
		var Mode: Pointer[ssc_number_t] = self.allocate("mode", nrec)
		var temp_sum: Float64 = 0.0
		var temp_count: size_t = 0
		var monthly_avg_temp: Array[Float64, 12]
		var monthly_avg_count: Array[size_t, 12]
		for i in range(12):
			monthly_avg_temp[i] = 0.0
			monthly_avg_count[i] = 0
		var idx: size_t = 0
		for hour in range(8760):
			for jj in range(step_per_hour):
				if not wdprov.read(&wf):
					raise exec_error("swh", util.format("error reading from weather file at position %d", int(idx)))
				Beam[idx] = ssc_number_t(wf.dn)
				Diffuse[idx] = ssc_number_t(wf.df)
				T_amb[idx] = ssc_number_t(wf.tdry)
				T_mains[idx] = 0.
				I_incident[idx] = 0
				I_transmitted[idx] = 0
				temp_sum += T_amb[idx]
				temp_count += 1
				var imonth: Int = util.month_of(double(hour)) - 1
				monthly_avg_temp[imonth] += T_amb[idx]
				monthly_avg_count[imonth] += 1
				/* **********************************************************************
				Process radiation (Isotropic model), calculate Incident[i] through cover
				********************************************************************** */
				var tt: irrad = irrad()
				if irrad_mode == 0:
					tt.set_beam_diffuse(wf.dn, wf.df)
				elif irrad_mode == 2:
					tt.set_global_diffuse(wf.gh, wf.df)
				else:
					tt.set_global_beam(wf.gh, wf.dn)
				tt.set_location(hdr.lat, hdr.lon, hdr.tz)
				tt.set_optional(hdr.elev, wf.pres, wf.tdry)
				var instantaneous_use: Bool = instantaneous
				tt.set_time(wf.year, wf.month, wf.day, wf.hour, wf.minute,
					IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET if instantaneous_use else ts_hour)
				tt.set_sky_model(sky_model  # isotropic=0, hdkr=1, perez=2
 , albedo)
				tt.set_surface(0, tilt, azimuth, 0, 0, 0, False, 0.0)
				tt.calc()
				var poa: Array[Float64, 3]
				tt.get_poa(&poa[0], &poa[1], &poa[2], 0, 0, 0)
				I_incident[idx] = ssc_number_t(poa[0] + poa[1] + poa[2])  # total PoA on surface
				var solalt: Float64 = 0
				var solazi: Float64 = 0
				tt.get_sun(&solazi, 0, &solalt, 0, 0, 0, 0, 0, 0, 0)
				var aoi: Float64 = 0
				tt.get_angles(&aoi, 0, 0, 0, 0)  # note: angles returned in degrees
				var Kta_d: Float64 = 0.0
				var Kta_b: Float64 = 0.0
				var Kta_g: Float64 = 0.0
				if aoi <= 60.0:
					Kta_b = 1 - iam * (1 / cos(aoi * M_PI / 180) - 1)
				elif aoi > 60.0 and aoi <= 90.0:
					Kta_b = (1 - iam) * (aoi - 90.0) * M_PI / 180
				if Kta_b < 0:
					Kta_b = 0
				var theta_eff_diffuse: Float64 = 59.7 * M_PI / 180 - 0.1388 * tilt * M_PI / 180 + 0.001497 * tilt * M_PI / 180 * tilt * M_PI / 180
				var cos_theta_eff_diffuse: Float64 = cos(theta_eff_diffuse)
				if theta_eff_diffuse <= M_PI / 3.:
					Kta_d = 1 - iam * (1 / cos_theta_eff_diffuse - 1)
				elif theta_eff_diffuse > M_PI / 3. and theta_eff_diffuse <= M_PI / .2:
					Kta_d = (1 - iam) * (theta_eff_diffuse - M_PI / 2.)
				if Kta_d < 0:
					Kta_d = 0
				var theta_eff_ground: Float64 = 90 * M_PI / 180 - 0.5788 * tilt * M_PI / 180 + 0.002693 * tilt * M_PI / 180 * tilt * M_PI / 180
				var cos_theta_eff_ground: Float64 = cos(theta_eff_ground)
				if theta_eff_ground <= M_PI / 3:
					Kta_g = 1 - iam * (1 / cos_theta_eff_ground - 1)
				elif theta_eff_ground > M_PI / 3 and theta_eff_ground <= M_PI / 2:
					Kta_g = (1 - iam) * (theta_eff_ground - M_PI / 2.)
				if Kta_g < 0:
					Kta_g = 0
				var beam_loss_factor: Float64 = 1.0
				if shad.fbeam(hour, wf.minute, solalt, solazi):
					beam_loss_factor = shad.beam_shade_factor()
				shading_loss[idx] = ssc_number_t((1 - beam_loss_factor) * 100)
				var shade_loss_factor: Float64 = shad.fdiff()
				I_transmitted[idx] = ssc_number_t(
					Kta_b * poa[0] * beam_loss_factor +
					Kta_d * poa[1] * shade_loss_factor +
					Kta_g * poa[2])
				idx += 1
		var use_custom_mains: Int = self.as_integer("use_custom_mains")
		if use_custom_mains:
			var iidx: size_t = 0
			for hr in range(8760):
				for jj in range(step_per_hour):
					T_mains[iidx] = ssc_number_t(custom_mains[hr])
					iidx += 1
		else:
			var min_monthly_avg: Float64 = 1e99
			var max_monthly_avg: Float64 = -1e99
			for m in range(12):
				monthly_avg_temp[m] = monthly_avg_temp[m] / monthly_avg_count[m]
				if monthly_avg_temp[m] < min_monthly_avg:
					min_monthly_avg = monthly_avg_temp[m]
				if monthly_avg_temp[m] > max_monthly_avg:
					max_monthly_avg = monthly_avg_temp[m]
			var avg_temp_high_f: Float64 = 32. + 1.8 * max_monthly_avg  # F
			var avg_temp_low_f: Float64 = 32. + 1.8 * min_monthly_avg  # F
			var annual_avg_temp: Float64 = (temp_sum / temp_count) * 1.8 + 32.  # F
			var mains_ratio: Float64 = 0.4 + 0.01 * (annual_avg_temp - 44.)  # F
			var lag: Float64 = 35. - (annual_avg_temp - 44.)  # F
			/* **********************************************************************
			Calculate hourly mains water temperature
			********************************************************************** */
			var iidx: size_t = 0
			var tmain: Float64 = 0
			for i in range(8760):
				var julian_day: int = int((double(i + 1)) / 24)
				if double(julian_day) != (double(i + 1)) / 24.0:
					julian_day += 1
				if wdprov.lat() > 0.:
					tmain = (annual_avg_temp + 6. + mains_ratio * ((avg_temp_high_f - avg_temp_low_f) / 2.)
						* sin(M_PI / 180 * (0.986 * (julian_day - 15 - lag) - 90.)))
				else:
					tmain = (annual_avg_temp + 6. + mains_ratio * ((avg_temp_high_f - avg_temp_low_f) / 2.)
						* sin(M_PI / 180 * (0.986 * (julian_day - 15 - lag) + 90.)))
				tmain = (tmain - 32) / 1.8  # convert to 'C
				for jj in range(step_per_hour):
					T_mains[iidx] = ssc_number_t(tmain)
					iidx += 1
		/* **********************************************************************
			Determine set temperatures based on user input
			********************************************************************** */
		var use_custom_set: Int = self.as_integer("use_custom_set")
		var T_set_array: Array[Float64, 8760]
		if use_custom_set == 0:
			for i in range(8760):
				T_set_array[i] = T_set
		else:
			for i in range(8760):
				T_set_array[i] = custom_set[i]
		/* **********************************************************************
		Calculate additional SWH system parameters
		********************************************************************** */
		/* set initial conditions on some simulation variables */
		var T_hot_prev: Float64 = T_mains[0] + 40.  # initial hot temp 40'C above ambient
		var T_cold_prev: Float64 = T_mains[0]
		var Q_tankloss: Float64 = 0
		var Q_useful_prev: Float64 = 0.0
		var V_hot_prev: Float64 = 0.8 * V_tank
		var V_cold_prev: Float64 = V_tank - V_hot_prev
		var T_tank_prev: Float64 = (V_hot_prev / V_tank) * T_hot_prev + (V_cold_prev / V_tank) * T_cold_prev  # weighted average tank temperature (initial)
		var T_deliv_prev: Float64 = 0.0
		var T_bot_prev: Float64 = T_mains[0]
		/* *********************************************************************************************
		Calculate SHW performance: Q_useful, Q_deliv, T_deliv, T_tank, Q_pump, Q_aux, Q_auxonly, energy_net (Q_saved)
		*********************************************************************************************** */
		var mode: Int = 0
		var annual_kwh: Float64 = 0.0
		var hour: size_t = 0
		idx = 0
		for hour in range(8760):
			#define NSTATUS_UPDATES 50  // set this to the number of times a progress update should be issued for the simulation
			if hour % (8760 // NSTATUS_UPDATES) == 0:
				var percent: float = 100.0 * (float(hour) + 1) / 8760.0
				if not self.update("", percent, float(hour)):
					raise exec_error("swh", "simulation canceled at hour " + util.to_string(hour + 1.0))
			for jj in range(step_per_hour):
				var I_incident_use: Float64 = I_incident[idx]
				var T_amb_use: Float64 = T_amb[idx]
				var T_mains_use: Float64 = T_mains[idx]
				var mdot_mix: Float64 = draw[hour] * (1.0 / 3600.0)
				var T_set_use: Float64 = T_set_array[hour]
				var T_tank: Float64 = T_tank_prev
				var Q_useful: Float64 = Q_useful_prev
				var T_deliv: Float64 = T_deliv_prev
				var V_hot: Float64 = V_hot_prev
				var V_cold: Float64 = V_tank - V_hot
				var T_hot: Float64 = T_hot_prev
				var T_cold: Float64 = T_cold_prev
				var T_bot: Float64 = T_bot_prev
				var T_top: Float64 = T_hot_prev
				var mdotCp_use: Float64 = mdot_total * fluid_cp  # mass flow rate (kg/s) * Cp_fluid (J/kg.K)
				var mdotCp_test: Float64 = test_flow * test_cp  # test flow (kg/s) * Cp_test
				/* Flow rate corrections to FRta, FRUL (D&B pp 307) */
				var FprimeUL: Float64 = -mdotCp_test / area_coll * log(1 - FRUL * area_coll / mdotCp_test)  # D&B eqn 6.20.4
				var r: Float64 = (mdotCp_use / area_total * (1 - exp(-area_total * FprimeUL / mdotCp_use))) / FRUL  # D&B eqn 6.20.3
				var FRta_use: Float64 = FRta * r  # FRta_use = value for this time step
				var FRUL_use: Float64 = FRUL * r  # FRUL_use = value for this time step
				/* Pipe loss adjustment (D&B pp 430) */
				FRta_use = FRta_use / (1 + UA_pipe / mdotCp_use)  # D&B eqn 10.3.9
				FRUL_use = FRUL_use * ((1 - UA_pipe / mdotCp_use + 2 * UA_pipe / (area_total * FRUL_use)) / (1 + UA_pipe / mdotCp_use))  # D&B eqn 10.3.10
				/* Heat exchanger adjustment (D&B pp 427) */
				var FR_ratio: Float64 = 1 / (1 + (area_total * FRUL_use / mdotCp_use) * (mdotCp_use / (Eff_hx * mdotCp_use) - 1))  # D&B eqn 10.2.3
				FRta_use = FRta_use * FR_ratio
				FRUL_use = FRUL_use * FR_ratio
				if Q_useful_prev > 0.:
					Q_useful = area_total * (FRta_use * I_transmitted[idx] - FRUL_use * (T_bot - T_amb_use))  # D&B eqn 6.8.1
				else:
					Q_useful = area_total * (FRta_use * I_transmitted[idx] - FRUL_use * (T_tank_prev - T_amb_use))
				if I_incident_use < 0.0:
					Q_useful = 0
				var dT_collector: Float64 = Q_useful / mdotCp_use
				if Q_useful > 0.:
					var V_hot_next: Float64 = V_hot_prev + (ts_sec * mdot_total / rho_water)
					if V_hot_next < V_tank:
						mode = 1
						T_tank = (T_tank_prev * m_tank * Cp_water + ts_sec * (Q_useful + UA_tank * T_room
							+ mdot_mix * Cp_water * (T_mains_use - 0.33 * dT_collector))) / (m_tank * Cp_water + ts_sec * (UA_tank + mdot_mix * Cp_water))
						if T_tank > T_tank_max:
							T_tank = T_tank_max
						Q_tankloss = UA_tank * (T_tank - T_room)
						V_hot = V_hot_prev + ts_sec * mdot_total / rho_water
						V_cold = V_tank - V_hot
						T_hot = (T_hot_prev * V_hot_prev + ts_sec * (mdot_total / rho_water) * (T_cold_prev + dT_collector)) / V_hot
						T_cold = (V_tank / V_cold) * T_tank - (V_hot / V_cold) * T_hot
						T_top = T_hot
						T_bot = T_cold
						T_deliv = T_top
					else:
						mode = 2
						T_tank = (T_tank_prev * m_tank * Cp_water + ts_sec * (Q_useful + UA_tank * T_room
							+ mdot_mix * Cp_water * (T_mains_use - 0.33 * dT_collector))) / (m_tank * Cp_water + ts_sec * (UA_tank + mdot_mix * Cp_water))
						if T_tank > T_tank_max:
							T_tank = T_tank_max
						Q_tankloss = UA_tank * (T_tank - T_room)
						T_top = T_tank + 0.33 * dT_collector
						T_bot = T_tank - 0.67 * dT_collector
						T_hot = T_top
						T_cold = T_bot
						T_deliv = T_top
				else:
					mode = 3
					var hotLoss: Float64 = 0.0
					var coldLoss: Float64 = 0.0
					var A_cold: Float64 = 0.0
					var A_hot: Float64 = 0.0
					if Q_useful_prev > 0.:
						V_hot_prev = V_tank
						T_hot_prev = T_tank
					V_hot = V_hot_prev - mdot_mix * ts_sec / rho_water
					if V_hot < 0:
						V_hot = 0
					if V_hot == 0:  # cold water drawn into the bottom of the tank in previous timesteps has completely flushed hot water from the tank
						T_hot = T_hot_prev
					else:
						var h_hot: Float64 = V_hot_prev / tank_cross_section
						A_hot = tank_cross_section + 2 * M_PI * tank_radius * h_hot
						var m_hot: Float64 = V_hot_prev * rho_water
						T_hot = ((T_hot_prev * Cp_water * m_hot) + (ts_sec * U_tank * A_hot * T_room)) / ((m_hot * Cp_water) + (ts_sec * U_tank * A_hot))  # IMPLICIT NON-STEADY (Euler)
					hotLoss = U_tank * A_hot * (T_hot - T_room)
					V_cold = V_tank - V_hot
					if V_cold_prev == 0 or V_cold == 0:
						T_cold = T_cold_prev
					else:
						var h_cold: Float64 = V_cold / tank_cross_section
						A_cold = tank_cross_section + 2 * M_PI * tank_radius * h_cold
						var m_cold: Float64 = rho_water * V_cold
						T_cold = ((T_cold_prev * m_cold * Cp_water) + (ts_sec * U_tank * A_cold * T_room) + (ts_sec * mdot_mix * Cp_water * T_mains_use)) / ((m_cold * Cp_water) + (ts_sec * A_cold * U_tank) + (mdot_mix * ts_sec * Cp_water))  # IMPLICIT NON-STEADY
					coldLoss = U_tank * A_cold * (T_cold - T_room)
					Q_tankloss = hotLoss + coldLoss
					T_tank = (V_hot / V_tank) * T_hot + (V_cold / V_tank) * T_cold
					T_top = T_tank + 0.33 * dT_collector
					T_bot = T_tank - 0.67 * dT_collector
					if V_hot > 0:
						T_deliv = T_hot
					else:
						T_deliv = T_cold
				var P_pump: Float64 = pump_watts / pump_eff if (Q_useful > 0 and I_incident_use >= 0.0) else 0.0
				var Q_deliv: Float64 = mdot_mix * Cp_water * (T_deliv - T_mains_use)
				var Q_aux: Float64 = mdot_mix * Cp_water * (T_set_use - T_deliv)
				if Q_aux < 0:
					Q_aux = 0.0
				var Q_auxonly: Float64 = mdot_mix * Cp_water * (T_set_use - T_mains_use)
				if Q_auxonly < 0:
					Q_auxonly = 0.0
				var Q_saved: Float64 = Q_auxonly - Q_aux - P_pump
				Q_useful_prev = Q_useful
				T_tank_prev = T_tank
				V_hot_prev = V_hot
				V_cold_prev = V_tank - V_hot
				T_deliv_prev = T_deliv
				T_hot_prev = T_hot
				T_cold_prev = T_cold
				T_bot_prev = T_bot
				if Q_useful < 0:
					Q_useful = 0.0
				out_Q_transmitted[idx] = ssc_number_t(I_transmitted[idx] * area_total * watt_to_kw)
				out_Q_useful[idx] = ssc_number_t(Q_useful * watt_to_kw)
				out_Q_deliv[idx] = ssc_number_t(Q_deliv * watt_to_kw)  # this is currently being output from a financial model as "Hourly Energy Delivered", they are equivalent
				out_Q_loss[idx] = ssc_number_t(Q_tankloss * watt_to_kw)
				out_T_tank[idx] = ssc_number_t(T_tank)
				out_T_deliv[idx] = ssc_number_t(T_deliv)
				out_P_pump[idx] = ssc_number_t(P_pump * watt_to_kw)
				out_Q_aux[idx] = ssc_number_t(Q_aux * watt_to_kw)
				out_Q_auxonly[idx] = ssc_number_t(Q_auxonly * watt_to_kw)
				out_T_hot[idx] = ssc_number_t(T_hot)
				out_T_cold[idx] = ssc_number_t(T_cold)
				out_V_hot[idx] = ssc_number_t(V_hot)
				out_V_cold[idx] = ssc_number_t(V_cold)
				out_Draw[idx] = draw[hour]  # pass to outputs for visualization
				Mode[idx] = ssc_number_t(mode)  # save mode for debugging
				out_energy[idx] = ssc_number_t(Q_saved * ts_hour * haf(hour) * watt_to_kw)  # kWh energy, with adjustment factors applied
				annual_kwh += out_energy[idx]
				idx += 1
		if self.is_assigned("load"):
			var load_year_one: List[ssc_number_t]
			var load_lifetime: List[ssc_number_t]
			load_year_one = self.as_vector_ssc_number_t("load")
			var analysis_period: size_t = 1
			var scaleFactors: List[Float64] = [1.0] * analysis_period
			var n_rec_single_year: size_t = 0
			var dt_hour_gen: Float64 = 0.0
			var interpolation_factor: Float64 = 1.0
			single_year_to_lifetime_interpolated[ssc_number_t](False, analysis_period, size_t(wdprov.nrecords()),
				load_year_one, scaleFactors, interpolation_factor, load_lifetime, n_rec_single_year, dt_hour_gen)
			for i in range(len(load_lifetime)):
				if out_energy[i] > load_lifetime[i]:
					out_energy[i] = load_lifetime[i]
		self.accumulate_monthly("Q_deliv", "monthly_Q_deliv", ts_hour)
		self.accumulate_monthly("Q_aux", "monthly_Q_aux", ts_hour)
		self.accumulate_monthly("Q_auxonly", "monthly_Q_auxonly", ts_hour)
		self.accumulate_monthly("gen", "monthly_energy")
		self.accumulate_annual("Q_deliv", "annual_Q_deliv", ts_hour)
		self.accumulate_annual("Q_aux", "annual_Q_aux", ts_hour)
		var auxonly: Float64 = self.accumulate_annual("Q_auxonly", "annual_Q_auxonly", ts_hour)
		var deliv: Float64 = self.accumulate_annual("gen", "annual_energy")
		self.assign("solar_fraction", var_data(ssc_number_t(deliv / auxonly)))
		var kWhperkW: Float64 = 0.0
		var nameplate: Float64 = self.as_double("system_capacity")
		kWhperkW = annual_kwh / nameplate
		self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
		self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))

DEFINE_MODULE_ENTRY(swh, "Solar water heating model using multi-mode tank node model.", 10)