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
from solpos00 import posdata, S_init, S_solpos, S_decode
from Toolbox import DateTime, Vect
from shared.lib_weatherfile import weatherfile, weather_header, weather_record
from definitions import var_map, var_ambient, mod_base, DTobj, spexception, PI, R2D, D2R
import math
import vector

struct Ambient(mod_base):
    var _amb_map: Pointer[var_ambient]

    def __init__(inout self):

    def Create(inout self, V: var_map):
        self._amb_map = V.amb
        self.updateCalculatedParameters(V)

    def Clean(inout self):

    def updateCalculatedParameters(inout self, V: var_map):
        # V unused

    @staticmethod
    def getDefaultSimStep() -> String:
        return "20,12,3,950,25,1,0,1"  # d.o.m., hour, month, dni, pressure, wind, weight factor

    @staticmethod
    def setDateTime(DT: DateTime, day_hour: Float64, year_day: Float64, year: Float64 = 2011.):
        DT.setZero()
        var min: Float64
        var sec: Float64
        min = (day_hour - math.floor(day_hour)) * 60.
        sec = (min - math.floor(min)) * 60.
        DT.SetHour(int(math.floor(day_hour)))
        DT.SetMinute(int(min))
        DT.SetSecond(int(sec))
        DT.SetYearDay(int(year_day))
        DT.SetYear(int(year))
        var month: Int
        var dom: Int
        DT.hours_to_date((year_day - 1.) * 24. + day_hour, month, dom)
        DT.SetMonth(int(month))
        DT.SetMonthDay(int(dom))

    @staticmethod
    def calcSunVectorFromAzZen(azimuth: Float64, zenith: Float64) -> Vect:
        """
        azimuth [rad]
        zenith [rad]
        Calculate the unit vector for sun position (i,j,k) relative to 
        the plant location.
        """
        var sp: Vect
        sp.i = math.sin(azimuth) * math.sin(zenith)
        sp.j = math.cos(azimuth) * math.sin(zenith)
        sp.k = math.cos(zenith)
        return sp

    @staticmethod
    def calcSunPosition(V: var_map, DT: DTobj, az: Pointer[Float64], zen: Pointer[Float64], wf_time_correction: Bool = False):
        var tstep: Float64
        if wf_time_correction:
            tstep = V.amb.sim_time_step.Val()
        else:
            tstep = 0.
        Ambient.calcSunPosition(V.amb.latitude.val, V.amb.longitude.val, V.amb.time_zone.val, tstep, DT, az, zen)

    @staticmethod
    def calcSunPosition(lat: Float64, lon: Float64, timezone: Float64, tstep: Float64, dt: DTobj, az: Pointer[Float64], zen: Pointer[Float64]):
        """
        lat [deg]
        lon [deg]
        timezone [hr]
        tstep [sec]
        Use SOLPOS to calculate the sun position.
        The required inputs for SOLPOS are:
            (via posdata)
            year, month, day of month, day of year, hour, minute, second,
            latitude, longitude, timezone, interval
        """
        var SP: posdata
        var pdat: Pointer[posdata]
        pdat = SP  # point to structure for convenience
        S_init(pdat)  # Initialize the values
        pdat.latitude = float(lat)  # [deg] {float} North is positive
        pdat.longitude = float(lon)  # [deg] {float} Degrees east. West is negative
        pdat.timezone = float(timezone)  # [hr] {float} Time zone, east pos. west negative. Mountain -7, Central -6, etc..
        pdat.year = dt._year  # [year] {int} 4-digit year
        pdat.month = dt._month + 1  # [mo] {int} (1-12)
        pdat.day = dt._mday  # [day] {int} Day of the month
        pdat.daynum = dt._yday  # [day] {int} Day of the year
        pdat.hour = dt._hour  # [hr] {int} 0-23
        pdat.minute = dt._min  # [min] {int} 0-59
        pdat.second = dt._sec  # [sec] {int} 0-59
        pdat.interval = int(tstep)  # [sec] {int} Measurement interval, should correspond to the duration of the weather file time step.
        var retcode: Int64 = 0  # Initialize with no errors
        retcode = S_solpos(pdat)  # Call the solar position algorithm
        S_decode(retcode, pdat)  # Check the return code
        az[] = SP.azim
        zen[] = SP.zenetr
        return

    @staticmethod
    def calcDaytimeHours(hrs: Pointer[Float64], lat: Float64, lon: Float64, timezone: Float64, dt: DTobj):
        """ Calculate the limiting hours during which the sun is above the horizon """
        var SP: posdata
        var pdat: Pointer[posdata]
        pdat = SP  # point to structure for convenience
        S_init(pdat)  # Initialize the values
        var r2d: Float64 = 180. / math.acos(-1.)
        pdat.latitude = float(lat * r2d)  # [deg] {float} North is positive
        pdat.longitude = float(lon * r2d)  # [deg] {float} Degrees east. West is negative
        pdat.timezone = float(timezone)  # [hr] {float} Time zone, east pos. west negative. Mountain -7, Central -6, etc..
        pdat.year = dt._year  # [year] {int} 4-digit year
        pdat.month = dt._month + 1  # [mo] {int} (1-12)
        pdat.day = dt._mday  # [day] {int} Day of the month
        pdat.daynum = dt._yday  # [day] {int} Day of the year
        pdat.hour = dt._hour  # [hr] {int} 0-23
        pdat.minute = dt._min  # [min] {int} 0-59
        pdat.second = dt._sec  # [sec] {int} 0-59
        pdat.interval = 0  # [sec] {int} Measurement interval. See solpos documentation.
        var retcode: Int64 = 0  # Initialize with no errors
        retcode = S_solpos(pdat)  # Call the solar position algorithm
        S_decode(retcode, pdat)  # Check the return code
        hrs[0] = pdat.sretr / 60.
        hrs[1] = pdat.ssetr / 60.

    @staticmethod
    def readWeatherFile(V: var_map) -> Bool:
        """
        NOTE: This method does not currently implement psychrometric property algorithms or irradiance correction methods, 
        so data is used "as is" from the weather file. Many weather files do not provide wet bulb temperature directly and
        it must be calculated from dry bulb, relative humidity, and ambient pressure.
        This method takes as inputs:
        A pointer to the data map that will contain the weather file data. This map will have keys (uppercase) 
        that correspond to the data label and an associated vector of the timestep data. The included data streams
        are:
        Key     |   Description                     | Units
        -----------------------------------------------------
        DAY     |   Day of the month (1-31)         | days
        MONTH   |   Month of the year (1-12)        | month
        HOUR    |   Hour of the day (1-24)          | hr
        DNI     |   Direct normal irradiation       | W/m2
        T_DB    |   Dry bulb ambient temperature    | C
        V WIND  |   Wind velocity                   | m/s
        """
        var wf_reader: weatherfile
        if not wf_reader.open(V.amb.weather_file.val):
            return False  # Error
        var wh: weather_header
        wf_reader.header(wh)
        V.amb.latitude.val = wh.lat  # deg
        V.amb.longitude.val = wh.lon  # deg
        V.amb.time_zone.val = wh.tz
        V.amb.elevation.val = wh.elev
        var nrec: Int = int(wf_reader.nrecords())
        V.amb.wf_data.val.resizeAll(nrec)
        var wrec: weather_record
        for i in range(nrec):
            if not wf_reader.read(wrec):
                return False  # Error
            V.amb.wf_data.val.Day[i] = float(wrec.day)
            V.amb.wf_data.val.DNI[i] = float(wrec.dn)
            V.amb.wf_data.val.Hour[i] = float(wrec.hour)
            V.amb.wf_data.val.Month[i] = float(wrec.month)
            V.amb.wf_data.val.Pres[i] = wrec.pres / 1000.  # bar
            V.amb.wf_data.val.T_db[i] = wrec.tdry  # C
            V.amb.wf_data.val.V_wind[i] = wrec.wspd  # m/s
            V.amb.wf_data.val.Step_weight[i] = 1.  # default step
        return True

    @staticmethod
    def calcAttenuation(V: var_map, len: Float64) -> Float64:
        """
        Length in units of meters. 
        Atmospheric attenuation model set on Create
        Calculate atmospheric attenuation as a function of slant range. Model options are:
        0:  Barstow 25km (polynomials, DELSOL)
        1:  Barstow 5km visibility (polynomials, DELSOL)
        2:  User defined coefficients (polynomials)
        3:  Sengupta & Wagner model
        """
        var att: Float64 = 0.0
        var rkm: Float64 = len * 0.001
        var nc: Int = int(V.amb.atm_coefs.val.ncols())
        var atm_sel: Int = V.amb.atm_model.combo_get_current_index()
        for i in range(nc):
            att += V.amb.atm_coefs.val[atm_sel, i] * math.pow(rkm, i)
        return 1. - att

    @staticmethod
    def calcSpacedDaysHours(lat: Float64, lon: Float64, tmz: Float64, nday: Int, delta_hr: Float64, utime: List[List[Float64]], uday: List[Int]):
        var pi: Float64 = PI
        uday.reserve(nday)
        var ntstep: List[Int] = List[Int](nday)
        var ntstep_day: List[Int] = List[Int](nday)
        var noons: List[Float64] = List[Float64](nday)
        var hours: List[Float64] = List[Float64](nday)
        var DT: DateTime
        var month: Int
        var dom: Int
        for i in range(nday):
            uday[i] = 355 - int(math.floor(math.acos(-1. + 2. * i / float(nday - 1)) / pi * float(355 - 172)))
            DT.hours_to_date(uday[i] * 24 + 12., month, dom)
            DT.SetHour(12)
            DT.SetDate(2011, month, dom)
            DT.SetYearDay(uday[i])
            var hrs: List[Float64](2)
            Ambient.calcDaytimeHours(hrs.data(), lat * D2R, lon * D2R, tmz, DT)
            noons[i] = (hrs[0] + hrs[1]) / 2.
            ntstep[i] = int(math.floor((hrs[1] - noons[i]) * 0.9 / delta_hr))
            ntstep_day[i] = 2 * ntstep[i] + 1
        utime.clear()
        var utemp: List[Float64]
        var nflux_sim: Int = 0
        for i in range(nday):
            utemp.clear()
            for j in range(ntstep_day[i]):
                utemp.append(noons[i] + (-ntstep[i] + j) * delta_hr - 12.)
                nflux_sim += 1
            utime.append(utemp)

    @staticmethod
    def calcInsolation(V: var_map, azimuth: Float64, zenith: Float64, day_of_year: Int) -> Float64:
        """
        Inputs:
        azimuth     |   solar azimuth (radians)
        zenith      |   solar zenith angle (radians)
        altitude    |   site elevation / altitude (kilometers)
        model       |   clear sky model { MEINEL, HOTTEL, CONSTANT, MOON, ALLEN }
        solcon      |   *required for CONSTANT*  specified DNI - (kW/m2)
        Delsol 7065-7082ish
        """
        var S0: Float64 = 1.353 * (1. + 0.0335 * math.cos(2. * PI * (day_of_year + 10.) / 365.))
        var szen: Float64 = math.sin(zenith)
        var czen: Float64 = math.cos(zenith)
        var save2: Float64 = 90. - math.atan2(szen, czen) * R2D
        var save: Float64 = 1.0 / czen
        if save2 <= 30.:
            save = save - 41.972213 * math.pow(save2, (-2.0936381 - 0.04117341 * save2 + 0.000849854 * math.pow(save2, 2)))
        var ALT: Float64 = V.amb.elevation.val / 1000.
        var dni: Float64
        # get insolation type enum value
        var ins_type: Int = V.amb.insol_type.mapval()
        if ins_type == var_ambient.INSOL_TYPE.MEINEL_MODEL:
            dni = (1. - 0.14 * ALT) * math.exp(-0.357 / math.pow(czen, 0.678)) + 0.14 * ALT
        elif ins_type == var_ambient.INSOL_TYPE.HOTTEL_MODEL:
            dni = 0.4237 - 0.00821 * math.pow(6. - ALT, 2) + (0.5055 + 0.00595 * math.pow(6.5 - ALT, 2)) * math.exp(-(0.2711 + 0.01858 * math.pow(2.5 - ALT, 2)) / (czen + 0.00001))
        elif ins_type == var_ambient.INSOL_TYPE.CONSTANT_VALUE:
            dni = V.sf.dni_des.val / (S0 * 1000.)
        elif ins_type == var_ambient.INSOL_TYPE.MOON_MODEL:
            dni = 1.0 - 0.263 * ((V.amb.del_h2o.val + 2.72) / (V.amb.del_h2o.val + 5.0)) * math.pow((save * V.amb.dpres.val), (0.367 * ((V.amb.del_h2o.val + 11.53) / (V.amb.del_h2o.val + 7.88))))
        elif ins_type == var_ambient.INSOL_TYPE.ALLEN_MODEL:
            dni = 0.183 * math.exp(-save * V.amb.dpres.val / 0.48) + 0.715 * math.exp(-save * V.amb.dpres.val / 4.15) + 0.102
        else:
            raise spexception("The specified clear sky DNI model is not available.")
        return dni * S0 * 1000.