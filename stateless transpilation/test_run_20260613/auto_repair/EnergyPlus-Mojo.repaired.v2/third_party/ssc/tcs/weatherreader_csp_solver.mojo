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
# define _TCSTYPEINTERFACE_
from memory import shared_ptr
from tcstype import *
from lib_weatherfile import *
from lib_irradproc import *
from csp_solver_core import *
# ifndef M_PI
# define M_PI 3.14159265358979323
# endif
enum {
		P_FILENAME, 
		P_TRACKMODE,
		P_TILT,
		P_AZIMUTH,
		O_YEAR,
		O_MONTH,
		O_DAY,
		O_HOUR,
		O_MINUTE,
		O_GLOBAL, 
		O_BEAM,
		O_HOR_BEAM,
		O_DIFFUSE,
		O_TDRY,
		O_TWET,
		O_TDEW,
		O_WSPD,
		O_WDIR,
		O_RHUM,
		O_PRES,
		O_SNOW,
		O_ALBEDO,
		O_POA,
		O_SOLAZI,
		O_SOLZEN,
		O_LAT,
		O_LON,
		O_TZ,
		O_SHIFT,
		O_ELEV,
		D_POABEAM,
		D_POADIFF,
		D_POAGND,
		N_MAX }

var weatherreader_variables: List[tcsvarinfo] = List[tcsvarinfo](
	tcsvarinfo(TCS_PARAM,   TCS_STRING,   P_FILENAME, "file_name",   "Weather file name on local computer",  "",        "",      "",     ""),
	tcsvarinfo(TCS_PARAM,   TCS_NUMBER,   P_TRACKMODE,"track_mode",  "Tracking mode for surface",            "0..2",    "Proc",  "0=fixed,1=1axis,2=2axis", "0"),
	tcsvarinfo(TCS_PARAM,   TCS_NUMBER,   P_TILT,     "tilt",        "Tilt angle of surface/axis",           "deg",     "Proc",  "",     ""),
	tcsvarinfo(TCS_PARAM,   TCS_NUMBER,   P_AZIMUTH,  "azimuth",     "Azimuth angle of surface/axis",        "deg",     "Proc",  "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_YEAR,     "year",        "Year",                                 "yr",      "Time",  "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_MONTH,    "month",       "Month",                                "mn",      "Time",  "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_DAY,      "day",         "Day",                                  "dy",      "Time",  "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_HOUR,     "hour",        "Hour",                                 "hr",      "Time",  "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_MINUTE,   "minute",      "Minute",                               "mi",      "Time",  "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_GLOBAL,   "global",      "Global horizontal irradiance",         "W/m2",    "Solar", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_BEAM,     "beam",        "Beam normal irradiance",               "W/m2",    "Solar", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_HOR_BEAM, "hor_beam",    "Beam-horizontal irradiance",           "W/m2",    "Solar", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_DIFFUSE,  "diff",        "Diffuse horizontal irradiance",        "W/m2",    "Solar", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_TDRY,     "tdry",        "Dry bulb temperature",                 "'C",      "Meteo", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_TWET,     "twet",        "Wet bulb temperature",                 "'C",      "Meteo", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_TDEW,     "tdew",        "Dew point temperature",                "'C",      "Meteo", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_WSPD,     "wspd",        "Wind speed",                           "m/s",     "Meteo", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_WDIR,     "wdir",        "Wind direction",                       "deg",     "Meteo", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_RHUM,     "rhum",        "Relative humidity",                    "%",       "Meteo", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_PRES,     "pres",        "Pressure",                             "mbar",    "Meteo", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_SNOW,     "snow",        "Snow cover",                           "cm",      "Meteo", "valid (0,150)",   ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_ALBEDO,   "albedo",      "Ground albedo",                        "0..1",    "Meteo", "valid (0,1)",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_POA,      "poa",         "Plane-of-array total incident irradiance", "W/m2","Irrad", "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_SOLAZI,   "solazi",      "Solar Azimuth",                        "deg",     "",      "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_SOLZEN,   "solzen",      "Solar Zenith",                         "deg",     "",      "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_LAT,      "lat",         "Latitude",                             "DDD",     "",      "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_LON,      "lon",         "Longitude",                            "DDD",     "",      "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_TZ,       "tz",          "Timezone",                             "DDD",     "",      "",     ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_SHIFT,    "shift",       "shift in longitude from local standard meridian", "deg", "Solar", "", ""),
	tcsvarinfo(TCS_OUTPUT,  TCS_NUMBER,   O_ELEV,     "elev",        "Site elevation",                       "m",       "Meteo", "",     ""),
	tcsvarinfo(TCS_DEBUG,   TCS_NUMBER,   D_POABEAM,  "poa_beam",    "Plane-of-array beam irradiance",       "W/m2",    "Irrad", "",     ""),
	tcsvarinfo(TCS_DEBUG,   TCS_NUMBER,   D_POADIFF,  "poa_diff",    "Plane-of-array diffuse irradiance",    "W/m2",    "Irrad", "",     ""),
	tcsvarinfo(TCS_DEBUG,   TCS_NUMBER,   D_POAGND,   "poa_gnd",     "Plane-of-array ground irradiance",     "W/m2",    "Irrad", "",     ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID,  N_MAX,       0,            0, 0, 0, 0, 0)
)

@value
class weatherreader(tcstypeinterface):
	var c_wr: C_csp_weatherreader
	var m_wf: Pointer[C_csp_weatherreader.S_outputs]
	var ms_sim_info: C_csp_solver_sim_info

	def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
		tcstypeinterface.__init__(self, cxt, ti)
		self.c_wr = C_csp_weatherreader()
		self.m_wf = Pointer[C_csp_weatherreader.S_outputs]()
		self.ms_sim_info = C_csp_solver_sim_info()

	def __del__(owned self):

	def init(self) -> Int:
		self.c_wr.m_filename = self.value_str(P_FILENAME)
		self.c_wr.m_trackmode = Int(self.value(P_TRACKMODE))
		self.c_wr.m_tilt = self.value(P_TILT)
		self.c_wr.m_azimuth = self.value(P_AZIMUTH)
		var out_type: Int = -1
		var out_msg: String = ""
		try:
			if len(self.c_wr.m_filename) > 0:
				self.c_wr.m_weather_data_provider = shared_ptr[weatherfile](weatherfile(self.c_wr.m_filename))
				if self.c_wr.m_weather_data_provider[].has_message():
					self.message(TCS_ERROR, self.c_wr.m_weather_data_provider[].message().c_str())
					return -1
			self.c_wr.init()
		except C_csp_exception as csp_exception:
			while self.c_wr.mc_csp_messages.get_message(&out_type, &out_msg):
				if out_type == C_csp_messages.NOTICE:
					self.message(TCS_NOTICE, out_msg.c_str())
				elif out_type == C_csp_messages.WARNING:
					self.message(TCS_WARNING, out_msg.c_str())
			self.message(TCS_ERROR, csp_exception.m_error_message.c_str())
			return -1
		while self.c_wr.mc_csp_messages.get_message(&out_type, &out_msg):
			if out_type == C_csp_messages.NOTICE:
				self.message(TCS_NOTICE, out_msg.c_str())
			elif out_type == C_csp_messages.WARNING:
				self.message(TCS_WARNING, out_msg.c_str())
		return 0

	def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
		self.ms_sim_info.ms_ts.m_time = time
		self.ms_sim_info.ms_ts.m_step = step
		var out_type: Int = -1
		var out_msg: String = ""
		try:
			self.c_wr.timestep_call(self.ms_sim_info)
		except C_csp_exception as csp_exception:
			while self.c_wr.mc_csp_messages.get_message(&out_type, &out_msg):
				if out_type == C_csp_messages.NOTICE:
					self.message(TCS_NOTICE, out_msg.c_str())
				elif out_type == C_csp_messages.WARNING:
					self.message(TCS_WARNING, out_msg.c_str())
			self.message(TCS_ERROR, csp_exception.m_error_message.c_str())
			return -1
		while self.c_wr.mc_csp_messages.get_message(&out_type, &out_msg):
			if out_type == C_csp_messages.NOTICE:
				self.message(TCS_NOTICE, out_msg.c_str())
			elif out_type == C_csp_messages.WARNING:
				self.message(TCS_WARNING, out_msg.c_str())
		self.m_wf = self.c_wr.ms_outputs
		self.value(O_YEAR, self.m_wf[].m_year)
		self.value(O_MONTH, self.m_wf[].m_month)
		self.value(O_DAY, self.m_wf[].m_day)
		self.value(O_HOUR, self.m_wf[].m_hour)
		self.value(O_MINUTE, self.m_wf[].m_minute)
		self.value(O_GLOBAL, self.m_wf[].m_global)
		self.value(O_BEAM, self.m_wf[].m_beam)
		self.value(O_HOR_BEAM, self.m_wf[].m_hor_beam)
		self.value(O_DIFFUSE, self.m_wf[].m_diffuse)
		self.value(O_TDRY, self.m_wf[].m_tdry)
		self.value(O_TWET, self.m_wf[].m_twet)
		self.value(O_TDEW, self.m_wf[].m_tdew)
		self.value(O_WSPD, self.m_wf[].m_wspd)
		self.value(O_WDIR, self.m_wf[].m_wdir)
		self.value(O_RHUM, self.m_wf[].m_rhum)
		self.value(O_PRES, self.m_wf[].m_pres)
		self.value(O_SNOW, self.m_wf[].m_snow)
		self.value(O_ALBEDO, self.m_wf[].m_albedo)
		self.value(O_POA, self.m_wf[].m_poa)
		self.value(O_SOLAZI, self.m_wf[].m_solazi)
		self.value(O_SOLZEN, self.m_wf[].m_solzen)
		self.value(O_LAT, self.m_wf[].m_lat)
		self.value(O_LON, self.m_wf[].m_lon)
		self.value(O_TZ, self.m_wf[].m_tz)
		self.value(O_SHIFT, self.m_wf[].m_shift)
		self.value(O_ELEV, self.m_wf[].m_elev)
		return 0

	def converged(self, time: Float64) -> Int:
		var out_type: Int = -1
		var out_msg: String = ""
		try:
			self.c_wr.converged()
		except C_csp_exception as csp_exception:
			while self.c_wr.mc_csp_messages.get_message(&out_type, &out_msg):
				if out_type == C_csp_messages.NOTICE:
					self.message(TCS_NOTICE, out_msg.c_str())
				elif out_type == C_csp_messages.WARNING:
					self.message(TCS_WARNING, out_msg.c_str())
			self.message(TCS_ERROR, csp_exception.m_error_message.c_str())
			return -1
		while self.c_wr.mc_csp_messages.get_message(&out_type, &out_msg):
			if out_type == C_csp_messages.NOTICE:
				self.message(TCS_NOTICE, out_msg.c_str())
			elif out_type == C_csp_messages.WARNING:
				self.message(TCS_WARNING, out_msg.c_str())
		return 0

TCS_IMPLEMENT_TYPE(weatherreader, "Standard Weather File format reader", "Aron Dobos", 1, weatherreader_variables, None, 1)