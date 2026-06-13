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
from common.h import var_info, vtab_standard_financial, vtab_standard_loan, vtab_oandm, vtab_equip_reserve, vtab_depreciation, vtab_depreciation_inputs, vtab_depreciation_outputs, vtab_tax_credits, vtab_payment_incentives, vtab_debt, vtab_ppa_inout, vtab_financial_metrics, vtab_adjustment_factors, vtab_dc_adjustment_factors, vtab_sf_adjustment_factors, vtab_technology_outputs, vtab_grid_curtailment, vtab_p50p90, vtab_forecast_price_signal, vtab_resilience_outputs, vtab_utility_rate_common, calculate_p50p90, calculate_resilience_outputs, adjustment_factors, forecast_price_signal, sf_adjustment_factors, shading_factor_calculator, weatherdata, scalefactors, ssc_cmod_update
from core import var_info, SSC_INPUT, SSC_OUTPUT, SSC_NUMBER, SSC_ARRAY, SSC_MATRIX, SSC_TABLE, ssc_number_t
from vartab import var_table
from lib_weatherfile import weather_data_provider, weather_record, calc_twet, wiki_dew_calc
from lib_time import days_in_month, nday
from lib_resilience import resilience_runner
from lib_util import util, general_error, extrapolate_timeseries, flatten_diurnal
from lib_pv_shade_loss_mpp import ShadeDB8_mpp
from util.math import floor as mojo_floor
from stdlib import *
from python.object import type as py_type

# forward declarations (from header)
# vtab_* arrays are declared extern in header; assumed defined elsewhere.

var_info vtab_standard_financial_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "analysis_period"                      , "Analyis period"                                                 , "years"                                  , ""                                      , "Financial Parameters" , "?=30"           , "INTEGER,MIN=0,MAX=50"  , ""),
var_info(SSC_INPUT, SSC_ARRAY  , "federal_tax_rate"                     , "Federal income tax rate"                                        , "%"                                      , ""                                      , "Financial Parameters" , "*"              , ""                      , ""),
var_info(SSC_INPUT, SSC_ARRAY  , "state_tax_rate"                       , "State income tax rate"                                          , "%"                                      , ""                                      , "Financial Parameters" , "*"              , ""                      , ""),
var_info(SSC_OUTPUT, SSC_ARRAY , "cf_federal_tax_frac"                  , "Federal income tax rate"                                        , "frac"                                   , ""                                      , "Financial Parameters" , "*"              , "LENGTH_EQUAL=cf_length", ""),
var_info(SSC_OUTPUT, SSC_ARRAY , "cf_state_tax_frac"                    , "State income tax rate"                                          , "frac"                                   , ""                                      , "Financial Parameters" , "*"              , "LENGTH_EQUAL=cf_length", ""),
var_info(SSC_OUTPUT, SSC_ARRAY , "cf_effective_tax_frac"                , "Effective income tax rate"                                      , "frac"                                   , ""                                      , "Financial Parameters" , "*"              , "LENGTH_EQUAL=cf_length", ""),
var_info(SSC_INPUT, SSC_NUMBER , "property_tax_rate"                    , "Property tax rate"                                              , "%"                                      , ""                                      , "Financial Parameters" , "?=0.0"          , "MIN=0,MAX=100"         , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "prop_tax_cost_assessed_percent"       , "Percent of pre-financing costs assessed"                        , "%"                                      , ""                                      , "Financial Parameters" , "?=95"           , "MIN=0,MAX=100"         , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "prop_tax_assessed_decline"            , "Assessed value annual decline"                                  , "%"                                      , ""                                      , "Financial Parameters" , "?=5"            , "MIN=0,MAX=100"         , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "real_discount_rate"                   , "Real discount rate"                                             , "%"                                      , ""                                      , "Financial Parameters" , "*"              , "MIN=-99"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "inflation_rate"                       , "Inflation rate"                                                 , "%"                                      , ""                                      , "Financial Parameters" , "*"              , "MIN=-99"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "insurance_rate"                       , "Insurance rate"                                                 , "%"                                      , ""                                      , "Financial Parameters" , "?=0.0"          , "MIN=0,MAX=100"         , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "system_capacity"                      , "System nameplate capacity"                                      , "kW"                                     , ""                                      , "Financial Parameters" , "*"              , "POSITIVE"              , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "system_heat_rate"                     , "System heat rate"                                               , "MMBTus/MWh"                             , ""                                      , "Financial Parameters" , "?=0.0"          , "MIN=0"                 , ""),
var_info_invalid() ]

var_info vtab_battery_replacement_cost_array: var_info[None] = [
var_info(SSC_INPUT, SSC_NUMBER , "en_batt"                              , "Enable battery storage model"                                   , "0/1"                                    , ""                                      , "BatterySystem"              , "?=0"            , ""                      , ""),
var_info(SSC_INPUT, SSC_ARRAY  , "batt_bank_replacement"                , "Battery bank replacements per year"                             , "number/year"                            , ""                                      , "BatterySystem"              , ""               , ""                      , ""),
var_info(SSC_INPUT, SSC_ARRAY  , "batt_replacement_schedule_percent"    , "Percentage of battery capacity to replace in each year"         , "%"                                      , "length <= analysis_period"             , "BatterySystem"              , ""               , ""                      , ""),
var_info(SSC_INPUT, SSC_NUMBER , "batt_replacement_option"              , "Enable battery replacement?"                                    , "0=none,1=capacity based,2=user schedule", ""                                      , "BatterySystem"              , "?=0"            , "INTEGER,MIN=0,MAX=2"   , ""),
var_info(SSC_INPUT, SSC_NUMBER , "battery_per_kWh"                      , "Battery cost"                                                   , "$/kWh"                                  , ""                                      , "BatterySystem"              , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT, SSC_NUMBER , "batt_computed_bank_capacity"          , "Battery bank capacity"                                          , "kWh"                                    , ""                                      , "BatterySystem"              , "?=0.0"          , ""                      , ""),
var_info(SSC_OUTPUT, SSC_ARRAY , "cf_battery_replacement_cost"          , "Battery replacement cost"                                       , "$"                                      , ""                                      , "Cash Flow"            , "*"              , ""                      , ""),
var_info(SSC_OUTPUT, SSC_ARRAY , "cf_battery_replacement_cost_schedule" , "Battery replacement cost schedule"                              , "$"                                  , ""                                      , "Cash Flow"            , "*"              , ""                      , ""),
var_info_invalid() ]

var_info vtab_financial_grid_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_ARRAY,      "grid_curtailment_price",                           "Curtailment price",                                  "$/kWh",  "",                      "GridLimits",      "?=0",                   "",          "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "grid_curtailment_price_esc",                           "Curtailment price escalation",                                  "%",  "",           "GridLimits",      "?=0",                   "",          "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "annual_energy_pre_curtailment_ac", "Annual Energy AC pre-curtailment (year 1)",                   "kWh",        "",                   "System Output",               "?=0",                     "",                              "" ),
var_info_invalid() ]

var_info vtab_fuelcell_replacement_cost_array: var_info[None] = [
var_info(SSC_INPUT, SSC_ARRAY  , "fuelcell_replacement"                 , "Fuel cell replacements per year"                                , "number/year"                            , ""                                      , "Fuel Cell"            , ""               , ""                      , ""),
var_info(SSC_INPUT, SSC_ARRAY  , "fuelcell_replacement_schedule"        , "Fuel cell replacements per year (user specified)"               , "number/year"                            , ""                                      , "Fuel Cell"            , ""               , ""                      , ""),
var_info(SSC_INPUT, SSC_NUMBER , "en_fuelcell"                          , "Enable fuel cell storage model"                                 , "0/1"                                    , ""                                      , "Fuel Cell"            , "?=0"            , ""                      , ""),
var_info(SSC_INPUT, SSC_NUMBER , "fuelcell_replacement_option"          , "Enable fuel cell replacement?"                                  , "0=none,1=capacity based,2=user schedule", ""                                      , "Fuel Cell"            , "?=0"            , "INTEGER,MIN=0,MAX=2"   , ""),
var_info(SSC_INPUT, SSC_NUMBER , "fuelcell_per_kWh"                     , "Fuel cell cost"                                                 , "$/kWh"                                  , ""                                      , "Fuel Cell"            , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT, SSC_NUMBER , "fuelcell_computed_bank_capacity"      , "Fuel cell capacity"                                             , "kWh"                                    , ""                                      , "Fuel Cell"            , "?=0.0"          , ""                      , ""),
var_info(SSC_OUTPUT, SSC_ARRAY , "cf_fuelcell_replacement_cost"         , "Fuel cell replacement cost"                                     , "$"                                      , ""                                      , "Cash Flow"            , "*"              , ""                      , ""),
var_info(SSC_OUTPUT, SSC_ARRAY , "cf_fuelcell_replacement_cost_schedule", "Fuel cell replacement cost schedule"                            , "$/kW"                                   , ""                                      , "Cash Flow"            , "*"              , ""                      , ""),
var_info_invalid() ]

var_info vtab_standard_loan_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "loan_term"                            , "Loan term"                                                      , "years"                                  , ""                                      , "Financial Parameters" , "?=0"            , "INTEGER,MIN=0,MAX=50"  , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "loan_rate"                            , "Loan rate"                                                      , "%"                                      , ""                                      , "Financial Parameters" , "?=0"            , "MIN=0,MAX=100"         , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "debt_fraction"                        , "Debt percentage"                                                , "%"                                      , ""                                      , "Financial Parameters" , "?=0"            , "MIN=0,MAX=100"         , ""),
var_info_invalid() ]

var_info vtab_oandm_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_ARRAY,       "om_fixed",                     "Fixed O&M annual amount",           "$/year",  "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "om_fixed_escal",               "Fixed O&M escalation",              "%/year",  "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_ARRAY,       "om_production",                "Production-based O&M amount",       "$/MWh",   "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "om_production_escal",          "Production-based O&M escalation",   "%/year",  "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_ARRAY,       "om_capacity",                  "Capacity-based O&M amount",         "$/kWcap", "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "om_capacity_escal",            "Capacity-based O&M escalation",     "%/year",  "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_ARRAY,		 "om_fuel_cost",                 "Fuel cost",                         "$/MMBtu", "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "om_fuel_cost_escal",           "Fuel cost escalation",              "%/year",  "",                  "System Costs",            "?=0.0",                 "",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "annual_fuel_usage",            "Fuel usage (yr 1)",                 "kWht",    "",                  "System Costs",            "?=0",                     "MIN=0",                                         "" ),
var_info(SSC_INPUT,        SSC_ARRAY,       "annual_fuel_usage_lifetime",   "Fuel usage (lifetime)",             "kWht",    "",                  "System Costs",            "",                     "",                                         "" ),
var_info(SSC_INPUT,SSC_ARRAY   , "om_replacement_cost1"                 , "Replacement cost 1"                                             , "$/kWh"                                  , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_replacement_cost2"                 , "Replacement cost 2"                                             , "$/kW"                                   , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "om_replacement_cost_escal"            , "Replacement cost escalation"                                    , "%/year"                                 , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "om_opt_fuel_1_usage"                  , "Biomass feedstock usage"                                        , "unit"                                   , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_opt_fuel_1_cost"                   , "Biomass feedstock cost"                                         , "$/unit"                                 , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "om_opt_fuel_1_cost_escal"             , "Biomass feedstock cost escalation"                              , "%/year"                                 , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "om_opt_fuel_2_usage"                  , "Coal feedstock usage"                                           , "unit"                                   , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_opt_fuel_2_cost"                   , "Coal feedstock cost"                                            , "$/unit"                                 , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "om_opt_fuel_2_cost_escal"             , "Coal feedstock cost escalation"                                 , "%/year"                                 , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "add_om_num_types"                     , "Number of O and M types"                                        , ""                                       , ""                                      , "System Costs"         , "?=0"            , "INTEGER,MIN=0,MAX=2"   , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "om_capacity1_nameplate"               , "Battery capacity for System Costs values"                       , "kW"                                     , ""                                      , "System Costs"         , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_production1_values"                , "Battery production for System Costs values"                     , "kWh"                                    , ""                                      , "System Costs"         , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_fixed1"                            , "Battery fixed System Costs annual amount"                       , "$/year"                                 , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_production1"                       , "Battery production-based System Costs amount"                   , "$/MWh"                                  , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_capacity1"                         , "Battery capacity-based System Costs amount"                     , "$/kWcap"                                , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "om_capacity2_nameplate"               , "Fuel cell capacity for System Costs values"                     , "kW"                                     , ""                                      , "System Costs"         , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_production2_values"                , "Fuel cell production for System Costs values"                   , "kWh"                                    , ""                                      , "System Costs"         , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_fixed2"                            , "Fuel cell fixed System Costs annual amount"                     , "$/year"                                 , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_production2"                       , "Fuel cell production-based System Costs amount"                 , "$/MWh"                                  , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "om_capacity2"                         , "Fuel cell capacity-based System Costs amount"                   , "$/kWcap"                                , ""                                      , "System Costs"         , "?=0.0"          , ""                      , ""),
var_info_invalid() ]

var_info vtab_equip_reserve_array: var_info[None] = [
var_info(SSC_INPUT,         SSC_NUMBER,    "reserves_interest",                      "Interest on reserves",				                           "%",	 "",					  "Financial Parameters",             "?=1.75",                     "MIN=0,MAX=100",      			"" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip1_reserve_cost",                    "Major equipment reserve 1 cost",	                               "$/W",	        "",				  "Financial Parameters",             "?=0.25",               "MIN=0",                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip1_reserve_freq",                    "Major equipment reserve 1 frequency",	                       "years",	 "",			  "Financial Parameters",             "?=12",               "INTEGER,MIN=0",                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip2_reserve_cost",                    "Major equipment reserve 2 cost",	                               "$/W",	 "",				  "Financial Parameters",             "?=0",               "MIN=0",                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip2_reserve_freq",                    "Major equipment reserve 2 frequency",	                       "years",	 "",			  "Financial Parameters",             "?=15",               "INTEGER,MIN=0",                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip3_reserve_cost",                    "Major equipment reserve 3 cost",	                               "$/W",	 "",				  "Financial Parameters",             "?=0",               "MIN=0",                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip3_reserve_freq",                    "Major equipment reserve 3 frequency",	                       "years",	 "",			  "Financial Parameters",             "?=20",               "INTEGER,MIN=0",                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip_reserve_depr_sta",                 "Major equipment reserve state depreciation",	                   "",	 "0=5yr MACRS,1=15yr MACRS,2=5yr SL,3=15yr SL, 4=20yr SL,5=39yr SL,6=Custom",  "Financial Parameters", "?=0",   "INTEGER,MIN=0,MAX=6",  "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "equip_reserve_depr_fed",                 "Major equipment reserve federal depreciation",	               "",	 "0=5yr MACRS,1=15yr MACRS,2=5yr SL,3=15yr SL, 4=20yr SL,5=39yr SL,6=Custom",  "Financial Parameters", "?=0",   "INTEGER,MIN=0,MAX=6",  "" ),
var_info_invalid()
]

var_info vtab_depreciation_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "depr_fed_type"                        , "Federal depreciation type"                                      , ""                                       , "0=none,1=macrs_half_year,2=sl,3=custom", "Depreciation"         , "?=0"            , "INTEGER,MIN=0,MAX=3"   , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "depr_fed_sl_years"                    , "Federal depreciation straight-line Years"                       , "years"                                  , ""                                      , "Depreciation"         , "depr_fed_type=2", "INTEGER,POSITIVE"      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "depr_fed_custom"                      , "Federal custom depreciation"                                    , "%/year"                                 , ""                                      , "Depreciation"         , "depr_fed_type=3", ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "depr_sta_type"                        , "State depreciation type"                                        , ""                                       , "0=none,1=macrs_half_year,2=sl,3=custom", "Depreciation"         , "?=0"            , "INTEGER,MIN=0,MAX=3"   , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "depr_sta_sl_years"                    , "State depreciation straight-line years"                         , "years"                                  , ""                                      , "Depreciation"         , "depr_sta_type=2", "INTEGER,POSITIVE"      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "depr_sta_custom"                      , "State custom depreciation"                                      , "%/year"                                 , ""                                      , "Depreciation"         , "depr_sta_type=3", ""                      , ""),
var_info_invalid() ]

var_info vtab_depreciation_inputs_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_alloc_macrs_5_percent",		      "5-yr MACRS depreciation federal and state allocation",	"%", "",	  "Depreciation",             "?=89",					  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_alloc_macrs_15_percent",		      "15-yr MACRS depreciation federal and state allocation",	"%", "",  "Depreciation",             "?=1.5",					  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_alloc_sl_5_percent",		          "5-yr straight line depreciation federal and state allocation",	"%", "",  "Depreciation",             "?=0",						  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_alloc_sl_15_percent",		          "15-yr straight line depreciation federal and state allocation","%", "",  "Depreciation",             "?=3",						  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_alloc_sl_20_percent",		          "20-yr straight line depreciation federal and state allocation","%", "",  "Depreciation",             "?=3",						  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_alloc_sl_39_percent",		          "39-yr straight line depreciation federal and state allocation","%", "",  "Depreciation",             "?=0.5",					  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_alloc_custom_percent",	          "Custom depreciation federal and state allocation","%", "",  "Depreciation",             "?=0",					  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_ARRAY,      "depr_custom_schedule",		              "Custom depreciation schedule",	"%",   "",                      "Depreciation",             "*",						   "",                              "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_bonus_sta",			              "State bonus depreciation",			"%",	 "",					  "Depreciation",             "?=0",						  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_sta_macrs_5",                 "State bonus depreciation 5-yr MACRS","0/1", "",                      "Depreciation",			 "?=1",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_sta_macrs_15",                "State bonus depreciation 15-yr MACRS","0/1","",                     "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_sta_sl_5",                    "State bonus depreciation 5-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_sta_sl_15",                   "State bonus depreciation 15-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_sta_sl_20",                   "State bonus depreciation 20-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_sta_sl_39",                   "State bonus depreciation 39-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_sta_custom",                  "State bonus depreciation custom","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "depr_bonus_fed",			              "Federal bonus depreciation",			"%",	 "",					  "Depreciation",             "?=0",						  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_fed_macrs_5",                 "Federal bonus depreciation 5-yr MACRS","0/1", "",                      "Depreciation",			 "?=1",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_fed_macrs_15",                "Federal bonus depreciation 15-yr MACRS","0/1","",                     "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_fed_sl_5",                    "Federal bonus depreciation 5-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_fed_sl_15",                   "Federal bonus depreciation 15-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_fed_sl_20",                   "Federal bonus depreciation 20-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_fed_sl_39",                   "Federal bonus depreciation 39-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_bonus_fed_custom",                  "Federal bonus depreciation custom","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_sta_macrs_5",                   "State ITC depreciation 5-yr MACRS","0/1", "",                      "Depreciation",			 "?=1",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_sta_macrs_15",                  "State ITC depreciation 15-yr MACRS","0/1","",                     "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_sta_sl_5",                      "State ITC depreciation 5-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_sta_sl_15",                     "State ITC depreciation 15-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_sta_sl_20",                     "State ITC depreciation 20-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_sta_sl_39",                     "State ITC depreciation 39-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_sta_custom",                    "State ITC depreciation custom","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_fed_macrs_5",                   "Federal ITC depreciation 5-yr MACRS","0/1", "",                      "Depreciation",			 "?=1",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_fed_macrs_15",                  "Federal ITC depreciation 15-yr MACRS","0/1","",                     "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_fed_sl_5",                      "Federal ITC depreciation 5-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_fed_sl_15",                     "Federal ITC depreciation 15-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_fed_sl_20",                     "Federal ITC depreciation 20-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_fed_sl_39",                     "Federal ITC depreciation 39-yr straight line","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"depr_itc_fed_custom",                    "Federal ITC depreciation custom","0/1","",                  "Depreciation",			 "?=0",                       "BOOLEAN",                        "" ),
var_info_invalid()
]

var_info vtab_depreciation_outputs_array: var_info[None] = [
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_macrs_5",                     "State depreciation from 5-yr MACRS",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_macrs_15",                    "State depreciation from 15-yr MACRS",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_sl_5",                        "State depreciation from 5-yr straight line",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_sl_15",                       "State depreciation from 15-yr straight line",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_sl_20",                       "State depreciation from 20-yr straight line",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_sl_39",                       "State depreciation from 39-yr straight line",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_custom",                      "State depreciation from custom",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_me1",                         "State depreciation from major equipment 1",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_me2",                         "State depreciation from major equipment 2",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_me3",                         "State depreciation from major equipment 3",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_stadepr_total",                       "Total state tax depreciation",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_statax_income_prior_incentives",      "State taxable income without incentives",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_statax_taxable_incentives",           "State taxable incentives",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_statax_income_with_incentives",       "State taxable income",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_statax",				              "State tax benefit (liability)",                   "$",            "",                      "Cash Flow State Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_macrs_5",                     "Federal depreciation from 5-yr MACRS",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_macrs_15",                    "Federal depreciation from 15-yr MACRS",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_sl_5",                        "Federal depreciation from 5-yr straight line",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_sl_15",                       "Federal depreciation from 15-yr straight line",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_sl_20",                       "Federal depreciation from 20-yr straight line",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_sl_39",                       "Federal depreciation from 39-yr straight line",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_custom",                      "Federal depreciation from custom",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_me1",                         "Federal depreciation from major equipment 1",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_me2",                         "Federal depreciation from major equipment 2",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_me3",                         "Federal depreciation from major equipment 3",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_feddepr_total",                       "Total federal tax depreciation",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_fedtax_income_prior_incentives",      "Federal taxable income without incentives",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_fedtax_taxable_incentives",           "Federal taxable incentives",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_fedtax_income_with_incentives",       "Federal taxable income",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_fedtax",				              "Federal tax benefit (liability)",                   "$",            "",                      "Cash Flow Federal Income Tax",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info_invalid()
]

var_info vtab_tax_credits_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "itc_fed_amount"                       , "Federal amount-based ITC amount"                                , "$"                                      , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_fed_amount_deprbas_fed"           , "Federal amount-based ITC reduces federal depreciation basis"    , "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_fed_amount_deprbas_sta"           , "Federal amount-based ITC reduces state depreciation basis"      , "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_sta_amount"                       , "State amount-based ITC amount"                                  , "$"                                      , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_sta_amount_deprbas_fed"           , "State amount-based ITC reduces federal depreciation basis"      , "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_sta_amount_deprbas_sta"           , "State amount-based ITC reduces state depreciation basis"        , "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_fed_percent"                      , "Federal percentage-based ITC percent"                           , "%"                                      , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_fed_percent_maxvalue"             , "Federal percentage-based ITC maximum value"                     , "$"                                      , ""                                      , "Tax Credit Incentives", "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_fed_percent_deprbas_fed"          , "Federal percentage-based ITC reduces federal depreciation basis", "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_fed_percent_deprbas_sta"          , "Federal percentage-based ITC reduces state depreciation basis"  , "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_sta_percent"                      , "State percentage-based ITC percent"                             , "%"                                      , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_sta_percent_maxvalue"             , "State percentage-based ITC maximum Value"                       , "$"                                      , ""                                      , "Tax Credit Incentives", "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_sta_percent_deprbas_fed"          , "State percentage-based ITC reduces federal depreciation basis"  , "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "itc_sta_percent_deprbas_sta"          , "State percentage-based ITC reduces state depreciation basis"    , "0/1"                                    , ""                                      , "Tax Credit Incentives", "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "ptc_fed_amount"                       , "Federal PTC amount"                                             , "$/kWh"                                  , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ptc_fed_term"                         , "Federal PTC term"                                               , "years"                                  , ""                                      , "Tax Credit Incentives", "?=10"           , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ptc_fed_escal"                        , "Federal PTC escalation"                                         , "%/year"                                 , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "ptc_sta_amount"                       , "State PTC amount"                                               , "$/kWh"                                  , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ptc_sta_term"                         , "State PTC term"                                                 , "years"                                  , ""                                      , "Tax Credit Incentives", "?=10"           , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ptc_sta_escal"                        , "State PTC escalation"                                           , "%/year"                                 , ""                                      , "Tax Credit Incentives", "?=0"            , ""                      , ""),
var_info_invalid() ]

var_info vtab_payment_incentives_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_amount"                       , "Federal amount-based IBI amount"                                , "$"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_amount_tax_fed"               , "Federal amount-based IBI federal taxable"                       , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_amount_tax_sta"               , "Federal amount-based IBI state taxable"                         , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_amount_deprbas_fed"           , "Federal amount-based IBI reduces federal depreciation basis"    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_amount_deprbas_sta"           , "Federal amount-based IBI reduces state depreciation basis"      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_amount"                       , "State amount-based IBI amount"                                  , "$"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_amount_tax_fed"               , "State amount-based IBI federal taxable"                         , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_amount_tax_sta"               , "State amount-based IBI state taxable"                           , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_amount_deprbas_fed"           , "State amount-based IBI reduces federal depreciation basis"      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_amount_deprbas_sta"           , "State amount-based IBI reduces state depreciation basis"        , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_amount"                       , "Utility amount-based IBI amount"                                , "$"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_amount_tax_fed"               , "Utility amount-based IBI federal taxable"                       , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_amount_tax_sta"               , "Utility amount-based IBI state taxable"                         , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_amount_deprbas_fed"           , "Utility amount-based IBI reduces federal depreciation basis"    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_amount_deprbas_sta"           , "Utility amount-based IBI reduces state depreciation basis"      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_amount"                       , "Other amount-based IBI amount"                                  , "$"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_amount_tax_fed"               , "Other amount-based IBI federal taxable"                         , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_amount_tax_sta"               , "Other amount-based IBI state taxable"                           , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_amount_deprbas_fed"           , "Other amount-based IBI reduces federal depreciation basis"      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_amount_deprbas_sta"           , "Other amount-based IBI reduces state depreciation basis"        , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_percent"                      , "Federal percentage-based IBI percent"                           , "%"                                      , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_percent_maxvalue"             , "Federal percentage-based IBI maximum value"                     , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_percent_tax_fed"              , "Federal percentage-based IBI federal taxable"                   , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_percent_tax_sta"              , "Federal percentage-based IBI state taxable"                     , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_percent_deprbas_fed"          , "Federal percentage-based IBI reduces federal depreciation basis", "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_fed_percent_deprbas_sta"          , "Federal percentage-based IBI reduces state depreciation basis"  , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_percent"                      , "State percentage-based IBI percent"                             , "%"                                      , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_percent_maxvalue"             , "State percentage-based IBI maximum value"                       , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_percent_tax_fed"              , "State percentage-based IBI federal taxable"                     , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_percent_tax_sta"              , "State percentage-based IBI state taxable"                       , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_percent_deprbas_fed"          , "State percentage-based IBI reduces federal depreciation basis"  , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_sta_percent_deprbas_sta"          , "State percentage-based IBI reduces state depreciation basis"    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_percent"                      , "Utility percentage-based IBI percent"                           , "%"                                      , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_percent_maxvalue"             , "Utility percentage-based IBI maximum value"                     , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_percent_tax_fed"              , "Utility percentage-based IBI federal taxable"                   , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_percent_tax_sta"              , "Utility percentage-based IBI state taxable"                     , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_percent_deprbas_fed"          , "Utility percentage-based IBI reduces federal depreciation basis", "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_uti_percent_deprbas_sta"          , "Utility percentage-based IBI reduces state depreciation basis"  , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_percent"                      , "Other percentage-based IBI percent"                             , "%"                                      , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_percent_maxvalue"             , "Other percentage-based IBI maximum value"                       , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_percent_tax_fed"              , "Other percentage-based IBI federal taxable"                     , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_percent_tax_sta"              , "Other percentage-based IBI state taxable"                       , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_percent_deprbas_fed"          , "Other percentage-based IBI reduces federal depreciation basis"  , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "ibi_oth_percent_deprbas_sta"          , "Other percentage-based IBI reduces state depreciation basis"    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_fed_amount"                       , "Federal CBI amount"                                             , "$/Watt"                                 , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_fed_maxvalue"                     , "Federal CBI maximum"                                            , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_fed_tax_fed"                      , "Federal CBI federal taxable"                                    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_fed_tax_sta"                      , "Federal CBI state taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_fed_deprbas_fed"                  , "Federal CBI reduces federal depreciation basis"                 , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_fed_deprbas_sta"                  , "Federal CBI reduces state depreciation basis"                   , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_sta_amount"                       , "State CBI amount"                                               , "$/Watt"                                 , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_sta_maxvalue"                     , "State CBI maximum"                                              , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_sta_tax_fed"                      , "State CBI federal taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_sta_tax_sta"                      , "State CBI state taxable"                                        , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_sta_deprbas_fed"                  , "State CBI reduces federal depreciation basis"                   , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_sta_deprbas_sta"                  , "State CBI reduces state depreciation basis"                     , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_uti_amount"                       , "Utility CBI amount"                                             , "$/Watt"                                 , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_uti_maxvalue"                     , "Utility CBI maximum"                                            , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_uti_tax_fed"                      , "Utility CBI federal taxable"                                    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_uti_tax_sta"                      , "Utility CBI state taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_uti_deprbas_fed"                  , "Utility CBI reduces federal depreciation basis"                 , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_uti_deprbas_sta"                  , "Utility CBI reduces state depreciation basis"                   , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_oth_amount"                       , "Other CBI amount"                                               , "$/Watt"                                 , ""                                      , "Payment Incentives"   , "?=0.0"          , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_oth_maxvalue"                     , "Other CBI maximum"                                              , "$"                                      , ""                                      , "Payment Incentives"   , "?=1e99"         , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_oth_tax_fed"                      , "Other CBI federal taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_oth_tax_sta"                      , "Other CBI state taxable"                                        , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_oth_deprbas_fed"                  , "Other CBI reduces federal depreciation basis"                   , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "cbi_oth_deprbas_sta"                  , "Other CBI reduces state depreciation basis"                     , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=0"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "pbi_fed_amount"                       , "Federal PBI amount"                                             , "$/kWh"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_fed_term"                         , "Federal PBI term"                                               , "years"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_fed_escal"                        , "Federal PBI escalation"                                         , "%"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_fed_tax_fed"                      , "Federal PBI federal taxable"                                    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_fed_tax_sta"                      , "Federal PBI state taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "pbi_sta_amount"                       , "State PBI amount"                                               , "$/kWh"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_sta_term"                         , "State PBI term"                                                 , "years"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_sta_escal"                        , "State PBI escalation"                                           , "%"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_sta_tax_fed"                      , "State PBI federal taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_sta_tax_sta"                      , "State PBI state taxable"                                        , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "pbi_uti_amount"                       , "Utility PBI amount"                                             , "$/kWh"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_uti_term"                         , "Utility PBI term"                                               , "years"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_uti_escal"                        , "Utility PBI escalation"                                         , "%"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_uti_tax_fed"                      , "Utility PBI federal taxable"                                    , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_uti_tax_sta"                      , "Utility PBI state taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "pbi_oth_amount"                       , "Other PBI amount"                                               , "$/kWh"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_oth_term"                         , "Other PBI term"                                                 , "years"                                  , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_oth_escal"                        , "Other PBI escalation"                                           , "%"                                      , ""                                      , "Payment Incentives"   , "?=0"            , ""                      , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_oth_tax_fed"                      , "Other PBI federal taxable"                                      , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_INPUT,SSC_NUMBER  , "pbi_oth_tax_sta"                      , "Other PBI state taxable"                                        , "0/1"                                    , ""                                      , "Payment Incentives"   , "?=1"            , "BOOLEAN"               , ""),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "cbi_total_fed",                          "Federal CBI income",         "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "cbi_total_sta",                          "State CBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "cbi_total_oth",                          "Other CBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "cbi_total_uti",                          "Utility CBI income",         "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "cbi_total",                              "Total CBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "cbi_statax_total",                       "State taxable CBI income",   "$",            "",                      "Cash Flow Incentives",      "",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "cbi_fedtax_total",                       "Federal taxable CBI income", "$",            "",                      "Cash Flow Incentives",      "",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ibi_total_fed",                          "Federal IBI income",         "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ibi_total_sta",                          "State IBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ibi_total_oth",                          "Other IBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ibi_total_uti",                          "Utility IBI income",         "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ibi_total",                              "Total IBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ibi_statax_total",                       "State taxable IBI income",   "$",            "",                      "Cash Flow Incentives",      "",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ibi_fedtax_total",                       "Federal taxable IBI income", "$",            "",                      "Cash Flow Incentives",      "",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_pbi_total_fed",                       "Federal PBI income",         "$",            "",                      "Cash Flow Incentives",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_pbi_total_sta",                       "State PBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_pbi_total_oth",                       "Other PBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_pbi_total_uti",                       "Utility PBI income",         "$",            "",                      "Cash Flow Incentives",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_pbi_total",                           "Total PBI income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_pbi_statax_total",                    "State taxable PBI income",   "$",            "",                      "Cash Flow Incentives",      "",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_pbi_fedtax_total",                    "Federal taxable PBI income", "$",            "",                      "Cash Flow Incentives",      "",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "itc_total_fed",                          "Federal ITC income",         "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "itc_total_sta",                          "State ITC income",           "$",            "",                      "Cash Flow Incentives",      "*",                     "",                                      "" ),
var_info(SSC_OUTPUT,        SSC_NUMBER,    "itc_total",							  "Total ITC income",                 "$",            "",                      "Cash Flow Incentives",      "*",                     "",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_ptc_fed",                             "Federal PTC income",                 "$",            "",                      "Cash Flow Incentives",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT,       SSC_ARRAY,      "cf_ptc_sta",                             "State PTC income",                   "$",            "",                      "Cash Flow Incentives",      "*",                     "LENGTH_EQUAL=cf_length",                "" ),
var_info(SSC_OUTPUT, 	SSC_ARRAY, 	    "cf_ptc_total", 	                         "Total PTC", 	            "$", 	            "", 	                "Cash Flow Incentives", 	        "", 	"LENGTH_EQUAL=cf_length", 	""),
var_info_invalid() ]

var_info vtab_ppa_inout_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_NUMBER,		"ppa_soln_mode",                          "PPA solution mode",                              "0/1",   "0=solve ppa,1=specify ppa", "Revenue",         "?=0",                     "INTEGER,MIN=0,MAX=1",            "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ppa_soln_tolerance",                     "PPA solution tolerance",                         "",                 "", "Revenue", "?=1e-5", "", "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ppa_soln_min",                           "PPA solution minimum ppa",                       "cents/kWh",        "", "Revenue", "?=0", "", "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"ppa_soln_max",                           "PPA solution maximum ppa",                       "cents/kWh",        "", "Revenue",         "?=100",                     "",            "" ),
var_info(SSC_INPUT,        SSC_NUMBER,		"ppa_soln_max_iterations",                "PPA solution maximum number of iterations",      "",                 "", "Revenue",         "?=100",                     "INTEGER,MIN=1",            "" ),
var_info(SSC_INPUT,        SSC_ARRAY,      "ppa_price_input",			              "PPA price in first year",			            "$/kWh",	        "",	"Revenue",			 "*",         "",      			"" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ppa_escalation",                         "PPA escalation rate",                            "%/year",           "", "Revenue", "?=0", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lppa_real",                              "Levelized PPA price (real)",                         "cents/kWh",               "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lppa_nom",                               "Levelized PPA price (nominal)",                      "cents/kWh",               "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ppa",                                    "PPA price (Year 1)",                        "cents/kWh",               "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "ppa_escalation",                         "PPA price escalation",                      "%/year",              "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "npv_ppa_revenue",                        "Present value of PPA revenue",              "$",                   "", "Metrics", "*", "", "" ),
var_info_invalid() ]

var_info vtab_financial_metrics_array: var_info[None] = [
var_info(SSC_OUTPUT,       SSC_NUMBER,     "debt_fraction",                          "Debt percent",                             "%", "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "flip_target_year",                       "Target year to meet IRR",                   "",                    "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "flip_target_irr",                        "IRR target",                                "%",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "flip_actual_year",                       "Year target IRR was achieved",              "year",                    "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "flip_actual_irr",                        "IRR in target year",                        "%",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lcoe_real",                              "Levelized cost (real)",                               "cents/kWh",               "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lcoe_nom",                               "Levelized cost (nominal)",                            "cents/kWh",               "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "npv_energy_nom",                         "Present value of annual energy (nominal)",     "kWh",                 "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "npv_energy_real",                        "Present value of annual energy (real)",     "kWh",                 "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "present_value_oandm",                    "Present value of O&M",				       "$",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "present_value_oandm_nonfuel",            "Present value of non-fuel O&M",         "$",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "present_value_fuel",                     "Present value of fuel O&M",             "$",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "present_value_insandproptax",            "Present value of insurance and prop tax",   "$",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lcoptc_fed_real",                        "Levelized federal PTC (real)",              "cents/kWh",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lcoptc_fed_nom",                         "Levelized federal PTC (nominal)",           "cents/kWh",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lcoptc_sta_real",                        "Levelized state PTC (real)",                "cents/kWh",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "lcoptc_sta_nom",                         "Levelized state PTC (nominal)",             "cents/kWh",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "wacc",                                   "Weighted average cost of capital (WACC)",   "$",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "effective_tax_rate",                     "Effective tax rate",                        "%",                   "", "Metrics", "*", "", "" ),
var_info(SSC_OUTPUT,       SSC_NUMBER,     "analysis_period_irr",                    "IRR at end of analysis period",             "%",                   "", "Metrics", "*", "", "" ),
var_info_invalid()
]

var_info vtab_debt_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_NUMBER,     "term_tenor",                             "Term financing period",				                            "years", "",				      "Financial Parameters",             "?=10",					"INTEGER,MIN=0",      			"" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "term_int_rate",                          "Term financing interest rate",		                            "%",	 "",					  "Financial Parameters",             "?=8.5",                   "MIN=0,MAX=100",      			"" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "dscr",						              "Debt service coverage ratio",		                            "",	     "",				      "Financial Parameters",             "?=1.5",					"MIN=0",      			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "dscr_reserve_months",		              "Debt service reserve account",		                            "months P&I","",			      "Financial Parameters",             "?=6",					    "MIN=0",      			        "" ),
var_info(SSC_INPUT, SSC_NUMBER, "debt_percent", "Debt percent", "%", "", "Financial Parameters", "?=50", "MIN=0,MAX=100", "" ),
var_info(SSC_INPUT, SSC_NUMBER, "debt_option", "Debt option", "0/1", "0=debt percent,1=dscr", "Financial Parameters", "?=1", "INTEGER,MIN=0,MAX=1", "" ),
var_info(SSC_INPUT, SSC_NUMBER, "payment_option", "Debt repayment option", "0/1", "0=Equal payments (standard amortization),1=Fixed principal declining interest", "Financial Parameters", "?=0", "INTEGER,MIN=0,MAX=1", "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "cost_debt_closing",		              "Debt closing cost",                                              "$",                 "",       "Financial Parameters",        "?=250000",         "MIN=0",              "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "cost_debt_fee",		                  "Debt closing fee (% of total debt amount)",                      "%",                 "",       "Financial Parameters",        "?=1.5",            "MIN=0",              "" ),
var_info(SSC_INPUT, SSC_NUMBER, "months_working_reserve", "Working capital reserve months of operating costs", "months", "", "Financial Parameters", "?=6", "MIN=0", "" ),
var_info(SSC_INPUT, SSC_NUMBER, "months_receivables_reserve", "Receivables reserve months of PPA revenue", "months", "", "Financial Parameters", "?=0", "MIN=0", "" ),
var_info(SSC_INPUT, SSC_NUMBER, "cost_other_financing", "Other financing cost", "$", "", "Financial Parameters", "?=150000", "MIN=0", "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "flip_target_percent",			          "After-tax IRR target",		"%",	 "",					  "Revenue",             "?=11",					  "MIN=0,MAX=100",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "flip_target_year",		                  "IRR target year",				"Year",		 "",					  "Revenue",             "?=11",					  "MIN=1",     			        "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "pbi_fed_for_ds",                         "Federal PBI available for debt service",     "0/1",      "",                      "Payment Incentives",      "?=0",                       "BOOLEAN",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "pbi_sta_for_ds",                         "State PBI available for debt service",     "0/1",      "",                      "Payment Incentives",      "?=0",                       "BOOLEAN",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "pbi_uti_for_ds",                         "Utility PBI available for debt service",     "0/1",      "",                      "Payment Incentives",      "?=0",                       "BOOLEAN",                                         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "pbi_oth_for_ds",                         "Other PBI available for debt service",     "0/1",      "",                      "Payment Incentives",      "?=0",                       "BOOLEAN",                                         "" ),
var_info_invalid()
]

var_info vtab_adjustment_factors_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "adjust:constant"                      , "Constant loss adjustment"                                       , "%"                                      , ""                                      , "Adjustment Factors"   , "*"              , "MAX=100"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "adjust:hourly"                        , "Hourly Adjustment Factors"                                      , "%"                                      , ""                                      , "Adjustment Factors"   , "?"              , "LENGTH=8760"           , ""),
var_info(SSC_INPUT,SSC_MATRIX  , "adjust:periods"                       , "Period-based Adjustment Factors"                                , "%"                                      , "n x 3 matrix [ start, end, loss ]"     , "Adjustment Factors"   , "?"              , "COLS=3"                , ""),
var_info_invalid() ]

var_info vtab_dc_adjustment_factors_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "dc_adjust:constant"                   , "DC Constant loss adjustment"                                    , "%"                                      , ""                                      , "Adjustment Factors"   , "*"               , "MAX=100"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "dc_adjust:hourly"                     , "DC Hourly Adjustment Factors"                                   , "%"                                      , ""                                      , "Adjustment Factors"   , "?"               , "LENGTH=8760"           , ""),
var_info(SSC_INPUT,SSC_MATRIX  , "dc_adjust:periods"                    , "DC Period-based Adjustment Factors"                             , "%"                                      , "n x 3 matrix [ start, end, loss ]"     , "Adjustment Factors"   , "?"               , "COLS=3"                , ""),
var_info_invalid() ]

var_info vtab_sf_adjustment_factors_array: var_info[None] = [
var_info(SSC_INPUT,SSC_NUMBER  , "sf_adjust:constant"                   , "SF Constant loss adjustment"                                    , "%"                                      , ""                                      , "Adjustment Factors"   , "*"              , "MAX=100"               , ""),
var_info(SSC_INPUT,SSC_ARRAY   , "sf_adjust:hourly"                     , "SF Hourly Adjustment Factors"                                   , "%"                                      , ""                                      , "Adjustment Factors"   , "?"              , "LENGTH=8760"           , ""),
var_info(SSC_INPUT,SSC_MATRIX  , "sf_adjust:periods"                    , "SF Period-based Adjustment Factors"                             , "%"                                      , "n x 3 matrix [ start, end, loss ]"     , "Adjustment Factors"   , "?"              , "COLS=3"                , ""),
var_info_invalid() ]

var_info vtab_financial_capacity_payments_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_NUMBER,      "cp_capacity_payment_esc",             "Capacity payment escalation",                      "%/year",    "",                               "Capacity Payments",      "*",                   "",                      "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "cp_capacity_payment_type",            "Capacity payment type",                            "",          "0=Energy basis,1=Fixed amount",  "Capacity Payments",      "*",                   "INTEGER,MIN=0,MAX=1",   "" ),
var_info(SSC_INPUT,        SSC_ARRAY,       "cp_capacity_payment_amount",          "Capacity payment amount",                          "$ or $/MW", "",                               "Capacity Payments",      "*",                   "",                      "" ),
var_info(SSC_INPUT,        SSC_ARRAY,       "cp_capacity_credit_percent",          "Capacity credit (eligible portion of nameplate)",  "%",         "",                               "Capacity Payments",      "cp_capacity_payment_type=0",   "",                      "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "cp_system_nameplate",                 "System nameplate",                                 "MW",        "",                               "Capacity Payments",      "cp_capacity_payment_type=0",   "MIN=0",                 "" ),
var_info(SSC_INPUT,        SSC_NUMBER,      "cp_battery_nameplate",                "Battery nameplate",                                "MW",        "",                               "Capacity Payments",      "cp_capacity_payment_type=0",   "MIN=0",                 "" ),
var_info_invalid() ]

var_info vtab_grid_curtailment_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_ARRAY,       "grid_curtailment",              "Grid curtailment as energy delivery limit (first year)",              "MW",    "",                                     "GridLimits",      "?",                     "",                "" ),
var_info_invalid() ]

var_info vtab_technology_outputs_array: var_info[None] = [
var_info(SSC_OUTPUT, SSC_ARRAY , "gen"                                  , "System power generated"                                         , "kW"                                     , ""                                      , "Time Series"          , "*"              , ""                      , ""),
var_info_invalid() ]

var_info vtab_p50p90_array: var_info[None] = [
var_info(SSC_INPUT, SSC_NUMBER ,  "total_uncert"                 , "Total uncertainty in energy production as percent of annual energy", "%"                                   , ""                                      , "Uncertainty"          , ""              , "MIN=0,MAX=100"         , ""),
var_info(SSC_OUTPUT, SSC_NUMBER , "annual_energy_p75"            , "Annual energy with 75% probability of exceedance"                  , "kWh"                                 , ""                                      , "Uncertainty"          , ""              , ""                      , ""),
var_info(SSC_OUTPUT, SSC_NUMBER , "annual_energy_p90"            , "Annual energy with 90% probability of exceedance"                  , "kWh"                                 , ""                                      , "Uncertainty"          , ""              , ""                      , ""),
var_info(SSC_OUTPUT, SSC_NUMBER , "annual_energy_p95"            , "Annual energy with 95% probability of exceedance"                  , "kWh"                                 , ""                                      , "Uncertainty"          , ""              , ""                      , ""),
var_info_invalid() ]

def calculate_p50p90(cm: compute_module) -> bool:
    if not cm.is_assigned("total_uncert") or not cm.is_assigned("annual_energy"):
        return False
    aep = cm.as_double("annual_energy")
    uncert = cm.as_double("total_uncert") / 100.0
    cm.assign("annual_energy_p75", aep * (-0.67 * uncert + 1))
    cm.assign("annual_energy_p90", aep * (-1.28 * uncert + 1))
    cm.assign("annual_energy_p95", aep * (-1.64 * uncert + 1))
    return True

var_info vtab_forecast_price_signal_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_NUMBER,     "forecast_price_signal_model",					"Forecast price signal model selected",   "0/1",   "0=PPA based,1=Merchant Plant",    "Price Signal",  "?=0",	"INTEGER,MIN=0,MAX=1",      "" ),
var_info(SSC_INPUT,        SSC_ARRAY,      "ppa_price_input",		                        "PPA Price Input",	                                        "",      "",                  "Price Signal", "forecast_price_signal_model=0&en_batt=1&batt_meter_position=1"   "",          "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ppa_multiplier_model",                         "PPA multiplier model",                                    "0/1",    "0=diurnal,1=timestep","Price Signal", "forecast_price_signal_model=0&en_batt=1&batt_meter_position=1",                                                  "INTEGER,MIN=0", "" ),
var_info(SSC_INPUT,        SSC_ARRAY,      "dispatch_factors_ts",                          "Dispatch payment factor time step",                        "",      "",                  "Price Signal", "forecast_price_signal_model=0&en_batt=1&batt_meter_position=1&ppa_multiplier_model=1", "", "" ),
var_info(SSC_INPUT,        SSC_ARRAY,      "dispatch_tod_factors",		                    "TOD factors for periods 1-9",	                            "",      "",                  "Price Signal", "en_batt=1&batt_meter_position=1&forecast_price_signal_model=0&ppa_multiplier_model=0"   "",          "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "dispatch_sched_weekday",                       "Diurnal weekday TOD periods",                              "1..9",  "12 x 24 matrix",    "Price Signal", "en_batt=1&batt_meter_position=1&forecast_price_signal_model=0&ppa_multiplier_model=0",  "",          "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "dispatch_sched_weekend",                       "Diurnal weekend TOD periods",                              "1..9",  "12 x 24 matrix",    "Price Signal", "en_batt=1&batt_meter_position=1&forecast_price_signal_model=0&ppa_multiplier_model=0",  "",          "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "mp_enable_energy_market_revenue",				"Enable energy market revenue",   "0/1",   "0=false,1=true",    "Price Signal",  "en_batt=1&batt_meter_position=1&forecast_price_signal_model=1",	"INTEGER,MIN=0,MAX=1",      "" ),
var_info(SSC_INPUT,		SSC_MATRIX,		"mp_energy_market_revenue",						"Energy market revenue input", " [MW, $/MW]", "", "Price Signal","en_batt=1&batt_meter_position=1&forecast_price_signal_model=1",  ""),
var_info(SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv1",							"Enable ancillary services 1 revenue",   "0/1",   "",    "Price Signal",  "forecast_price_signal_model=1",	"INTEGER,MIN=0,MAX=1",      "" ),
var_info(SSC_INPUT,		SSC_MATRIX,		"mp_ancserv1_revenue",							"Ancillary services 1 revenue input", " [MW, $/MW]", "", "Price Signal", "en_batt=1&batt_meter_position=1&forecast_price_signal_model=1", "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv2",							"Enable ancillary services 2 revenue",   "0/1",   "",    "Price Signal",  "forecast_price_signal_model=1",	"INTEGER,MIN=0,MAX=1",      "" ),
var_info(SSC_INPUT,		SSC_MATRIX,		"mp_ancserv2_revenue",							"Ancillary services 2 revenue input", " [MW, $/MW]", "", "Price Signal", "en_batt=1&batt_meter_position=1&forecast_price_signal_model=1", ""),
var_info(SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv3",							"Enable ancillary services 3 revenue",   "0/1",   "",    "Price Signal",  "forecast_price_signal_model=1",	"INTEGER,MIN=0,MAX=1",      "" ),
var_info(SSC_INPUT,		SSC_MATRIX,		"mp_ancserv3_revenue",							"Ancillary services 3 revenue input", " [MW, $/MW]", "","Price Signal", "en_batt=1&batt_meter_position=1&forecast_price_signal_model=1", "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv4",							"Enable ancillary services 4 revenue",   "0/1",   "",    "Price Signal",  "forecast_price_signal_model=1",	"INTEGER,MIN=0,MAX=1",      "" ),
var_info(SSC_INPUT,		SSC_MATRIX,		"mp_ancserv4_revenue",							"Ancillary services 4 revenue input", " [MW, $/MW]", "","Price Signal", "en_batt=1&batt_meter_position=1&forecast_price_signal_model=1", ""),
var_info_invalid() ]

struct forecast_price_signal:
    var vartab: var_table
    var m_forecast_price: List[ssc_number_t]
    var m_error: String

    def __init__(inout self, vt: var_table):
        self.vartab = vt
        self.m_forecast_price = List[ssc_number_t]()
        self.m_error = String("")

    def setup(inout self, nsteps: size_t = 8760) -> bool:
        var step_per_hour: size_t = 1
        if nsteps > 8760:
            step_per_hour = nsteps / 8760
        if step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != nsteps:
            self.m_error = util.format("The requested number of timesteps must be a multiple of 8760. Instead requested timesteps is %d.", int(nsteps))
            return False
        self.m_forecast_price.reserve(nsteps)
        for i in range(nsteps):
            self.m_forecast_price.push_back(0.0)
        var forecast_price_signal_model: int = self.vartab.as_integer("forecast_price_signal_model")
        if forecast_price_signal_model == 1:
            var en_mp_energy_market: bool = (self.vartab.as_integer("mp_enable_energy_market_revenue") == 1)
            var en_mp_ancserv1: bool = (self.vartab.as_integer("mp_enable_ancserv1") == 1)
            var en_mp_ancserv2: bool = (self.vartab.as_integer("mp_enable_ancserv2") == 1)
            var en_mp_ancserv3: bool = (self.vartab.as_integer("mp_enable_ancserv3") == 1)
            var en_mp_ancserv4: bool = (self.vartab.as_integer("mp_enable_ancserv4") == 1)
            var nrows: size_t = 0
            var ncols: size_t = 0
            var mp_energy_market_revenue_mat: util.matrix_t[float64] = util.matrix_t[float64](1, 2, 0.0)
            if en_mp_energy_market:
                var mp_energy_market_revenue_in: Pointer[ssc_number_t] = self.vartab.as_matrix("mp_energy_market_revenue", &nrows, &ncols)
                if ncols != 2:
                    self.m_error = util.format("The energy market revenue table must have 2 columns. Instead it has %d columns.", int(ncols))
                    return False
                mp_energy_market_revenue_mat.resize(nrows, ncols)
                mp_energy_market_revenue_mat.assign(mp_energy_market_revenue_in, nrows, ncols)
            var mp_ancserv_1_revenue_mat: util.matrix_t[float64] = util.matrix_t[float64](1, 2, 0.0)
            if en_mp_ancserv1:
                var mp_ancserv1_revenue_in: Pointer[ssc_number_t] = self.vartab.as_matrix("mp_ancserv1_revenue", &nrows, &ncols)
                if ncols != 2:
                    self.m_error = util.format("The ancillary services revenue 1 table must have 2 columns. Instead it has %d columns.", int(ncols))
                    return False
                mp_ancserv_1_revenue_mat.resize(nrows, ncols)
                mp_ancserv_1_revenue_mat.assign(mp_ancserv1_revenue_in, nrows, ncols)
            var mp_ancserv_2_revenue_mat: util.matrix_t[float64] = util.matrix_t[float64](1, 2, 0.0)
            if en_mp_ancserv2:
                var mp_ancserv2_revenue_in: Pointer[ssc_number_t] = self.vartab.as_matrix("mp_ancserv2_revenue", &nrows, &ncols)
                if ncols != 2:
                    self.m_error = util.format("The ancillary services revenue 2 table must have 2 columns. Instead it has %d columns.", int(ncols))
                    return False
                mp_ancserv_2_revenue_mat.resize(nrows, ncols)
                mp_ancserv_2_revenue_mat.assign(mp_ancserv2_revenue_in, nrows, ncols)
            var mp_ancserv_3_revenue_mat: util.matrix_t[float64] = util.matrix_t[float64](1, 2, 0.0)
            if en_mp_ancserv3:
                var mp_ancserv3_revenue_in: Pointer[ssc_number_t] = self.vartab.as_matrix("mp_ancserv3_revenue", &nrows, &ncols)
                if ncols != 2:
                    self.m_error = util.format("The ancillary services revenue 3 table must have 2 columns. Instead it has %d columns.", int(ncols))
                    return False
                mp_ancserv_3_revenue_mat.resize(nrows, ncols)
                mp_ancserv_3_revenue_mat.assign(mp_ancserv3_revenue_in, nrows, ncols)
            var mp_ancserv_4_revenue_mat: util.matrix_t[float64] = util.matrix_t[float64](1, 2, 0.0)
            if en_mp_ancserv4:
                var mp_ancserv4_revenue_in: Pointer[ssc_number_t] = self.vartab.as_matrix("mp_ancserv4_revenue", &nrows, &ncols)
                if ncols != 2:
                    self.m_error = util.format("The ancillary services revenue 4 table must have 2 columns. Instead it has %d columns.", int(ncols))
                    return False
                mp_ancserv_4_revenue_mat.resize(nrows, ncols)
                mp_ancserv_4_revenue_mat.assign(mp_ancserv4_revenue_in, nrows, ncols)
            var nyears: int = self.vartab.as_integer("analysis_period")
            var as_revenue: List[float64] = List[float64]()
            var as_revenue_extrapolated: List[float64] = List[float64]()
            as_revenue_extrapolated.resize(nsteps, 0.0)
            var n_marketrevenue_per_year: size_t = mp_energy_market_revenue_mat.nrows() / size_t(nyears)
            as_revenue.clear()
            as_revenue.reserve(n_marketrevenue_per_year)
            for j in range(n_marketrevenue_per_year):
                as_revenue.push_back(mp_energy_market_revenue_mat.at(j, 0) * mp_energy_market_revenue_mat.at(j, 1) / float64(step_per_hour))
            as_revenue_extrapolated = extrapolate_timeseries(as_revenue, step_per_hour)
            for i in range(self.m_forecast_price.size):
                self.m_forecast_price[i] = self.m_forecast_price[i] + as_revenue_extrapolated[i]
            var n_ancserv_1_revenue_per_year: size_t = mp_ancserv_1_revenue_mat.nrows() / size_t(nyears)
            as_revenue.clear()
            as_revenue.reserve(n_ancserv_1_revenue_per_year)
            for j in range(n_ancserv_1_revenue_per_year):
                as_revenue.push_back(mp_ancserv_1_revenue_mat.at(j, 0) * mp_ancserv_1_revenue_mat.at(j, 1) / float64(step_per_hour))
            as_revenue_extrapolated = extrapolate_timeseries(as_revenue, step_per_hour)
            for i in range(self.m_forecast_price.size):
                self.m_forecast_price[i] = self.m_forecast_price[i] + as_revenue_extrapolated[i]
            var n_ancserv_2_revenue_per_year: size_t = mp_ancserv_2_revenue_mat.nrows() / size_t(nyears)
            as_revenue.clear()
            as_revenue.reserve(n_ancserv_2_revenue_per_year)
            for j in range(n_ancserv_2_revenue_per_year):
                as_revenue.push_back(mp_ancserv_2_revenue_mat.at(j, 0) * mp_ancserv_2_revenue_mat.at(j, 1) / float64(step_per_hour))
            as_revenue_extrapolated = extrapolate_timeseries(as_revenue, step_per_hour)
            for i in range(self.m_forecast_price.size):
                self.m_forecast_price[i] = self.m_forecast_price[i] + as_revenue_extrapolated[i]
            var n_ancserv_3_revenue_per_year: size_t = mp_ancserv_3_revenue_mat.nrows() / size_t(nyears)
            as_revenue.clear()
            as_revenue.reserve(n_ancserv_3_revenue_per_year)
            for j in range(n_ancserv_3_revenue_per_year):
                as_revenue.push_back(mp_ancserv_3_revenue_mat.at(j, 0) * mp_ancserv_3_revenue_mat.at(j, 1) / float64(step_per_hour))
            as_revenue_extrapolated = extrapolate_timeseries(as_revenue, step_per_hour)
            for i in range(self.m_forecast_price.size):
                self.m_forecast_price[i] = self.m_forecast_price[i] + as_revenue_extrapolated[i]
            var n_ancserv_4_revenue_per_year: size_t = mp_ancserv_4_revenue_mat.nrows() / size_t(nyears)
            as_revenue.clear()
            as_revenue.reserve(n_ancserv_4_revenue_per_year)
            for j in range(n_ancserv_4_revenue_per_year):
                as_revenue.push_back(mp_ancserv_4_revenue_mat.at(j, 0) * mp_ancserv_4_revenue_mat.at(j, 1) / float64(step_per_hour))
            as_revenue_extrapolated = extrapolate_timeseries(as_revenue, step_per_hour)
            for i in range(self.m_forecast_price.size):
                self.m_forecast_price[i] = self.m_forecast_price[i] + as_revenue_extrapolated[i]
        else:
            var ppa_multiplier_mode: int = self.vartab.as_integer("ppa_multiplier_model")
            var count_ppa_price_input: size_t = 0
            var ppa_price: Pointer[ssc_number_t] = self.vartab.as_array("ppa_price_input", &count_ppa_price_input)
            if count_ppa_price_input < 1:
                self.m_error = util.format("The ppa price array needs at least one entry. Input had less than one input.")
                return False
            if ppa_multiplier_mode == 0:
                self.m_forecast_price = flatten_diurnal(
                        self.vartab.as_matrix_unsigned_long("dispatch_sched_weekday"),
                        self.vartab.as_matrix_unsigned_long("dispatch_sched_weekend"),
                    step_per_hour,
                        self.vartab.as_vector_double("dispatch_tod_factors"), ppa_price[0] / float64(step_per_hour))
            else:
                var factors: List[float64] = self.vartab.as_vector_double("dispatch_factors_ts")
                self.m_forecast_price = extrapolate_timeseries(factors, step_per_hour, ppa_price[0] / float64(step_per_hour))
        return True

    def __call__(inout self, time: size_t) -> ssc_number_t:
        if time < self.m_forecast_price.size:
            return self.m_forecast_price[time]
        else:
            return 0.0

    def error(inout self) -> String:
        return self.m_error

    def forecast_price(inout self) -> List[ssc_number_t]:
        return self.m_forecast_price

var_info vtab_resilience_outputs_array: var_info[None] = [
var_info(SSC_OUTPUT, SSC_ARRAY  , "resilience_hrs"                       , "Hours of autonomy during outage at each timestep for resilience"       , "hr"                                     , ""                                                         , "Resilience"          , ""               , ""                      , ""),
var_info(SSC_OUTPUT, SSC_NUMBER , "resilience_hrs_min"                   , "Min hours of autonomy for resilience "                                 , "hr"                                     , ""                                                         , "Resilience"          , ""               , "MIN=0"                 , ""),
var_info(SSC_OUTPUT, SSC_NUMBER , "resilience_hrs_max"                   , "Max hours of autonomy for resilience"                                  , "hr"                                     , ""                                                         , "Resilience"          , ""               , "MIN=0"                 , ""),
var_info(SSC_OUTPUT, SSC_NUMBER , "resilience_hrs_avg"                   , "Avg hours of autonomy for resilience"                                  , "hr"                                     , ""                                                         , "Resilience"          , ""               , "MIN=0"                 , ""),
var_info(SSC_OUTPUT, SSC_ARRAY  , "outage_durations"                     , "List of autonomous hours for resilience from min to max"               , "hr"                                     , "Hours from resilience_hrs_min to resilience_hrs_max"      , "Resilience"          , ""               , ""                      , ""),
var_info(SSC_OUTPUT, SSC_ARRAY  , "pdf_of_surviving"                     , "Probabilities of autonomous hours for resilience "                     , ""                                       , "Hours from resilience_hrs_min to resilience_hrs_max"      , "Resilience"          , ""               , "MIN=0,MAX=1"           , ""),
var_info(SSC_OUTPUT, SSC_ARRAY  , "cdf_of_surviving"                     , "Cumulative probabilities of autonomous hours for resilience"           , ""                                       , "Prob surviving at least x hrs; hrs from min to max"       , "Resilience"          , ""               , "MIN=0,MAX=1"           , ""),
var_info(SSC_OUTPUT, SSC_ARRAY  , "survival_function"                    , "Survival function of autonomous hours for resilience"                  , ""                                       , "Prob surviving greater than x hours; hrs from min to max" , "Resilience"          , ""               , "MIN=0,MAX=1"           , ""),
var_info(SSC_OUTPUT, SSC_NUMBER , "avg_critical_load"                    , "Average critical load met for resilience"                              , "kWh"                                    , ""                                                         , "Resilience"          , ""               , "MIN=0"                 , ""),
var_info_invalid()
]

def calculate_resilience_outputs(cm: compute_module, resilience: resilience_runner):
    if not cm or not resilience:
        return
    var avg_hours_survived: float64 = resilience.compute_metrics()
    var outage_durations: List[float64] = resilience.get_outage_duration_hrs()
    cm.assign("resilience_hrs", resilience.get_hours_survived())
    cm.assign("resilience_hrs_min", int(outage_durations[0]))
    cm.assign("resilience_hrs_max", int(outage_durations.back()))
    cm.assign("resilience_hrs_avg", avg_hours_survived)
    cm.assign("outage_durations", outage_durations)
    cm.assign("pdf_of_surviving", resilience.get_probs_of_surviving())
    cm.assign("cdf_of_surviving", resilience.get_cdf_of_surviving())
    cm.assign("survival_function", resilience.get_survival_function())
    cm.assign("avg_critical_load", resilience.get_avg_crit_load_kwh())

var_info vtab_utility_rate_common_array: var_info[None] = [
var_info(SSC_INPUT,        SSC_ARRAY,      "rate_escalation",          "Annual electricity rate escalation",   "%/year",   "",                      "Electricity Rates",       "?=0",              "",                             "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_metering_option",       "Metering options",                     "0=net energy metering,1=net energy metering with $ credits,2=net billing,3=net billing with carryover to next month,4=buy all - sell all", "Net metering monthly excess", "Electricity Rates", "?=0", "INTEGER,MIN=0,MAX=4", "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_nm_yearend_sell_rate",  "Net metering true-up credit sell rate", "$/kWh",    "",                     "Electricity Rates",        "?=0.0",            "",                             "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_nm_credit_month",       "Month of year end payout (true-up)",    "mn",       "",                     "Electricity Rates",        "?=11",             "INTEGER,MIN=0,MAX=11",         "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_nm_credit_rollover",    "Apply net metering true-up credits to future bills", "0/1", "",           "Electricity Rates",        "?=0",              "INTEGER,MIN=0,MAX=1",          "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_monthly_fixed_charge",  "Monthly fixed charge",                 "$",        "",                     "Electricity Rates",        "?=0.0",            "",                             "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_sell_eq_buy",           "Set sell rate equal to buy rate",      "0/1",      "Optional override",    "Electricity Rates",        "?=0",              "BOOLEAN",                      "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_monthly_min_charge",    "Monthly minimum charge",               "$",        "",                     "Electricity Rates",        "?=0.0",            "",                             "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_annual_min_charge",     "Annual minimum charge",                "$",        "",                     "Electricity Rates",        "?=0.0",            "",                             "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_en_ts_sell_rate",       "Enable time step sell rates",          "0/1",      "",                     "Electricity Rates",        "?=0",              "BOOLEAN",                      "" ),
var_info(SSC_INPUT,        SSC_ARRAY,      "ur_ts_sell_rate",          "Time step sell rates",                 "0/1",      "",                     "Electricity Rates",        "",                 "",                             "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_en_ts_buy_rate",        "Enable time step buy rates",           "0/1",      "",                     "Electricity Rates",        "?=0",              "BOOLEAN",                      "" ),
var_info(SSC_INPUT,        SSC_ARRAY,      "ur_ts_buy_rate",           "Time step buy rates",                  "0/1",      "",                     "Electricity Rates",        "",                 "",                             "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "ur_ec_sched_weekday",      "Energy charge weekday schedule",       "",         "12x24",                "Electricity Rates",        "",                 "",                             "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "ur_ec_sched_weekend",      "Energy charge weekend schedule",       "",         "12x24",                "Electricity Rates",        "",                 "",                             "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "ur_ec_tou_mat",            "Energy rates table",                   "",         "",                     "Electricity Rates",        "",                 "",                             "" ),
var_info(SSC_INPUT,        SSC_NUMBER,     "ur_dc_enable",             "Enable demand charge",                 "0/1",      "",                     "Electricity Rates",        "?=0",              "BOOLEAN",                      "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "ur_dc_sched_weekday",      "Demand charge weekday schedule",       "",         "12x24",                "Electricity Rates",        "",                 "",                             "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "ur_dc_sched_weekend",      "Demand charge weekend schedule",       "",         "12x24",                "Electricity Rates",        "",                 "",                             "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "ur_dc_tou_mat",            "Demand rates (TOU) table",             "",         "",                     "Electricity Rates",        "ur_dc_enable=1",   "",                             "" ),
var_info(SSC_INPUT,        SSC_MATRIX,     "ur_dc_flat_mat",           "Demand rates (flat) table",            "",         "",                     "Electricity Rates",        "ur_dc_enable=1",   "",                             "" ),
var_info_invalid()
]

struct adjustment_factors:
    var m_cm: compute_module
    var m_factors: List[ssc_number_t]
    var m_error: String
    var m_prefix: String

    def __init__(inout self, cm: compute_module, prefix: String):
        self.m_cm = cm
        self.m_prefix = prefix
        self.m_factors = List[ssc_number_t]()
        self.m_error = String("")

    def setup(inout self, nsteps: int = 8760) -> bool:
        var f: ssc_number_t = self.m_cm.as_number(self.m_prefix + ":constant")
        f = 1.0 - f / 100.0
        self.m_factors.resize(nsteps, f)
        if self.m_cm.is_assigned(self.m_prefix + ":hourly"):
            var n: size_t = 0
            var p: Pointer[ssc_number_t] = self.m_cm.as_array(self.m_prefix + ":hourly", &n)
            if p and n == size_t(nsteps):
                for i in range(nsteps):
                    self.m_factors[i] = self.m_factors[i] * (1.0 - p[i] / 100.0)
        if self.m_cm.is_assigned(self.m_prefix + ":periods"):
            var nr: size_t = 0
            var nc: size_t = 0
            var mat: Pointer[ssc_number_t] = self.m_cm.as_matrix(self.m_prefix + ":periods", &nr, &nc)
            if mat and nc == 3:
                for r in range(nr):
                    var start: int = int(mat[nc * r])
                    var end: int = int(mat[nc * r + 1])
                    var factor: ssc_number_t = mat[nc * r + 2]
                    if start < 0 or start >= nsteps or end < start:
                        self.m_error = util.format("period %d is invalid ( start: %d, end %d )", int(r), start, end)
                        continue
                    if end >= nsteps:
                        end = nsteps - 1
                    for i in range(start, end + 1):
                        self.m_factors[i] = self.m_factors[i] * (1.0 - factor / 100.0)
        return self.m_error.length() == 0

    def __call__(inout self, time: size_t) -> ssc_number_t:
        if time < self.m_factors.size():
            return self.m_factors[time]
        else:
            return 0.0

    def error(inout self) -> String:
        return self.m_error

struct sf_adjustment_factors:
    var m_cm: compute_module
    var m_factors: List[ssc_number_t]
    var m_error: String

    def __init__(inout self, cm: compute_module):
        self.m_cm = cm
        self.m_factors = List[ssc_number_t]()
        self.m_error = String("")

    def setup(inout self, nsteps: int = 8760) -> bool:
        var f: ssc_number_t = self.m_cm.as_number("sf_adjust:constant")
        f = 1.0 - f / 100.0
        self.m_factors.resize(nsteps, f)
        if self.m_cm.is_assigned("sf_adjust:hourly"):
            var n: size_t = 0
            var p: Pointer[ssc_number_t] = self.m_cm.as_array("sf_adjust:hourly", &n)
            if p and n == size_t(nsteps):
                for i in range(nsteps):
                    self.m_factors[i] = self.m_factors[i] * (1.0 - p[i] / 100.0)
            if n != size_t(nsteps):
                self.m_error = util.format("array length (%d) must match number of yearly simulation time steps (%d).", n, nsteps)
        if self.m_cm.is_assigned("sf_adjust:periods"):
            var nr: size_t = 0
            var nc: size_t = 0
            var mat: Pointer[ssc_number_t] = self.m_cm.as_matrix("sf_adjust:periods", &nr, &nc)
            if mat and nc == 3:
                for r in range(nr):
                    var start: int = int(mat[nc * r])
                    var end: int = int(mat[nc * r + 1])
                    var factor: float32 = float32(mat[nc * r + 2])
                    if start < 0 or start >= nsteps or end < start:
                        self.m_error = util.format("period %d is invalid ( start: %d, end %d )", int(r), start, end)
                        continue
                    if end >= nsteps:
                        end = nsteps - 1
                    for i in range(start, end + 1):
                        self.m_factors[i] = self.m_factors[i] * (1 - factor / 100)
        return self.m_error.length() == 0

    def __call__(inout self, time: size_t) -> ssc_number_t:
        if time < self.m_factors.size():
            return self.m_factors[time]
        else:
            return 0.0

    def size(inout self) -> int:
        return int(self.m_factors.size())

    def error(inout self) -> String:
        return self.m_error

struct shading_factor_calculator:
    var m_errors: List[String]
    var m_azaltvals: util.matrix_t[float64]
    var m_enAzAlt: bool
    var m_diffFactor: float64
    var m_string_option: int
    var m_beam_shade_factor: float64
    var m_dc_shade_factor: float64
    var m_steps_per_hour: int
    var m_enTimestep: bool
    var m_beamFactors: util.matrix_t[float64]
    var m_enMxH: bool
    var m_mxhFactors: util.matrix_t[float64]

    def __init__(inout self):
        self.m_errors = List[String]()
        self.m_azaltvals = util.matrix_t[float64]()
        self.m_enAzAlt = False
        self.m_diffFactor = 1.0
        self.m_beam_shade_factor = 1.0
        self.m_dc_shade_factor = 1.0
        self.m_steps_per_hour = 1
        self.m_enTimestep = False
        self.m_beamFactors = util.matrix_t[float64]()
        self.m_enMxH = False
        self.m_mxhFactors = util.matrix_t[float64]()
        self.m_string_option = -1

    def setup(inout self, cm: compute_module, prefix: String = "") -> bool:
        var ok: bool = True
        self.m_diffFactor = 1.0
        self.m_string_option = -1
        self.m_beam_shade_factor = 1.0
        self.m_dc_shade_factor = 1.0
        self.m_steps_per_hour = 1
        if cm.is_assigned(prefix + "shading:string_option"):
            self.m_string_option = cm.as_integer(prefix + "shading:string_option")
        var nrecs: size_t = 8760
        self.m_beamFactors.resize_fill(nrecs, 1, 1.0)
        self.m_enTimestep = False
        if cm.is_assigned(prefix + "shading:timestep"):
            var nrows: size_t = 0
            var ncols: size_t = 0
            var mat: Pointer[ssc_number_t] = cm.as_matrix(prefix + "shading:timestep", &nrows, &ncols)
            if nrows % 8760 == 0:
                nrecs = nrows
                self.m_beamFactors.resize_fill(nrows, ncols, 1.0)
                if self.m_string_option == 0:
                    for r in range(nrows):
                        for c in range(ncols):
                            self.m_beamFactors.at(r, c) = mat[r * ncols + c]
                elif self.m_string_option == 1:
                    for r in range(nrows):
                        var sum_percent_shaded: float64 = 0.0
                        for c in range(ncols):
                            sum_percent_shaded += mat[r * ncols + c]
                        sum_percent_shaded /= ncols
                        self.m_beamFactors.at(r, 0) = 1.0 - sum_percent_shaded / 100
                elif self.m_string_option == 2:
                    for r in range(nrows):
                        var max_percent_shaded: float64 = 0.0
                        for c in range(ncols):
                            if mat[r * ncols + c] > max_percent_shaded:
                                max_percent_shaded = mat[r * ncols + c]
                        self.m_beamFactors.at(r, 0) = 1.0 - max_percent_shaded / 100
                elif self.m_string_option == 3:
                    for r in range(nrows):
                        var min_percent_shaded: float64 = 100.0
                        for c in range(ncols):
                            if mat[r * ncols + c] < min_percent_shaded:
                                min_percent_shaded = mat[r * ncols + c]
                        self.m_beamFactors.at(r, 0) = 1.0 - min_percent_shaded / 100
                else:
                    for r in range(nrows):
                        for c in range(ncols):
                            self.m_beamFactors.at(r, c) = 1 - mat[r * ncols + c] / 100
                self.m_steps_per_hour = int(nrows) / 8760
                self.m_enTimestep = True
            else:
                ok = False
                self.m_errors.push_back("hourly shading beam losses must be multiple of 8760 values")
        self.m_enMxH = False
        if cm.is_assigned(prefix + "shading:mxh"):
            self.m_mxhFactors.resize_fill(nrecs, 1, 1.0)
            var nrows: size_t = 0
            var ncols: size_t = 0
            var mat: Pointer[ssc_number_t] = cm.as_matrix(prefix + "shading:mxh", &nrows, &ncols)
            if nrows != 12 or ncols != 24:
                ok = False
                self.m_errors.push_back("month x hour shading losses must have 12 rows and 24 columns")
            else:
                var c: int = 0
                for m in range(12):
                    for d in range(util.nday[m]):
                        for h in range(24):
                            for jj in range(self.m_steps_per_hour):
                                self.m_mxhFactors.at(c, 0) = 1 - mat[m * ncols + h] / 100
                                c += 1
            self.m_enMxH = True
        self.m_enAzAlt = False
        if cm.is_assigned(prefix + "shading:azal"):
            var nrows: size_t = 0
            var ncols: size_t = 0
            var mat: Pointer[ssc_number_t] = cm.as_matrix(prefix + "shading:azal", &nrows, &ncols)
            if nrows < 3 or ncols < 3:
                ok = False
                self.m_errors.push_back("azimuth x altitude shading losses must have at least 3 rows and 3 columns")
            self.m_azaltvals.resize_fill(nrows, ncols, 1.0)
            for r in range(nrows):
                for c in range(ncols):
                    if r == 0 or c == 0:
                        self.m_azaltvals.at(r, c) = mat[r * ncols + c]
                    else:
                        self.m_azaltvals.at(r, c) = 1 - mat[r * ncols + c] / 100
            self.m_enAzAlt = True
        if cm.is_assigned(prefix + "shading:diff"):
            self.m_diffFactor = 1 - cm.as_double(prefix + "shading:diff") / 100
        return ok

    def get_error(inout self, i: size_t = 0) -> String:
        if i < self.m_errors.size():
            return self.m_errors[i]
        else:
            return String("")

    def use_shade_db(inout self) -> bool:
        return (self.m_enTimestep and (self.m_string_option == 0))

    def get_row_index_for_input(inout self, hour_of_year: size_t, minute: size_t) -> size_t:
        var ndx: size_t = hour_of_year * size_t(self.m_steps_per_hour)
        ndx += mojo_floor(int(minute) / (60 / (self.m_steps_per_hour)))
        return ndx

    def fbeam(inout self, hour_of_year: size_t, minute: float64, solalt: float64, solazi: float64) -> bool:
        var ok: bool = False
        var factor: float64 = 1.0
        var irow: size_t = self.get_row_index_for_input(hour_of_year, size_t(minute))
        if irow < self.m_beamFactors.nrows() and int(irow) >= 0:
            factor = self.m_beamFactors.at(irow, 0)
            if self.m_enMxH and irow < self.m_mxhFactors.nrows():
                factor = factor * self.m_mxhFactors(irow, 0)
            if self.m_enAzAlt:
                factor = factor * util.bilinear(solalt, solazi, self.m_azaltvals)
            self.m_beam_shade_factor = factor
            ok = True
        return ok

    def fbeam_shade_db(inout self, p_shadedb: ShadeDB8_mpp, hour: size_t, minute: float64, solalt: float64, solazi: float64, gpoa: float64 = 0.0, dpoa: float64 = 0.0, pv_cell_temp: float64 = 0.0, mods_per_str: int = 0, str_vmp_stc: float64 = 0.0, mppt_lo: float64 = 0.0, mppt_hi: float64 = 0.0) -> bool:
        var ok: bool = False
        var dc_factor: float64 = 1.0
        var beam_factor: float64 = 1.0
        var irow: size_t = self.get_row_index_for_input(hour, size_t(minute))
        if irow < self.m_beamFactors.nrows():
            var shad_fracs: List[float64] = List[float64]()
            for icol in range(self.m_beamFactors.ncols()):
                shad_fracs.push_back(self.m_beamFactors.at(irow, icol))
            dc_factor = 1.0 - p_shadedb.get_shade_loss(gpoa, dpoa, shad_fracs, True, pv_cell_temp, mods_per_str, str_vmp_stc, mppt_lo, mppt_hi)
            if self.m_enMxH and irow < self.m_mxhFactors.nrows():
                beam_factor = beam_factor * self.m_mxhFactors(irow, 0)
            if self.m_enAzAlt:
                beam_factor = beam_factor * util.bilinear(solalt, solazi, self.m_azaltvals)
            self.m_dc_shade_factor = dc_factor
            self.m_beam_shade_factor = beam_factor
            ok = True
        return ok

    def fdiff(inout self) -> float64:
        return self.m_diffFactor

    def beam_shade_factor(inout self) -> float64:
        return self.m_beam_shade_factor

    def dc_shade_factor(inout self) -> float64:
        return self.m_dc_shade_factor

struct weatherdata(weather_data_provider):
    var m_data: List[Pointer[weather_record]]
    var m_columns: List[size_t]
    var m_startSec: float64
    var m_stepSec: float64
    var m_nRecords: size_t
    var m_index: size_t
    var m_ok: bool
    var m_message: String
    var m_continuousYear: bool
    var m_hdr: weather_data_provider_header

    def check_continuous_single_year(inout self, leapyear: bool) -> bool:
        var ts_per_hour: int = 0
        if leapyear:
            ts_per_hour = int(self.m_nRecords / 8784)
        else:
            ts_per_hour = int(self.m_nRecords / 8760)
        var ts_min: float64 = 60.0 / ts_per_hour
        var has_leapday: bool = False
        var leapDayNoon: int = 1429 * ts_per_hour
        if self.m_data[leapDayNoon][].month == 2 and self.m_data[leapDayNoon][].day == 29:
            has_leapday = True
        var idx: int = 0
        for m in range(1, 13):
            var daymax: int = util.days_in_month(m - 1)
            if m == 2 and has_leapday:
                daymax = 29
            if m == 12 and has_leapday and not leapyear:
                daymax = 30
            for d in range(1, daymax + 1):
                for h in range(24):
                    var min: float64 = self.m_data[idx][].minute
                    for tsph in range(ts_per_hour):
                        if idx > self.m_nRecords - 1:
                            return False
                        min += tsph * ts_min
                        if self.m_data[idx][].month != m or self.m_data[idx][].day != d or self.m_data[idx][].hour != h or self.m_data[idx][].minute != min:
                            return False
                        else:
                            idx += 1
        return True

    def __init__(inout self, data_table: var_data):
        self.m_startSec = 0.0
        self.m_stepSec = 0.0
        self.m_nRecords = 0
        self.m_index = 0
        self.m_ok = True
        self.m_data = List[Pointer[weather_record]]()
        self.m_columns = List[size_t]()
        self.m_message = String("")
        self.m_continuousYear = True
        self.m_hdr = weather_data_provider_header()

        if data_table.type != SSC_TABLE:
            self.m_message = "solar data must be an SSC table variable with fields: (numbers): lat, lon, tz, elev, (arrays): year, month, day, hour, minute, gh, dn, df, poa, wspd, wdir, tdry, twet, tdew, rhum, pres, snow, alb, aod"
            return
        self.m_hdr.lat = self.get_number(data_table, "lat")
        self.m_hdr.lon = self.get_number(data_table, "lon")
        self.m_hdr.tz = self.get_number(data_table, "tz")
        self.m_hdr.elev = self.get_number(data_table, "elev")
        var nrec: size_t = 0
        var n_irr: int = 0
        var value: var_data = data_table.table.lookup("df")
        if value:
            if value.type == SSC_ARRAY:
                nrec = value.num.length()
                n_irr += 1
        value = data_table.table.lookup("dn")
        if value:
            if value.type == SSC_ARRAY:
                nrec = value.num.length()
                n_irr += 1
        value = data_table.table.lookup("gh")
        if value:
            if value.type == SSC_ARRAY:
                nrec = value.num.length()
                n_irr += 1
        if nrec == 0 or n_irr < 2:
            value = data_table.table.lookup("poa")
            if value:
                if value.type == SSC_ARRAY:
                    nrec = value.num.length()
                    n_irr += 1
            else:
                self.m_message = "missing irradiance: could not find gh, dn, df, or poa"
                self.m_ok = False
                return
        var year: vec = self.get_vector(data_table, "year", &nrec)
        var month: vec = self.get_vector(data_table, "month", &nrec)
        var day: vec = self.get_vector(data_table, "day", &nrec)
        var hour: vec = self.get_vector(data_table, "hour", &nrec)
        var minute: vec = self.get_vector(data_table, "minute", &nrec)
        var gh: vec = self.get_vector(data_table, "gh", &nrec)
        var dn: vec = self.get_vector(data_table, "dn", &nrec)
        var df: vec = self.get_vector(data_table, "df", &nrec)
        var poa: vec = self.get_vector(data_table, "poa", &nrec)
        var wspd: vec = self.get_vector(data_table, "wspd", &nrec)
        var wdir: vec = self.get_vector(data_table, "wdir", &nrec)
        var tdry: vec = self.get_vector(data_table, "tdry", &nrec)
        var twet: vec = self.get_vector(data_table, "twet", &nrec)
        var tdew: vec = self.get_vector(data_table, "tdew", &nrec)
        var rhum: vec = self.get_vector(data_table, "rhum", &nrec)
        var pres: vec = self.get_vector(data_table, "pres", &nrec)
        var snow: vec = self.get_vector(data_table, "snow", &nrec)
        var alb: vec = self.get_vector(data_table, "alb", &nrec)
        var aod: vec = self.get_vector(data_table, "aod", &nrec)
        if not self.m_ok:
            return
        if not self.has_data_column(weather_data_provider.MINUTE):
            self.m_message = "minute column required for weather data input"
            self.m_ok = False
            return
        self.m_nRecords = nrec
        if nrec > 0:
            self.m_data.resize(nrec)
            for i in range(nrec):
                var r: Pointer[weather_record] = Pointer[weather_record].init(weather_record())
                if i < year.len:
                    r[].year = int(year.p[i])
                if i < month.len:
                    r[].month = int(month.p[i])
                if i < day.len:
                    r[].day = int(day.p[i])
                if i < hour.len:
                    r[].hour = int(hour.p[i])
                if i < minute.len:
                    r[].minute = minute.p[i]
                if minute.p[i] > 60:
                    self.m_message = "minute column must contain integers from 0-59"
                    self.m_ok = False
                    return
                r[].gh = float64('nan')
                r[].dn = float64('nan')
                r[].df = float64('nan')
                r[].poa = float64('nan')
                r[].wspd = float64('nan')
                r[].wdir = float64('nan')
                r[].tdry = float64('nan')
                r[].twet = float64('nan')
                r[].tdew = float64('nan')
                r[].rhum = float64('nan')
                r[].pres = float64('nan')
                r[].snow = float64('nan')
                r[].alb = float64('nan')
                r[].aod = float64('nan')
                if i < gh.len:
                    r[].gh = gh.p[i]
                if i < dn.len:
                    r[].dn = dn.p[i]
                if i < df.len:
                    r[].df = df.p[i]
                if i < poa.len:
                    r[].poa = poa.p[i]
                if i < wspd.len:
                    r[].wspd = wspd.p[i]
                if i < wdir.len:
                    r[].wdir = wdir.p[i]
                if i < tdry.len:
                    r[].tdry = tdry.p[i]
                if i < twet.len:
                    r[].twet = twet.p[i]
                else:
                    if (i < tdry.len) and (i < rhum.len) and (i < pres.len):
                        r[].twet = float32(calc_twet(tdry.p[i], rhum.p[i], pres.p[i]))
                if i < tdew.len:
                    r[].tdew = tdew.p[i]
                else:
                    if (i < tdry.len) and (i < rhum.len):
                        r[].tdew = float32(wiki_dew_calc(tdry.p[i], rhum.p[i]))
                if i < rhum.len:
                    r[].rhum = rhum.p[i]
                if i < pres.len:
                    r[].pres = pres.p[i]
                if i < snow.len:
                    r[].snow = snow.p[i]
                if i < alb.len:
                    r[].alb = alb.p[i]
                if i < aod.len:
                    r[].aod = aod.p[i]
                self.m_data[i] = r
            self.start_hours_at_0()
        var nmult: size_t = 0
        var is_leap_year: bool = False
        if self.m_nRecords % 8784 == 0:
            self.m_nRecords = self.m_nRecords / 8784 * 8760
            is_leap_year = True
        if self.m_nRecords % 8760 == 0:
            if self.check_continuous_single_year(is_leap_year):
                nmult = nrec / 8760
                self.m_stepSec = 3600 / nmult
                self.m_startSec = self.m_stepSec / 2
            else:
                self.m_continuousYear = False
        else:
            self.m_continuousYear = False

    def __del__(inout self):
        for i in range(self.m_data.size):
            del self.m_data[i]

    def name_to_id(inout self, name: String) -> int:
        var n: String = util.lower_case(name)
        if n == "year":
            return YEAR
        if n == "month":
            return MONTH
        if n == "day":
            return DAY
        if n == "hour":
            return HOUR
        if n == "minute":
            return MINUTE
        if n == "gh":
            return GHI
        if n == "dn":
            return DNI
        if n == "df":
            return DHI
        if n == "poa":
            return POA
        if n == "wspd":
            return WSPD
        if n == "wdir":
            return WDIR
        if n == "tdry":
            return TDRY
        if n == "twet":
            return TWET
        if n == "tdew":
            return TDEW
        if n == "rhum":
            return RH
        if n == "pres":
            return PRES
        if n == "snow":
            return SNOW
        if n == "alb":
            return ALB
        if n == "aod":
            return AOD
        return -1

    def get_vector(inout self, v: var_data, name: String, len: Pointer[size_t]) -> vec:
        var x: vec
        x.p = Pointer[ssc_number_t]()
        x.len = 0
        var value: var_data = v.table.lookup(name)
        if value:
            if value.type == SSC_ARRAY:
                x.len = value.num.length()
                x.p = value.num.data()
                if len and len[] != x.len:
                    var name_s: String = name
                    self.m_message = name_s + " number of entries doesn't match with other fields"
                    self.m_ok = False
                var id: size_t = size_t(self.name_to_id(name))
                if not self.has_data_column(id):
                    self.m_columns.push_back(id)
        return x

    def get_number(inout self, v: var_data, name: String) -> ssc_number_t:
        var value: var_data = v.table.lookup(name)
        if value:
            if value.type == SSC_NUMBER:
                return value.num
        return ssc_number_t(float64('nan'))

    def start_hours_at_0(inout self):
        var hours: List[int] = List[int]()
        for i in self.m_data:
            hours.push_back(i[].hour)
        var max_hr: float64 = float64(*std.max_element(hours.begin(), hours.end()))
        var min_hr: float64 = float64(*std.min_element(hours.begin(), hours.end()))
        if max_hr - min_hr != 23.0:
            self.m_message = "Weather data range was not (0-23) or (1-24)"
        elif max_hr == 24.0:
            for i in self.m_data:
                i[].hour -= 1

    def set_counter_to(inout self, cur_index: size_t):
        if cur_index < self.m_data.size():
            self.m_index = cur_index

    def read(inout self, r: Pointer[weather_record]) -> bool:
        if self.m_index < self.m_data.size():
            r[] = self.m_data[self.m_index][]
            self.m_index += 1
            return True
        else:
            return False

    def read_average(inout self, r: Pointer[weather_record], cols: List[int], num_timesteps: size_t) -> bool:
        if self.m_index < self.m_data.size():
            r[] = self.m_data[self.m_index][]
            self.m_index += 1
            return True
        else:
            return False

    def has_data_column(inout self, id: size_t) -> bool:
        for i in range(self.m_columns.size):
            if self.m_columns[i] == id:
                return True
        return False

struct scalefactors:
    var vt: var_table

    def __init__(inout self, v: var_table):
        self.vt = v

    def get_factors(inout self, name: String) -> List[float64]:
        var nyears: size_t = 1
        if self.vt.is_assigned("analysis_period"):
            nyears = size_t(self.vt.as_integer("analysis_period"))
        var scale_factors: List[float64] = List[float64]()
        scale_factors.resize(nyears, 1.0)
        if self.vt.is_assigned(name):
            var count: size_t = 0
            var i: size_t = 0
            var parr: Pointer[ssc_number_t] = self.vt.as_array(name, &count)
            if count < 1:
                for i in range(nyears):
                    scale_factors[i] = 1.0
            elif count < 2:
                for i in range(nyears):
                    scale_factors[i] = math.pow(float64(1 + parr[0] * 0.01), float64(i))
            else:
                if count < nyears:
                    var ss: String = ""
                    ss += "Expected length of "
                    ss += name
                    ss += " to be "
                    ss += str(nyears)
                    ss += " found "
                    ss += str(count)
                    ss += " entries"
                    raise general_error(ss)
                for i in range(nyears):
                    scale_factors[i] = float64(1 + parr[i] * 0.01)
        return scale_factors

def ssc_cmod_update(log_msg: String, progress_msg: String, data: object, progress: float64, out_type: int) -> bool:
    var cm: compute_module = compute_module(data)
    if not cm:
        return False
    if log_msg != "":
        cm.log(log_msg, out_type)
    return cm.update(progress_msg, float32(progress))