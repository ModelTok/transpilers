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
from tcstype import *
from sam_csp_util import *
from math import *
from memory import *
from sys import *

enum:
	P_COOLING_TOWER_ON = 0
	P_TOWER_MODE = 1
	P_D_PIPE_TOWER = 2
	P_TOWER_M_DOT_WATER = 3
	P_TOWER_M_DOT_WATER_TEST = 4
	P_TOWER_PIPE_MATERIAL = 5
	P_ETA_TOWER_PUMP = 6
	P_FAN_CONTROL_SIGNAL = 7
	P_EPSILON_TOWER_TEST = 8
	P_SYSTEM_AVAILABILITY = 9
	P_PUMP_SPEED = 10
	P_FAN_SPEED1 = 11
	P_FAN_SPEED2 = 12
	P_FAN_SPEED3 = 13
	P_T_COOL_SPEED2 = 14
	P_T_COOL_SPEED3 = 15
	P_EPSILON_COOLER_TEST = 16
	P_EPSILON_RADIATOR_TEST = 17
	P_COOLING_FLUID = 18
	P_MANUFACTURER = 19
	P_P_CONTROLS = 20
	P_TEST_P_PUMP = 21
	P_TEST_PUMP_SPEED = 22
	P_TEST_COOLING_FLUID = 23
	P_TEST_T_FLUID = 24
	P_TEST_V_DOT_FLUID = 25
	P_TEST_P_FAN = 26
	P_TEST_FAN_SPEED = 27
	P_TEST_FAN_RHO_AIR = 28
	P_TEST_FAN_CFM = 29
	P_B_RADIATOR = 30
	P_B_COOLER = 31
	I_GROSS_POWER = 32
	I_T_AMB = 33
	I_N_COLS = 34
	I_DNI = 35
	I_T_HEATER_HEAD_LOW = 36
	I_V_SWEPT = 37
	I_FREQUENCY = 38
	I_ENGINE_PRESSURE = 39
	I_I_CUT_IN = 40
	I_Q_REJECT = 41
	I_TOWER_WATER_OUTLET_TEMP = 42
	I_P_AMB_PA = 43
	I_NS_DISH_SEPARATION = 44
	I_EW_DISH_SEPARATION = 45
	I_P_TOWER_FAN = 46
	I_POWER_IN_COLLECTOR = 47
	O_NET_POWER = 48
	O_P_PARASITIC = 49
	O_T_COMPRESSION = 50
	O_P_FAN = 51
	O_P_PUMP = 52
	O_TOWER_WATER_INLET_TEMP = 53
	O_M_DOT_WATER = 54
	O_FAN_CONTROL_SIGNAL = 55
	O_P_PARASITIC_TOWER = 56
	O_T_TOWER_IN = 57
	O_T_TOWER_OUT = 58
	O_ETA_NET = 59
	N_MAX = 60

var sam_pf_dish_parasitics_type298_variables: StaticArray[tcsvarinfo, N_MAX + 1] = tcsvarinfo(
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_COOLING_TOWER_ON,      "cooling_tower_on",          "Option to use a cooling tower (set to 0=off)",                      "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TOWER_MODE,            "tower_mode",				  "Cooling tower type (natural or forced draft)",                      "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_D_PIPE_TOWER,          "d_pipe_tower",			  "Runner pipe diameter to the cooling tower (set to 0.4m)",           "m", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TOWER_M_DOT_WATER,     "tower_m_dot_water",		  "Tower cooling water flow rate (set to 134,000 kg/hr)",              "kg/s", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TOWER_M_DOT_WATER_TEST,"tower_m_dot_water_test",	  "Test value for the cooling water flow rate (set to 134,000 kg/hr)", "kg/s", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TOWER_PIPE_MATERIAL,   "tower_pipe_material",		  "Tower pipe material (1=plastic, 2=new cast iron, 3=riveted steel)", "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_TOWER_PUMP,        "eta_tower_pump",			  "Tower pump efficiency (set to 0.6)",                                "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FAN_CONTROL_SIGNAL,    "fan_control_signal",		  "Fan control signal (set to 1, not used in this model)",             "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_EPSILON_TOWER_TEST,    "epsilon_power_test",		  "Test value for cooling tower effectiveness (set to 0.7)",           "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_SYSTEM_AVAILABILITY,   "system_availability",		  "System availability (set to 1.0)",                                  "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PUMP_SPEED,            "pump_speed",				  "Reference Condition Pump Speed",                                    "rpm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FAN_SPEED1,            "fan_speed1",				  "Cooling system fan speed 1",                                        "rpm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FAN_SPEED2,            "fan_speed2",				  "Cooling system fan speed 2",                                        "rpm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FAN_SPEED3,            "fan_speed3",				  "Cooling system fan speed 3",                                        "rpm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_COOL_SPEED2,         "T_cool_speed2",			  "Cooling Fluid Temp. For Fan Speed 2 Cut-In",                        "C", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_COOL_SPEED3,         "T_cool_speed3",			  "Cooling Fluid Temp. For Fan Speed 3 Cut-In",                        "C", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_EPSILON_COOLER_TEST,   "epsilon_cooler_test",		  "Cooler effectiveness",                                              "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_EPSILON_RADIATOR_TEST, "epsilon_radiator_test",	  "Radiator effectiveness",                                            "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_COOLING_FLUID,         "cooling_fluid",          "Reference Condition Cooling Fluid: 1=Water,2=V50%EG,3=V25%EG,4=V40%PG,5=V25%PG", "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_MANUFACTURER,          "manufacturer",              "Manufacturer (fixed as 5=other)",                           "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_P_CONTROLS,            "P_controls",				  "Control System Parasitic Power, Avg.",                      "W", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_P_PUMP,           "test_P_pump",				  "Reference Condition Pump Parasitic Power",                  "W", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_PUMP_SPEED,       "test_pump_speed",			  "Reference Condition Pump Speed",                            "rpm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_COOLING_FLUID,    "test_cooling_fluid",		  "Reference Condition Cooling Fluid",                         "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_T_FLUID,          "test_T_fluid",			  "Reference Condition Cooling Fluid Temperature",             "K", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_V_DOT_FLUID,      "test_V_dot_fluid",		  "Reference Condition Cooling Fluid Volumetric Flow Rate",    "gpm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_P_FAN,            "test_P_fan",				  "Reference Condition Cooling System Fan Power",              "W", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_FAN_SPEED,        "test_fan_speed",			  "Reference Condition Cooling System Fan Speed",              "rpm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_FAN_RHO_AIR,      "test_fan_rho_air",		  "Reference condition fan air density",                       "kg/m^3", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TEST_FAN_CFM,          "test_fan_cfm",			  "Reference condition van volumentric flow rate",             "cfm", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_B_RADIATOR,            "b_radiator",				  "b_radiator parameter",                                      "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_B_COOLER,              "b_cooler",				  "b_cooler parameter",                                        "-", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_GROSS_POWER,           "gross_power",               "Stirling engine gross output",                              "kW", "", "", ""),                       
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_AMB,                 "T_amb",					  "Ambient temperature in Kelvin",                     		   "K", "", "", ""),     
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_N_COLS,                "N_cols",					  "Number of collectors",                              		   "none", "", "", ""),  
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_DNI,                   "DNI",						  "Direct normal radiation (not interpolated)",        		   "W/m2", "", "", ""),  
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_HEATER_HEAD_LOW,     "T_heater_head_low",		  "Header Head Lowest Temperature",                    		   "K", "", "", ""),     
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_V_SWEPT,               "V_swept",					  "Displaced engine volume",                           		   "cm3", "", "", ""),   
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_FREQUENCY,             "frequency",				  "Engine frequency (= RPM/60s)",                      		   "1/s", "", "", ""),   
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_ENGINE_PRESSURE,       "engine_pressure",			  "Engine pressure",                                   		   "Pa", "", "", ""),    
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_I_CUT_IN,              "I_cut_in",				  "Cut in DNI value used in the simulation",           		   "W/m2", "", "", ""),  
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_REJECT,              "Q_reject",				  "Stirling engine losses",                            		   "W", "", "", ""),     
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TOWER_WATER_OUTLET_TEMP, "Tower_water_outlet_temp", "Tower water outlet temperature (set to 20)",        		   "C", "", "", ""),     
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_AMB_PA,              "P_amb_Pa",				  "Atmospheric pressure",                              		   "Pa", "", "", ""),    
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_NS_DISH_SEPARATION,    "ns_dish_separation",		  "North-South dish separation used in the simulation",		   "m", "", "", ""),     
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_EW_DISH_SEPARATION,    "ew_dish_separation",		  "East-West dish separation used in the simulation",  		   "m", "", "", ""),     
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_TOWER_FAN,           "P_tower_fan",				  "Tower fan power (set to 0)",                        		   "kJ/hr", "", "", ""), 
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_POWER_IN_COLLECTOR,    "power_in_collector",		  "Power incident on the collector",                   		   "kW", "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_NET_POWER,            "net_power",                 "Net system output power",                                          "kW",   "", "", ""),    
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_PARASITIC,          "P_parasitic",				  "Total parasitic power load",                                       "W",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_COMPRESSION,        "T_compression",			  "Cold sink temperature / compression temperature",                  "K",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_FAN,                "P_fan",					  "System fan power",                                                 "W",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_PUMP,               "P_pump",					  "Pumping parasitic power",                                          "W",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TOWER_WATER_INLET_TEMP, "Tower_water_inlet_temp",  "Cooling water temperature into the cooling system",                "C",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_WATER,          "Tower_m_dot_water",		  "Cooling water mass flow rate in the cooling tower",                "kg/hr",   "", "", ""), 
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_FAN_CONTROL_SIGNAL,   "fan_control_signal",		  "Fan control signal (set to 1, not used in this model)",            "-",   "", "", ""),  
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_PARASITIC_TOWER,    "P_parasitic_tower",		  "Parasitic load associated with the heat rejection system",         "W",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_TOWER_IN,           "T_tower_in",				  "Cooling fluid temperature out of the cooling and into the tower",  "C",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_TOWER_OUT,          "T_tower_out",				  "Cooling fluid temperature into the cooler and out of the tower",   "C",   "", "", ""),     
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_NET,              "eta_net",					  "Net system efficiency",                                            "-",   "", "", ""),  
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX,			0,					0, 0, 0, 0, 0	)
)

@value
struct sam_pf_dish_parasitics_type298(tcstypeinterface):
	var m_cooling_tower_on: Float64
	var m_tower_mode: Float64
	var m_d_pipe_tower: Float64
	var m_tower_m_dot_water: Float64
	var m_tower_m_dot_water_test: Float64
	var m_tower_pipe_material: Float64
	var m_eta_tower_pump: Float64
	var m_fan_control_sigmal: Float64
	var m_epsilon_tower_test: Float64
	var m_system_availability: Float64
	var m_pump_speed: Float64
	var m_fan_speed1: Float64
	var m_fan_speed2: Float64
	var m_fan_speed3: Float64
	var m_T_cool_speed2: Float64
	var m_T_cool_speed3: Float64
	var m_epsilon_cooler_test: Float64
	var m_epsilon_radiator_test: Float64
	var m_cooling_fluid: Float64
	var m_manufacturer: Int
	var m_P_controls: Float64
	var m_test_P_pump: Float64
	var m_test_pump_speed: Float64
	var m_test_cooling_fluid: Int
	var m_test_T_fluid: Float64
	var m_test_V_dot_fluid: Float64
	var m_test_P_fan: Float64
	var m_test_fan_speed: Float64
	var m_test_fan_diameter: Float64
	var m_test_fan_rho_air: Float64
	var m_test_fan_cfm: Float64
	var m_b_radiator: Float64
	var m_b_cooler: Float64
	var m_test_pump_d_impeller: Float64
	var m_pump_d_impeller: Float64

	def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
		self.m_cooling_tower_on = Float64(Float64.nan)
		self.m_tower_mode = Float64(Float64.nan)
		self.m_d_pipe_tower = Float64(Float64.nan)
		self.m_tower_m_dot_water = Float64(Float64.nan)
		self.m_tower_m_dot_water_test = Float64(Float64.nan)
		self.m_tower_pipe_material = Float64(Float64.nan)
		self.m_eta_tower_pump = Float64(Float64.nan)
		self.m_fan_control_sigmal = Float64(Float64.nan)
		self.m_epsilon_tower_test = Float64(Float64.nan)
		self.m_system_availability = Float64(Float64.nan)
		self.m_pump_speed = Float64(Float64.nan)
		self.m_fan_speed1 = Float64(Float64.nan)
		self.m_fan_speed2 = Float64(Float64.nan)
		self.m_fan_speed3 = Float64(Float64.nan)
		self.m_T_cool_speed2 = Float64(Float64.nan)
		self.m_T_cool_speed3 = Float64(Float64.nan)
		self.m_epsilon_cooler_test = Float64(Float64.nan)
		self.m_epsilon_radiator_test = Float64(Float64.nan)
		self.m_cooling_fluid = Float64(Float64.nan)
		self.m_manufacturer = -1
		self.m_P_controls = Float64(Float64.nan)
		self.m_test_P_pump = Float64(Float64.nan)
		self.m_test_pump_speed = Float64(Float64.nan)
		self.m_test_cooling_fluid = -1
		self.m_test_T_fluid = Float64(Float64.nan)
		self.m_test_V_dot_fluid = Float64(Float64.nan)
		self.m_test_P_fan = Float64(Float64.nan)
		self.m_test_fan_speed = Float64(Float64.nan)
		self.m_test_fan_diameter = Float64(Float64.nan)
		self.m_test_fan_rho_air = Float64(Float64.nan)
		self.m_test_fan_cfm = Float64(Float64.nan)
		self.m_b_radiator = Float64(Float64.nan)
		self.m_b_cooler = Float64(Float64.nan)
		self.m_test_pump_d_impeller = Float64(Float64.nan)
		self.m_pump_d_impeller = Float64(Float64.nan)

	def __del__(owned self):

	def init(inout self) -> Int:
		self.m_cooling_tower_on = self.value(P_COOLING_TOWER_ON)
		self.m_tower_mode = self.value(P_TOWER_MODE)
		self.m_d_pipe_tower = self.value(P_D_PIPE_TOWER)
		self.m_tower_m_dot_water = self.value(P_TOWER_M_DOT_WATER)
		self.m_tower_m_dot_water_test = self.value(P_TOWER_M_DOT_WATER_TEST)
		self.m_tower_pipe_material = self.value(P_TOWER_PIPE_MATERIAL)
		self.m_eta_tower_pump = self.value(P_ETA_TOWER_PUMP)
		self.m_fan_control_sigmal = self.value(P_FAN_CONTROL_SIGNAL)
		self.m_epsilon_tower_test = self.value(P_EPSILON_TOWER_TEST)
		self.m_system_availability = self.value(P_SYSTEM_AVAILABILITY)
		self.m_pump_speed = self.value(P_PUMP_SPEED)
		self.m_fan_speed1 = self.value(P_FAN_SPEED1)
		self.m_fan_speed2 = self.value(P_FAN_SPEED2)
		self.m_fan_speed3 = self.value(P_FAN_SPEED3)
		self.m_T_cool_speed2 = self.value(P_T_COOL_SPEED2)
		self.m_T_cool_speed3 = self.value(P_T_COOL_SPEED3)
		self.m_epsilon_cooler_test = self.value(P_EPSILON_COOLER_TEST)
		self.m_epsilon_radiator_test = self.value(P_EPSILON_RADIATOR_TEST)
		self.m_cooling_fluid = self.value(P_COOLING_FLUID)
		self.m_manufacturer = Int(self.value(P_MANUFACTURER))
		self.m_tower_m_dot_water = self.m_tower_m_dot_water / 3600.0
		self.m_tower_m_dot_water_test = self.m_tower_m_dot_water_test / 3600.0
		if self.m_manufacturer == 1:
			self.m_P_controls = 150.0
			self.m_test_P_pump = 100.0
			self.m_test_pump_speed = 1800.0
			self.m_test_cooling_fluid = 2
			self.m_test_T_fluid = 288.0
			self.m_test_V_dot_fluid = 9.0 * 0.003785 / 60.0
			self.m_test_P_fan = 1000.0
			self.m_test_fan_speed = 890.0
			self.m_test_fan_rho_air = 1.2
			self.m_test_fan_cfm = 6000.0
			self.m_b_radiator = 0.7
			self.m_b_cooler = 0.7
		elif self.m_manufacturer == 2:
			self.m_P_controls = 100.0
			self.m_test_P_pump = 75.0
			self.m_test_pump_speed = 1800.0
			self.m_test_cooling_fluid = 2
			self.m_test_T_fluid = 288.0
			self.m_test_V_dot_fluid = 7.5 * 0.003785 / 60.0
			self.m_test_P_fan = 410.0
			self.m_test_fan_speed = 890.0
			self.m_test_fan_rho_air = 1.2
			self.m_test_fan_cfm = 4000.0
			self.m_b_radiator = 0.7
			self.m_b_cooler = 0.7
		elif self.m_manufacturer == 3:
			self.m_P_controls = 175.0
			self.m_test_P_pump = 100.0
			self.m_test_pump_speed = 1800.0
			self.m_test_cooling_fluid = 1
			self.m_test_T_fluid = 288.0
			self.m_test_V_dot_fluid = 7.5 * 0.003785 / 60.0
			self.m_test_P_fan = 510.0
			self.m_test_fan_speed = 890.0
			self.m_test_fan_rho_air = 1.2
			self.m_test_fan_cfm = 4500.0
			self.m_b_radiator = 0.7
			self.m_b_cooler = 0.7
		elif self.m_manufacturer == 4:
			self.m_P_controls = 300.0
			self.m_test_P_pump = 200.0
			self.m_test_pump_speed = 1800.0
			self.m_test_cooling_fluid = 2
			self.m_test_T_fluid = 288.0
			self.m_test_V_dot_fluid = 12.0 * 0.003785 / 60.0
			self.m_test_P_fan = 2500.0
			self.m_test_fan_speed = 850.0
			self.m_test_fan_rho_air = 1.2
			self.m_test_fan_cfm = 10000.0
			self.m_b_radiator = 0.7
			self.m_b_cooler = 0.7
		elif self.m_manufacturer == 5:
			self.m_P_controls = self.value(P_P_CONTROLS)
			self.m_test_P_pump = self.value(P_TEST_P_PUMP)
			self.m_test_pump_speed = self.value(P_TEST_PUMP_SPEED)
			self.m_test_cooling_fluid = Int(self.value(P_TEST_COOLING_FLUID))
			self.m_test_T_fluid = self.value(P_TEST_T_FLUID)
			self.m_test_V_dot_fluid = self.value(P_TEST_V_DOT_FLUID) * 0.003785 / 60.0
			self.m_test_P_fan = self.value(P_TEST_P_FAN)
			self.m_test_fan_speed = self.value(P_TEST_FAN_SPEED)
			self.m_test_fan_rho_air = self.value(P_TEST_FAN_RHO_AIR)
			self.m_test_fan_cfm = self.value(P_TEST_FAN_CFM)
			self.m_b_radiator = self.value(P_B_RADIATOR)
			self.m_b_cooler = self.value(P_B_COOLER)
		else:
			self.message(TCS_ERROR, "Manufacturer integer needs to be from 1 to 5")
			return -1
		self.m_test_fan_diameter = 0.63
		self.m_test_pump_d_impeller = 0.15
		self.m_pump_d_impeller = 0.15
		return 0

	def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
		var gross_power = self.value(I_GROSS_POWER)
		var T_amb = self.value(I_T_AMB) + 273.15
		var Number_of_Collectors = self.value(I_N_COLS)
		var DNI = self.value(I_DNI)
		var T_heater_head_low = self.value(I_T_HEATER_HEAD_LOW)
		var V_swept = self.value(I_V_SWEPT)
		var frequency = self.value(I_FREQUENCY)
		var engine_pressure = self.value(I_ENGINE_PRESSURE)
		var I_cut_in = self.value(I_I_CUT_IN)
		var Q_reject = self.value(I_Q_REJECT)
		var Tower_water_outlet_temp = self.value(I_TOWER_WATER_OUTLET_TEMP)
		var P_amb_Pa = self.value(I_P_AMB_PA) * 100.0
		var NS_dish_separation = self.value(I_NS_DISH_SEPARATION)
		var P_tower_fan = self.value(I_P_TOWER_FAN)
		var P_in_collector = self.value(I_POWER_IN_COLLECTOR)
		var M_air = 28.97
		var R_bar = 8314.0
		var R_air = R_bar / M_air
		var rho_air = P_amb_Pa / (R_air * T_amb)
		P_tower_fan = P_tower_fan * 1000.0 / 3600.0
		var P_SE_losses = Q_reject
		var Q_losses = 1000.0 * P_SE_losses
		var Q_reject_total = Number_of_Collectors * Q_reject * 1000.0
		var T_K2 = self.m_test_T_fluid
		var T_K1 = self.m_test_T_fluid
		var mu_water: Float64
		var mu_fluid_test: Float64
		var rho_cool_fluid_test: Float64
		var cp_fluid_test: Float64
		if self.m_test_cooling_fluid == 1:
			mu_water = 3.50542 - 0.0539638 * T_K2 + 0.000333345 * pow(T_K2, 2) - 0.0000010319 * pow(T_K2, 3) + 1.59983E-09 * pow(T_K2, 4) - 9.93386E-13 * pow(T_K2, 5)
			mu_fluid_test = 3.50542 - 0.0539638 * T_K2 + 0.000333345 * pow(T_K2, 2) - 0.0000010319 * pow(T_K2, 3) + 1.59983E-09 * pow(T_K2, 4) - 9.93386E-13 * pow(T_K2, 5)
			rho_cool_fluid_test = 692.604 + 2.2832 * T_K2 - 0.00423412 * pow(T_K2, 2)
			cp_fluid_test = 2.14384E+06 - 34048.9 * T_K2 + 216.467 * pow(T_K2, 2) - 0.687249 * pow(T_K2, 3) + 0.00108959 * pow(T_K2, 4) - 6.90127E-07 * pow(T_K2, 5)
		elif self.m_test_cooling_fluid == 2:
			mu_fluid_test = 18.3853 - 0.238994 * T_K1 + 0.00116489 * pow(T_K1, 2) - 0.00000252199 * pow(T_K1, 3) + 2.04562E-09 * pow(T_K1, 4)
			rho_cool_fluid_test = 1026.4 + 0.80163 * T_K1 - 0.00227397 * pow(T_K1, 2)
			cp_fluid_test = 1899.32 + 4.19104 * T_K1 + 0.00194702 * pow(T_K1, 2)
		elif self.m_test_cooling_fluid == 3:
			mu_fluid_test = 5.33548 - 0.0686842 * T_K1 + 0.000331949 * pow(T_K1, 2) - 7.13336E-07 * pow(T_K1, 3) + 5.74824E-10 * pow(T_K1, 4)
			rho_cool_fluid_test = 823.536 + 1.76857 * T_K1 - 0.00360812 * pow(T_K1, 2)
			cp_fluid_test = 3056.35 + 3.04401 * T_K1 - 0.00126969 * pow(T_K1, 2)
		elif self.m_test_cooling_fluid == 4:
			mu_fluid_test = 29.2733 - 0.367285 * T_K1 + 0.00172909 * pow(T_K1, 2) - 0.00000361866 * pow(T_K1, 3) + 2.83986E-09 * pow(T_K1, 4)
			rho_cool_fluid_test = 1032.38 + 0.658226 * T_K1 - 0.00217079 * pow(T_K1, 2)
			cp_fluid_test = 3501.54 - 2.12091 * T_K1 + 0.00807326 * pow(T_K1, 2)
		elif self.m_test_cooling_fluid == 5:
			mu_fluid_test = 8.22884 - 0.104386 * T_K1 + 0.000496931 * pow(T_K1, 2) - 0.00000105157 * pow(T_K1, 3) + 8.34276E-10 * pow(T_K1, 4)
			rho_cool_fluid_test = 814.76 + 1.75047 * T_K1 - 0.00358803 * pow(T_K1, 2)
			cp_fluid_test = 10775.6 - 62.9957 * T_K1 + 0.190454 * pow(T_K1, 2) - 0.000186685 * pow(T_K1, 3)
		else:
			mu_fluid_test = 18.3853 - 0.238994 * T_K1 + 0.00116489 * pow(T_K1, 2) - 0.00000252199 * pow(T_K1, 3) + 2.04562E-09 * pow(T_K1, 4)
			rho_cool_fluid_test = 1026.4 + 0.80163 * T_K1 - 0.00227397 * pow(T_K1, 2)
			cp_fluid_test = 1899.32 + 4.19104 * T_K1 + 0.00194702 * pow(T_K1, 2)
		var T_tolerance = 1.0
		var d_T = 1.0
		var T_difference = 200.0
		var T_cool_in = 300.0
		var T_cool_speed2 = self.m_T_cool_speed2 + 273.15
		var T_cool_speed3 = self.m_T_cool_speed3 + 273.15
		var mu_cool_fluid: Float64
		var rho_tower: Float64
		var T1: Float64
		var fan_speed_use: Float64
		var T_compression: Float64
		var Tower_water_inlet_temp: Float64
		var P_pump: Float64
		var P_fan: Float64
		var T_cool_out = -987.6
		var T_res = 260.0
		while T_res <= 600.0:
			if T_difference >= T_tolerance:
				var fan_speed: Float64
				if T_cool_in >= T_cool_speed2:
					if T_cool_in < T_cool_speed3:
						fan_speed = self.m_fan_speed2
					else:
						fan_speed = self.m_fan_speed3
				else:
					fan_speed = self.m_fan_speed1
				if DNI < I_cut_in:
					fan_speed = 0.0
				fan_speed_use = fan_speed
				if fan_speed < 50.0:
					fan_speed = 50.0
				var rho_fluid: Float64
				var cp_fluid: Float64
				mu_water = 3.50542 - 0.0539638 * T_res + 0.000333345 * pow(T_res, 2) - 0.0000010319 * pow(T_res, 3) + 1.59983E-09 * pow(T_res, 4) - 9.93386E-13 * pow(T_res, 5)
				if self.m_cooling_fluid == 1:
					mu_cool_fluid = 3.50542 - 0.0539638 * T_res + 0.000333345 * pow(T_res, 2) - 0.0000010319 * pow(T_res, 3) + 1.59983E-09 * pow(T_res, 4) - 9.93386E-13 * pow(T_res, 5)
					rho_fluid = 692.604 + 2.2832 * T_res - 0.00423412 * pow(T_res, 2)
					cp_fluid = 2.14384E+06 - 34048.9 * T_res + 216.467 * pow(T_res, 2) - 0.687249 * pow(T_res, 3) + 0.00108959 * pow(T_res, 4) - 6.90127E-07 * pow(T_res, 5)
				elif self.m_cooling_fluid == 2:
					mu_cool_fluid = 18.3853 - 0.238994 * T_res + 0.00116489 * pow(T_res, 2) - 0.00000252199 * pow(T_res, 3) + 2.04562E-09 * pow(T_res, 4)
					rho_fluid = 1026.4 + 0.80163 * T_res - 0.00227397 * pow(T_res, 2)
					cp_fluid = 1899.32 + 4.19104 * T_res + 0.00194702 * pow(T_res, 2)
				elif self.m_cooling_fluid == 3:
					mu_cool_fluid = 5.33548 - 0.0686842 * T_res + 0.000331949 * pow(T_res, 2) - 7.13336E-07 * pow(T_res, 3) + 5.74824E-10 * pow(T_res, 4)
					rho_fluid = 823.536 + 1.76857 * T_res - 0.00360812 * pow(T_res, 2)
					cp_fluid = 3056.35 + 3.04401 * T_res - 0.00126969 * pow(T_res, 2)
				elif self.m_cooling_fluid == 4:
					mu_cool_fluid = 29.2733 - 0.367285 * T_res + 0.00172909 * pow(T_res, 2) - 0.00000361866 * pow(T_res, 3) + 2.83986E-09 * pow(T_res, 4)
					rho_fluid = 1032.38 + 0.658226 * T_res - 0.00217079 * pow(T_res, 2)
					cp_fluid = 3501.54 - 2.12091 * T_res + 0.00807326 * pow(T_res, 2)
				elif self.m_cooling_fluid == 5:
					mu_cool_fluid = 8.22884 - 0.104386 * T_res + 0.000496931 * pow(T_res, 2) - 0.00000105157 * pow(T_res, 3) + 8.34276E-10 * pow(T_res, 4)
					rho_fluid = 814.76 + 1.75047 * T_res - 0.00358803 * pow(T_res, 2)
					cp_fluid = 10775.6 - 62.9957 * T_res + 0.190454 * pow(T_res, 2) - 0.000186685 * pow(T_res, 3)
				else:
					mu_cool_fluid = 18.3853 - 0.238994 * T_res + 0.00116489 * pow(T_res, 2) - 0.00000252199 * pow(T_res, 3) + 2.04562E-09 * pow(T_res, 4)
					rho_fluid = 1026.4 + 0.80163 * T_res - 0.00227397 * pow(T_res, 2)
					cp_fluid = 1899.32 + 4.19104 * T_res + 0.00194702 * pow(T_res, 2)
				var test_fan_speed_rad = self.m_test_fan_speed * 2.0 * 3.14159 / 60.0
				var fan_speed_rad = fan_speed * 2.0 * 3.14159 / 60.0
				var C_W = self.m_test_P_fan / (pow(test_fan_speed_rad, 3) * pow(self.m_test_fan_diameter, 5) * self.m_test_fan_rho_air + 1.0E-8)
				P_fan = C_W * pow(fan_speed_rad, 3) * pow(self.m_test_fan_diameter, 5) * rho_air
				var V_dot_air_test = self.m_test_fan_cfm * pow(0.3048, 3) / 60.0
				var C_V = V_dot_air_test / (test_fan_speed_rad * pow(self.m_test_fan_diameter, 3) + 1.0E-8)
				var V_dot_air = C_V * fan_speed_rad * pow(self.m_test_fan_diameter, 3)
				var m_dot_air = V_dot_air * rho_air
				var test_pump_speed_rad = self.m_test_pump_speed * 2.0 * 3.14159 / 60.0
				var pump_speed_rad = self.m_pump_speed * 2.0 * 3.14159 / 60.0
				var C_W_pump = self.m_test_P_pump / (pow(test_pump_speed_rad, 3) * pow(self.m_test_pump_d_impeller, 5) * rho_cool_fluid_test + 1.0E-8)
				P_pump = C_W_pump * pow(pump_speed_rad, 3) * pow(self.m_test_pump_d_impeller, 5) * rho_fluid
				var C_V_pump = self.m_test_V_dot_fluid / (test_pump_speed_rad * pow(self.m_test_pump_d_impeller, 3) + 1.0E-8)
				var V_dot_cool_fluid = C_V_pump * pump_speed_rad * pow(self.m_test_pump_d_impeller, 3)
				var m_dot_cool_fluid = V_dot_cool_fluid * rho_fluid
				var engine_pressure_test = 15000000.0
				var frequency_test = 30.0
				var T_H2_ave_test = 600.0
				var Cp_H2_TEST = 14500.0
				var R_gas = 8314.0
				var M_H2 = 2.0160
				var T_H2_ave = (T_heater_head_low + T_amb) / 2.0
				var V_total = 2.5 * V_swept
				var mass_H2 = engine_pressure * V_total * M_H2 / (R_gas * T_H2_ave + 1.0E-8)
				var mass_H2_test = engine_pressure_test * V_total * M_H2 / (R_gas * T_H2_ave_test + 1.0E-8)
				var rho_H2 = engine_pressure * M_H2 / (R_gas * T_H2_ave + 1.0E-8)
				var rho_H2_test = engine_pressure_test / (R_gas * T_H2_ave_test + 1.0E-8)
				var m_dot_H2_test = mass_H2_test * 2.0 * frequency_test
				var m_dot_H2 = mass_H2 * 2.0 * frequency
				var Cp_H2 = 14500.0
				var C_dot_H2 = m_dot_H2 * Cp_H2
				var V_dot_H2 = m_dot_H2 / (rho_H2 + 1.0E-8)
				var V_dot_H2_test = m_dot_H2_test / (rho_H2_test + 1.0E-8)
				var C_dot_H2_test = m_dot_H2_test * Cp_H2_TEST
				var C_dot_cool_fluid = m_dot_cool_fluid * cp_fluid
				var m_dot_cool_fluid_test = self.m_test_V_dot_fluid * rho_cool_fluid_test
				var C_dot_cool_fluid_test = m_dot_cool_fluid_test * cp_fluid_test
				var cp_air_test = 1005.0
				var m_dot_air_test = V_dot_air_test * self.m_test_fan_rho_air
				var C_dot_air_test = m_dot_air_test * cp_air_test
				var cp_air = 1005.0
				var C_dot_air = m_dot_air * cp_air
				var C_dot_min_test_rad = min(C_dot_air_test, C_dot_cool_fluid_test)
				var C_dot_max_test_rad = max(C_dot_air_test, C_dot_cool_fluid_test)
				var C_dot_min_rad = min(C_dot_air, C_dot_cool_fluid)
				var C_dot_max_rad = max(C_dot_air, C_dot_cool_fluid)
				var V_dot_min_rad = min(V_dot_air, V_dot_cool_fluid)
				var V_dot_min_test_rad = min(V_dot_air_test, self.m_test_V_dot_fluid)
				var C_dot_min_test_cooler = min(C_dot_H2_test, C_dot_cool_fluid_test)
				var C_dot_max_test_cooler = max(C_dot_H2_test, C_dot_cool_fluid_test)
				var C_dot_min_cooler = min(C_dot_H2, C_dot_cool_fluid)
				var C_dot_max_cooler = max(C_dot_H2, C_dot_cool_fluid)
				var V_dot_min_cooler = min(V_dot_H2, V_dot_cool_fluid)
				var V_dot_min_test_cooler = min(V_dot_H2_test, self.m_test_V_dot_fluid)
				var Cr_radiator_TEST = C_dot_min_test_rad / C_dot_max_test_rad
				var NTU_radiator_TEST = -log(1.0 + (1.0 / Cr_radiator_TEST) * (log(1.0 - self.m_epsilon_radiator_test * Cr_radiator_TEST)))
				var UA_radiator_TEST = NTU_radiator_TEST * C_dot_min_test_rad
				var UA_radiator = UA_radiator_TEST * pow((V_dot_min_rad / V_dot_min_test_rad), self.m_b_radiator)
				var NTU_radiator = UA_radiator / (C_dot_min_rad + 1.0E-8)
				var Cr_radiator = C_dot_min_rad / C_dot_max_rad
				var EPSILON_radiator = (1.0 / (Cr_radiator + 1.0E-8)) * (1.0 - exp(-Cr_radiator * (1.0 - exp(-NTU_radiator))))
				Tower_water_inlet_temp = Tower_water_outlet_temp + Q_reject_total / (cp_fluid * self.m_tower_m_dot_water + 1.0E-8)
				var Tower_water_ave = (Tower_water_inlet_temp + Tower_water_outlet_temp) / 2.0
				T1 = Tower_water_outlet_temp + 273.15
				rho_tower = 589.132 + 2.98577 * T1 - 0.00542465 * pow(T1, 2)
				var Cr_cooler_test = C_dot_min_test_cooler / C_dot_max_test_cooler
				var NTU_cooler_test = 1.0 / (Cr_cooler_test - 1.0) * log((self.m_epsilon_cooler_test - 1.0) / (self.m_epsilon_cooler_test * Cr_cooler_test - 1.0))
				var UA_cooler_test = NTU_cooler_test * C_dot_min_test_cooler
				var UA_cooler = UA_cooler_test * pow((V_dot_min_cooler / (V_dot_min_test_cooler + 1.0E-8)), self.m_b_cooler)
				var NTU_cooler = UA_cooler / (C_dot_min_cooler + 1.0E-8)
				var Cr_cooler = C_dot_min_cooler / C_dot_max_cooler
				var epsilon_cooler = (1.0 - exp(-NTU_cooler * (1.0 - Cr_cooler))) / (1.0 - Cr_cooler * exp(-NTU_cooler * (1.0 - Cr_cooler)))
				if self.m_cooling_tower_on == 0.0:
					T_cool_out = Q_losses / (EPSILON_radiator * C_dot_min_rad + 1.0E-8) + T_amb
					T_cool_in = -Q_losses / (C_dot_cool_fluid + 1.0E-8) + T_cool_out
				else:
					T_cool_out = Q_losses / (EPSILON_radiator * C_dot_min_rad + 1.0E-8) + (Tower_water_ave + 273.15)
					T_cool_in = -Q_losses / (C_dot_cool_fluid + 1.0E-8) + T_cool_out
				C_dot_min_cooler = min(C_dot_H2, C_dot_cool_fluid)
				var T_H2_in = Q_losses / (epsilon_cooler * C_dot_min_cooler) + T_cool_in
				var T_H2_out = T_H2_in - epsilon_cooler * C_dot_min_cooler / (C_dot_H2 + 1.0E-8) * (T_H2_in - T_cool_in)
				T_compression = T_H2_out
			else:
				break
			T_difference = fabs(T_res - T_cool_out)
			T_res += d_T
		var mu_div_mu_water = mu_cool_fluid / (mu_water + 1.0E-8)
		var pump_multiplier = 1.01178 - 0.0117778 * mu_div_mu_water
		P_pump = P_pump / (pump_multiplier + 1.0E-8)
		var P_controls: Float64
		if DNI < 1.0:
			P_pump = 0.0
			P_controls = 1.0
		else:
			P_controls = self.m_P_controls
		if self.m_cooling_tower_on != 0.0:
			P_fan = 0.0
		if DNI < 300.0:
			P_tower_fan = 0.0
		var pipe_length = NS_dish_separation * Number_of_Collectors
		var A_pipe = 3.14159 * pow((self.m_d_pipe_tower / 2.0), 2)
		var vel_tower = self.m_tower_m_dot_water / (rho_tower * A_pipe + 1.0E-8)
		var mu_tower = 0.299062 - 0.00283786 * T1 + 0.0000090396 * pow(T1, 2) - 9.64494E-09 * pow(T1, 3)
		var Re_tower = rho_tower * vel_tower * self.m_d_pipe_tower / (mu_tower + 1.0E-8)
		var epsilon_wall: Float64
		if self.m_tower_pipe_material == 1.0:
			epsilon_wall = 0.0000015
		elif self.m_tower_pipe_material == 2.0:
			epsilon_wall = 0.00026
		elif self.m_tower_pipe_material == 3.0:
			epsilon_wall = 0.003
		else:
			epsilon_wall = Float64(Float64.nan)
		var friction_factor = 1.0 / pow((-1.8 * log10(6.9 / (Re_tower + 1.0E-8) + pow(epsilon_wall / (3.7 * self.m_d_pipe_tower), 1.11))), 2)
		var head_friction = friction_factor * pipe_length * pow(vel_tower, 2) / (self.m_d_pipe_tower * 2.0 * 9.8)
		var K_total = 0.001 / 39.37
		var head_minor = K_total * (pow(vel_tower, 2) / (2.0 * 9.8))
		var head_total = head_friction + head_minor
		var V_dot_tower = self.m_tower_m_dot_water / (rho_tower + 1.0E-8)
		var P_tower_pump = rho_tower * 9.8 * V_dot_tower * head_total / (self.m_eta_tower_pump + 1.0E-8)
		if self.m_cooling_tower_on == 0.0:
			P_tower_pump = 0.0
			P_tower_fan = 0.0
		var P_parasitic = P_fan + P_pump + P_controls
		var P_parasitic_tower: Float64
		if self.m_tower_mode == 1.0:
			P_parasitic_tower = P_tower_pump
		else:
			P_parasitic_tower = P_tower_pump + P_tower_fan
		var net_power_out = gross_power - (P_parasitic / 1000.0)
		var SUM = Number_of_Collectors * net_power_out - P_parasitic_tower / 1000.0
		if self.m_tower_mode == 1.0:
			if SUM <= 0.0:
				net_power_out = 0.0
				P_parasitic_tower = 0.0
		if net_power_out >= 0.0:
			if fan_speed_use >= 50.0:
				self.value(O_NET_POWER, net_power_out * self.m_system_availability)
			else:
				self.value(O_NET_POWER, net_power_out * self.m_system_availability * pow(((fan_speed_use + 0.5) / 50.0), 0.5))
		else:
			self.value(O_NET_POWER, 0.0)
		self.value(O_P_PARASITIC, P_parasitic)
		self.value(O_T_COMPRESSION, T_compression)
		self.value(O_P_FAN, P_fan)
		self.value(O_P_PUMP, P_pump)
		self.value(O_TOWER_WATER_INLET_TEMP, Tower_water_inlet_temp)
		self.value(O_M_DOT_WATER, self.m_tower_m_dot_water * 3600.0)
		self.value(O_FAN_CONTROL_SIGNAL, self.m_fan_control_sigmal)
		self.value(O_P_PARASITIC_TOWER, P_parasitic_tower)
		self.value(O_T_TOWER_OUT, T_cool_out - 273.15)
		self.value(O_T_TOWER_IN, T_cool_in - 273.15)
		self.value(O_ETA_NET, self.value(O_NET_POWER) / (P_in_collector + 0.00000001))
		return 0

	def converged(inout self, time: Float64) -> Int:
		return 0

TCS_IMPLEMENT_TYPE(sam_pf_dish_parasitics_type298, "Collector Dish", "Ty Neises", 1, sam_pf_dish_parasitics_type298_variables, None, 1)