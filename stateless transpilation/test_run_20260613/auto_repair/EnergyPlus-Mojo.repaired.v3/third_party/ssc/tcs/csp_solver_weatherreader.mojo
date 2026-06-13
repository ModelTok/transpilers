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
from csp_solver_core import C_csp_exception, C_csp_solver_sim_info
from csp_solver_util import util
from sam_csp_util import calc_humidity, calc_twet, CSP
from lib_weatherfile import WeatherDataProvider, WeatherRecord, WeatherHeader
from lib_irradproc import solarpos_spa, incidence, perez

struct C_csp_weatherreader:
    var m_filename: String
    var m_trackmode: Int32
    var m_tilt: Float64
    var m_azimuth: Float64
    var m_ncall: Int32
    var day_prev: Int32
    var m_is_wf_init: Bool
    var m_error_msg: String
    var m_weather_data_provider: WeatherDataProvider
    var m_hdr: WeatherHeader
    var m_rec: WeatherRecord
    var ms_solved_params: S_solved_params
    var ms_outputs: S_outputs
    var m_first: Bool

    def __init__(inout self):
        self.m_filename = ""
        self.m_trackmode = -1
        self.m_tilt = Float64.NaN
        self.m_azimuth = Float64.NaN
        self.m_ncall = -1
        self.day_prev = -1
        self.m_is_wf_init = False

    def init(inout self):
        if self.m_is_wf_init:
            return
        if self.m_weather_data_provider.has_message() and (self.m_weather_data_provider.message().find("leap day") == -1):
            self.m_error_msg = self.m_weather_data_provider.message()
            return
        self.m_hdr = self.m_weather_data_provider.header()
        self.ms_solved_params.m_lat = self.m_hdr.lat  # [deg]
        self.ms_solved_params.m_lon = self.m_hdr.lon  # [deg]
        self.ms_solved_params.m_tz = self.m_hdr.tz  # [deg]
        self.ms_solved_params.m_shift = (self.m_hdr.lon - self.m_hdr.tz * 15.0)  # [deg]
        self.ms_solved_params.m_elev = self.m_hdr.elev  # [m]
        # Leap year:
        #     The year is evenly divisible by 4;
        #     If the year can be evenly divided by 100, it is NOT a leap year, unless;
        #     The year is also evenly divisible by 400. Then it is a leap year.
        self.m_weather_data_provider.read(self.m_rec)
        self.m_weather_data_provider.rewind()
        self.ms_solved_params.m_leapyear = (self.m_rec.year % 4 == 0) and ((self.m_rec.year % 100 != 0) or (self.m_rec.year % 400 == 0))
        if self.ms_solved_params.m_leapyear and (self.m_weather_data_provider.nrecords() % 8760 == 0):
            self.ms_solved_params.m_leapyear = False
        self.m_first = True  # True the first time call() is accessed
        if self.m_trackmode < 0 or self.m_trackmode > 2:
            self.m_error_msg = util.format("invalid tracking mode specified %d [0..2]", self.m_trackmode)
            return
        self.m_is_wf_init = True

    def timestep_call(inout self, inout p_sim_info: C_csp_solver_sim_info):
        self.m_ncall += 1
        var time: Float64 = p_sim_info.ms_ts.m_time  # [s]
        var step: Float64 = p_sim_info.ms_ts.m_step  # [s]
        if self.m_ncall == 0:  # only read data values once per timestep
            var nread: Int = 1
            if self.m_first:
                nread = Int(time / step)
                self.m_first = False
            for i in range(nread):  # for all calls except the first, nread=1
                self.m_weather_data_provider.set_counter_to(Int(time / step - 1))
                if not self.m_weather_data_provider.read(self.m_rec):
                    self.m_error_msg = self.m_weather_data_provider.message()
                    raise C_csp_exception(self.m_error_msg, "")
        var sunn = Array[Float64](9)
        var angle = Array[Float64](5)
        var poa = Array[Float64](3)
        var diffc = Array[Float64](3)
        poa[0] = 0.0
        poa[1] = 0.0
        poa[2] = 0.0
        angle[0] = 0.0
        angle[1] = 0.0
        angle[2] = 0.0
        angle[3] = 0.0
        angle[4] = 0.0
        diffc[0] = 0.0
        diffc[1] = 0.0
        diffc[2] = 0.0
        solarpos_spa(self.m_rec.year, self.m_rec.month, self.m_rec.day, self.m_rec.hour, self.m_rec.minute, 0, self.m_hdr.lat, self.m_hdr.lon, self.m_hdr.tz, 0, self.m_hdr.elev, self.m_rec.pres, self.m_rec.tdry, self.m_tilt, self.m_azimuth, sunn)
        if sunn[2] > 0.0087:
            # sun elevation > 0.5 degrees
            incidence(self.m_trackmode, self.m_tilt, self.m_azimuth, 45.0, sunn[1], sunn[0], 0, 0, False, 0.0, angle)
            perez(sunn[8], self.m_rec.dn, self.m_rec.df, 0.2, angle[0], angle[1], sunn[1], poa, diffc)  # diffuse shading factor not enabled (set to 1.0 by default)
        self.ms_outputs.m_year = self.m_rec.year
        self.ms_outputs.m_month = self.m_rec.month
        self.ms_outputs.m_day = self.m_rec.day
        self.ms_outputs.m_hour = self.m_rec.hour
        self.ms_outputs.m_minute = self.m_rec.minute
        self.ms_outputs.m_global = self.m_rec.gh
        self.ms_outputs.m_beam = self.m_rec.dn
        self.ms_outputs.m_diffuse = self.m_rec.df
        self.ms_outputs.m_tdry = self.m_rec.tdry
        self.ms_outputs.m_twet = self.m_rec.twet
        self.ms_outputs.m_tdew = self.m_rec.tdew
        self.ms_outputs.m_wspd = self.m_rec.wspd
        self.ms_outputs.m_wdir = self.m_rec.wdir
        self.ms_outputs.m_rhum = self.m_rec.rhum
        self.ms_outputs.m_pres = self.m_rec.pres
        self.ms_outputs.m_snow = self.m_rec.snow
        self.ms_outputs.m_albedo = self.m_rec.alb
        self.ms_outputs.m_aod = self.m_rec.aod
        self.ms_outputs.m_poa = poa[0] + poa[1] + poa[2]
        self.ms_outputs.m_solazi = sunn[0] * 180.0 / CSP.pi
        self.ms_outputs.m_solzen = sunn[1] * 180.0 / CSP.pi
        self.ms_outputs.m_lat = self.m_hdr.lat
        self.ms_outputs.m_lon = self.m_hdr.lon
        self.ms_outputs.m_tz = self.m_hdr.tz
        self.ms_outputs.m_shift = (self.m_hdr.lon - self.m_hdr.tz * 15.0)
        self.ms_outputs.m_elev = self.m_hdr.elev
        self.ms_outputs.m_hor_beam = self.m_rec.dn * cos(sunn[1])
        if self.m_rec.rhum != self.m_rec.rhum and self.m_rec.tdry == self.m_rec.tdry and self.m_rec.tdew == self.m_rec.tdew:
            self.ms_outputs.m_rhum = Float64(calc_humidity(Float32(self.m_rec.tdry), Float32(self.m_rec.tdew)))
        if self.m_rec.twet != self.m_rec.twet and self.m_rec.tdry == self.m_rec.tdry and self.ms_outputs.m_rhum == self.ms_outputs.m_rhum and self.m_rec.pres == self.m_rec.pres:
            self.ms_outputs.m_twet = calc_twet(self.m_rec.tdry, self.ms_outputs.m_rhum, self.m_rec.pres)
        if self.m_rec.day != self.day_prev:
            var day_of_year: Int = Int(ceil(time / 3600.0))  # Day of year
            var B: Float64 = Float64(day_of_year - 1) * 360.0 / 365.0 * CSP.pi / 180.0  # [rad]
            var EOT: Float64 = 229.2 * (0.000075 + 0.001868 * cos(B) - 0.032077 * sin(B) - 0.014615 * cos(B * 2.0) - 0.04089 * sin(B * 2.0))
            var Dec: Float64 = 23.45 * sin(360.0 * (284.0 + Float64(day_of_year)) / 365.0 * CSP.pi / 180.0) * CSP.pi / 180.0
            var SolarNoon: Float64 = 12.0 - (self.ms_outputs.m_shift) / 15.0 - EOT / 60.0
            var N_daylight_hours: Float64 = (2.0 / 15.0) * acos(-tan(self.m_hdr.lat * CSP.pi / 180.0) * tan(Dec)) * 180.0 / CSP.pi
            self.ms_outputs.m_time_rise = SolarNoon - N_daylight_hours / 2.0  # [hr]
            self.ms_outputs.m_time_set = SolarNoon + N_daylight_hours / 2.0  # [hr]

    def read_time_step(inout self, time_step: Int32, inout p_sim_info: C_csp_solver_sim_info) -> Bool:
        # Read in the weather file for the specified time step
        if time_step < 0:
            self.m_weather_data_provider.rewind()
            self.converged()
        else:
            self.converged()
            p_sim_info.ms_ts.m_time = (Float64(time_step) + 1.0) * p_sim_info.ms_ts.m_step
            self.m_first = False
            self.timestep_call(p_sim_info)
            self.converged()
        return True

    def converged(inout self):
        self.m_ncall = -1
        self.day_prev = self.m_rec.day