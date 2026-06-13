// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from core import *
from lib_windfile import *
from lib_windwatts import *
from common import *
from lib_util import *

typealias ssc_number_t = Float64  # approximate

var _cm_vtab_windpower: List[var_info] = List[var_info](
    var_info(SSC_INPUT, SSC_NUMBER, "wind_resource_model_choice", "Hourly, Weibull or Distribution model", "0/1/2", "", "Resource", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_STRING, "wind_resource_filename", "Local wind data file path", "", "", "Resource", "?", "LOCAL_FILE", ""),
    var_info(SSC_INPUT, SSC_TABLE, "wind_resource_data", "Wind resouce data in memory", "", "", "Resource", "?", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "wind_resource_distribution", "Wind Speed x Dir Distribution as 2-D PDF", "m/s,deg", "", "Resource", "wind_resource_model_choice=2", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "weibull_reference_height", "Reference height for Weibull wind speed", "m", "", "Resource", "?=50", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "weibull_k_factor", "Weibull K factor for wind resource", "", "", "Resource", "wind_resource_model_choice=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "weibull_wind_speed", "Average wind speed for Weibull model", "", "", "Resource", "wind_resource_model_choice=1", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wind_resource_shear", "Shear exponent", "", "", "Turbine", "*", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wind_turbine_rotor_diameter", "Rotor diameter", "m", "", "Turbine", "*", "POSITIVE", ""),
    var_info(SSC_INOUT, SSC_ARRAY, "wind_turbine_powercurve_windspeeds", "Power curve wind speed array", "m/s", "", "Turbine", "*", "", "GROUP=WTPCD"),
    var_info(SSC_INOUT, SSC_ARRAY, "wind_turbine_powercurve_powerout", "Power curve turbine output array", "kW", "", "Turbine", "*", "LENGTH_EQUAL=wind_turbine_powercurve_windspeeds", "GROUP=WTPCD"),
    var_info(SSC_INPUT, SSC_NUMBER, "wind_turbine_hub_ht", "Hub height", "m", "", "Turbine", "*", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wind_turbine_max_cp", "Max Coefficient of Power", "", "", "Turbine", "wind_resource_model_choice=1", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wind_farm_wake_model", "Wake Model [Simple, Park, EV, Constant]", "0/1/2/3", "", "Farm", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wind_resource_turbulence_coeff", "Turbulence coefficient", "%", "", "Farm", "*", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "Farm", "*", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "wind_farm_xCoordinates", "Turbine X coordinates", "m", "", "Farm", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "wind_farm_yCoordinates", "Turbine Y coordinates", "m", "", "Farm", "*", "LENGTH_EQUAL=wind_farm_xCoordinates", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_low_temp_cutoff", "Enable Low Temperature Cutoff", "0/1", "", "Losses", "?=0", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "low_temp_cutoff", "Low Temperature Cutoff", "C", "", "Losses", "en_low_temp_cutoff=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "en_icing_cutoff", "Enable Icing Cutoff", "0/1", "", "Losses", "?=0", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "icing_cutoff_temp", "Icing Cutoff Temperature", "C", "", "Losses", "en_icing_cutoff=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "icing_cutoff_rh", "Icing Cutoff Relative Humidity", "%", "'rh' required in wind_resource_data", "Losses", "en_icing_cutoff=1", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wake_int_loss", "Constant Wake Model, internal wake loss", "%", "", "Losses", "wind_farm_wake_model=3", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wake_ext_loss", "External Wake loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wake_future_loss", "Future Wake loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "avail_bop_loss", "Balance-of-plant availability loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "avail_grid_loss", "Grid availability loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "avail_turb_loss", "Turbine availabaility loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "elec_eff_loss", "Electrical efficiency loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "elec_parasitic_loss", "Electrical parasitic consumption loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "env_degrad_loss", "Environmental Degradation loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "env_exposure_loss", "Environmental Exposure loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "env_env_loss", "Environmental External Conditions loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "env_icing_loss", "Environmental Icing loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "ops_env_loss", "Environmental/Permit Curtailment loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "ops_grid_loss", "Grid curtailment loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "ops_load_loss", "Load curtailment loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "ops_strategies_loss", "Operational strategies loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "turb_generic_loss", "Turbine Generic Powercurve loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "turb_hysteresis_loss", "Turbine High Wind Hysteresis loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "turb_perf_loss", "Turbine Sub-optimal performance loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "turb_specific_loss", "Turbine Site-specific Powercurve loss", "%", "", "Losses", "?=0", "MIN=0,MAX=100", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "turbine_output_by_windspeed_bin", "Turbine output by wind speed bin", "kW", "", "Power Curve", "", "LENGTH_EQUAL=wind_turbine_powercurve_windspeeds", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wind_direction", "Wind direction", "deg", "", "Time Series", "wind_resource_model_choice=0", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wind_speed", "Wind speed", "m/s", "", "Time Series", "wind_resource_model_choice=0", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "temp", "Air temperature", "'C", "", "Time Series", "wind_resource_model_choice=0", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pressure", "Pressure", "atm", "", "Time Series", "wind_resource_model_choice=0", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "monthly_energy", "Monthly Energy", "kWh", "", "Monthly", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual Energy", "kWh", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_gross_energy", "Annual Gross Energy", "kWh", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wind_speed_average", "Average Wind speed", "m/s", "", "Annual", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "avail_losses", "Availability losses", "%", "", "Annual", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "elec_losses", "Electrical losses", "%", "", "Annual", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "env_losses", "Environmental losses", "%", "", "Annual", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "ops_losses", "Operational losses", "%", "", "Annual", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "turb_losses", "Turbine losses", "%", "", "Annual", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wake_losses", "Wake losses", "%", "", "Annual", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "cutoff_losses", "Low temp and Icing Cutoff losses", "%", "", "Annual", "", "", ""),
    var_info_invalid
)

struct winddata: winddata_provider:
    var irecord: Int
    var data: util.matrix_t[Float64]
    var stdErrorMsg: String

    def __init__(inout self, data_table: borrowed var_data):
        self.irecord = 0
        self.stdErrorMsg = "wind data must be an SSC table variable with fields: " \
            "(number): lat, lon, elev, year, " \
            "(array): heights, fields [dim: 4, temp=1,pres=2,speed=3,dir=4], rh (dim: nstep, optional)" \
            "(matrix): data (dim: 4 x Nheights x nstep)"
        if data_table.type != SSC_TABLE:
            self.m_errorMsg = self.stdErrorMsg
            return
        self.lat = self.get_number(data_table, "lat")
        self.lon = self.get_number(data_table, "lon")
        self.elev = self.get_number(data_table, "elev")
        self.year = Int(self.get_number(data_table, "year"))
        var len_: Int = 0
        var p = self.get_vector(data_table, "heights", &len_)
        for i in range(len_):
            self.m_heights.append(Float64(p[i]))
        p = self.get_vector(data_table, "fields", &len_)
        for i in range(len_):
            self.m_dataid.append(Int(p[i]))
        if self.m_dataid.size() != self.m_heights.size() or self.m_heights.size() == 0:
            self.m_errorMsg = util.format("'fields' and 'heights' must have same length")
            return
        var D = data_table.table.lookup("data")
        if D is not None:
            if D.type == SSC_MATRIX:
                self.data = D.num
        if self.data.ncols() != self.m_heights.size():
            self.m_errorMsg = util.format("number of columns in 'data' must be same as length of 'fields' and 'heights'")
            return
        var rh = self.get_vector(data_table, "rh", &len_)
        if rh is not None and len_ == self.data.nrows():
            self.m_relativeHumidity = List[Float64](rh, rh + len_)
        elif rh is not None:
            self.m_errorMsg = self.stdErrorMsg
            return

    def nrecords(self) -> Int:
        return self.data.nrows()

    def get_number(self, v: borrowed var_data, name: String) -> ssc_number_t:
        var value = v.table.lookup(name)
        if value is not None:
            if value.type == SSC_NUMBER:
                return value.num
        return Float64.NaN

    def get_vector(self, v: borrowed var_data, name: String, len: Pointer[Int]) -> Pointer[ssc_number_t]:
        var p: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        len[0] = 0
        var value = v.table.lookup(name)
        if value is not None:
            if value.type == SSC_ARRAY:
                len[0] = value.num.length()
                p = value.num.data()
        return p

    def read_line(inout self, values: List[Float64]) -> Bool:
        if self.irecord >= self.data.nrows() or self.data.ncols() == 0 or self.data.nrows() == 0:
            return False
        values.resize(self.data.ncols(), 0.0)
        for j in range(self.data.ncols()):
            values[j] = Float64(self.data(self.irecord, j))
        self.irecord += 1
        return True

    def get_stdErrorMsg(self) -> String:
        return self.stdErrorMsg

struct cm_windpower: compute_module:
    def __init__(inout self):
        self.add_var_info(_cm_vtab_windpower)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)
        self.add_var_info(vtab_p50p90)

    def exec(inout self):
        var wt = windTurbine()
        wt.shearExponent = self.as_double("wind_resource_shear")
        wt.hubHeight = self.as_double("wind_turbine_hub_ht")
        wt.measurementHeight = wt.hubHeight
        wt.rotorDiameter = self.as_double("wind_turbine_rotor_diameter")
        var pc_w = self.as_array("wind_turbine_powercurve_windspeeds", &wt.powerCurveArrayLength)
        var pc_p = self.as_array("wind_turbine_powercurve_powerout", None)
        var windSpeeds = List[Float64](wt.powerCurveArrayLength)
        var powerOutput = List[Float64](wt.powerCurveArrayLength)
        for i in range(wt.powerCurveArrayLength):
            windSpeeds[i] = pc_w[i]
            powerOutput[i] = pc_p[i]
        wt.setPowerCurve(windSpeeds, powerOutput)
        var wpc = windPowerCalculator()
        wpc.windTurb = &wt
        wpc.turbulenceIntensity = self.as_double("wind_resource_turbulence_coeff")
        var wind_farm_xCoordinates = self.as_array("wind_farm_xCoordinates", &wpc.nTurbines)
        var wind_farm_yCoordinates = self.as_array("wind_farm_yCoordinates", None)
        wpc.XCoords.resize(wpc.nTurbines)
        wpc.YCoords.resize(wpc.nTurbines)
        for i in range(wpc.nTurbines):
            wpc.XCoords[i] = Float64(wind_farm_xCoordinates[i])
            wpc.YCoords[i] = Float64(wind_farm_yCoordinates[i])
        if not wt.isInitialized():
            throw exec_error("windpower", util.format("wind turbine class not properly initialized"))
        if wpc.nTurbines < 1:
            throw exec_error("windpower", util.format("the number of wind turbines was zero."))
        if wpc.nTurbines > wpc.GetMaxTurbines():
            throw exec_error("windpower", util.format("the wind model is only configured to handle up to %d turbines.", wpc.GetMaxTurbines()))
        var haf = adjustment_factors(self, "adjust")
        if not haf.setup():
            throw exec_error("windpower", "failed to setup adjustment factors: " + haf.error())
        var lossMultiplier = get_fixed_losses(self)
        if lossMultiplier > 1 or lossMultiplier < 0:
            throw exec_error("windpower", "Total percent losses must be between 0 and 100.")
        var wake_int_loss_percent = 0.0
        var lowTempCutoff = self.as_boolean("en_low_temp_cutoff")
        var lowTempCutoffValue = lowTempCutoff ? self.as_double("low_temp_cutoff") : -1.0
        var icingCutoff = self.as_boolean("en_icing_cutoff")
        var icingTempCutoffValue = icingCutoff ? self.as_double("icing_cutoff_temp") : -1.0
        var icingRHCutoffValue = icingCutoff ? self.as_double("icing_cutoff_rh") : -1.0
        if self.as_integer("wind_resource_model_choice") == 1:
            var turbine_output = self.allocate("turbine_output_by_windspeed_bin", wt.powerCurveArrayLength)
            var turbine_outkW = List[Float64](wt.powerCurveArrayLength)
            var weibull_k = self.as_double("weibull_k_factor")
            var avg_speed = self.as_double("weibull_wind_speed")
            var ref_height = self.as_double("weibull_reference_height")
            var turbine_kw = wpc.windPowerUsingWeibull(weibull_k, avg_speed, ref_height, &turbine_outkW[0])
            var gross_energy = turbine_kw * Float64(wpc.nTurbines)
            wake_int_loss_percent = self.is_assigned("wake_int_loss") ? self.as_double("wake_int_loss") : 0.0
            turbine_kw = turbine_kw * lossMultiplier * (1.0 - wake_int_loss_percent / 100.0)
            var nstep = 8760
            var farm_kw = ssc_number_t(turbine_kw) * Float64(wpc.nTurbines) / Float64(nstep)
            var farmpwr = self.allocate("gen", nstep)
            for i in range(nstep):
                farmpwr[i] = farm_kw
                farmpwr[i] *= haf(i)
            for i in range(wpc.nTurbines):
                turbine_output[i] = ssc_number_t(turbine_outkW[i])
            self.accumulate_monthly("gen", "monthly_energy")
            self.accumulate_annual("gen", "annual_energy")
            var kWhperkW = 0.0
            var nameplate = self.as_double("system_capacity")
            var annual_energy = self.as_double("annual_energy")
            if nameplate > 0:
                kWhperkW = annual_energy / nameplate
            self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
            self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
            self.assign("annual_gross_energy", gross_energy)
            self.assign("wind_speed", avg_speed)
            calculate_p50p90(self)
            calculate_losses(self, wake_int_loss_percent)
            return
        var wakeModel: Pointer[wakeModelBase] = Pointer[wakeModelBase]()
        var wakeModelChoice = self.as_integer("wind_farm_wake_model")
        if wakeModelChoice == 0:
            wakeModel = Pointer[wakeModelBase](simpleWakeModel(wpc.nTurbines, &wt))
        elif wakeModelChoice == 1:
            wakeModel = Pointer[wakeModelBase](parkWakeModel(wpc.nTurbines, &wt))
        elif wakeModelChoice == 2:
            wpc.turbulenceIntensity *= 100
            wakeModel = Pointer[wakeModelBase](eddyViscosityWakeModel(wpc.nTurbines, &wt, self.as_double("wind_resource_turbulence_coeff")))
        elif wakeModelChoice == 3:
            wake_int_loss_percent = self.as_double("wake_int_loss")
            wakeModel = Pointer[wakeModelBase](constantWakeModel(wpc.nTurbines, &wt, (100.0 - wake_int_loss_percent) / 100.0))
        else:
            throw exec_error("windpower", util.format("wind_farm_wake_model must be 0, 1, 2 or 3."))
        if not wpc.InitializeModel(wakeModel):
            throw exec_error("windpower", util.format("Error initializing wake model."))
        if self.as_integer("wind_resource_model_choice") == 2:
            var farmPower = 0.0
            var farmPowerGross = 0.0
            var wind_dist = self.lookup("wind_resource_distribution").matrix_vector()
            if not wpc.windPowerUsingDistribution(wind_dist, &farmPower, &farmPowerGross):
                throw exec_error("windpower", wpc.GetErrorDetails())
            if wakeModelChoice != 3:
                wake_int_loss_percent = (1.0 - farmPower / farmPowerGross) * 100.0
            var nstep = 8760
            var farm_kw = farmPower / Float64(nstep)
            var farmpwr = self.allocate("gen", nstep)
            for i in range(nstep):
                farmpwr[i] = farm_kw
                farmpwr[i] *= haf(i)
                farmpwr[i] *= lossMultiplier
            self.accumulate_monthly("gen", "monthly_energy")
            self.accumulate_annual("gen", "annual_energy")
            var avg_speed = 0.0
            for row in wind_dist:
                avg_speed += row[0] * row[2]
            var kWhperkW = 0.0
            var nameplate = self.as_double("system_capacity")
            var annual_energy = self.as_double("annual_energy")
            if nameplate > 0:
                kWhperkW = annual_energy / nameplate
            self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
            self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
            self.assign("annual_gross_energy", farmPowerGross)
            self.assign("wind_speed_average", avg_speed)
            calculate_p50p90(self)
            calculate_losses(self, wake_int_loss_percent)
            return
        var nstep = 8760
        var wdprov: smart_ptr[winddata_provider].ptr = smart_ptr[winddata_provider].ptr()
        if self.is_assigned("wind_resource_filename"):
            var file = self.as_string("wind_resource_filename")
            var wp = windfile(file)
            nstep = wp.nrecords()
            wdprov = smart_ptr[winddata_provider].ptr(wp)
            if not wp.ok() or nstep == 0:
                throw exec_error("windpower", "failed to read local weather file: " + String(file) + " " + wp.error())
        elif self.is_assigned("wind_resource_data"):
            wdprov = smart_ptr[winddata_provider].ptr(winddata(self.lookup("wind_resource_data")))
            if not wdprov.error().empty():
                throw exec_error("windpower", wdprov.error())
            nstep = wdprov.nrecords()
            if icingCutoff:
                if wdprov.relativeHumidity().empty():
                    var err = (wdprov as winddata).get_stdErrorMsg()
                    throw exec_error("windpower", err)
                if wdprov.relativeHumidity().size() != nstep:
                    throw exec_error("windpower", "Length of rh (relative humidity) data must be equal to length of other fields.")
        else:
            throw exec_error("windpower", "no wind resource data supplied")
        var contains_leap_day = False
        if Math.fmod(Float64(nstep), 8784.0) == 0:
            contains_leap_day = True
            var leap_steps_per_hr = Int(nstep) / 8784
            self.log("This weather file appears to contain a leap day. Feb 29th will be skipped. If this is not the case, please check your wind resource file.", SSC_NOTICE)
            nstep = leap_steps_per_hr * 8760
        var steps_per_hour = nstep / 8760
        if steps_per_hour * 8760 != nstep and not contains_leap_day:
            throw exec_error("windpower", util.format("invalid number of data records (%d): must be an integer multiple of 8760", Int(nstep)))
        var farmpwr = self.allocate("gen", nstep)
        var wspd = self.allocate("wind_speed", nstep)
        var wdir = self.allocate("wind_direction", nstep)
        var air_temp = self.allocate("temp", nstep)
        var air_pres = self.allocate("pressure", nstep)
        var Power = List[Float64](wpc.nTurbines, 0.0)
        var Thrust = List[Float64](wpc.nTurbines, 0.0)
        var Eff = List[Float64](wpc.nTurbines, 0.0)
        var Wind = List[Float64](wpc.nTurbines, 0.0)
        var Turb = List[Float64](wpc.nTurbines, 0.0)
        var DistDown = List[Float64](wpc.nTurbines, 0.0)
        var DistCross = List[Float64](wpc.nTurbines, 0.0)
        var monthly = self.allocate("monthly_energy", 12)
        for i in range(12):
            monthly[i] = 0.0
        var annual = 0.0
        var annual_gross = 0.0
        var withoutCutOffLosses = 0.0
        var annual_after_wake_loss = 0.0
        var i = 0
        for hr in range(8760):
            var imonth = util.month_of(Float64(hr)) - 1
            for istep in range(steps_per_hour):
                if i % (nstep / 20) == 0:
                    self.update("", 100.0 * Float32(i) / Float32(nstep), Float32(i))
                var wind: Float64 = 0.0
                var dir: Float64 = 0.0
                var temp: Float64 = 0.0
                var pres: Float64 = 0.0
                var closest_dir_meas_ht: Float64 = 0.0
                if contains_leap_day:
                    if hr == 1416:
                        for j in range(24 * steps_per_hour):
                            if not wdprov.read(wt.hubHeight, &wind, &dir, &temp, &pres, &wt.measurementHeight, &closest_dir_meas_ht, True):
                                throw exec_error("windpower", util.format("error reading wind resource file at %d: ", i) + wdprov.error())
                if not wdprov.read(wt.hubHeight, &wind, &dir, &temp, &pres, &wt.measurementHeight, &closest_dir_meas_ht, True):
                    throw exec_error("windpower", util.format("error reading wind resource file at %d: ", i) + wdprov.error())
                if Math.abs(wt.measurementHeight - wt.hubHeight) > 35.0:
                    throw exec_error("windpower", util.format("the closest wind speed measurement height (%lg m) found is more than 35 m from the hub height specified (%lg m)", wt.measurementHeight, wt.hubHeight))
                if Math.abs(closest_dir_meas_ht - wt.measurementHeight) > 10.0:
                    if i > 0:
                        if (wt.measurementHeight == wt.hubHeight) and (closest_dir_meas_ht != wt.hubHeight):
                            throw exec_error("windpower", util.format("on hour %d, SAM interpolated the wind speed to an %lgm measurement height, but could not interpolate the wind direction from the two closest measurements because the directions encountered were too disparate", i + 1, wt.measurementHeight))
                        else:
                            throw exec_error("windpower", util.format("SAM encountered an error at hour %d: hub height = %lg, closest wind speed meas height = %lg, closest wind direction meas height = %lg ", i + 1, wt.hubHeight, wt.measurementHeight, closest_dir_meas_ht))
                    else:
                        throw exec_error("windpower", util.format("the closest wind speed measurement height (%lg m) and direction measurement height (%lg m) were more than 10m apart", wt.measurementHeight, closest_dir_meas_ht))
                if Math.abs(wt.measurementHeight - wt.hubHeight) > 1:
                    if wt.shearExponent > 1.0:
                        wt.shearExponent = 1.0 / 7.0
                    wind = wind * Math.pow(wt.hubHeight / wt.measurementHeight, wt.shearExponent)
                    wt.measurementHeight = wt.hubHeight
                var farmp = 0.0
                var gross_farmp = 0.0
                if Int(wpc.nTurbines) != wpc.windPowerUsingResource(
                    wind, dir, pres, temp,
                    &farmp, &gross_farmp,
                    &Power[0], &Thrust[0], &Eff[0], &Wind[0], &Turb[0], &DistDown[0], &DistCross[0]):
                    throw exec_error("windpower", util.format("error in wind calculation at time %d, details: %s", i, wpc.GetErrorDetails().c_str()))
                annual_gross += gross_farmp
                annual_after_wake_loss += farmp
                farmp *= lossMultiplier
                withoutCutOffLosses += farmp * haf(hr)
                if lowTempCutoff:
                    if temp < lowTempCutoffValue:
                        farmp = 0.0
                if icingCutoff:
                    if temp < icingTempCutoffValue and wdprov.relativeHumidity()[i] > icingRHCutoffValue:
                        farmp = 0.0
                farmpwr[i] = ssc_number_t(farmp) * haf(hr)
                wspd[i] = ssc_number_t(wind)
                wdir[i] = ssc_number_t(dir)
                air_temp[i] = ssc_number_t(temp)
                air_pres[i] = ssc_number_t(pres)
                monthly[imonth] += farmpwr[i] / ssc_number_t(steps_per_hour)
                annual += farmpwr[i] / ssc_number_t(steps_per_hour)
                i += 1
        self.assign("annual_energy", var_data(ssc_number_t(annual)))
        var kWhperkW = 0.0
        var nameplate = self.as_double("system_capacity")
        if nameplate > 0:
            kWhperkW = annual / nameplate
        self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
        self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
        self.assign("cutoff_losses", var_data(ssc_number_t((withoutCutOffLosses - annual) / withoutCutOffLosses)))
        self.assign("annual_gross_energy", annual_gross)
        var wsp_avg = 0.0
        for n in range(nstep):
            wsp_avg += wspd[n]
        wsp_avg /= Float64(nstep)
        self.assign("wind_speed_average", wsp_avg)
        if wakeModelChoice != 3:
            wake_int_loss_percent = (1.0 - annual_after_wake_loss / annual_gross) * 100.0
        calculate_p50p90(self)
        calculate_losses(self, wake_int_loss_percent)

def calculate_losses(cm: borrowed compute_module, wake_int_loss_percent: Float64):
    var avail_loss_percent = 1.0 - (100.0 - cm.as_double("avail_bop_loss")) / 100.0 * (100.0 - cm.as_double("avail_grid_loss")) / 100.0 * (100.0 - cm.as_double("avail_turb_loss")) / 100.0
    var elec_loss_percent = 1.0 - (100.0 - cm.as_double("elec_eff_loss")) / 100.0 * (100.0 - cm.as_double("elec_parasitic_loss")) / 100.0
    var env_loss_percent = 1.0 - (100.0 - cm.as_double("env_degrad_loss")) / 100.0 * (100.0 - cm.as_double("env_exposure_loss")) / 100.0 * (100.0 - cm.as_double("env_env_loss")) / 100.0 * (100.0 - cm.as_double("env_icing_loss")) / 100.0
    var ops_loss_percent = 1.0 - (100.0 - cm.as_double("ops_env_loss")) / 100.0 * (100.0 - cm.as_double("ops_grid_loss")) / 100.0 * (100.0 - cm.as_double("ops_load_loss")) / 100.0 * (100.0 - cm.as_double("ops_strategies_loss")) / 100.0
    var turb_loss_percent = 1.0 - (100.0 - cm.as_double("turb_generic_loss")) / 100.0 * (100.0 - cm.as_double("turb_hysteresis_loss")) / 100.0 * (100.0 - cm.as_double("turb_perf_loss")) / 100.0 * (100.0 - cm.as_double("turb_specific_loss")) / 100.0
    var wake_loss_percent = 1.0 - (100.0 - cm.as_double("wake_ext_loss")) / 100.0 * (100.0 - cm.as_double("wake_future_loss")) / 100.0 * (100.0 - wake_int_loss_percent) / 100.0
    cm.assign("avail_losses", avail_loss_percent * 100.0)
    cm.assign("elec_losses", elec_loss_percent * 100.0)
    cm.assign("env_losses", env_loss_percent * 100.0)
    cm.assign("ops_losses", ops_loss_percent * 100.0)
    cm.assign("turb_losses", turb_loss_percent * 100.0)
    cm.assign("wake_losses", wake_loss_percent * 100.0)

def get_fixed_losses(cm: borrowed compute_module) -> Float64:
    var lossMultiplier = 1.0
    var loss_names = List[String]("avail_bop_loss", "avail_grid_loss", "avail_turb_loss", "elec_eff_loss",
                                              "elec_parasitic_loss", "env_degrad_loss", "env_exposure_loss", "env_env_loss",
                                              "env_icing_loss", "ops_env_loss", "ops_grid_loss", "ops_load_loss",
                                              "ops_strategies_loss", "turb_generic_loss", "turb_hysteresis_loss",
                                              "turb_perf_loss", "turb_specific_loss", "wake_ext_loss", "wake_future_loss")
    for loss in loss_names:
        if cm.is_assigned(loss):
            lossMultiplier *= (1.0 - cm.as_double(loss) / 100.0)
    return lossMultiplier

def windpower_module_entry():

// DEFINE_MODULE_ENTRY(windpower, "Utility scale wind farm model (adapted from TRNSYS code by P.Quinlan and openWind software by AWS Truepower)", 2)