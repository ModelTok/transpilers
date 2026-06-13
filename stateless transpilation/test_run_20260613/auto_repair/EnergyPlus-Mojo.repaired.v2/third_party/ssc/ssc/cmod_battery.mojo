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
from math import pow
from cmod_battery import batt_variables, battstor, vtab_battery_inputs, vtab_battery_outputs
from common import *
from core import *
from lib_battery import *
from lib_battery_dispatch import *
from lib_battery_dispatch_automatic_btm import *
from lib_battery_dispatch_automatic_fom import *
from lib_battery_dispatch_manual import *
from lib_battery_powerflow import *
from lib_power_electronics import *
from lib_resilience import *
from lib_shared_inverter import *
from lib_time import *
from lib_util import *
from lib_utility_rate import *

var_info vtab_battery_inputs = [
        #   VARTYPE           DATATYPE         NAME                                            LABEL                                                   UNITS      META                   GROUP           REQUIRED_IF                 CONSTRAINTS                      UI_HINTS
        { SSC_INPUT,        SSC_NUMBER,      "system_use_lifetime_output",                 "Enable lifetime simulation",                                  "0/1",     "0=SingleYearRepeated,1=RunEveryYear",                     "Lifetime",             "?=0",                        "BOOLEAN",                        "" },
        { SSC_INPUT,        SSC_NUMBER,      "analysis_period",                            "Lifetime analysis period",                                "years",   "The number of years in the simulation",                   "Lifetime",             "system_use_lifetime_output =1",   "",                               "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_chem",                                  "Battery chemistry",                                       "",        "0=LeadAcid,1=LiIon",   "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inverter_model",                             "Inverter model specifier",                                "",        "0=cec,1=datasheet,2=partload,3=coefficientgenerator,4=generic","Inverter","?=4", "INTEGER,MIN=0,MAX=4",           "" },
        { SSC_INPUT,        SSC_NUMBER,      "inverter_count",                             "Number of inverters",                                     "",        "",                     "Inverter"        "",                            "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_snl_eff_cec",                            "Inverter Sandia CEC Efficiency",                          "%",       "",                     "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_snl_paco",                               "Inverter Sandia Maximum AC Power",                        "Wac",     "",                     "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_ds_eff",                                 "Inverter Datasheet Efficiency",                           "%",       "",                     "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_ds_paco",                                "Inverter Datasheet Maximum AC Power",                     "Wac",     "",                     "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_pd_eff",                                 "Inverter Partload Efficiency",                            "%",       "",                     "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_pd_paco",                                "Inverter Partload Maximum AC Power",                      "Wac",     "",                     "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_cec_cg_eff_cec",                         "Inverter Coefficient Generator CEC Efficiency",           "%",       "",                     "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_cec_cg_paco",                            "Inverter Coefficient Generator Max AC Power",             "Wac",       "",                   "Inverter",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_ac_or_dc",                              "Battery interconnection (AC or DC)",                      "",        "0=DC_Connected,1=AC_Connected",                  "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_dc_dc_efficiency",                      "System DC to battery DC efficiency",                          "",        "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "dcoptimizer_loss",                           "DC optimizer loss",                      "",        "",                     "Losses",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_dc_ac_efficiency",                      "Battery DC to AC efficiency",                             "",        "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_ac_dc_efficiency",                      "Inverter AC to battery DC efficiency",                    "",        "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_meter_position",                        "Position of battery relative to electric meter",          "",        "0=BehindTheMeter,1=FrontOfMeter",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_inverter_efficiency_cutoff",            "Inverter efficiency at which to cut battery charge or discharge off",          "%",        "","BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_ARRAY,       "batt_losses",                                "Battery system losses at each timestep (kW DC for DC connected, AC for AC connected)",                  "kW",       "",                     "BatterySystem",       "?=0",                        "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,       "batt_losses_charging",                       "Battery system losses when charging (kW DC for DC connected, AC for AC connected)",                     "kW",       "",                     "BatterySystem",       "?=0",                        "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,       "batt_losses_discharging",                    "Battery system losses when discharging (kW DC for DC connected, AC for AC connected)",                  "kW",       "",                     "BatterySystem",       "?=0",                        "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,       "batt_losses_idle",                           "Battery system losses when idle (kW DC for DC connected, AC for AC connected)",                         "kW",       "",                     "BatterySystem",       "?=0",                        "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_loss_choice",                           "Loss power input option",                                 "0/1",      "0=Monthly,1=TimeSeries",                     "BatterySystem",       "?=0",                        "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_current_choice",                        "Limit cells by current or power",                         "",        "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_computed_strings",                      "Number of strings of cells",                              "",        "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_computed_series",                       "Number of cells in series",                               "",        "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_computed_bank_capacity",                "Computed bank capacity",                                  "kWh",     "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_current_charge_max",                    "Maximum charge current",                                  "A",       "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_current_discharge_max",                 "Maximum discharge current",                               "A",       "",                     "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_power_charge_max_kwdc",                 "Maximum charge power (DC)",                               "kWdc",    "",                    "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_power_discharge_max_kwdc",              "Maximum discharge power (DC)",                            "kWdc",    "",                    "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_power_charge_max_kwac",                 "Maximum charge power (AC)",                               "kWac",    "",                    "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_power_discharge_max_kwac",              "Maximum discharge power (AC)",                            "kWac",    "",                    "BatterySystem",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_voltage_choice",                        "Battery voltage input option",                            "0/1",      "0=UseVoltageModel,1=InputVoltageTable",                    "BatteryCell",       "?=0",                        "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Vfull",                                 "Fully charged cell voltage",                              "V",       "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Vexp",                                  "Cell voltage at end of exponential zone",                 "V",       "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Vnom",                                  "Cell voltage at end of nominal zone",                     "V",       "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Vnom_default",                          "Default nominal cell voltage",                            "V",       "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Qfull",                                 "Fully charged cell capacity",                             "Ah",      "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Qfull_flow",                            "Fully charged flow battery capacity",                     "Ah",      "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Qexp",                                  "Cell capacity at end of exponential zone",                "Ah",      "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_Qnom",                                  "Cell capacity at end of nominal zone",                    "Ah",      "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_C_rate",                                "Rate at which voltage vs. capacity curve input",          "",        "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_resistance",                            "Internal resistance",                                     "Ohm",     "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,		SSC_MATRIX,      "batt_voltage_matrix",                        "Battery voltage vs. depth-of-discharge",                 "",         "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,		SSC_NUMBER,		"LeadAcid_q20_computed",	                   "Capacity at 20-hour discharge rate",                     "Ah",       "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,		SSC_NUMBER,		"LeadAcid_q10_computed",	                   "Capacity at 10-hour discharge rate",                     "Ah",       "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,		SSC_NUMBER,		"LeadAcid_qn_computed",	                       "Capacity at discharge rate for n-hour rate",             "Ah",       "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,		SSC_NUMBER,		"LeadAcid_tn",	                               "Time to discharge",                                      "h",        "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_initial_SOC",		                   "Initial state-of-charge",                                 "%",       "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_minimum_SOC",		                   "Minimum allowed state-of-charge",                         "%",       "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_maximum_SOC",                           "Maximum allowed state-of-charge",                         "%",       "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "batt_minimum_modetime",                      "Minimum time at charge state",                            "min",     "",                     "BatteryCell",       "",                           "",                              "" },
        { SSC_INPUT,		SSC_NUMBER,     "batt_life_model",                             "Battery life model specifier",                           "0/1",      "0=calendar/cycle,1=NMC", "BatteryCell",       "?=0",                           "",                             "" },
        { SSC_INPUT,		SSC_MATRIX,     "batt_lifetime_matrix",                        "Cycles vs capacity at different depths-of-discharge",    "",         "",                     "BatteryCell",       "en_batt=1&batt_life_model=0",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_calendar_choice",                        "Calendar life degradation input option",                 "0/1/2",    "0=NoCalendarDegradation,1=LithiomIonModel,2=InputLossTable", "BatteryCell",       "en_batt=1&batt_life_model=0",                           "",                             "" },
        { SSC_INPUT,        SSC_MATRIX,     "batt_calendar_lifetime_matrix",               "Days vs capacity",                                       "",         "",                     "BatteryCell",       "en_batt=1&batt_life_model=0&batt_calendar_choice=2", "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_calendar_q0",                            "Calendar life model initial capacity cofficient",        "",         "",                     "BatteryCell",       "en_batt=1&batt_life_model=0&batt_calendar_choice=1",  "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_calendar_a",                             "Calendar life model coefficient",                        "1/sqrt(day)","",                   "BatteryCell",       "en_batt=1&batt_life_model=0&batt_calendar_choice=1",  "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_calendar_b",                             "Calendar life model coefficient",                        "K",        "",                     "BatteryCell",       "en_batt=1&batt_life_model=0&batt_calendar_choice=1",  "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_calendar_c",                             "Calendar life model coefficient",                        "K",        "",                     "BatteryCell",       "en_batt=1&batt_life_model=0&batt_calendar_choice=1",  "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_replacement_capacity",                   "Capacity degradation at which to replace battery",       "%",        "",                     "BatterySystem",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_replacement_option",                     "Enable battery replacement?",                            "0=none,1=capacity based,2=user schedule", "", "BatterySystem", "?=0",                  "INTEGER,MIN=0,MAX=2",          "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_replacement_schedule_percent",           "Percentage of battery capacity to replace in each year", "%","length <= analysis_period",                  "BatterySystem",      "batt_replacement_option=2",   "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "om_replacement_cost1",                        "Cost to replace battery per kWh",                        "$/kWh",    "",                     "BatterySystem",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_mass",                                   "Battery mass",                                           "kg",       "",                     "BatterySystem",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_surface_area",                            "Battery surface area",                                   "m^2",      "",                     "BatterySystem",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_Cp",                                     "Battery specific heat capacity",                         "J/KgK",    "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_h_to_ambient",                           "Heat transfer between battery and environment",          "W/m2K",    "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_room_temperature_celsius",               "Temperature of storage room",                            "C", "length=1 for fixed, # of weatherfile records otherwise", "BatteryCell",        "",                           "",                             "" },
        { SSC_INPUT,        SSC_MATRIX,     "cap_vs_temp",                                 "Effective capacity as function of temperature",          "C,%",      "",                     "BatteryCell",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "dispatch_manual_charge",                      "Periods 1-6 charging from system allowed?",              "",         "",                     "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=4",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "dispatch_manual_fuelcellcharge",			  "Periods 1-6 charging from fuel cell allowed?",           "",         "",                      "BatteryDispatch",     "",                        "",                              "" },
        { SSC_INPUT,        SSC_ARRAY,      "dispatch_manual_discharge",                   "Periods 1-6 discharging allowed?",                       "",         "",                     "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=4",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "dispatch_manual_gridcharge",                  "Periods 1-6 grid charging allowed?",                     "",         "",                     "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=4",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "dispatch_manual_percent_discharge",           "Periods 1-6 discharge percent",                          "%",        "",                     "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=4",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "dispatch_manual_percent_gridcharge",          "Periods 1-6 gridcharge percent",                         "%",        "",                     "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=4",                           "",                             "" },
        { SSC_INPUT,        SSC_MATRIX,     "dispatch_manual_sched",                       "Battery dispatch schedule for weekday",                  "",         "",                     "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=4",                           "",                             "" },
        { SSC_INPUT,        SSC_MATRIX,     "dispatch_manual_sched_weekend",               "Battery dispatch schedule for weekend",                  "",         "",                     "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=4",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_target_power",                           "Grid target power for every time step",                  "kW",       "",                     "BatteryDispatch",       "en_batt=1&batt_meter_position=0&batt_dispatch_choice=2",                        "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_target_power_monthly",                   "Grid target power on monthly basis",                     "kW",       "",                     "BatteryDispatch",       "en_batt=1&batt_meter_position=0&batt_dispatch_choice=2",                        "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_target_choice",                          "Target power input option",                              "0/1",      "0=InputMonthlyTarget,1=InputFullTimeSeries", "BatteryDispatch", "en_batt=1&batt_meter_position=0&batt_dispatch_choice=2",                        "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_custom_dispatch",                        "Custom battery power for every time step",               "kW",       "kWAC if AC-connected, else kWDC", "BatteryDispatch",       "en_batt=1&batt_dispatch_choice=3","",                         "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_dispatch_choice",                        "Battery dispatch algorithm",                             "0/1/2/3/4/5", "If behind the meter: 0=PeakShavingLookAhead,1=PeakShavingLookBehind,2=InputGridTarget,3=InputBatteryPower,4=ManualDispatch,5=PriceSignalForecast if front of meter: 0=AutomatedLookAhead,1=AutomatedLookBehind,2=AutomatedInputForecast,3=InputBatteryPower,4=ManualDispatch",                    "BatteryDispatch",       "en_batt=1",                        "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_dispatch_auto_can_fuelcellcharge",       "Charging from fuel cell allowed for automated dispatch?",          "kW",       "",                     "BatteryDispatch",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_dispatch_auto_can_gridcharge",           "Grid charging allowed for automated dispatch?",          "kW",       "",                     "BatteryDispatch",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_dispatch_auto_can_charge",               "System charging allowed for automated dispatch?",            "kW",       "",                     "BatteryDispatch",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_dispatch_auto_can_clipcharge",           "Battery can charge from clipped power for automated dispatch?", "kW",   "",                     "BatteryDispatch",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_auto_gridcharge_max_daily",              "Allowed grid charging percent per day for automated dispatch","kW",  "",                     "BatteryDispatch",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_look_ahead_hours",                       "Hours to look ahead in automated dispatch",              "hours",    "",                     "BatteryDispatch",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_dispatch_update_frequency_hours",        "Frequency to update the look-ahead dispatch",            "hours",    "",                     "BatteryDispatch",       "",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_pv_clipping_forecast",                   "PV clipping forecast",                                   "kW",       "",                     "BatteryDispatch",       "",  "",          "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_pv_ac_forecast",                         "PV ac power forecast",                                   "kW",       "",                     "BatteryDispatch",       "",  "",          "" },
        { SSC_INPUT,        SSC_NUMBER,     "batt_cycle_cost_choice",                      "Use SAM cost model for degradaton penalty or input custom via batt_cycle_cost", "0/1",     "0=UseCostModel,1=InputCost", "BatterySystem", "?=0",                           "",                             "" },
        { SSC_INPUT,        SSC_ARRAY,      "batt_cycle_cost",                             "Input battery cycle degradaton penalty per year",                      "$/cycle-kWh","length 1 or analysis_period, length 1 will be extended using inflation", "BatterySystem",       "batt_cycle_cost_choice=1",                           "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,     "inflation_rate",                              "Inflation rate",                                          "%", "", "Lifetime", "?=0", "MIN=-99", "" },
        { SSC_INPUT,        SSC_ARRAY,      "load_escalation",                             "Annual load escalation",                                  "%/year", "",                                                                                                                                                                                      "Load",                                               "?=0",                                "",                    "" },
        { SSC_INPUT,       SSC_ARRAY,       "fuelcell_power",                               "Electricity from fuel cell",                            "kW",       "",                     "FuelCell",     "",                           "",                         "" },
        var_info_invalid
]

var_info vtab_battery_outputs = [
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_q0",                                    "Battery total charge",                                   "Ah",       "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_q1",                                    "Battery available charge",                               "Ah",       "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_q2",                                    "Battery bound charge",                                   "Ah",       "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_SOC",                                   "Battery state of charge",                                "%",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_DOD",                                   "Battery cycle depth of discharge",                       "%",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_qmaxI",                                 "Battery maximum capacity at current",                    "Ah",       "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_qmax",                                  "Battery maximum charge with degradation",                "Ah",       "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_qmax_thermal",                          "Battery maximum charge at temperature",                  "Ah",       "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_I",                                     "Battery current",                                        "A",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_voltage_cell",                          "Battery cell voltage",                                   "V",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_voltage",                               "Battery voltage",	                                     "V",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_DOD_cycle_average",                     "Battery average cycle DOD",                              "",         "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_cycles",                                "Battery number of cycles",                               "",         "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_temperature",                           "Battery temperature",                                    "C",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_capacity_percent",                      "Battery relative capacity to nameplate",                 "%",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_capacity_percent_cycle",                "Battery relative capacity to nameplate (cycling)",       "%",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_capacity_percent_calendar",             "Battery relative capacity to nameplate (calendar)",      "%",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_capacity_thermal_percent",              "Battery capacity percent for temperature",               "%",        "",                     "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_bank_replacement",                      "Battery bank replacements per year",                     "number/year", "",                  "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_power",                                 "Electricity to/from battery",                           "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "grid_power",                                 "Electricity to/from grid",                              "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "system_to_load",                             "Electricity to load from system",                       "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_to_load",                               "Electricity to load from battery",                      "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "grid_to_load",                               "Electricity to load from grid",                         "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "system_to_batt",                             "Electricity to battery from system",                    "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "fuelcell_to_batt",                           "Electricity to battery from fuel cell",                 "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "grid_to_batt",                               "Electricity to battery from grid",                      "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "system_to_grid",                             "Electricity to grid from system",                       "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_to_grid",                               "Electricity to grid from battery",                      "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_conversion_loss",                       "Electricity loss in battery power electronics",         "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_system_loss",                           "Electricity loss from battery ancillary equipment (kW DC for DC connected, AC for AC connected)",     "kW",      "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "grid_power_target",                          "Electricity grid power target for automated dispatch","kW","",                               "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_power_target",                          "Electricity battery power target for automated dispatch","kW","",                            "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_cost_to_cycle",                         "Battery computed cycle degradation penalty",            "$/cycle-kWh", "",                       "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "market_sell_rate_series_yr1",                "Market sell rate (Year 1)",                             "$/MWh", "",                         "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_revenue_gridcharge",					   "Revenue to charge from grid",                           "$/kWh", "",                         "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_revenue_charge",                        "Revenue to charge from system",                         "$/kWh", "",                         "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_revenue_clipcharge",                    "Revenue to charge from clipped",                        "$/kWh", "",                         "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_revenue_discharge",                     "Revenue to discharge",                                  "$/kWh", "",                         "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "gen_without_battery",                        "Energy produced without the battery or curtailment",    "kW","",                      "Battery",       "",                           "",                              "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "monthly_system_to_load",                     "Energy to load from system",                            "kWh",      "",                      "Battery",       "",                          "LENGTH=12",                     "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "monthly_batt_to_load",                       "Energy to load from battery",                           "kWh",      "",                      "Battery",       "",                          "LENGTH=12",                     "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "monthly_grid_to_load",                       "Energy to load from grid",                              "kWh",      "",                      "Battery",       "",                          "LENGTH=12",                     "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "monthly_system_to_grid",                     "Energy to grid from system",                            "kWh",      "",                      "Battery",       "",                          "LENGTH=12",                     "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "monthly_batt_to_grid",                       "Energy to grid from battery",                           "kWh",      "",                      "Battery",       "",                          "LENGTH=12",                     "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "monthly_system_to_batt",                     "Energy to battery from system",                         "kWh",      "",                      "Battery",       "",                          "LENGTH=12",                     "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "monthly_grid_to_batt",                       "Energy to battery from grid",                           "kWh",      "",                      "Battery",       "",                          "LENGTH=12",                     "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_annual_charge_from_system",                 "Battery annual energy charged from system",                 "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_annual_charge_from_grid",               "Battery annual energy charged from grid",               "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_annual_charge_energy",                  "Battery annual energy charged",                         "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_annual_discharge_energy",               "Battery annual energy discharged",                      "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_annual_energy_loss",                    "Battery annual energy loss",                            "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "batt_annual_energy_system_loss",             "Battery annual system energy loss",                     "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "annual_export_to_grid_energy",               "Annual energy exported to grid",                        "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_ARRAY,      "annual_import_to_grid_energy",               "Annual energy imported from grid",                      "kWh",      "",                      "Battery",       "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_NUMBER,     "average_battery_conversion_efficiency",      "Battery average cycle conversion efficiency",           "%",        "",                      "Annual",        "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_NUMBER,     "average_battery_roundtrip_efficiency",       "Battery average roundtrip efficiency",                  "%",        "",                      "Annual",        "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_NUMBER,     "batt_system_charge_percent",                 "Battery charge energy charged from system",             "%",        "",                      "Annual",        "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_NUMBER,     "batt_bank_installed_capacity",               "Battery bank installed capacity",                       "kWh",      "",                      "Annual",        "",                           "",                               "" },
        { SSC_OUTPUT,        SSC_MATRIX,     "batt_dispatch_sched",                        "Battery dispatch schedule",                              "",        "",                     "Battery",       "",                           "",                               "ROW_LABEL=MONTHS,COL_LABEL=HOURS_OF_DAY"  },
        var_info_invalid ]

def battstor.__init__(inout self, vt: var_table, setup_model: bool, nrec: size_t, dt_hr: float64, batt_vars_in: std.shared_ptr[batt_variables] = std.shared_ptr[batt_variables]()):
    self.make_vars = False
    self._dt_hour = dt_hr
    self.step_per_hour = static_cast[size_t](1. / self._dt_hour)
    self.initialize_time(0, 0, 0)
    var has_fuelcell: bool = False
    if var vd = vt.lookup("fuelcell_power"):
        self.fuelcellPower = vd.arr_vector()
        has_fuelcell = True
    if batt_vars_in == 0:
        self.make_vars = True
        self.batt_vars = std.make_shared[batt_variables]()
        self.batt_vars.en_fuelcell = False
        if has_fuelcell:
            self.batt_vars.en_fuelcell = True
            self.batt_vars.batt_can_fuelcellcharge = vt.as_vector_bool("dispatch_manual_fuelcellcharge")
        self.batt_vars.en_batt = vt.as_boolean("en_batt")
        if self.batt_vars.en_batt:
            self.batt_vars.analysis_period = vt.as_integer("analysis_period")
            self.batt_vars.system_use_lifetime_output = vt.as_boolean("system_use_lifetime_output")
            self.nyears = 1
            if self.batt_vars.system_use_lifetime_output:
                self.nyears = self.batt_vars.analysis_period
            self.batt_vars.batt_chem = vt.as_integer("batt_chem")
            if self.batt_vars.batt_chem == battery_params.LEAD_ACID:
                self.batt_vars.LeadAcid_q10_computed = vt.as_double("LeadAcid_q10_computed")
                self.batt_vars.LeadAcid_q20_computed = vt.as_double("LeadAcid_q20_computed")
                self.batt_vars.LeadAcid_qn_computed = vt.as_double("LeadAcid_qn_computed")
                self.batt_vars.LeadAcid_tn = vt.as_double("LeadAcid_tn")
            self.batt_vars.batt_computed_series = vt.as_integer("batt_computed_series")
            self.batt_vars.batt_computed_strings = vt.as_integer("batt_computed_strings")
            self.batt_vars.batt_kwh = vt.as_double("batt_computed_bank_capacity")
            self.batt_vars.batt_kw = vt.as_double("batt_power_discharge_max_kwdc")
            self.batt_vars.batt_voltage_choice = vt.as_integer("batt_voltage_choice")
            self.batt_vars.batt_Vnom_default = vt.as_double("batt_Vnom_default")
            self.batt_vars.batt_Vfull = vt.as_double("batt_Vfull")
            self.batt_vars.batt_Vexp = vt.as_double("batt_Vexp")
            self.batt_vars.batt_Vnom = vt.as_double("batt_Vnom")
            self.batt_vars.batt_Qfull_flow = vt.as_double("batt_Qfull_flow")
            self.batt_vars.batt_Qfull = vt.as_double("batt_Qfull")
            self.batt_vars.batt_Qexp = vt.as_double("batt_Qexp")
            self.batt_vars.batt_Qnom = vt.as_double("batt_Qnom")
            self.batt_vars.batt_C_rate = vt.as_double("batt_C_rate")
            self.batt_vars.batt_resistance = vt.as_double("batt_resistance")
            self.batt_vars.batt_current_choice = vt.as_integer("batt_current_choice")
            self.batt_vars.batt_current_charge_max = vt.as_double("batt_current_charge_max")
            self.batt_vars.batt_current_discharge_max = vt.as_double("batt_current_discharge_max")
            self.batt_vars.batt_power_charge_max_kwdc = vt.as_double("batt_power_charge_max_kwdc")
            self.batt_vars.batt_power_discharge_max_kwdc = vt.as_double("batt_power_discharge_max_kwdc")
            self.batt_vars.batt_power_charge_max_kwac = vt.as_double("batt_power_charge_max_kwac")
            self.batt_vars.batt_power_discharge_max_kwac = vt.as_double("batt_power_discharge_max_kwac")
            self.batt_vars.batt_topology = vt.as_integer("batt_ac_or_dc")
            self.batt_vars.batt_ac_dc_efficiency = vt.as_double("batt_ac_dc_efficiency")
            self.batt_vars.batt_dc_ac_efficiency = vt.as_double("batt_dc_ac_efficiency")
            self.batt_vars.batt_dc_dc_bms_efficiency = vt.as_double("batt_dc_dc_efficiency")
            if vt.is_assigned("dcoptimizer_loss"):
                self.batt_vars.pv_dc_dc_mppt_efficiency = 100. - vt.as_double("dcoptimizer_loss")
            else:
                self.batt_vars.pv_dc_dc_mppt_efficiency = 100
            self.batt_vars.batt_loss_choice = vt.as_integer("batt_loss_choice")
            self.batt_vars.batt_losses_charging = vt.as_vector_double("batt_losses_charging")
            self.batt_vars.batt_losses_discharging = vt.as_vector_double("batt_losses_discharging")
            self.batt_vars.batt_losses_idle = vt.as_vector_double("batt_losses_idle")
            self.batt_vars.batt_losses = vt.as_vector_double("batt_losses")
            self.batt_vars.batt_initial_SOC = vt.as_double("batt_initial_SOC")
            self.batt_vars.batt_maximum_SOC = vt.as_double("batt_maximum_soc")
            self.batt_vars.batt_minimum_SOC = vt.as_double("batt_minimum_soc")
            self.batt_vars.batt_minimum_modetime = vt.as_double("batt_minimum_modetime")
            self.batt_vars.batt_dispatch = vt.as_integer("batt_dispatch_choice")
            self.batt_vars.batt_meter_position = vt.as_integer("batt_meter_position")
            self.batt_vars.batt_cycle_cost_choice = vt.as_integer("batt_cycle_cost_choice")
            var cnt: size_t = 0
            var i: size_t = 0
            var inflation_rate: float64 = vt.as_double("inflation_rate") * 0.01
            var cycle_cost: std.vector[ssc_number_t](self.nyears)
            if self.batt_vars.batt_cycle_cost_choice == 1:
                var parr: ssc_number_t* = vt.as_array("batt_cycle_cost", &cnt)
                if cnt == 1:
                    for i in range(self.nyears):
                        cycle_cost[i] = parr[0] * (ssc_number_t)pow((float64)(inflation_rate + 1), (float64)i)
                elif cnt < self.nyears:
                    throw exec_error("battery", "Invalid number for batt_cycle_cost, must be 1 or equal to analysis_period.")
                else:
                    for i in range(self.nyears):
                        cycle_cost[i] = parr[i]
            self.batt_vars.batt_cycle_cost = cycle_cost
            if vt.is_assigned("om_replacement_cost1"):
                var replacement_cost: std.vector[ssc_number_t](self.nyears)
                var parr: ssc_number_t* = vt.as_array("om_replacement_cost1", &cnt)
                if cnt == 1:
                    for i in range(self.nyears):
                        replacement_cost[i] = parr[0] * (ssc_number_t)pow((float64)(inflation_rate + 1), (float64)i)
                elif cnt < self.nyears:
                    throw exec_error("battery", "Invalid number for om_replacement_cost1, must be 1 or equal to analysis_period.")
                else:
                    for i in range(self.nyears):
                        replacement_cost[i] = parr[i]
                self.batt_vars.batt_cost_per_kwh = replacement_cost
            else:
                self.batt_vars.batt_cost_per_kwh = std.vector[float64](self.nyears, 0.0)
            if self.batt_vars.batt_meter_position == dispatch_t.FRONT:
                var fps: forecast_price_signal = forecast_price_signal(&vt)
                fps.setup(8760 * self.step_per_hour)
                self.batt_vars.forecast_price_series_dollar_per_kwh = fps.forecast_price()
                self.outMarketPrice = vt.allocate("market_sell_rate_series_yr1", self.batt_vars.forecast_price_series_dollar_per_kwh.size())
                for i in range(self.batt_vars.forecast_price_series_dollar_per_kwh.size()):
                    self.outMarketPrice[i] = (ssc_number_t)(self.batt_vars.forecast_price_series_dollar_per_kwh[i] * 1000.0)
                self.batt_vars.ec_rate_defined = False
                if vt.is_assigned("en_electricity_rates"):
                    if vt.as_integer("en_electricity_rates"):
                        self.batt_vars.ec_use_realtime = vt.as_boolean("ur_en_ts_sell_rate")
                        if not self.batt_vars.ec_use_realtime:
                            self.batt_vars.ec_weekday_schedule = vt.as_matrix_unsigned_long("ur_ec_sched_weekday")
                            self.batt_vars.ec_weekend_schedule = vt.as_matrix_unsigned_long("ur_ec_sched_weekend")
                            self.batt_vars.ec_tou_matrix = vt.as_matrix("ur_ec_tou_mat")
                        else:
                            self.batt_vars.ec_realtime_buy = vt.as_vector_double("ur_ts_buy_rate")
                        self.batt_vars.ec_rate_defined = True
                    else:
                        self.batt_vars.ec_use_realtime = True
                        self.batt_vars.ec_realtime_buy = self.batt_vars.forecast_price_series_dollar_per_kwh
                if self.batt_vars.batt_dispatch == dispatch_t.FOM_LOOK_AHEAD or self.batt_vars.batt_dispatch == dispatch_t.FOM_FORECAST or self.batt_vars.batt_dispatch == dispatch_t.FOM_LOOK_BEHIND:
                    self.batt_vars.batt_look_ahead_hours = vt.as_unsigned_long("batt_look_ahead_hours")
                    self.batt_vars.batt_dispatch_update_frequency_hours = vt.as_double("batt_dispatch_update_frequency_hours")
                elif self.batt_vars.batt_dispatch == dispatch_t.FOM_CUSTOM_DISPATCH:
                    self.batt_vars.batt_custom_dispatch = vt.as_vector_double("batt_custom_dispatch")
            else:
                self.batt_vars.ec_rate_defined = False
                if vt.is_assigned("ur_ec_tou_mat"):
                    self.batt_vars.ec_rate_defined = True
                if self.batt_vars.batt_dispatch == dispatch_t.MAINTAIN_TARGET:
                    self.batt_vars.batt_target_choice = vt.as_integer("batt_target_choice")
                    self.batt_vars.target_power_monthly = vt.as_vector_double("batt_target_power_monthly")
                    self.batt_vars.target_power = vt.as_vector_double("batt_target_power")
                    if self.batt_vars.batt_target_choice == dispatch_automatic_behind_the_meter_t.TARGET_SINGLE_MONTHLY:
                        self.target_power_monthly = self.batt_vars.target_power_monthly
                        self.target_power.clear()
                        self.target_power.reserve(8760 * self.step_per_hour)
                        for month in range(12):
                            var target: float64 = self.target_power_monthly[month]
                            for h in range(util.hours_in_month(month + 1)):
                                for s in range(self.step_per_hour):
                                    self.target_power.push_back(target)
                    else:
                        self.target_power = self.batt_vars.target_power
                    if self.target_power.size() != nrec:
                        throw exec_error("battery", "Invalid number of target powers, must be equal to number of records in weather file.")
                    for y in range(1, self.nyears):
                        for i in range(nrec):
                            self.target_power.push_back(self.target_power[i])
                    self.batt_vars.target_power = self.target_power
                elif self.batt_vars.batt_dispatch == dispatch_t.CUSTOM_DISPATCH:
                    self.batt_vars.batt_custom_dispatch = vt.as_vector_double("batt_custom_dispatch")
            if (self.batt_vars.batt_meter_position == dispatch_t.FRONT and self.batt_vars.batt_dispatch == dispatch_t.FOM_MANUAL) or (self.batt_vars.batt_meter_position == dispatch_t.BEHIND and self.batt_vars.batt_dispatch == dispatch_t.MANUAL):
                self.batt_vars.batt_can_charge = vt.as_vector_bool("dispatch_manual_charge")
                self.batt_vars.batt_can_discharge = vt.as_vector_bool("dispatch_manual_discharge")
                self.batt_vars.batt_can_gridcharge = vt.as_vector_bool("dispatch_manual_gridcharge")
                self.batt_vars.batt_discharge_percent = vt.as_vector_double("dispatch_manual_percent_discharge")
                self.batt_vars.batt_gridcharge_percent = vt.as_vector_double("dispatch_manual_percent_gridcharge")
                self.batt_vars.batt_discharge_schedule_weekday = vt.as_matrix_unsigned_long("dispatch_manual_sched")
                self.batt_vars.batt_discharge_schedule_weekend = vt.as_matrix_unsigned_long("dispatch_manual_sched_weekend")
            self.batt_vars.batt_dispatch_auto_can_charge = True
            self.batt_vars.batt_dispatch_auto_can_clipcharge = True
            self.batt_vars.batt_dispatch_auto_can_gridcharge = False
            self.batt_vars.batt_dispatch_auto_can_fuelcellcharge = True
            if vt.is_assigned("batt_dispatch_auto_can_gridcharge"):
                self.batt_vars.batt_dispatch_auto_can_gridcharge = vt.as_boolean("batt_dispatch_auto_can_gridcharge")
            if vt.is_assigned("batt_dispatch_auto_can_charge"):
                self.batt_vars.batt_dispatch_auto_can_charge = vt.as_boolean("batt_dispatch_auto_can_charge")
            if vt.is_assigned("batt_dispatch_auto_can_clipcharge"):
                self.batt_vars.batt_dispatch_auto_can_clipcharge = vt.as_boolean("batt_dispatch_auto_can_clipcharge")
            if vt.is_assigned("batt_dispatch_auto_can_fuelcellcharge"):
                self.batt_vars.batt_dispatch_auto_can_fuelcellcharge = vt.as_boolean("batt_dispatch_auto_can_fuelcellcharge")
            self.batt_vars.batt_replacement_option = vt.as_integer("batt_replacement_option")
            self.batt_vars.batt_replacement_capacity = vt.as_double("batt_replacement_capacity")
            if self.batt_vars.batt_replacement_option == replacement_params.SCHEDULE:
                self.batt_vars.batt_replacement_schedule_percent = vt.as_vector_double("batt_replacement_schedule_percent")
            self.batt_vars.batt_life_model = vt.as_integer("batt_life_model")
            if self.batt_vars.batt_life_model == 1 and self.batt_vars.batt_chem != 1:
                throw exec_error("battery", "NMC life model (batt_life_model=1) can only be used with Li-Ion chemistries (batt_chem=1).")
            if self.batt_vars.batt_life_model == 0:
                self.batt_vars.batt_calendar_choice = vt.as_integer("batt_calendar_choice")
                self.batt_vars.batt_lifetime_matrix = vt.as_matrix("batt_lifetime_matrix")
                self.batt_vars.batt_calendar_lifetime_matrix = vt.as_matrix("batt_calendar_lifetime_matrix")
                self.batt_vars.batt_voltage_matrix = vt.as_matrix("batt_voltage_matrix")
                self.batt_vars.batt_calendar_q0 = vt.as_double("batt_calendar_q0")
                self.batt_vars.batt_calendar_a = vt.as_double("batt_calendar_a")
                self.batt_vars.batt_calendar_b = vt.as_double("batt_calendar_b")
                self.batt_vars.batt_calendar_c = vt.as_double("batt_calendar_c")
            self.batt_vars.batt_surface_area = vt.as_double("batt_surface_area")
            self.batt_vars.cap_vs_temp = vt.as_matrix("cap_vs_temp")
            self.batt_vars.batt_mass = vt.as_double("batt_mass")
            self.batt_vars.batt_Cp = vt.as_double("batt_Cp")
            self.batt_vars.batt_h_to_ambient = vt.as_double("batt_h_to_ambient")
            self.batt_vars.T_room = vt.as_vector_double("batt_room_temperature_celsius")
            if self.batt_vars.T_room.size() == 1:
                var T_ambient: float64 = self.batt_vars.T_room[0]
                self.batt_vars.T_room = std.vector[float64](T_ambient, nrec)
            self.batt_vars.inverter_model = vt.as_integer("inverter_model")
            if self.batt_vars.inverter_model < 4:
                self.batt_vars.inverter_count = vt.as_integer("inverter_count")
                self.batt_vars.batt_inverter_efficiency_cutoff = vt.as_double("batt_inverter_efficiency_cutoff")
                if self.batt_vars.inverter_model == SharedInverter.SANDIA_INVERTER:
                    self.batt_vars.inverter_efficiency = vt.as_double("inv_snl_eff_cec")
                    self.batt_vars.inverter_paco = self.batt_vars.inverter_count * vt.as_double("inv_snl_paco") * util.watt_to_kilowatt
                elif self.batt_vars.inverter_model == SharedInverter.DATASHEET_INVERTER:
                    self.batt_vars.inverter_efficiency = vt.as_double("inv_ds_eff")
                    self.batt_vars.inverter_paco = self.batt_vars.inverter_count * vt.as_double("inv_ds_paco") * util.watt_to_kilowatt
                elif self.batt_vars.inverter_model == SharedInverter.PARTLOAD_INVERTER:
                    self.batt_vars.inverter_efficiency = vt.as_double("inv_pd_eff")
                    self.batt_vars.inverter_paco = self.batt_vars.inverter_count * vt.as_double("inv_pd_paco") * util.watt_to_kilowatt
                elif self.batt_vars.inverter_model == SharedInverter.COEFFICIENT_GENERATOR:
                    self.batt_vars.inverter_efficiency = vt.as_double("inv_cec_cg_eff_cec")
                    self.batt_vars.inverter_paco = self.batt_vars.inverter_count * vt.as_double("inv_cec_cg_paco") * util.watt_to_kilowatt
            else:
                self.batt_vars.inverter_model = SharedInverter.NONE
                self.batt_vars.inverter_count = 1
                self.batt_vars.inverter_efficiency = self.batt_vars.batt_ac_dc_efficiency
                self.batt_vars.inverter_paco = self.batt_vars.batt_kw
    else:
        self.nyears = (batt_vars_in.system_use_lifetime_output) ? batt_vars_in.analysis_period : 1
        self.batt_vars = batt_vars_in
    self.battery_model = 0
    self.dispatch_model = 0
    self.charge_control = 0
    self.battery_metrics = 0
    self.outTotalCharge = 0
    self.outAvailableCharge = 0
    self.outBoundCharge = 0
    self.outMaxChargeAtCurrent = 0
    self.outMaxChargeThermal = 0
    self.outMaxCharge = 0
    self.outSOC = 0
    self.outDOD = 0
    self.outDODCycleAverage = 0
    self.outCurrent = 0
    self.outCellVoltage = 0
    self.outBatteryVoltage = 0
    self.outCapacityPercent = 0
    self.outCycles = 0
    self.outBatteryBankReplacement = 0
    self.outBatteryTemperature = 0
    self.outCapacityThermalPercent = 0
    self.outBatteryPower = 0
    self.outGridPower = 0
    self.outSystemToLoad = 0
    self.outBatteryToLoad = 0
    self.outGridToLoad = 0
    self.outFuelCellToLoad = 0
    self.outGridPowerTarget = 0
    self.outSystemToBatt = 0
    self.outGridToBatt = 0
    self.outFuelCellToBatt = 0
    self.outSystemToGrid = 0
    self.outBatteryToGrid = 0
    self.outFuelCellToGrid = 0
    self.outBatteryConversionPowerLoss = 0
    self.outBatterySystemLoss = 0
    self.outAverageCycleEfficiency = 0
    self.outSystemChargePercent = 0
    self.outAnnualSystemChargeEnergy = 0
    self.outAnnualGridChargeEnergy = 0
    self.outAnnualChargeEnergy = 0
    self.outAnnualDischargeEnergy = 0
    self.outAnnualGridImportEnergy = 0
    self.outAnnualGridExportEnergy = 0
    self.outCostToCycle = 0
    self.outBenefitCharge = 0
    self.outBenefitGridcharge = 0
    self.outBenefitClipcharge = 0
    self.outBenefitDischarge = 0
    self.en = setup_model
    if not self.en:
        return
    if not self.batt_vars.system_use_lifetime_output:
        if self.batt_vars.batt_replacement_option > 0:
            throw exec_error("battery", "Battery replacements are enabled with single year simulation. You must enable lifetime simulations to model battery replacements.")
    self.total_steps = self.nyears * 8760 * self.step_per_hour
    self.chem = self.batt_vars.batt_chem
    # Initialize outputs
    if self.chem == 0:
        self.outAvailableCharge = vt.allocate("batt_q1", nrec * self.nyears)
        self.outBoundCharge = vt.allocate("batt_q2", nrec * self.nyears)
    self.outCellVoltage = vt.allocate("batt_voltage_cell", nrec)
    self.outMaxCharge = vt.allocate("batt_qmax", nrec)
    self.outMaxChargeThermal = vt.allocate("batt_qmax_thermal", nrec)
    self.outBatteryTemperature = vt.allocate("batt_temperature", nrec)
    self.outCapacityThermalPercent = vt.allocate("batt_capacity_thermal_percent", nrec)
    self.outCurrent = vt.allocate("batt_I", nrec * self.nyears)
    self.outBatteryVoltage = vt.allocate("batt_voltage", nrec * self.nyears)
    self.outTotalCharge = vt.allocate("batt_q0", nrec * self.nyears)
    self.outCycles = vt.allocate("batt_cycles", nrec * self.nyears)
    self.outSOC = vt.allocate("batt_SOC", nrec * self.nyears)
    self.outDOD = vt.allocate("batt_DOD", nrec * self.nyears)
    self.outDODCycleAverage = vt.allocate("batt_DOD_cycle_average", nrec * self.nyears)
    self.outCapacityPercent = vt.allocate("batt_capacity_percent", nrec * self.nyears)
    self.outCapacityPercentCycle = vt.allocate("batt_capacity_percent_cycle", nrec * self.nyears)
    self.outCapacityPercentCalendar = vt.allocate("batt_capacity_percent_calendar", nrec * self.nyears)
    self.outBatteryPower = vt.allocate("batt_power", nrec * self.nyears)
    self.outGridPower = vt.allocate("grid_power", nrec * self.nyears)
    self.outGenPower = vt.allocate("pv_batt_gen", nrec * self.nyears)
    self.outGenWithoutBattery = vt.allocate("gen_without_battery", nrec * self.nyears)
    self.outSystemToGrid = vt.allocate("system_to_grid", nrec * self.nyears)
    if self.batt_vars.batt_meter_position == dispatch_t.BEHIND:
        self.outSystemToLoad = vt.allocate("system_to_load", nrec * self.nyears)
        self.outBatteryToLoad = vt.allocate("batt_to_load", nrec * self.nyears)
        self.outGridToLoad = vt.allocate("grid_to_load", nrec * self.nyears)
        if self.batt_vars.batt_dispatch != dispatch_t.MANUAL:
            self.outGridPowerTarget = vt.allocate("grid_power_target", nrec * self.nyears)
            self.outBattPowerTarget = vt.allocate("batt_power_target", nrec * self.nyears)
    elif self.batt_vars.batt_meter_position == dispatch_t.FRONT:
        self.outBatteryToGrid = vt.allocate("batt_to_grid", nrec * self.nyears)
        if self.batt_vars.batt_dispatch != dispatch_t.FOM_MANUAL:
            self.outBattPowerTarget = vt.allocate("batt_power_target", nrec * self.nyears)
            self.outBenefitCharge = vt.allocate("batt_revenue_charge", nrec * self.nyears)
            self.outBenefitGridcharge = vt.allocate("batt_revenue_gridcharge", nrec * self.nyears)
            self.outBenefitClipcharge = vt.allocate("batt_revenue_clipcharge", nrec * self.nyears)
            self.outBenefitDischarge = vt.allocate("batt_revenue_discharge", nrec * self.nyears)
    self.outSystemToBatt = vt.allocate("system_to_batt", nrec * self.nyears)
    self.outGridToBatt = vt.allocate("grid_to_batt", nrec * self.nyears)
    if self.batt_vars.en_fuelcell:
        self.outFuelCellToBatt = vt.allocate("fuelcell_to_batt", nrec * self.nyears)
        self.outFuelCellToGrid = vt.allocate("fuelcell_to_grid", nrec * self.nyears)
        self.outFuelCellToLoad = vt.allocate("fuelcell_to_load", nrec * self.nyears)
    var cycleCostRelevant: bool = (self.batt_vars.batt_meter_position == dispatch_t.BEHIND and self.batt_vars.batt_dispatch == dispatch_t.FORECAST) or (self.batt_vars.batt_meter_position == dispatch_t.FRONT and (self.batt_vars.batt_dispatch != dispatch_t.FOM_MANUAL and self.batt_vars.batt_dispatch != dispatch_t.FOM_CUSTOM_DISPATCH))
    if cycleCostRelevant and self.batt_vars.batt_cycle_cost_choice == dispatch_t.MODEL_CYCLE_COST:
        self.outCostToCycle = vt.allocate("batt_cost_to_cycle", nrec * self.nyears)
    self.outBatteryConversionPowerLoss = vt.allocate("batt_conversion_loss", nrec * self.nyears)
    self.outBatterySystemLoss = vt.allocate("batt_system_loss", nrec * self.nyears)
    var annual_size: size_t = self.nyears + 1
    if self.nyears == 1:
        annual_size = 1
    self.outBatteryBankReplacement = vt.allocate("batt_bank_replacement", annual_size)
    self.outAnnualChargeEnergy = vt.allocate("batt_annual_charge_energy", annual_size)
    self.outAnnualDischargeEnergy = vt.allocate("batt_annual_discharge_energy", annual_size)
    self.outAnnualGridImportEnergy = vt.allocate("annual_import_to_grid_energy", annual_size)
    self.outAnnualGridExportEnergy = vt.allocate("annual_export_to_grid_energy", annual_size)
    self.outAnnualEnergySystemLoss = vt.allocate("batt_annual_energy_system_loss", annual_size)
    self.outAnnualEnergyLoss = vt.allocate("batt_annual_energy_loss", annual_size)
    self.outAnnualSystemChargeEnergy = vt.allocate("batt_annual_charge_from_system", annual_size)
    self.outAnnualGridChargeEnergy = vt.allocate("batt_annual_charge_from_grid", annual