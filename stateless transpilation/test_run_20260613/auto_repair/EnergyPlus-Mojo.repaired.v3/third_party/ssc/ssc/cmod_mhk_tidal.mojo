/*******************************************************************************************************
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  (Alliance) under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
*
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
*
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
*
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as System Advisor Model or SAM. Except
*  to comply with the foregoing, the terms System Advisor Model, SAM, or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
*
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/
from core import *
from common import *

var _cm_vtab_mhk_tidal: StaticArray[var_info, 35] = [
    var_info(SSC_INPUT, SSC_MATRIX, "tidal_resource", "Frequency distribution of resource as a function of stream speeds", "", "", "MHKTidal", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "tidal_power_curve", "Power curve of tidal energy device as function of stream speeds", "kW", "", "MHKTidal", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "number_devices", "Number of tidal devices in the system", "", "", "MHKTidal", "?=1", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fixed_charge_rate", "FCR from LCOE Cost page", "", "", "MHKTidal", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "device_costs_total", "Device costs", "$", "", "MHKTidal", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "balance_of_system_cost_total", "BOS costs", "$", "", "MHKTidal", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "financial_cost_total", "Financial costs", "$", "", "MHKTidal", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "total_operating_cost", "O&M costs", "$", "", "MHKTidal", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_array_spacing", "Array spacing loss", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_resource_overprediction", "Resource overprediction loss", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_transmission", "Transmission losses", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_downtime", "Array/WEC downtime loss", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_additional", "Additional losses", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "device_rated_capacity", "Rated capacity of device", "kW", "", "MHKTidal", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "device_average_power", "Average power production of a single device", "kW", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual energy production of array", "kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity Factor of array", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "annual_energy_distribution", "Annual energy production of array as function of speed", "kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "annual_cumulative_energy_distribution", "Cumulative annual energy production of array as function of speed", "kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "tidal_resource_start_velocity", "First tidal velocity where probability distribution is greater than 0 ", "m/s", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "tidal_resource_end_velocity", "Last tidal velocity where probability distribution is greater than 0 ", "m/s", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "tidal_power_start_velocity", "First tidal velocity where power curve is greater than 0 ", "m/s", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "tidal_power_end_velocity", "Last tidal velocity where power curve is greater than 0 ", "m/s", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_capital_cost_kwh", "Capital costs per unit annual energy", "$/kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_device_cost_kwh", "Device costs per unit annual energy", "$/kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_bos_cost_kwh", "Balance of system costs per unit annual energy", "$/kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_financial_cost_kwh", "Financial costs per unit annual energy", "$/kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_om_cost_kwh", "O&M costs per unit annual energy", "$/kWh", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_capital_cost_lcoe", "Capital cost as percentage of overall LCOE", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_device_cost_lcoe", "Device cost", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_bos_cost_lcoe", "BOS cost", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_financial_cost_lcoe", "Financial cost", "%", "", "MHKTidal", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_om_cost_lcoe", "O&M cost (annual)", "%", "", "MHKTidal", "*", "", ""),
    var_info_invalid
]

class cm_mhk_tidal(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_mhk_tidal)

    def exec(inout self):
        var tidal_resource_matrix: matrix_t[float64] = self.as_matrix("tidal_resource")
        var tidal_power_curve: matrix_t[float64] = self.as_matrix("tidal_power_curve")
        if tidal_power_curve.nrows() != tidal_resource_matrix.nrows():
            raise exec_error("mhk_tidal", "Size of Power Curve is not equal to Tidal Resource")
        var number_rows: int = int(tidal_resource_matrix.nrows())
        if tidal_power_curve.ncols() != size_t(2):
            raise exec_error("mhk_tidal", "Power curve must contain two columns")
        if tidal_power_curve.ncols() < size_t(2):
            raise exec_error("mhk_tidal", "Resource matrix must have at least two columns")
        var _speed_vect: List[float64] = List[float64](number_rows)
        var _probability_vect: List[float64] = List[float64](number_rows)
        var _power_vect: List[float64] = List[float64](number_rows)
        var p_annual_energy_dist: Pointer[ssc_number_t] = self.allocate("annual_energy_distribution", number_rows)
        var p_annual_cumulative_energy_dist: Pointer[ssc_number_t] = self.allocate("annual_cumulative_energy_distribution", number_rows)
        var annual_energy: float64 = 0.0
        var device_average_power: float64 = 0.0
        var _probability_vect_checker: float64 = 0.0
        var capacity_factor: float64 = 0.0
        var device_rated_capacity: float64 = 0.0
        if self.is_assigned("device_rated_capacity"):
            device_rated_capacity = self.as_double("device_rated_capacity")
        else:
            device_rated_capacity = 0.0
        var number_devices: int = self.as_integer("number_devices")
        var total_loss: float64 = self.as_double("loss_array_spacing") + self.as_double("loss_resource_overprediction") + self.as_double("loss_transmission") + self.as_double("loss_downtime") + self.as_double("loss_additional")
        var tidal_resource_start_velocity: float64 = 0.0
        var tidal_power_start_velocity: float64 = 0.0
        var tidal_resource_end_velocity: float64 = 0.0
        var tidal_power_end_velocity: float64 = 0.0
        var min_velocity: float64 = 0.0
        var max_velocity: float64 = 0.0
        min_velocity = tidal_resource_matrix.at(0, 0)
        max_velocity = tidal_resource_matrix.at(size_t(number_rows) - 1, 0)
        for i in range(number_rows):
            var n: size_t = i
            if tidal_resource_matrix.at(n, 1) != 0 and tidal_resource_matrix.at(n - 1, 1) == 0 and n != 0:
                tidal_resource_start_velocity = tidal_resource_matrix.at(n, 0)
            if tidal_power_curve.at(n, 1) != 0 and tidal_power_curve.at(n - 1, 1) == 0 and n != 0:
                tidal_power_start_velocity = tidal_power_curve.at(n, 0)
            if tidal_resource_matrix.at(n, 1) != 0 and tidal_resource_matrix.at(n + 1, 1) == 0 and n != 0:
                tidal_resource_end_velocity = tidal_resource_matrix.at(n, 0)
            if i == number_rows - 1 and tidal_resource_end_velocity == 0:
                tidal_resource_end_velocity = tidal_resource_matrix.at(n, 0)
            if tidal_power_curve.at(n, 1) != 0 and tidal_power_curve.at(n + 1, 1) == 0 and n != 0:
                tidal_power_end_velocity = tidal_power_curve.at(n, 0)
            if i == number_rows - 1 and tidal_power_end_velocity == 0:
                tidal_power_end_velocity = tidal_power_curve.at(n, 0)
            _speed_vect[i] = tidal_resource_matrix.at(i, 0)
            _probability_vect[i] = tidal_resource_matrix.at(i, 1)
            _power_vect[i] = tidal_power_curve.at(i, 1)
            if _power_vect[i] > device_rated_capacity:
                device_rated_capacity = _power_vect[i]
            _probability_vect_checker += _probability_vect[i]
            p_annual_energy_dist[i] = _power_vect[i] * _probability_vect[i] * number_devices * 8760
            annual_energy += p_annual_energy_dist[i]
            if i == 0:
                p_annual_cumulative_energy_dist[i] = p_annual_energy_dist[i]
            else:
                p_annual_cumulative_energy_dist[i] = p_annual_energy_dist[i] + p_annual_cumulative_energy_dist[i - 1]
            device_average_power += _power_vect[i] * _probability_vect[i]
        var probability_tolerance: float64 = 0.005
        if math.fabs(1.0 - _probability_vect_checker) > probability_tolerance:
            raise exec_error("mhk_tidal", "Probability distribution vector does not add up to 100%.")
        annual_energy *= (1 - (total_loss / 100))
        var device_cost: float64 = self.as_double("device_costs_total")
        var bos_cost: float64 = self.as_double("balance_of_system_cost_total")
        var financial_cost: float64 = self.as_double("financial_cost_total")
        var om_cost: float64 = self.as_double("total_operating_cost")
        var fcr: float64 = self.as_double("fixed_charge_rate")
        var total_capital_cost_kwh: float64 = fcr * (device_cost + bos_cost + financial_cost) / annual_energy
        var total_device_cost_kwh: float64 = fcr * device_cost / annual_energy
        var total_bos_cost_kwh: float64 = fcr * bos_cost / annual_energy
        var total_financial_cost_kwh: float64 = fcr * financial_cost / annual_energy
        var total_om_cost_kwh: float64 = om_cost / annual_energy
        var total_capital_cost_lcoe: float64 = (fcr * (device_cost + bos_cost + financial_cost)) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        var total_device_cost_lcoe: float64 = (fcr * device_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        var total_bos_cost_lcoe: float64 = (fcr * bos_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        var total_financial_cost_lcoe: float64 = (fcr * financial_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        var total_om_cost_lcoe: float64 = (om_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        self.assign("total_capital_cost_kwh", var_data(ssc_number_t(total_capital_cost_kwh)))
        self.assign("total_device_cost_kwh", var_data(ssc_number_t(total_device_cost_kwh)))
        self.assign("total_bos_cost_kwh", var_data(ssc_number_t(total_bos_cost_kwh)))
        self.assign("total_financial_cost_kwh", var_data(ssc_number_t(total_financial_cost_kwh)))
        self.assign("total_om_cost_kwh", var_data(ssc_number_t(total_om_cost_kwh)))
        self.assign("total_capital_cost_lcoe", var_data(ssc_number_t(total_capital_cost_lcoe)))
        self.assign("total_device_cost_lcoe", var_data(ssc_number_t(total_device_cost_lcoe)))
        self.assign("total_bos_cost_lcoe", var_data(ssc_number_t(total_bos_cost_lcoe)))
        self.assign("total_financial_cost_lcoe", var_data(ssc_number_t(total_financial_cost_lcoe)))
        self.assign("total_om_cost_lcoe", var_data(ssc_number_t(total_om_cost_lcoe)))
        capacity_factor = annual_energy / (device_rated_capacity * number_devices * 8760)
        self.assign("annual_energy", var_data(ssc_number_t(annual_energy)))
        self.assign("device_average_power", var_data(ssc_number_t(device_average_power)))
        self.assign("device_rated_capacity", var_data(ssc_number_t(device_rated_capacity)))
        self.assign("capacity_factor", var_data(ssc_number_t(capacity_factor * 100)))
        self.assign("tidal_resource_start_velocity", var_data(ssc_number_t(tidal_resource_start_velocity)))
        self.assign("tidal_resource_end_velocity", var_data(ssc_number_t(tidal_resource_end_velocity)))
        self.assign("tidal_power_start_velocity", var_data(ssc_number_t(tidal_power_start_velocity)))
        self.assign("tidal_power_end_velocity", var_data(ssc_number_t(tidal_power_end_velocity)))

DEFINE_MODULE_ENTRY(mhk_tidal, "MHK Tidal power calculation model using power distribution.", 3)