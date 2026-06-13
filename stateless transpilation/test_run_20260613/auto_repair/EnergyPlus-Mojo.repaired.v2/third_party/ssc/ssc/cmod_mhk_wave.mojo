# /*******************************************************************************************************
# *  Copyright 2017 Alliance for Sustainable Energy, LLC
# *
# *  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
# *  (Alliance) under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
# *  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
# *  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
# *  copies to the public, perform publicly and display publicly, and to permit others to do so.
# *  copies to the public, perform publicly and display publicly, and to permit others to do so.
# *
# *  Redistribution and use in source and binary forms, with or without modification, are permitted
# *  provided that the following conditions are met:
# *
# *  1. Redistributions of source code must retain the above copyright notice, the above government
# *  rights notice, this list of conditions and the following disclaimer.
# *
# *  2. Redistributions in binary form must reproduce the above copyright notice, the above government
# *  rights notice, this list of conditions and the following disclaimer in the documentation and/or
# *  other materials provided with the distribution.
# *
# *  3. The entire corresponding source code of any redistribution, with or without modification, by a
# *  research entity, including but not limited to any contracting manager/operator of a United States
# *  National Laboratory, any institution of higher learning, and any non-profit organization, must be
# *  made publicly available under this license for as long as the redistribution is made available by
# *  the research entity.
# *
# *  4. Redistribution of this software, without modification, must refer to the software by the same
# *  designation. Redistribution of a modified version of this software (i) may not refer to the modified
# *  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
# *  the underlying software originally provided by Alliance asSystem Advisor Model orSAM. Except
# *  to comply with the foregoing, the termsSystem Advisor Model,SAM, or any confusingly similar
# *  designation may not be used to refer to any modified version of this software or any modified
# *  version of the underlying software originally provided by Alliance without the prior written consent
# *  of Alliance.
# *
# *  5. The name of the copyright holder, contributors, the United States Government, the United States
# *  Department of Energy, or any of their employees may not be used to endorse or promote products
# *  derived from this software without specific prior written permission.
# *
# *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# *  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
# *  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
# *  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# *  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# *  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************************************/

from core import compute_module, var_info, ssc_number_t, Matrix, SSC_INPUT, SSC_OUTPUT, SSC_MATRIX, SSC_NUMBER, var_info_invalid
from core import exec_error  # assume exec_error is an exception class

# static var_info _cm_vtab_mhk_wave[] = { ... }
var _cm_vtab_mhk_wave = List[var_info](
    var_info(SSC_INPUT, SSC_MATRIX, "wave_resource_matrix", "Frequency distribution of wave resource as a function of Hs and Te", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "wave_power_matrix", "Wave Power Matrix", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "number_devices", "Number of wave devices in the system", "", "", "MHKWave", "?=1", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "system_capacity", "System Nameplate Capacity", "kW", "", "MHKWave", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "device_rated_power", "Rated capacity of device", "kW", "", "MHKWave", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fixed_charge_rate", "FCR from LCOE Cost page", "", "", "MHKWave", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "device_costs_total", "Device costs", "$", "", "MHKWave", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "balance_of_system_cost_total", "BOS costs", "$", "", "MHKWave", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "financial_cost_total", "Financial costs", "$", "", "MHKWave", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "total_operating_cost", "O&M costs", "$", "", "MHKWave", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_array_spacing", "Array spacing loss", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_resource_overprediction", "Resource overprediction loss", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_transmission", "Transmission losses", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_downtime", "Array/WEC downtime loss", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "loss_additional", "Additional losses", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "device_average_power", "Average power production of a single device", "kW", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual energy production of array", "kWh", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity Factor", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_MATRIX, "annual_energy_distribution", "Annual energy production as function of Hs and Te", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_resource_start_height", "Wave height at which first non-zero wave resource value occurs (m)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_resource_start_period", "Wave period at which first non-zero wave resource value occurs (s)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_resource_end_height", "Wave height at which last non-zero wave resource value occurs (m)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_resource_end_period", "Wave period at which last non-zero wave resource value occurs (s)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_power_start_height", "Wave height at which first non-zero WEC power output occurs (m)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_power_start_period", "Wave period at which first non-zero WEC power output occurs (s)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_power_end_height", "Wave height at which last non-zero WEC power output occurs (m)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "wave_power_end_period", "Wave period at which last non-zero WEC power output occurs (s)", "", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_capital_cost_kwh", "Capital costs per unit annual energy", "$/kWh", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_device_cost_kwh", "Device costs per unit annual energy", "$/kWh", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_bos_cost_kwh", "Balance of system costs per unit annual energy", "$/kWh", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_financial_cost_kwh", "Financial costs per unit annual energy", "$/kWh", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_om_cost_kwh", "O&M costs per unit annual energy", "$/kWh", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_capital_cost_lcoe", "Capital cost as percentage of overall LCOE", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_device_cost_lcoe", "Device cost", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_bos_cost_lcoe", "BOS cost", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_financial_cost_lcoe", "Financial cost", "%", "", "MHKWave", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "total_om_cost_lcoe", "O&M cost (annual)", "%", "", "MHKWave", "*", "", ""),
    var_info_invalid
)

class cm_mhk_wave(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_mhk_wave)

    def exec(self):
        wave_resource_matrix = self.as_matrix("wave_resource_matrix")
        wave_power_matrix = self.as_matrix("wave_power_matrix")
        if (wave_resource_matrix.ncols() != wave_power_matrix.ncols()) or (wave_resource_matrix.nrows() != wave_power_matrix.nrows()):
            raise exec_error("mhk_wave", "Size of Power Matrix is not equal to Wave Resource Matrix")
        resource_vect_checker = 0.0
        p_annual_energy_dist = self.allocate("annual_energy_distribution", wave_resource_matrix.nrows(), wave_resource_matrix.ncols())
        k = 0
        annual_energy = 0.0
        device_rated_capacity = 0.0
        device_average_power = 0.0
        capacity_factor = 0.0
        total_loss = (self.as_double("loss_array_spacing")
            + self.as_double("loss_resource_overprediction")
            + self.as_double("loss_transmission")
            + self.as_double("loss_downtime")
            + self.as_double("loss_additional"))
        device_rated_capacity = self.as_double("device_rated_power")
        number_devices = self.as_integer("number_devices")
        for i in range(wave_power_matrix.nrows()):
            for j in range(wave_power_matrix.ncols()):
                # /*if(as_integer("calculate_capacity") > 0)
                #     if (_power_vect[i][j] > system_capacity)
                #         system_capacity = _power_vect[i][j];*/
                if j == 0 or i == 0:  # Where (i = 0) is the row header, and (j =  0) is the column header.
                    p_annual_energy_dist[k] = ssc_number_t(wave_resource_matrix.at(i, j))
                else:
                    p_annual_energy_dist[k] = ssc_number_t(wave_resource_matrix.at(i, j) * wave_power_matrix.at(i, j) * 8760.0 / 100.0)
                    annual_energy += p_annual_energy_dist[k]
                    device_average_power += (p_annual_energy_dist[k] / 8760)
                    resource_vect_checker += wave_resource_matrix.at(i, j)
                k += 1
            # /*//Throw exception if default header column (of power curve and resource) does not match user input header row:
            # if (_check_column[i] != wave_resource_matrix.at(i, 0))
            #     throw compute_module::exec_error("mhk_wave", "Wave height bins of resource matrix don't match. Reset bins to default");
            # if (_check_column[i] != wave_power_matrix.at(i,0))
            #     throw compute_module::exec_error("mhk_wave", "Wave height bins of power matrix don't match. Reset bins to default");*/
        wave_resource_start_period = 0.0
        wave_resource_start_height = 0.0
        wave_resource_end_period = 0.0
        wave_resource_end_height = 0.0
        for l in range(wave_power_matrix.nrows()):
            for m in range(wave_power_matrix.ncols()):
                # /*if(as_integer("calculate_capacity") > 0)
                #     if (_power_vect[i][j] > system_capacity)
                #         system_capacity = _power_vect[i][j];*/
                if (ssc_number_t(wave_resource_matrix.at(l, m)) != 0 and ssc_number_t(wave_resource_matrix.at(l, m - 1)) == 0 and ssc_number_t(wave_resource_matrix.at(l, m + 1)) != 0 and (m - 1) != 0):
                    if wave_resource_start_period == 0:
                        wave_resource_start_period = wave_resource_matrix.at(0, m)
                        wave_resource_start_height = wave_resource_matrix.at(l, 0)
                elif (ssc_number_t(wave_resource_matrix.at(l, m)) != 0 and ssc_number_t(wave_resource_matrix.at(l, m - 1)) != 0 and ssc_number_t(wave_resource_matrix.at(l, m + 1)) == 0 and (m - 1) != 0):
                    wave_resource_end_period = wave_resource_matrix.at(0, m)
                    wave_resource_end_height = wave_resource_matrix.at(l, 0)
                else:

            # /*//Throw exception if default header column (of power curve and resource) does not match user input header row:
            # if (_check_column[i] != wave_resource_matrix.at(i, 0))
            #     throw compute_module::exec_error("mhk_wave", "Wave height bins of resource matrix don't match. Reset bins to default");
            # if (_check_column[i] != wave_power_matrix.at(i,0))
            #     throw compute_module::exec_error("mhk_wave", "Wave height bins of power matrix don't match. Reset bins to default");*/
        wave_power_start_period = 0.0
        wave_power_start_height = 0.0
        wave_power_end_period = 0.0
        wave_power_end_height = 0.0
        for n in range(wave_power_matrix.nrows()):
            for p in range(wave_power_matrix.ncols()):
                # /*if(as_integer("calculate_capacity") > 0)
                #     if (_power_vect[i][j] > system_capacity)
                #         system_capacity = _power_vect[i][j];*/
                if (ssc_number_t(wave_power_matrix.at(n, p)) != 0 and ssc_number_t(wave_power_matrix.at(n, p - 1)) == 0 and ssc_number_t(wave_power_matrix.at(n, p + 1)) != 0 and (p - 1) != 0):
                    if wave_power_start_period == 0:
                        wave_power_start_period = wave_power_matrix.at(0, p)
                        wave_power_start_height = wave_power_matrix.at(n, 0)
                elif (ssc_number_t(wave_power_matrix.at(n, p)) != 0 and ssc_number_t(wave_power_matrix.at(n, p - 1)) != 0 and (p - 1) != 0 and ssc_number_t(wave_power_matrix.at(n, p + 1)) == 0):
                    wave_power_end_period = wave_power_matrix.at(0, p)
                    wave_power_end_height = wave_power_matrix.at(n, 0)
                else:

            # /*//Throw exception if default header column (of power curve and resource) does not match user input header row:
            # if (_check_column[i] != wave_resource_matrix.at(i, 0))
            #     throw compute_module::exec_error("mhk_wave", "Wave height bins of resource matrix don't match. Reset bins to default");
            # if (_check_column[i] != wave_power_matrix.at(i,0))
            #     throw compute_module::exec_error("mhk_wave", "Wave height bins of power matrix don't match. Reset bins to default");*/
        # /*
        # vector<double> _check_header{ 0, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5,	11.5, 12.5,	13.5, 14.5, 15.5, 16.5, 17.5, 18.5, 19.5, 20.5 };
        # if (_check_header != wave_resource_matrix[0])
        #     throw compute_module::exec_error("mhk_wave", "Time period bins of resource matrix don't match. Reset bins to default");
        # if (_check_header != wave_power_matrix[0])
        #     throw compute_module::exec_error("mhk_wave", "Time period bins of wave power matrix don't match. Reset bins to default"); */
        if resource_vect_checker < 99.5:
            raise exec_error("mhk_wave", "Probability vector does not add up to 100%.")
        annual_energy *= (1 - (total_loss / 100))
        annual_energy *= number_devices
        device_cost = self.as_double("device_costs_total")
        bos_cost = self.as_double("balance_of_system_cost_total")
        financial_cost = self.as_double("financial_cost_total")
        om_cost = self.as_double("total_operating_cost")
        fcr = self.as_double("fixed_charge_rate")
        total_capital_cost_kwh = fcr * (device_cost + bos_cost + financial_cost) / annual_energy
        total_device_cost_kwh = fcr * device_cost / annual_energy
        total_bos_cost_kwh = fcr * bos_cost / annual_energy
        total_financial_cost_kwh = fcr * financial_cost / annual_energy
        total_om_cost_kwh = om_cost / annual_energy
        total_capital_cost_lcoe = (fcr * (device_cost + bos_cost + financial_cost)) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        total_device_cost_lcoe = (fcr * device_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        total_bos_cost_lcoe = (fcr * bos_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        total_financial_cost_lcoe = (fcr * financial_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
        total_om_cost_lcoe = (om_cost) / (fcr * (device_cost + bos_cost + financial_cost) + om_cost) * 100
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
        self.assign("average_power", var_data(ssc_number_t(device_average_power)))
        self.assign("capacity_factor", var_data(ssc_number_t(capacity_factor * 100)))
        self.assign("device_average_power", var_data(ssc_number_t(device_average_power)))
        self.assign("wave_resource_start_height", var_data(ssc_number_t(wave_resource_start_height)))
        self.assign("wave_resource_end_height", var_data(ssc_number_t(wave_resource_end_height)))
        self.assign("wave_resource_start_period", var_data(ssc_number_t(wave_resource_start_period)))
        self.assign("wave_resource_end_period", var_data(ssc_number_t(wave_resource_end_period)))
        self.assign("wave_power_start_height", var_data(ssc_number_t(wave_power_start_height)))
        self.assign("wave_power_end_height", var_data(ssc_number_t(wave_power_end_height)))
        self.assign("wave_power_start_period", var_data(ssc_number_t(wave_power_start_period)))
        self.assign("wave_power_end_period", var_data(ssc_number_t(wave_power_end_period)))

# DEFINE_MODULE_ENTRY(mhk_wave, "MHK Wave power calculation model using power distribution.", 3);
def get_module_entry():
    return cm_mhk_wave

register_module("mhk_wave", cm_mhk_wave, "MHK Wave power calculation model using power distribution.", 3)