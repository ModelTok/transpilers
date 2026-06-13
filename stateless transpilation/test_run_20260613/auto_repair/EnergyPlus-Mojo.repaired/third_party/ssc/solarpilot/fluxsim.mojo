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
from fluxsim import FluxSimData, var_map
from definitions import var_fluxsim, DateTime  # assuming DateTime defined there
from solpos00 import S_init, S_solpos, S_decode, posdata

@value
struct FluxSimData:
    def Create(inout self, V: var_map):
        self.updateCalculatedParameters(V)

    def updateCalculatedParameters(inout self, V: var_map):
        var az: Float64
        var zen: Float64
        if V.flux.flux_time_type.mapval() == var_fluxsim.FLUX_TIME_TYPE.SUN_POSITION:
            V.flux.flux_solar_az.Setval(V.flux.flux_solar_az_in.val)
            V.flux.flux_solar_el.Setval(V.flux.flux_solar_el_in.val)
        else:
            var flux_day: Int = V.flux.flux_day.val  # Day of the month
            var flux_month: Int = V.flux.flux_month.val  # month of the year
            var flux_hour: Float64 = V.flux.flux_hour.val  # hour of the day
            var lat: Float64 = V.amb.latitude.val
            var lon: Float64 = V.amb.longitude.val
            var tmz: Float64 = V.amb.time_zone.val
            var DT: DateTime
            var doy: Int = DT.GetDayOfYear(2011, Int(flux_month), Int(flux_day))
            var SP: posdata
            var pdat: Pointer[posdata]
            pdat = SP.ptr  # point to structure for convenience
            S_init(pdat)  # Initialize the values
            var mins: Float64 = 60. * (flux_hour - floor(flux_hour))
            var secs: Float64 = 60. * (mins - floor(mins))
            pdat.latitude = Float32(lat)  # [deg] {float} North is positive
            pdat.longitude = Float32(lon)  # [deg] {float} Degrees east. West is negative
            pdat.timezone = Float32(tmz)  # [hr] {float} Time zone, east pos. west negative. Mountain -7, Central -6, etc..
            pdat.year = 2011  # [year] {int} 4-digit year
            pdat.month = Int(flux_month)  # [mo] {int} (1-12)
            pdat.day = Int(flux_day)  # [day] {int} Day of the month
            pdat.daynum = doy  # [day] {int} Day of the year
            pdat.hour = Int(flux_hour + 0.0001)  # [hr] {int} 0-23
            pdat.minute = Int(mins)  # [min] {int} 0-59
            pdat.second = Int(secs)  # [sec] {int} 0-59
            pdat.interval = 0  # [sec] {int} Measurement interval. See solpos documentation.
            var retcode: Int64 = 0  # Initialize with no errors
            retcode = S_solpos(pdat)  # Call the solar position algorithm
            S_decode(retcode, pdat)  # Check the return code
            az = SP.azim
            zen = SP.zenetr
            V.flux.flux_solar_az.Setval(az)
            V.flux.flux_solar_el.Setval(90. - zen)