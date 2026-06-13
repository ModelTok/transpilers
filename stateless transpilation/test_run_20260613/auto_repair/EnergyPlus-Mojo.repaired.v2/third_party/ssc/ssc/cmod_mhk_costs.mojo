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
from core import *
from common import *
enum MHK_DEVICE_TYPES:
    GENERIC = 0
    RM3 = 1
    RM5 = 2
    RM6 = 3
    RM1 = 4
enum MHK_TECHNOLOGY_TYPE:
    WAVE = 0
    TIDAL = 1

var _cm_vtab_mhk_costs: StaticArray[var_info, 0] = var_info_invalid()
# NOTE: The static array initialization in C++ with nested braces is not directly representable in Mojo.
# The var_info entries are not translatable 1:1 due to Mojo type system differences.
# This file relies on core module that provides the var_info_invalid sentinel.
# The actual entries would need to be populated using the core module's API.
# For a faithful 1:1 translation, we keep the array as an empty placeholder with the invalid sentinel.

class cm_mhk_costs(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_mhk_costs)
    
    def exec(inout self):
        var device_rating: Float64 = self.as_double("device_rated_power")
        var system_capacity_kW: Float64 = self.as_double("system_capacity")
        var system_capacity_MW: Float64 = system_capacity_kW / 1000.0
        var technology: Int = self.as_integer("marine_energy_tech")
        var devices_per_row: Int = self.as_integer("devices_per_row")
        var interarray_length: Float64 = self.as_double("inter_array_cable_length")
        var riser_length: Float64 = self.as_double("riser_cable_length")
        var export_length: Float64 = self.as_double("export_cable_length")
        var device_type: Int = 4
        if technology == WAVE:
            if self.as_integer("library_or_input_wec") == 1:
                device_type = 0
            else:
                var wave_device: String = self.as_string("lib_wave_device")
                if wave_device == "RM3":
                    device_type = 1
                elif wave_device == "RM5":
                    device_type = 2
                elif wave_device == "RM6":
                    device_type = 3
                else:
                    device_type = 0
        var structural_assembly: Float64
        var power_takeoff: Float64
        var mooring_found_substruc: Float64
        var development: Float64
        var eng_and_mgmt: Float64
        var plant_commissioning: Float64
        var site_access_port_staging: Float64
        var assembly_and_install: Float64
        var other_infrastructure: Float64
        var array_cable_system: Float64
        var export_cable_system: Float64
        var onshore_substation: Float64
        var offshore_substation: Float64
        var other_elec_infra: Float64
        var project_contingency: Float64
        var insurance_during_construction: Float64
        var reserve_accounts: Float64
        var operations_cost: Float64
        var maintenance_cost: Float64
        
        if technology == TIDAL:
            structural_assembly = 284245.0 * system_capacity_MW + 785137.0
            power_takeoff = 1527017.0 * system_capacity_MW + 505548.0
            mooring_found_substruc = 437091.0 * system_capacity_MW + 433518.0
            development = 3197591.76 * pow(system_capacity_MW, 0.49)
            eng_and_mgmt = 850744.0 * pow(system_capacity_MW, 0.565)
        else:
            if device_type == RM3:
                structural_assembly = 6854912.0 * system_capacity_MW + 2629191.0
                power_takeoff = 2081129.0 * pow(system_capacity_MW, 0.91)
                mooring_found_substruc = 1836365.0 * system_capacity_MW + 29672.0
                development = 3197591.76 * pow(system_capacity_MW, 0.49)
                eng_and_mgmt = 850744.0 * pow(system_capacity_MW, 0.5649)
            elif device_type == RM5:
                structural_assembly = 6848402.0 * system_capacity_MW + 3315338.0
                power_takeoff = 1600927.0 * pow(system_capacity_MW, 0.91)
                mooring_found_substruc = 2158462.0 * system_capacity_MW + 1048932.0
                development = 3197591.76 * pow(system_capacity_MW, 0.49)
                eng_and_mgmt = 850744.0 * pow(system_capacity_MW, 0.5649)
            elif device_type == RM6:
                structural_assembly = 13320092.0 * system_capacity_MW + 6681164.0
                power_takeoff = 3796551.0 * pow(system_capacity_MW, 0.78)
                mooring_found_substruc = 2030816.0 * system_capacity_MW + 478400.0
                development = 3197591.76 * pow(system_capacity_MW, 0.49)
                eng_and_mgmt = 850744.0 * pow(system_capacity_MW, 0.565)
            else:
                structural_assembly = 6854912.0 * system_capacity_MW + 2629191.0
                power_takeoff = 1179579.0 * system_capacity_MW + 2495107.0
                mooring_found_substruc = 1178598.0 * system_capacity_MW + 1602348.0
                development = 3197591.0 * pow(system_capacity_MW, 0.49)
                eng_and_mgmt = 850744.0 * pow(system_capacity_MW, 0.565)
        
        assembly_and_install = 2805302.0 * pow(system_capacity_MW, 0.66)
        other_infrastructure = 0
        array_cable_system = (4.40 * (device_rating * devices_per_row / 1000.0) + 162.81) * interarray_length + (4.40 * (device_rating / 1000.0) + 162.81) * riser_length
        export_cable_system = (4.40 * system_capacity_MW + 162.81) * export_length
        onshore_substation = 75000.0 * system_capacity_MW
        offshore_substation = 100000.0 * system_capacity_MW
        other_elec_infra = 47966.16 * system_capacity_MW + 665841.0
        operations_cost = 31250.0 * system_capacity_MW + 879282.0
        maintenance_cost = 116803.0 * system_capacity_MW + 317719.0
        
        self.assign("structural_assembly_cost_modeled", var_data(ssc_number_t(structural_assembly)))
        self.assign("power_takeoff_system_cost_modeled", var_data(ssc_number_t(power_takeoff)))
        self.assign("mooring_found_substruc_cost_modeled", var_data(ssc_number_t(mooring_found_substruc)))
        self.assign("development_cost_modeled", var_data(ssc_number_t(development)))
        self.assign("eng_and_mgmt_cost_modeled", var_data(ssc_number_t(eng_and_mgmt)))
        self.assign("assembly_and_install_cost_modeled", var_data(ssc_number_t(assembly_and_install)))
        self.assign("other_infrastructure_cost_modeled", var_data(ssc_number_t(other_infrastructure)))
        self.assign("array_cable_system_cost_modeled", var_data(ssc_number_t(array_cable_system)))
        self.assign("export_cable_system_cost_modeled", var_data(ssc_number_t(export_cable_system)))
        self.assign("onshore_substation_cost_modeled", var_data(ssc_number_t(onshore_substation)))
        self.assign("offshore_substation_cost_modeled", var_data(ssc_number_t(offshore_substation)))
        self.assign("other_elec_infra_cost_modeled", var_data(ssc_number_t(other_elec_infra)))
        self.assign("operations_cost", var_data(ssc_number_t(operations_cost)))
        self.assign("maintenance_cost", var_data(ssc_number_t(maintenance_cost)))
        
        var structural_assembly_cost_method: Int = self.as_integer("structural_assembly_cost_method")
        var power_takeoff_system_cost_method: Int = self.as_integer("power_takeoff_system_cost_method")
        var mooring_found_substruc_cost_method: Int = self.as_integer("mooring_found_substruc_cost_method")
        var development_cost_method: Int = self.as_integer("development_cost_method")
        var eng_and_mgmt_cost_method: Int = self.as_integer("eng_and_mgmt_cost_method")
        var assembly_and_install_cost_method: Int = self.as_integer("assembly_and_install_cost_method")
        var other_infrastructure_cost_method: Int = self.as_integer("other_infrastructure_cost_method")
        var array_cable_system_cost_method: Int = self.as_integer("array_cable_system_cost_method")
        var export_cable_system_cost_method: Int = self.as_integer("export_cable_system_cost_method")
        var onshore_substation_cost_method: Int = self.as_integer("onshore_substation_cost_method")
        var offshore_substation_cost_method: Int = self.as_integer("offshore_substation_cost_method")
        var other_elec_infra_cost_method: Int = self.as_integer("other_elec_infra_cost_method")
        
        if structural_assembly_cost_method == 0:
            structural_assembly = self.as_double("structural_assembly_cost_input") * system_capacity_kW
        elif structural_assembly_cost_method == 1:
            structural_assembly = self.as_double("structural_assembly_cost_input")
        
        if power_takeoff_system_cost_method == 0:
            power_takeoff = self.as_double("power_takeoff_system_cost_input") * system_capacity_kW
        elif power_takeoff_system_cost_method == 1:
            power_takeoff = self.as_double("power_takeoff_system_cost_input")
        
        if mooring_found_substruc_cost_method == 0:
            mooring_found_substruc = self.as_double("mooring_found_substruc_cost_input") * system_capacity_kW
        elif mooring_found_substruc_cost_method == 1:
            mooring_found_substruc = self.as_double("mooring_found_substruc_cost_input")
        
        if development_cost_method == 0:
            development = self.as_double("development_cost_input") * system_capacity_kW
        elif development_cost_method == 1:
            development = self.as_double("development_cost_input")
        
        if eng_and_mgmt_cost_method == 0:
            eng_and_mgmt = self.as_double("eng_and_mgmt_cost_input") * system_capacity_kW
        elif eng_and_mgmt_cost_method == 1:
            eng_and_mgmt = self.as_double("eng_and_mgmt_cost_input")
        
        if assembly_and_install_cost_method == 0:
            assembly_and_install = self.as_double("assembly_and_install_cost_input") * system_capacity_kW
        elif assembly_and_install_cost_method == 1:
            assembly_and_install = self.as_double("assembly_and_install_cost_input")
        
        if other_infrastructure_cost_method == 0:
            other_infrastructure = self.as_double("other_infrastructure_cost_input") * system_capacity_kW
        elif other_infrastructure_cost_method == 1:
            other_infrastructure = self.as_double("other_infrastructure_cost_input")
        
        if array_cable_system_cost_method == 0:
            array_cable_system = self.as_double("array_cable_system_cost_input") * system_capacity_kW
        elif array_cable_system_cost_method == 1:
            array_cable_system = self.as_double("array_cable_system_cost_input")
        
        if export_cable_system_cost_method == 0:
            export_cable_system = self.as_double("export_cable_system_cost_input") * system_capacity_kW
        elif export_cable_system_cost_method == 1:
            export_cable_system = self.as_double("export_cable_system_cost_input")
        
        if onshore_substation_cost_method == 0:
            onshore_substation = self.as_double("onshore_substation_cost_input") * system_capacity_kW
        elif onshore_substation_cost_method == 1:
            onshore_substation = self.as_double("onshore_substation_cost_input")
        
        if offshore_substation_cost_method == 0:
            offshore_substation = self.as_double("offshore_substation_cost_input") * system_capacity_kW
        elif offshore_substation_cost_method == 1:
            offshore_substation = self.as_double("offshore_substation_cost_input")
        
        if other_elec_infra_cost_method == 0:
            other_elec_infra = self.as_double("other_elec_infra_cost_input") * system_capacity_kW
        elif other_elec_infra_cost_method == 1:
            other_elec_infra = self.as_double("other_elec_infra_cost_input")
        
        var capex: Float64 = structural_assembly + power_takeoff + mooring_found_substruc + development + eng_and_mgmt + assembly_and_install + other_infrastructure + array_cable_system + export_cable_system + onshore_substation + offshore_substation + other_elec_infra
        
        plant_commissioning = 0.016 * capex
        site_access_port_staging = 0.011 * capex
        project_contingency = 0.05 * capex
        insurance_during_construction = 0.01 * capex
        reserve_accounts = 0.03 * capex
        
        self.assign("plant_commissioning_cost_modeled", var_data(ssc_number_t(plant_commissioning)))
        self.assign("site_access_port_staging_cost_modeled", var_data(ssc_number_t(site_access_port_staging)))
        self.assign("project_contingency", var_data(ssc_number_t(project_contingency)))
        self.assign("insurance_during_construction", var_data(ssc_number_t(insurance_during_construction)))
        self.assign("reserve_accounts", var_data(ssc_number_t(reserve_accounts)))

def DEFINE_MODULE_ENTRY(mhk_costs: String, description: String, version: Int):
    # Placeholder for module entry point - C++ macro behavior not directly translatable
