# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met :
# 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from core import compute_module, var_info, SSC_INPUT, SSC_OUTPUT, SSC_NUMBER, var_info_invalid, ssc_number_t, var_data, define_module_entry

var _cm_vtab_windcsm: List[var_info] = List[var_info]()
var _cm_vtab_windcsm_data: List[var_info] = [
/*   VARTYPE           DATATYPE         NAME                                LABEL                                UNITS     META           GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/			
	{ SSC_INPUT,        SSC_NUMBER,      "turbine_class",					 "Turbine class",                     "",      "",            "wind_csm",      "?=0",                    "INTEGER,MIN=0,MAX=3",            "" },
	{ SSC_INPUT,        SSC_NUMBER,      "turbine_user_exponent",			 "Turbine user exponent",             "",      "",            "wind_csm",      "?=2.5",                  "",                               "" },
	{ SSC_INPUT,		SSC_NUMBER,      "turbine_carbon_blades",            "Turbine carbon blades",             "0/1",   "",            "wind_csm",      "?=0",                    "INTEGER,MIN=0,MAX=1",            "" },
	{ SSC_INPUT,		SSC_NUMBER,      "turbine_rotor_diameter",           "Turbine rotor diameter",            "m",     "",            "wind_csm",      "*",                      "",                               "" },
	{ SSC_INPUT,		SSC_NUMBER,      "machine_rating",                   "Machine rating",                    "kW",    "",            "wind_csm",      "*",                      "",                               "" },
	{ SSC_INPUT,		SSC_NUMBER,      "rotor_torque",                     "Rotor torque",                      "Nm",    "",            "wind_csm",      "*",                      "",                               "" },
	{ SSC_INPUT,		SSC_NUMBER,      "onboard_crane",                    "Onboard crane",                     "0/1",   "",            "wind_csm",      "?=0",                    "INTEGER,MIN=0,MAX=1",            "" },
	{ SSC_INPUT,		SSC_NUMBER,      "hub_height",                       "Hub height",                        "m",     "",            "wind_csm",      "*",                      "",                               "" },
	{ SSC_INPUT,		SSC_NUMBER,      "num_blades",                       "Number of blades",                  "",      "",            "wind_csm",      "?=3",                    "INTEGER,MIN=1",                  "" },
	{ SSC_INPUT,		SSC_NUMBER,      "num_bearings",                     "Number of main bearings",           "",      "",            "wind_csm",      "?=2",                    "INTEGER,MIN=1",                  "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "rotor_mass",                       "Rotor mass",                        "kg",    "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "rotor_cost",                       "Rotor cost",                        "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "blade_cost",                       "Rotor cost",                        "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "hub_cost",                         "Hub cost",                          "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "pitch_cost",                       "Pitch cost",                        "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "spinner_cost",                     "Spinner cost",                      "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "drivetrain_mass",                  "Drivetrain mass",                   "kg",    "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "drivetrain_cost",                  "Drivetrain cost",                   "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "low_speed_side_cost",              "Low speed side cost",               "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "main_bearings_cost",               "Main bearings cost",                "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "gearbox_cost",                     "Gearbox cost",                      "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "high_speed_side_cost",             "High speed side cost",              "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "generator_cost",                   "Generator cost",                    "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "bedplate_cost",                    "Bedplate cost",                     "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "yaw_system_cost",                  "Yaw system cost",                   "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "variable_speed_electronics_cost",  "Variable speed electronics cost",   "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "hvac_cost",                        "HVAC cost",                         "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "electrical_connections_cost",      "Electrical connections cost",       "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "controls_cost",                    "Controls cost",                     "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "mainframe_cost",                   "Mainframe cost",                    "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "transformer_cost",                 "Transformer cost",                  "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "tower_mass",                       "Tower mass",                        "kg",    "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "tower_cost",                       "Tower cost",                        "$",     "",            "wind_csm",      "*",                       "",                              "" },
	{ SSC_OUTPUT,       SSC_NUMBER,      "turbine_cost",                     "Turbine cost",                      "$",     "",            "wind_csm",      "*",                       "",                              "" },
var_info_invalid ]
# Note: In C++ the array is terminated by var_info_invalid; we include it as last element.

# Copy the data into the static variable (Mojo doesn't have static arrays like C++ so we just use the list)
_cm_vtab_windcsm = _cm_vtab_windcsm_data

class cm_windcsm(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_windcsm)

    def exec(self):
        var blades: Float64 = self.as_number("num_blades") as Float64
        var turbine_user_exponent: Float64 = self.as_number("turbine_user_exponent") as Float64
        var turbine_rotor_diameter: Float64 = self.as_number("turbine_rotor_diameter") as Float64
        var turbine_carbon_blades: Bool = self.as_integer("turbine_carbon_blades") == 1
        var turbine_class: Int64 = self.as_integer("turbine_class")
        var exponent: Float64 = 0
        match turbine_class:
            case 0:
                exponent = turbine_user_exponent
            case 1:
                if turbine_carbon_blades:
                    exponent = 2.47
                else:
                    exponent = 2.54
            case 2:
                if turbine_carbon_blades:
                    exponent = 2.44
                else:
                    exponent = 2.50
            case 3:
                if turbine_carbon_blades:
                    exponent = 2.44
                else:
                    exponent = 2.50
            case _:
                exponent = 2.5
        var blade_mass: Float64 = 0.5 * Math.pow((0.5 * turbine_rotor_diameter), exponent)
        var blade_mass_cost_coeff: Float64 = 14.6 # line 27
        var blade_cost_2015: Float64 = blade_mass_cost_coeff * blade_mass
        var hub_mass: Float64 = 2.3 * blade_mass + 1320.0
        var hub_mass_cost_coeff: Float64 = 3.9 # line 45
        var hub_cost_2015: Float64 = hub_mass_cost_coeff * hub_mass
        var pitch_bearing_mass: Float64 = 0.1295 * blade_mass * blades + 491.31
        var pitch_mass: Float64 = pitch_bearing_mass * (1.0 + 0.3280) + 555.0
        var pitch_mass_cost_coeff: Float64 = 22.1 # line 63
        var pitch_cost_2015: Float64 = pitch_mass_cost_coeff * pitch_mass
        var spinner_mass: Float64 = 15.5 * turbine_rotor_diameter - 980.0
        var spinner_mass_cost_coeff: Float64 = 11.1 # line 81
        var spinner_cost_2015: Float64 = spinner_mass_cost_coeff * spinner_mass
        var rotor_mass: Float64 = blade_mass + hub_mass + pitch_mass + spinner_mass
        var hub_assembly_cost_multiplier: Float64 = 0.0
        var hub_overhead_cost_multiplier: Float64 = 0.0
        var hub_profit_multiplier: Float64 = 0.0
        var hub_transport_multiplier: Float64 = 0.0
        var parts_cost: Float64 = hub_cost_2015 + pitch_cost_2015 + spinner_cost_2015
        var hub_system_cost_adder_2015: Float64 = (1.0 + hub_transport_multiplier + hub_profit_multiplier) * ((1.0 + hub_overhead_cost_multiplier + hub_assembly_cost_multiplier) * parts_cost)
        var num_blades: Int64 = self.as_integer("num_blades")
        var rotor_cost_adder_2015: Float64 = blade_cost_2015 * (num_blades as Float64) + hub_system_cost_adder_2015
        var machine_rating: Float64 = self.as_double("machine_rating") #kW
        var low_speed_shaft_mass: Float64 = 13.0 * Math.pow((blade_mass * machine_rating / 1000.0), 0.65) + 775.0
        var low_speed_shaft_mass_cost_coeff: Float64 = 11.9 # line 211
        var low_speed_shaft_cost: Float64 = low_speed_shaft_mass_cost_coeff * low_speed_shaft_mass
        var bearings_mass: Float64 = 0.0001 * Math.pow(turbine_rotor_diameter, 3.5)
        var num_bearings: Int64 = self.as_integer("num_bearings")
        var bearings_mass_cost_coeff: Float64 = 4.5 # line 230
        var bearings_cost: Float64 = (num_bearings as Float64) * bearings_mass_cost_coeff * bearings_mass
        var rotor_torque: Float64 = self.as_double("rotor_torque")
        var gearbox_mass: Float64 = 113.0 * Math.pow(rotor_torque / 1000.0, 0.71)
        var gearbox_mass_cost_coeff: Float64 = 12.9 # line 248
        var gearbox_cost: Float64 = gearbox_mass_cost_coeff * gearbox_mass
        var high_speed_side_mass: Float64 = 0.19894 * machine_rating
        var high_speed_side_mass_cost_coeff: Float64 = 6.8 # line 266
        var high_speed_side_cost: Float64 = high_speed_side_mass_cost_coeff * high_speed_side_mass
        var generator_mass: Float64 = 2300.0 * machine_rating / 1000.0 + 3400.0
        var generator_mass_cost_coeff: Float64 = 12.4 # line 284
        var generator_cost: Float64 = generator_mass_cost_coeff * generator_mass
        var bedplate_mass: Float64 = Math.pow(turbine_rotor_diameter, 2.2)
        var bedplate_mass_cost_coeff: Float64 = 2.9 # line 302
        var bedplate_cost: Float64 = bedplate_mass_cost_coeff * bedplate_mass
        var yaw_system_mass: Float64 = 1.5 * (0.0009 * Math.pow(turbine_rotor_diameter, 3.314))
        var yaw_system_mass_cost_coeff: Float64 = 8.3 # line 320
        var yaw_system_cost: Float64 = yaw_system_mass_cost_coeff * yaw_system_mass
        var variable_speed_elec_mass: Float64 = 0 #???
        var variable_speed_elec_mass_cost_coeff: Float64 = 18.8 # line 338
        var variable_speed_elec_cost: Float64 = variable_speed_elec_mass_cost_coeff * variable_speed_elec_mass
        var hydraulic_cooling_mass: Float64 = 0.08 * machine_rating
        var hydraulic_cooling_mass_cost_coeff: Float64 = 124.0 # line 356
        var hydraulic_cooling_cost: Float64 = hydraulic_cooling_mass_cost_coeff * hydraulic_cooling_mass
        var nacelle_cover_mass: Float64 = 1.2817 * machine_rating + 428.19
        var nacelle_cover_mass_cost_coeff: Float64 = 5.7 # line 374
        var nacelle_cover_cost: Float64 = nacelle_cover_mass_cost_coeff * nacelle_cover_mass
        var elec_connec_machine_rating_mass_cost_coeff: Float64 = 41.85 # line 392
        var elec_connec_machine_rating_cost: Float64 = elec_connec_machine_rating_mass_cost_coeff * machine_rating
        var controls_machine_rating_mass_cost_coeff: Float64 = 21.15 # line 409
        var controls_machine_rating_cost: Float64 = controls_machine_rating_mass_cost_coeff * machine_rating
        var nacelle_platforms_mass: Float64 = 0.125 * bedplate_mass
        var nacelle_platforms_mass_cost_coeff: Float64 = 17.1 # line 427
        var nacelle_platforms_cost: Float64 = nacelle_platforms_mass_cost_coeff * nacelle_platforms_mass
        var onboard_crane: Bool = self.as_integer("onboard_crane") == 1
        var crane_mass: Float64 = 0.0
        var crane_cost: Float64 = 0.0
        if onboard_crane:
            crane_mass = 3000.0 #kg line 259 nrel_csm_tcc_2015.py
            crane_cost = 12000.0 # line 429 nrel_csm_costsse_2015.py
            nacelle_platforms_cost = nacelle_platforms_mass_cost_coeff * (nacelle_platforms_mass - crane_mass)
        var mainframe_cost: Float64 = nacelle_platforms_cost + crane_cost
        var other_mass: Float64 = nacelle_platforms_mass + crane_mass
        var transformer_mass: Float64 = 1915.0 * machine_rating / 1000.0 + 1910.0
        var transformer_mass_cost_coeff: Float64 = 18.8 # line 462
        var transformer_cost: Float64 = transformer_mass_cost_coeff * transformer_mass
        var drivetrain_mass: Float64 = low_speed_shaft_mass + bearings_mass + gearbox_mass + high_speed_side_mass + generator_mass + bedplate_mass + yaw_system_mass + hydraulic_cooling_mass + nacelle_cover_mass + other_mass + transformer_mass
        var nacelle_assembly_cost_multiplier: Float64 = 0.0
        var nacelle_overhead_cost_multiplier: Float64 = 0.0
        var nacelle_profit_multiplier: Float64 = 0.0
        var nacelle_transport_multiplier: Float64 = 0.0
        parts_cost = low_speed_shaft_cost + bearings_cost + gearbox_cost + high_speed_side_cost + generator_cost + bedplate_cost + yaw_system_cost + variable_speed_elec_cost + hydraulic_cooling_cost + nacelle_cover_cost + elec_connec_machine_rating_cost + controls_machine_rating_cost + mainframe_cost + transformer_cost
        var nacelle_system_cost_adder_2015: Float64 = (1.0 + nacelle_transport_multiplier + nacelle_profit_multiplier) * ((1.0 + nacelle_overhead_cost_multiplier + nacelle_assembly_cost_multiplier) * parts_cost)
        var hub_height: Float64 = self.as_double("hub_height")
        var tower_mass: Float64 = 19.828 * Math.pow(hub_height, 2.0282)
        var tower_mass_cost_coeff: Float64 = 2.9 # line 660
        var tower_cost: Float64 = tower_mass_cost_coeff * tower_mass
        var tower_assembly_cost_multiplier: Float64 = 0.0
        var tower_overhead_cost_multiplier: Float64 = 0.0
        var tower_profit_multiplier: Float64 = 0.0
        var tower_transport_multiplier: Float64 = 0.0
        var tower_cost_adder_2015: Float64 = (1.0 + tower_transport_multiplier + tower_profit_multiplier) * ((1.0 + tower_overhead_cost_multiplier + tower_assembly_cost_multiplier) * tower_cost)
        var turbine_assembly_cost_multiplier: Float64 = 0.0
        var turbine_overhead_cost_multiplier: Float64 = 0.0
        var turbine_profit_multiplier: Float64 = 0.0
        var turbine_transport_multiplier: Float64 = 0.0
        parts_cost = rotor_cost_adder_2015 + nacelle_system_cost_adder_2015 + tower_cost_adder_2015
        var turbine_cost_adder_2015: Float64 = (1.0 + turbine_transport_multiplier + turbine_profit_multiplier) * ((1.0 + turbine_overhead_cost_multiplier + turbine_assembly_cost_multiplier) * parts_cost)
        self.assign("rotor_mass", var_data(ssc_number_t(rotor_mass)))
        self.assign("rotor_cost", var_data(ssc_number_t(rotor_cost_adder_2015)))
        self.assign("blade_cost", var_data(ssc_number_t(blade_cost_2015)))
        self.assign("hub_cost", var_data(ssc_number_t(hub_cost_2015)))
        self.assign("pitch_cost", var_data(ssc_number_t(pitch_cost_2015)))
        self.assign("spinner_cost", var_data(ssc_number_t(spinner_cost_2015)))
        self.assign("drivetrain_mass", var_data(ssc_number_t(drivetrain_mass)))
        self.assign("drivetrain_cost", var_data(ssc_number_t(nacelle_system_cost_adder_2015)))
        self.assign("low_speed_side_cost", var_data(ssc_number_t(low_speed_shaft_cost)))
        self.assign("main_bearings_cost", var_data(ssc_number_t(bearings_cost)))
        self.assign("gearbox_cost", var_data(ssc_number_t(gearbox_cost)))
        self.assign("high_speed_side_cost", var_data(ssc_number_t(high_speed_side_cost)))
        self.assign("generator_cost", var_data(ssc_number_t(generator_cost)))
        self.assign("bedplate_cost", var_data(ssc_number_t(bedplate_cost)))
        self.assign("yaw_system_cost", var_data(ssc_number_t(yaw_system_cost)))
        self.assign("variable_speed_electronics_cost", var_data(ssc_number_t(variable_speed_elec_cost)))
        self.assign("hvac_cost", var_data(ssc_number_t(hydraulic_cooling_cost)))
        self.assign("electrical_connections_cost", var_data(ssc_number_t(elec_connec_machine_rating_cost)))
        self.assign("controls_cost", var_data(ssc_number_t(controls_machine_rating_cost)))
        self.assign("mainframe_cost", var_data(ssc_number_t(mainframe_cost)))
        self.assign("transformer_cost", var_data(ssc_number_t(transformer_cost)))
        self.assign("tower_mass", var_data(ssc_number_t(tower_mass)))
        self.assign("tower_cost", var_data(ssc_number_t(tower_cost_adder_2015)))
        self.assign("turbine_cost", var_data(ssc_number_t(turbine_cost_adder_2015)))

define_module_entry("windcsm", "WISDEM turbine cost model", 1)