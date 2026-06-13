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
from core import compute_module, var_info, ssc_number_t, SSC_INPUT, SSC_INOUT, SSC_OUTPUT, SSC_NUMBER, SSC_ARRAY, SSC_STRING, SSC_BOOLEAN, SSC_WARNING, var_info_invalid, general_error, exec_error
from lib_weatherfile import weatherfile, weather_record, weather_header
from lib_irradproc import irrad
from stdlib.math import is_nan, abs, sqrt, pow, ceil, round as std_round, fabs

# define M_PI and DTOR
alias M_PI: Float64 = 3.14159265358979323
alias DTOR: Float64 = 0.0174532925

# utility namespace
alias util = _Util()

@value
struct _Util:
    var nday: List[Int] = List[Int](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)

    def format(self, fmt: String, args: ...) -> String:
        return String.format(fmt, args)

var _cm_vtab_belpe: List[var_info] = List[var_info](
    # VARTYPE, DATATYPE, NAME, LABEL, UNITS, META, GROUP, REQUIRED_IF, CONSTRAINTS, UI_HINTS
    var_info(SSC_INPUT, SSC_NUMBER, "en_belpe", "Enable building load calculator", "0/1", "", "Load Profile Estimator", "*", "BOOLEAN", ""),
    var_info(SSC_INOUT, SSC_ARRAY, "load", "Electricity load (year 1)", "kW", "", "Load Profile Estimator", "en_belpe=0", "", ""),
    var_info(SSC_INPUT, SSC_STRING, "solar_resource_file", "Weather Data file", "n/a", "", "Load Profile Estimator", "en_belpe=1", "LOCAL_FILE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "floor_area", "Building floor area", "m2", "", "Load Profile Estimator", "en_belpe=1", "", "Floor area"),
    var_info(SSC_INPUT, SSC_NUMBER, "Stories", "Number of stories", "#", "", "Load Profile Estimator", "en_belpe=1", "", "Stories"),
    var_info(SSC_INPUT, SSC_NUMBER, "YrBuilt", "Year built", "yr", "", "Load Profile Estimator", "en_belpe=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Retrofits", "Energy retrofitted", "0/1", "0=No, 1=Yes", "Load Profile Estimator", "en_belpe=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Occupants", "Occupants", "#", "", "Load Profile Estimator", "en_belpe=1", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "Occ_Schedule", "Hourly occupant schedule", "frac/hr", "", "Load Profile Estimator", "en_belpe=1", "LENGTH=24", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "THeat", "Heating setpoint", "degF", "", "Load Profile Estimator", "en_belpe=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "TCool", "Cooling setpoint", "degF", "", "Load Profile Estimator", "en_belpe=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "THeatSB", "Heating setpoint setback", "degf", "", "Load Profile Estimator", "en_belpe=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "TCoolSB", "Cooling setpoint setback", "degF", "", "Load Profile Estimator", "en_belpe=1", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "T_Sched", "Temperature schedule", "0/1", "", "Load Profile Estimator", "en_belpe=1", "LENGTH=24", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_heat", "Enable electric heat", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_cool", "Enable electric cool", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_fridge", "Enable electric fridge", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_range", "Enable electric range", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_dish", "Enable electric dishwasher", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_wash", "Enable electric washer", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_dry", "Enable electric dryer", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_mels", "Enable misc electric loads", "0/1", "", "Load Profile Estimator", "en_belpe=1", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "Monthly_util", "Monthly consumption from utility bill", "kWh", "", "Load Profile Estimator", "en_belpe=1", "LENGTH=12", ""),
    var_info_invalid
)

class cm_belpe(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_belpe)

    def sum(self, a: List[Float64], n: Int) -> Float64:
        var acc: Float64 = 0.0
        for i in range(n):
            acc += a[i]
        return acc

    def sumsub(self, a: List[Float64], m: Int, n: Int) -> Float64:
        var acc: Float64 = 0.0
        for i in range(m, n+1):
            acc += a[i]
        return acc

    def monthly_sums(self, hourly: List[ssc_number_t], monthly: List[ssc_number_t]):
        var c: Int = 0
        for i in range(12):
            monthly[i] = 0
            for d in range(util.nday[i]):
                for h in range(24):
                    monthly[i] += hourly[c]
                    c += 1

    def monthly_averages(self, hourly: List[ssc_number_t], monthly: List[ssc_number_t]):
        self.monthly_sums(hourly, monthly)
        for i in range(12):
            monthly[i] /= Float64(util.nday[i] * 24)

    def exec(self):
        var en_belpe: ssc_number_t = self.as_boolean("en_belpe")
        if not en_belpe:
            if not self.is_assigned("load"):
                raise general_error("variable 'load' is required but not assigned.")
            return
        var load: List[ssc_number_t] = self.allocate("load", 8760)
        var month: List[Int] = List[Int](8760, 0)
        var day: List[Int] = List[Int](8760, 0)
        var hour: List[Int] = List[Int](8760, 0)
        var index: Int = 0
        for m in range(12):
            for d in range(util.nday[m]):
                for h in range(24):
                    month[index] = m
                    day[index] = d
                    hour[index] = h
                    index += 1
        var file: String = self.as_string("solar_resource_file")
        var wfile: weatherfile = weatherfile(file)
        if not wfile.ok():
            raise exec_error("belpe", wfile.message())
        if wfile.has_message():
            self.log(wfile.message(), SSC_WARNING)
        var T_ambF: List[ssc_number_t] = self.allocate("T_ambF", 8760)
        var VwindMPH: List[ssc_number_t] = self.allocate("VwindMPH", 8760)
        var GHI: List[ssc_number_t] = self.allocate("GHI", 8760)
        var RadWallN: List[Float64] = List[Float64](8760, 0.0)
        var RadWallS: List[Float64] = List[Float64](8760, 0.0)
        var RadWallE: List[Float64] = List[Float64](8760, 0.0)
        var RadWallW: List[Float64] = List[Float64](8760, 0.0)
        var hvac_load: List[ssc_number_t] = self.allocate("HVAC_load", 8760)
        var non_hvac_load: List[ssc_number_t] = self.allocate("non_HVAC_load", 8760)
        var radn: List[ssc_number_t] = self.allocate("Rad_N", 8760)
        var rade: List[ssc_number_t] = self.allocate("Rad_E", 8760)
        var rads: List[ssc_number_t] = self.allocate("Rad_S", 8760)
        var radw: List[ssc_number_t] = self.allocate("Rad_W", 8760)
        # debugging outputs commented out
        var hdr: weather_header
        wfile.header(hdr)
        for i in range(8760):
            var wf: weather_record
            if not wfile.read(wf):
                raise exec_error(" belpe", "error reading record in weather file")
            var ghi: Float64 = wf.gh
            if is_nan(ghi):
                raise exec_error("belpe", "weather file must contain GHI data in order to use the building load calculator")
            var irr: irrad = irrad()
            irr.set_location(hdr.lat, hdr.lon, hdr.tz)
            irr.set_optional(hdr.elev, wf.pres, wf.tdry)
            irr.set_time(wf.year, wf.month, wf.day, wf.hour, wf.minute, Float64(wfile.step_sec() / 3600.0))
            irr.set_global_beam(wf.gh, wf.dn)
            irr.set_sky_model(1, 0.2)
            var beam: Float64
            var sky: Float64
            var gnd: Float64
            irr.set_surface(0, 90, 0, 0, 0, 0, False, 0.0)
            irr.calc()
            irr.get_poa(beam, sky, gnd, 0, 0, 0)
            RadWallN[i] = beam + sky + gnd
            irr.set_surface(0, 90, 90, 0, 0, 0, False, 0.0)
            irr.calc()
            irr.get_poa(beam, sky, gnd, 0, 0, 0)
            RadWallE[i] = beam + sky + gnd
            irr.set_surface(0, 90, 180, 0, 0, 0, False, 0.0)
            irr.calc()
            irr.get_poa(beam, sky, gnd, 0, 0, 0)
            RadWallS[i] = beam + sky + gnd
            irr.set_surface(0, 90, 270, 0, 0, 0, False, 0.0)
            irr.calc()
            irr.get_poa(beam, sky, gnd, 0, 0, 0)
            RadWallW[i] = beam + sky + gnd
            radn[i] = ssc_number_t(RadWallN[i])
            rade[i] = ssc_number_t(RadWallE[i])
            rads[i] = ssc_number_t(RadWallS[i])
            radw[i] = ssc_number_t(RadWallW[i])
            T_ambF[i] = ssc_number_t(wf.tdry * 1.8 + 32)
            VwindMPH[i] = ssc_number_t(wf.wspd * 2.237)
            GHI[i] = ssc_number_t(wf.gh)
        var T_annual_avg: Float64 = 0.0
        for i in range(8760):
            T_annual_avg += T_ambF[i]
        T_annual_avg /= 8760.0
        var TGnd: Float64 = (T_annual_avg - 32) / 1.8
        var alphaho_wall: Float64 = 0.15 / 5.6783
        var T_solair_walls: List[Float64] = List[Float64](8760, 0.0)
        var T_solair_roof: List[Float64] = List[Float64](8760, 0.0)
        var T_solair: List[Float64] = List[Float64](8760, 0.0)
        var T_solairF: List[Float64] = List[Float64](8760, 0.0)
        for i in range(8760):
            T_solair_walls[i] = 4 * ((T_ambF[i] - 32) / 1.8 + alphaho_wall * (RadWallN[i] + RadWallS[i] + RadWallE[i] + RadWallW[i]) / 4)
            T_solair_roof[i] = (T_ambF[i] - 32) / 1.8 + alphaho_wall * GHI[i] - 7
            T_solair[i] = (T_solair_walls[i] + T_solair_roof[i] + TGnd) / 6
            T_solairF[i] = T_solair[i] * 1.8 + 32
        var dT: Float64 = 1.0
        var A_Floor: Float64 = self.as_double("floor_area")
        var Stories: Float64 = self.as_double("Stories")
        var YrBuilt: Float64 = self.as_double("YrBuilt")
        var Occupants: Float64 = self.as_double("Occupants")
        var EnergyRetrofits: Bool = self.as_boolean("Retrofits")
        var len_Occ_Schedule: Int = 0
        var Occ_Schedule: List[ssc_number_t] = self.as_array("Occ_Schedule", len_Occ_Schedule)
        if len_Occ_Schedule != 24:
            raise exec_error("belpe", "occupancy schedule needs to have 24 values")
        var THeat: Float64 = self.as_double("THeat")
        var TCool: Float64 = self.as_double("TCool")
        var THeatSB: Float64 = self.as_double("THeatSB")
        var TCoolSB: Float64 = self.as_double("TCoolSB")
        var len_T_Sched: Int = 0
        var T_Sched: List[ssc_number_t] = self.as_array("T_Sched", len_T_Sched)
        if len_T_Sched != 24:
            raise exec_error("belpe", "temperature schedule must have 24 values")
        var len_monthly_util: Int = 0
        var monthly_util: List[ssc_number_t] = self.as_array("Monthly_util", len_monthly_util)
        if len_monthly_util != 12:
            raise exec_error("belpe", "Monthly consumption from utility bill must have 12 values")
        var en_heat: ssc_number_t = self.as_number("en_heat")
        var en_cool: ssc_number_t = self.as_number("en_cool")
        var en_fridge: ssc_number_t = self.as_number("en_fridge")
        var en_range: ssc_number_t = self.as_number("en_range")
        var en_dish: ssc_number_t = self.as_number("en_dish")
        var en_wash: ssc_number_t = self.as_number("en_wash")
        var en_dry: ssc_number_t = self.as_number("en_dry")
        var en_mels: ssc_number_t = self.as_number("en_mels")
        var N_vacation: Int = 14
        var VacationMonths: List[Float64] = List[Float64](5.0, 5.0, 5.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 12.0, 12.0, 12.0, 12.0)
        var VacationDays: List[Float64] = List[Float64](26.0, 27.0, 28.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 22.0, 23.0, 24.0, 25.0)
        var H_ceiling: Float64 = 8.0
        var WWR: Float64 = 0.15
        var NL: Float64 = 0.0
        if A_Floor <= 1600:
            if YrBuilt < 1940:
                NL = 1.29
            elif YrBuilt < 1970:
                NL = 1.03
            elif YrBuilt < 1990:
                NL = 0.65
            else:
                NL = 0.31
        else:
            if YrBuilt < 1940:
                NL = 0.58
            elif YrBuilt < 1970:
                NL = 0.49
            elif YrBuilt < 1990:
                NL = 0.36
            else:
                NL = 0.24
        var ELA: Float64 = NL * A_Floor * 0.0929 / 1000 / pow(Stories, 0.3)
        ELA = 1550 * ELA
        var Cs: Float64
        var Cw: Float64
        if 1 == Stories:
            Cs = 0.015
            Cw = 0.0065
        elif Stories == 2:
            Cs = 0.0299
            Cw = 0.0086
        else:
            Cs = 0.045
            Cw = 0.0101
        var Renv: Float64
        var SHGC: Float64
        if YrBuilt > 1990 or EnergyRetrofits == True:
            Renv = 16
            SHGC = 0.25
        elif YrBuilt >= 1980:
            Renv = 12
            SHGC = 0.25
        else:
            Renv = 5
            SHGC = 0.53
        var Cenv: Float64 = 2.0
        var hsurf: Float64 = 0.68
        var Cmass: Float64 = 1.6
        var TambFAvg: List[ssc_number_t] = List[ssc_number_t](12, 0.0)
        self.monthly_averages(T_ambF, TambFAvg)
        var HtEn: List[Float64] = List[Float64](13, 0.0)
        var ClEn: List[Float64] = List[Float64](13, 0.0)
        for m in range(12):
            if TambFAvg[m] <= 66:
                HtEn[m] = 1
            else:
                ClEn[m] = 1
        ClEn[12] = ClEn[0]
        HtEn[12] = HtEn[0]
        var HtEnNew: List[Float64] = List[Float64](13, 0.0)
        var ClEnNew: List[Float64] = List[Float64](13, 0.0)
        for i in range(13):
            HtEnNew[i] = HtEn[i]
            ClEnNew[i] = ClEn[i]
        for m in range(12):
            if ClEn[m] == 0 and ClEn[m+1] == 1:
                HtEnNew[m+1] = 1
                ClEnNew[m] = 1
            elif HtEn[m] == 0 and HtEn[m+1] == 1:
                ClEnNew[m+1] = 1
        for i in range(13):
            HtEn[i] = HtEnNew[i]
            ClEn[i] = ClEnNew[i]
        var SolMassFrac: Float64 = 0.2
        var SolEnvFrac: Float64 = 1 - SolMassFrac
        var A_Wins: Float64 = sqrt(A_Floor / Stories) * 4 * H_ceiling * Stories * WWR
        var A_Walls: Float64 = sqrt(A_Floor / Stories) * 4 * H_ceiling * Stories - A_Wins
        var Aenv: Float64 = A_Walls + 2 * A_Floor
        var V_bldg: Float64 = A_Floor * H_ceiling * Stories
        var AIntMass: Float64 = 0.4 * A_Floor
        var Cair: Float64 = 0.075 * 0.245 * V_bldg * 10
        var PerPersonLoad: Float64 = 220 / 3412.142
        var PPL_rad: List[Float64] = List[Float64](24, 0.0)
        var PPL_conv: List[Float64] = List[Float64](24, 0.0)
        for i in range(24):
            PPL_rad[i] = 0.6 * PerPersonLoad * ceil(Occupants * Occ_Schedule[i])
            PPL_conv[i] = 0.4 * PerPersonLoad * ceil(Occupants * Occ_Schedule[i])
        var NBR: Float64 = std_round((Occupants - 0.87) / 0.59)
        var Load_light: Float64 = 2000.0
        var Load_fridge: Float64 = 600 * en_fridge
        var Load_range: Float64 = (250 + 83 * NBR) * en_range
        var Load_dw: Float64 = (87.6 + 29.2 * NBR) * en_dish
        var Load_wash: Float64 = (38.8 + 12.9 * NBR) * en_wash
        var Load_dry: Float64 = (538.2 + 179.4 * NBR) * en_dry
        var Load_mels: Float64 = 1595 + 248 * NBR + 0.426 * A_Floor * en_mels
        var FridgeFrac: List[Float64] = List[Float64](4.0, 3.9, 3.8, 3.7, 3.6, 3.6, 3.7, 4.0, 4.1, 4.2, 4.0, 4.0, 4.2, 4.2, 4.2, 4.2, 4.5, 4.8, 5.0, 4.8, 4.6, 4.5, 4.4, 4.2)
        var DWFrac: List[Float64] = List[Float64](17.0, 14.0, 13.0, 12.0, 12.0, 15.0, 20.0, 30.0, 60.0, 64.0, 57.0, 50.0, 40.0, 48.0, 38.0, 35.0, 38.0, 50.0, 88.0, 110.0, 90.0, 68.0, 46.0, 33.0)
        var RangeFrac: List[Float64] = List[Float64](8.0, 8.0, 5.0, 5.0, 8.0, 10.0, 26.0, 44.0, 48.0, 50.0, 44.0, 50.0, 57.0, 48.0, 45.0, 55.0, 85.0, 150.0, 120.0, 60.0, 40.0, 25.0, 15.0, 10.0)
        var WasherFrac: List[Float64] = List[Float64](10.0, 8.0, 5.0, 5.0, 8.0, 10.0, 20.0, 50.0, 70.0, 85.0, 85.0, 75.0, 68.0, 60.0, 52.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 47.0, 30.0, 17.0)
        var DryerFrac: List[Float64] = List[Float64](10.0, 8.0, 5.0, 5.0, 8.0, 10.0, 10.0, 20.0, 50.0, 70.0, 85.0, 85.0, 75.0, 68.0, 60.0, 52.0, 50.0, 50.0, 50.0, 50.0, 50.0, 47.0, 30.0, 17.0)
        var FridgeHrFrac: Float64 = Load_fridge / (self.sum(FridgeFrac, 24) * (1 + 0.1 * 2 / 7))
        var DWHrFrac: Float64 = Load_dw / (self.sum(DWFrac, 24) * (1 + 0.1 * 2 / 7))
        var RangeHrFrac: Float64 = Load_range / (self.sum(RangeFrac, 24) * (1 + 0.1 * 2 / 7))
        var WasherHrFrac: Float64 = Load_wash / (self.sum(WasherFrac, 24) * (1 + 0.1 * 2 / 7))
        var DryerHrFrac: Float64 = Load_dry / (self.sum(DryerFrac, 24) * (1 + 0.1 * 2 / 7))
        var FridgeHourly: List[Float64] = List[Float64](24, 0.0)
        var FridgeHourlyWkend: List[Float64] = List[Float64](24, 0.0)
        var DWHourly: List[Float64] = List[Float64](24, 0.0)
        var DWHourlyWkend: List[Float64] = List[Float64](24, 0.0)
        var RangeHourly: List[Float64] = List[Float64](24, 0.0)
        var RangeHourlyWkend: List[Float64] = List[Float64](24, 0.0)
        var WasherHourly: List[Float64] = List[Float64](24, 0.0)
        var WasherHourlyWkend: List[Float64] = List[Float64](24, 0.0)
        var DryerHourly: List[Float64] = List[Float64](24, 0.0)
        var DryerHourlyWkend: List[Float64] = List[Float64](24, 0.0)
        for i in range(24):
            FridgeHourly[i] = FridgeFrac[i] * FridgeHrFrac
            FridgeHourlyWkend[i] = FridgeHourly[i] * 1.1
            DWHourly[i] = DWFrac[i] * DWHrFrac
            DWHourlyWkend[i] = DWHourly[i] * 1.1
            RangeHourly[i] = RangeFrac[i] * RangeHrFrac
            RangeHourlyWkend[i] = RangeHourly[i] * 1.1
            WasherHourly[i] = WasherFrac[i] * WasherHrFrac
            WasherHourlyWkend[i] = WasherHourly[i] * 1.1
            DryerHourly[i] = DryerFrac[i] * DryerHrFrac
            DryerHourlyWkend[i] = DryerHourly[i] * 1.1
        var TotalPlugHourlyWkday: List[Float64] = List[Float64](24, 0.0)
        var SensibleEquipRadorConvWkday: List[Float64] = List[Float64](24, 0.0)
        var SensibleEquipRadorConvWkend: List[Float64] = List[Float64](24, 0.0)
        var TotalPlugHourlyWkend: List[Float64] = List[Float64](24, 0.0)
        for i in range(24):
            TotalPlugHourlyWkday[i] = (FridgeHourly[i] + DWHourly[i] + RangeHourly[i] + WasherHourly[i] + DryerHourly[i]) / 365
            SensibleEquipRadorConvWkday[i] = 0.5 * (FridgeHourly[i] + DWHourly[i] * 0.6 + RangeHourly[i] * 0.4 + WasherHourly[i] * 0.8 + DryerHourly[i] * 0.15) / 365
            SensibleEquipRadorConvWkend[i] = SensibleEquipRadorConvWkday[i] * 1.1
            TotalPlugHourlyWkend[i] = (FridgeHourlyWkend[i] + DWHourlyWkend[i] + RangeHourlyWkend[i] + WasherHourlyWkend[i] + DryerHourlyWkend[i]) / 365
        var TotalPlugHourlyVacay: List[Float64] = List[Float64](24, 0.0)
        var SensibleEquipRadorConvVacay: List[Float64] = List[Float64](24, 0.0)
        for i in range(24):
            TotalPlugHourlyVacay[i] = FridgeHourly[i] / 365
            SensibleEquipRadorConvVacay[i] = 0.5 * FridgeHourly[i] / 365
        var MELSFrac: List[Float64] = List[Float64](0.441138, 0.406172, 0.401462, 0.395811, 0.380859, 0.425009, 0.491056, 0.521783, 0.441138, 0.375444, 0.384274, 0.384391, 0.377916, 0.390984, 0.4130, 0.435957, 0.515661, 0.626446, 0.680131, 0.702029, 0.726164, 0.709211, 0.613731, 0.533321)
        var MELSMonthly: List[Float64] = List[Float64](1.0, 1.0, 0.88, 0.88, 0.88, 0.77, 0.77, 0.77, 0.77, 0.85, 0.85, 1.0)
        var MELSHourlyJan: List[Float64] = List[Float64](24, 0.0)
        var MELSHrFrac: Float64
        var MELSMonthSum: List[Float64] = List[Float64](12, 0.0)
        var MELSFracSum: Float64 = self.sum(MELSFrac, 24)
        for i in range(12):
            MELSMonthSum[i] = MELSFracSum * MELSMonthly[i] * util.nday[i]
        MELSHrFrac = Load_mels / self.sum(MELSMonthSum, 12)
        for i in range(24):
            MELSHourlyJan[i] = MELSHrFrac * MELSFrac[i]
        var LightFrac: List[Float64] = List[Float64](0.1758680, 0.1055210, 0.070347, 0.070347, 0.070347, 0.076992, 0.165661, 0.345977, 0.330648, 0.169731, 0.13829, 0.137022, 0.137272, 0.140247, 0.158163, 0.230715, 0.418541, 0.710948, 0.931195, 0.88306, 0.790511, 0.675746, 0.509894, 0.354185)
        var L96: Float64 = self.sumsub(LightFrac, 0, 5) + self.sumsub(LightFrac, 20, 23)
        var L73: Float64 = self.sumsub(LightFrac, 6, 14)
        var L48: Float64 = self.sumsub(LightFrac, 15, 19)
        var Lightz: List[List[Float64]] = List[List[Float64]](
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48),
            List[Float64](L96, L73, L48)
        )
        var LightMonHr: List[List[Float64]] = List[List[Float64]](
            List[Float64](1.0, 1.05, 1.05),
            List[Float64](1.0, 0.9, 1.0),
            List[Float64](1.0, 0.6, 0.75),
            List[Float64](1.0, 0.61, 0.3),
            List[Float64](1.0, 0.45, 0.10),
            List[Float64](1.0, 0.42, 0.10),
            List[Float64](1.0, 0.43, 0.10),
            List[Float64](1.0, 0.51, 0.14),
            List[Float64](1.0, 0.62, 0.38),
            List[Float64](1.0, 0.82, 0.52),
            List[Float64](1.0, 0.84, 1.02),
            List[Float64](1.0, 1.04, 1.14)
        )
        var LightUse: List[List[Float64]] = List[List[Float64]](12, List[Float64](3, 0.0))
        for i in range(12):
            for j in range(3):
                LightUse[i][j] = Lightz[i][j] * LightMonHr[i][j]
        var MonthlyDailyLightUse: List[Float64] = List[Float64](12, 0.0)
        for i in range(12):
            MonthlyDailyLightUse[i] = self.sum(LightUse[i], 3)
        var AnnualLightUseHrs: Float64 = 0.0
        for i in range(12):
            AnnualLightUseHrs += MonthlyDailyLightUse[i] * util.nday[i]
        var LightHrFrac: Float64 = Load_light / AnnualLightUseHrs
        var LightHourlyJan: List[Float64] = List[Float64](24, 0.0)
        for i in range(24):
            LightHourlyJan[i] = LightHrFrac * LightFrac[i]
        var GasHeat_capacity: Float64
        if YrBuilt > 1980 or EnergyRetrofits == True:
            GasHeat_capacity = 35 * A_Floor / 1000
        else:
            GasHeat_capacity = 40 * A_Floor / 1000
        var AuxHeat: Float64
        if en_heat == 0:
            AuxHeat = 9.2 * GasHeat_capacity
        else:
            AuxHeat = 0.0
        var SEER: Float64
        if YrBuilt >= 2005 or EnergyRetrofits == True:
            SEER = 13.0
        else:
            SEER = 10.0
        var D: Int = 1
        var Vacay: List[Float64] = List[Float64](8760, 0.0)
        var Hset: List[Float64] = List[Float64](8760, 0.0)
        var Cset: List[Float64] = List[Float64](8760, 0.0)
        var Tmass: List[Float64] = List[Float64](8760, 0.0)
        var Tair: List[Float64] = List[Float64](8760, 0.0)
        var Tsurf: List[Float64] = List[Float64](8760, 0.0)
        var Heaton: List[Float64] = List[Float64](8760, 0.0)
        var EquipElecHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var EquipRadHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var EquipConvHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var MELSElecHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var MELSRadHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var MELSConvHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var LightElecHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var LightRadHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var LightConvHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var PPLRadHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var PPLConvHrLoad: List[Float64] = List[Float64](8760, 0.0)
        var TAnew: List[Float64] = List[Float64](8760, 0.0)
        var TSnew: List[Float64] = List[Float64](8760, 0.0)
        var TMnew: List[Float64] = List[Float64](8760, 0.0)
        var QInt_Rad: List[Float64] = List[Float64](8760, 0.0)
        var QInt_Conv: List[Float64] = List[Float64](8760, 0.0)
        var Q_SolWin: List[Float64] = List[Float64](8760, 0.0)
        var CFM: List[Float64] = List[Float64](8760, 0.0)
        var UAInf: List[Float64] = List[Float64](8760, 0.0)
        var QInf: List[Float64] = List[Float64](8760, 0.0)
        var QG: List[Float64] = List[Float64](8760, 0.0)
        var QN: List[Float64] = List[Float64](8760, 0.0)
        var QHV2: List[Float64] = List[Float64](8760, 0.0)
        var Tdiff: List[Float64] = List[Float64](8760, 0.0)
        for j in range(8763):
            var i: Int = j
            var iprev: Int = i - 1
            var inext: Int = i + 1
            var flag: Bool = False
            if i == 8759:
                inext = 0
            elif i == 8760:
                iprev = 8759
                inext = 1
                i = 0
                flag = True
            elif i == 8761:
                iprev = 0
                inext = 2
                i = 1
            elif i == 8762:
                iprev = 1
                inext = 3
                i = 2
            var Hr: Int = hour[i]
            var NextHr: Int = hour[inext]
            if Hr == 0:
                D = D + 1
                if D > 7:
                    D = 1
            var Mon: Int = month[i]
            var Dy: Int = day[i]
            var NextMon: Int = month[inext]
            var NextDay: Int = day[inext]
            for v in range(N_vacation):
                if Mon == (Int(VacationMonths[v]) - 1) and Dy == (Int(VacationDays[v]) - 1):
                    Vacay[i] = 1
                if NextMon == (Int(VacationMonths[v]) - 1) and NextDay == (Int(VacationDays[v]) - 1):
                    Vacay[inext] = 1
            if Vacay[i] == 0 and T_Sched[Hr] == 1:
                Hset[i] = THeat
                Cset[i] = TCool
            else:
                Hset[i] = THeatSB
                Cset[i] = TCoolSB
            if i == 0 and flag == False:
                Tmass[i] = Hset[i]
                Tair[i] = Hset[i]
                Tsurf[i] = Hset[i]
                Heaton[i] = HtEn[1]
                EquipElecHrLoad[i] = TotalPlugHourlyWkend[Hr]
                EquipRadHrLoad[i] = SensibleEquipRadorConvWkend[Hr]
                EquipConvHrLoad[i] = SensibleEquipRadorConvWkend[Hr]
                MELSElecHrLoad[i] = MELSHourlyJan[Hr]
                MELSRadHrLoad[i] = MELSElecHrLoad[i] * 0.5 * 0.734
                MELSConvHrLoad[i] = MELSElecHrLoad[i] * 0.5 * 0.734
                LightElecHrLoad[i] = LightHourlyJan[Hr]
                LightRadHrLoad[i] = LightElecHrLoad[i] * 0.7
                LightConvHrLoad[i] = LightElecHrLoad[i] * 0.3
                PPLRadHrLoad[i] = PPL_rad[Hr]
                PPLConvHrLoad[i] = PPL_conv[Hr]
                if Vacay[i] == 1:
                    EquipElecHrLoad[i] = TotalPlugHourlyVacay[Hr]
                    EquipRadHrLoad[i] = SensibleEquipRadorConvVacay[Hr]
                    EquipConvHrLoad[i] = EquipRadHrLoad[i]
                    PPLRadHrLoad[i] = 0
                    PPLConvHrLoad[i] = 0
            if i > 0 or flag == True:
                Tair[i] = TAnew[iprev]
                Tsurf[i] = TSnew[iprev]
                Tmass[i] = TMnew[iprev]
            if Vacay[inext] == 1:
                EquipElecHrLoad[inext] = TotalPlugHourlyVacay[NextHr]
                EquipRadHrLoad[inext] = SensibleEquipRadorConvVacay[NextHr]
                EquipConvHrLoad[inext] = SensibleEquipRadorConvVacay[NextHr]
            elif (D == 2 and Hr < 23) or (D == 7 and Hr == 23) or D == 1:
                EquipElecHrLoad[inext] = TotalPlugHourlyWkend[NextHr]
                EquipRadHrLoad[inext] = SensibleEquipRadorConvWkend[NextHr]
                EquipConvHrLoad[inext] = SensibleEquipRadorConvWkend[NextHr]
            else:
                EquipElecHrLoad[inext] = TotalPlugHourlyWkday[NextHr]
                EquipRadHrLoad[inext] = SensibleEquipRadorConvWkday[NextHr]
                EquipConvHrLoad[inext] = SensibleEquipRadorConvWkday[NextHr]
            MELSElecHrLoad[inext] = MELSHourlyJan[NextHr] * MELSMonthly[NextMon]
            MELSRadHrLoad[inext] = MELSElecHrLoad[inext] * 0.734 * 0.5
            MELSConvHrLoad[inext] = MELSElecHrLoad[inext] * 0.734 * 0.5
            var ind: Int = 0
            if NextHr > 19 or NextHr < 6:
                ind = 0
            elif NextHr > 5 and NextHr < 15:
                ind = 1
            else:
                ind = 2
            LightElecHrLoad[inext] = LightHourlyJan[NextHr] * LightMonHr[NextMon][ind]
            LightRadHrLoad[inext] = LightElecHrLoad[inext] * 0.7
            LightConvHrLoad[inext] = LightElecHrLoad[inext] * 0.3
            if Vacay[inext] == 1:
                PPLRadHrLoad[inext] = 0
                PPLConvHrLoad[inext] = 0
            else:
                PPLRadHrLoad[inext] = PPL_rad[NextHr]
                PPLConvHrLoad[inext] = PPL_conv[NextHr]
            QInt_Rad[inext] = 3412.142 * (PPLRadHrLoad[inext] + LightRadHrLoad[inext] + MELSRadHrLoad[inext] + EquipRadHrLoad[inext])
            QInt_Conv[inext] = 3412.142 * (PPLConvHrLoad[inext] + LightConvHrLoad[inext] + MELSConvHrLoad[inext] + EquipConvHrLoad[inext])
            Q_SolWin[inext] = SHGC * (RadWallE[inext] + RadWallW[inext] + RadWallN[inext] + RadWallS[inext]) / 4 * A_Wins / 10.764
            Q_SolWin[inext] = Q_SolWin[inext] * 3.412
            CFM[inext] = ELA * sqrt(Cs * fabs(T_ambF[inext] - Tair[i]) + Cw * pow(VwindMPH[inext], 2)) * 0.67
            UAInf[inext] = CFM[inext] * 60 * 0.018
            QInf[i] = UAInf[i] * (T_ambF[i] - Tair[i])
            QG[i] = QInt_Conv[i] + QInf[i]
            var bar: Float64 = 1 + dT / Cenv / Renv + dT / hsurf / Cenv
            var bardub: Float64 = 1 + dT / Cmass / hsurf
            var TAnewBot: Float64 = 1 + UAInf[inext] * dT / Cair + dT / Cair * AIntMass / hsurf - pow(dT, 2) * AIntMass / Cair / Cmass / hsurf / hsurf / bardub + Aenv * dT / Cair / hsurf - dT * Aenv / Cair / Cenv / hsurf / hsurf / bar
            var TAnewTop: Float64 = Tair[i] + dT / Cair * (QInt_Conv[inext] + UAInf[inext] * T_ambF[inext]) + dT * AIntMass * (Tmass[i] + SolMassFrac * (Q_SolWin[inext] / AIntMass + QInt_Rad[inext] / AIntMass)) / Cair / hsurf / bardub + Aenv * dT / Cair / hsurf / bar * (Tsurf[i] + dT * T_solairF[inext] / Cenv / Renv + SolEnvFrac * (Q_SolWin[inext] / Aenv + QInt_Rad[inext] / Aenv))
            TAnew[i] = TAnewTop / TAnewBot
            var HourlyNonHVACLoad: Float64 = (LightElecHrLoad[i] + MELSElecHrLoad[i] + EquipElecHrLoad[i])
            if j < 8760:
                non_hvac_load[i] = ssc_number_t(HourlyNonHVACLoad * 1000)
            var HeatMaxBTU: Float64 = (A_Floor * 60 > 10000) ? A_Floor * 60 : 10000
            var CoolMaxBTU: Float64 = (A_Floor * 20 > 10000) ? A_Floor * 20 : 10000
            if Cset[i] >= TAnew[i] and Hset[i] <= TAnew[i]:
                Heaton[i] = 0
                QN[inext] = 0
                QHV2[inext] = 0
            elif Cset[i] <= TAnew[i]:
                if ClEn[NextMon] == 0:
                    Heaton[i] = 0
                    QN[inext] = 0
                    QHV2[inext] = 0
                else:
                    Heaton[i] = 0
                    Tdiff[i] = TAnew[i] - Cset[i]
                    TAnew[i] = Cset[i]
                    QN[inext] = Cair / dT / 1 * (TAnew[i] * TAnewBot - TAnewTop)
                    if ClEn[Mon] == 0 and ClEn[NextMon] == 1:
                        QN[inext] = -1 * ((fabs(QN[inext]) < CoolMaxBTU) ? fabs(QN[inext]) : CoolMaxBTU)
                    QHV2[inext] = QN[i] / SEER * en_cool
            elif HtEn[NextMon] == 0:
                Heaton[i] = 0
                QN[inext] = 0
                QHV2[inext] = 0
            else:
                Heaton[i] = 1
                Tdiff[i] = Hset[i] - TAnew[i]
                TAnew[i] = Hset[i]
                QN[inext] = Cair / dT * (TAnew[i] * TAnewBot - TAnewTop)
                if HtEn[Mon] == 0 and HtEn[NextMon] == 1:
                    QN[inext] = (QN[inext] < HeatMaxBTU) ? QN[inext] : HeatMaxBTU
                QHV2[inext] = (QN[i] * 0.2931) * en_heat
            TMnew[i] = (Tmass[i] + dT / Cmass * (TAnew[i] / hsurf + SolMassFrac * (Q_SolWin[i] + QInt_Rad[i]) / AIntMass)) / bardub
            TSnew[i] = (Tsurf[i] + dT / Cenv * (SolEnvFrac * (Q_SolWin[i] / Aenv + QInt_Rad[i] / Aenv) + T_solairF[inext] / Renv + TAnew[i] / hsurf)) / bar
            hvac_load[i] = ssc_number_t(fabs(QHV2[i]))
            load[i] = hvac_load[i] + non_hvac_load[i]
        var HrsHeat: Float64 = self.sum(Heaton, 8760)
        var AuxHeatPerHr: Float64
        var fan_load: List[Float64] = List[Float64](8760, 0.0)
        if HrsHeat != 0:
            AuxHeatPerHr = AuxHeat / HrsHeat / 1000
            for i in range(8760):
                if Heaton[i]:
                    fan_load[i] = AuxHeatPerHr
        var monthly_load: List[ssc_number_t] = List[ssc_number_t](12, 0)
        var monthly_hvac_load: List[ssc_number_t] = List[ssc_number_t](12, 0)
        var monthly_diff: List[Float64] = List[Float64](12, 0.0)
        var monthly_scale: List[Float64] = List[Float64](12, 0.0)
        self.monthly_sums(load, monthly_load)
        self.monthly_sums(hvac_load, monthly_hvac_load)
        for i in range(12):
            monthly_diff[i] = monthly_load[i] - monthly_util[i] * 1000
            if monthly_load[i] != 0:
                monthly_scale[i] = monthly_diff[i] / monthly_load[i]
            else:
                monthly_scale[i] = 0
        var min_diff_month: Int = 0
        var min_diff: Float64 = fabs(monthly_diff[0])
        for i in range(1, 12):
            if fabs(monthly_diff[i]) < min_diff:
                min_diff = fabs(monthly_diff[i])
                min_diff_month = i
        var closest_scale_avg: Float64 = monthly_scale[min_diff_month]
        var x_hvac: List[Float64] = List[Float64](12, 0.0)
        for i in range(12):
            if monthly_hvac_load[i] < 5:
                monthly_hvac_load[i] = 0
            x_hvac[i] = (monthly_diff[i] - (monthly_load[i] * closest_scale_avg)) / monthly_hvac_load[i]
            if x_hvac[i] > 0.9:
                x_hvac[i] = 0.9
            if x_hvac[i] < -1:
                x_hvac[i] = -1
        var NewScale: List[Float64] = List[Float64](12, 0.0)
        for z in range(12):
            NewScale[z] = (monthly_load[z] - monthly_util[z] * 1000 - x_hvac[z] * monthly_hvac_load[z]) / monthly_load[z]
        var nneg: Int = 0
        for i in range(8760):
            if monthly_hvac_load[month[i]] > 0:
                load[i] = ssc_number_t(load[i] * (1 - NewScale[month[i]]) - x_hvac[month[i]] * hvac_load[i])
            else:
                load[i] = load[i] * ssc_number_t(1 - monthly_scale[month[i]])
            if monthly_util[month[i]] == 0:
                load[i] = 0
            if load[i] < 0:
                load[i] = 0
                nneg += 1
            load[i] *= ssc_number_t(0.001)
        if nneg > 0:
            self.log(util.format("The building electric load profile estimator calculated negative loads for %d hours. "
                "Loads for these hours were set