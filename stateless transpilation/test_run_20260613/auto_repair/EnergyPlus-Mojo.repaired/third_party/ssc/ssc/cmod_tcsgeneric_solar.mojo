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
from tckernel import *
from common import *

static var_info _cm_vtab_tcsgeneric_solar = List[var_info](
    var_info( SSC_INPUT,        SSC_STRING,      "file_name",        "local weather file path",                                        "",                 "",             "Weather",        "*",                       "LOCAL_FILE",            "" ),
    var_info( SSC_INPUT,        SSC_NUMBER,      "track_mode",       "Tracking mode",                                                  "",                 "",             "Weather",        "*",                       "",                      "" ),
    var_info( SSC_INPUT,        SSC_NUMBER,      "tilt",             "Tilt angle of surface/axis",                                     "",                 "",             "Weather",        "*",                       "",                      "" ),
    var_info( SSC_INPUT,        SSC_NUMBER,      "azimuth",          "Azimuth angle of surface/axis",                                  "",                 "",             "Weather",        "*",                       "",                      "" ),
	var_info( SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "generic solar", "*", "", "" ),
    var_info( SSC_INPUT,        SSC_MATRIX,      "weekday_schedule", "12x24 Time of Use Values for week days",                         "",                 "",             "tou_translator", "*",                       "",                      "" ), 
    var_info( SSC_INPUT,        SSC_MATRIX,      "weekend_schedule", "12x24 Time of Use Values for week end days",                     "",                 "",             "tou_translator", "*",                       "",                      "" ), 
	var_info( SSC_INPUT,        SSC_NUMBER,      "latitude",         "Site latitude",                                                  "",                 "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "longitude",        "Site longitude",                                                 "",                 "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "timezone",         "Site timezone",                                                  "hr",               "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "theta_stow",       "Solar elevation angle at which the solar field stops operating", "deg",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "theta_dep",        "Solar elevation angle at which the solar field begins operating","deg",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "interp_arr",       "Interpolate the array or find nearest neighbor? (1=interp,2=no)","none",             "",             "type_260",       "*",                       "INTEGER",               "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "rad_type",         "Solar resource radiation type (1=DNI,2=horiz.beam,3=tot.horiz)", "none",             "",             "type_260",       "*",                       "INTEGER",               "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "solarm",           "Solar multiple",                                                 "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "T_sfdes",          "Solar field design point temperature (dry bulb)",                "C",                "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "irr_des",          "Irradiation design point",                                       "W/m2",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "eta_opt_soil",     "Soiling optical derate factor",                                  "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "eta_opt_gen",      "General/other optical derate",                                   "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_sfhl_ref",       "Reference solar field thermal loss fraction",                    "MW/MWcap",         "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "sfhlQ_coefs",      "Irr-based solar field thermal loss adjustment coefficients",     "1/MWt",            "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "sfhlT_coefs",      "Temp.-based solar field thermal loss adjustment coefficients",   "1/C",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "sfhlV_coefs",      "Wind-based solar field thermal loss adjustment coefficients",    "1/(m/s)",          "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "qsf_des",          "Solar field thermal production at design",                       "MWt",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "w_des",            "Design power cycle gross output",                                "MWe",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "eta_des",          "Design power cycle gross efficiency",                            "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_wmax",           "Maximum over-design power cycle operation fraction",             "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_wmin",           "Minimum part-load power cycle operation fraction",               "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_startup",        "Equivalent full-load hours required for power system startup",   "hours",            "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "eta_lhv",          "Fossil backup lower heating value efficiency",                   "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "etaQ_coefs",       "Part-load power conversion efficiency adjustment coefficients",  "1/MWt",            "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "etaT_coefs",       "Temp.-based power conversion efficiency adjustment coefs.",      "1/C",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "T_pcdes",          "Power conversion reference temperature",                         "C",                "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "PC_T_corr",        "Power conversion temperature correction mode (1=wetb, 2=dryb)",  "none",             "",             "type_260",       "*",                       "INTEGER",               "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_Wpar_fixed",     "Fixed capacity-based parasitic loss fraction",                   "MWe/MWcap",        "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_Wpar_prod",      "Production-based parasitic loss fraction",                       "MWe/MWe",          "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "Wpar_prodQ_coefs", "Part-load production parasitic adjustment coefs.",               "1/MWe",            "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "Wpar_prodT_coefs", "Temp.-based production parasitic adjustment coefs.",             "1/C",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "Wpar_prodD_coefs", "DNI-based production parasitic adjustment coefs.",               "m2/W",             "",            "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "hrs_tes",          "Equivalent full-load hours of storage",                          "hours",            "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_charge",         "Storage charging energy derate",                                 "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_disch",          "Storage discharging energy derate",                              "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_etes_0",         "Initial fractional charge level of thermal storage (0..1)",      "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "f_teshl_ref",      "Reference heat loss from storage per max stored capacity",       "kWt/MWhr-stored",  "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "teshlX_coefs",     "Charge-based thermal loss adjustment - constant coef.",          "1/MWhr-stored",    "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "teshlT_coefs",     "Temp.-based thermal loss adjustment - constant coef.",           "1/C",              "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "ntod",             "Number of time-of-dispatch periods in the dispatch schedule",    "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "disws",            "Time-of-dispatch control for with-solar conditions",             "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "diswos",           "Time-of-dispatch control for without-solar conditions",          "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "qdisp",            "TOD power output control factors",                               "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_ARRAY,       "fdisp",            "Fossil backup output control factors",                           "none",             "",             "type_260",       "*",                       "",                      "" ),
    var_info( SSC_INPUT,        SSC_NUMBER,      "istableunsorted",  "Is optical table unsorted format?",                              "none",             "",             "type_260",       "*",                       "",                      "" ),
    var_info( SSC_INPUT,        SSC_MATRIX,      "OpticalTable",     "Optical table",                                                  "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_MATRIX,      "exergy_table",     "Exergy table",                                                   "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "storage_config",   "Thermal storage configuration",                                  "none",             "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "ibn",              "Beam-normal (DNI) irradiation",                                  "kJ/hr-m^2",        "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "ibh",              "Beam-horizontal irradiation",                                    "kJ/hr-m^2",        "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "itoth",            "Total horizontal irradiation",                                   "kJ/hr-m^2",        "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "tdb",              "Ambient dry-bulb temperature",                                   "C",                "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "twb",              "Ambient wet-bulb temperature",                                   "C",                "",             "type_260",       "*",                       "",                      "" ),
	var_info( SSC_INPUT,        SSC_NUMBER,      "vwind",            "Wind velocity",                                                  "m/s",              "",             "type_260",       "*",                       "",                      "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "month",             "Resource Month",                                                  "",             "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "hour",              "Resource Hour of Day",                                            "",             "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "solazi",            "Resource Solar Azimuth",                                          "deg",          "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "solzen",            "Resource Solar Zenith",                                           "deg",          "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "beam",              "Resource Beam normal irradiance",                                 "W/m2",         "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "global",            "Resource Global horizontal irradiance",                           "W/m2",         "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "diff",              "Resource Diffuse horizontal irradiance",                          "W/m2",         "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "tdry",              "Resource Dry bulb temperature",                                   "C",            "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "twet",              "Resource Wet bulb temperature",                                   "C",            "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "wspd",              "Resource Wind Speed",                                             "m/s",          "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "pres",              "Resource Pressure",                                               "mbar",         "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "eta_opt_sf",        "Field collector optical efficiency",                             "none",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_inc",             "Field thermal power incident",                                   "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "f_sfhl_qdni",       "Field thermal power load-based loss correction",                 "none",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "f_sfhl_tamb",       "Field thermal power temp.-based loss correction",                "none",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "f_sfhl_vwind",      "Field thermal power wind-based loss correction",                 "none",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_hl_sf",           "Field thermal power loss total",                                 "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_sf",              "Field thermal power total produced",                             "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_to_tes",          "TES thermal energy into storage",                                "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_from_tes",        "TES thermal energy from storage",                                "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "e_in_tes",          "TES thermal energy available",                                   "MWht",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_hl_tes",          "TES thermal losses from tank(s)",                                "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "eta_cycle",         "Cycle efficiency (gross)",                                       "",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "f_effpc_qtpb",      "Cycle efficiency load-based correction",                         "",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "f_effpc_tamb",      "Cycle efficiency temperature-based correction",                  "",         "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "enet",              "Cycle electrical power output (net)",                            "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_gr",              "Cycle electrical power output (gross)",                          "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_gr_solar",        "Cycle electrical power output (gross, solar share)",             "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_gr_fossil",       "Cycle electrical power output (gross, fossil share)",            "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_to_pb",           "Cycle thermal power input",                                      "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_startup",         "Cycle thermal startup energy",                                   "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_dump_tesfull",    "Cycle thermal energy dumped - TES is full",                      "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_dump_umin",       "Cycle thermal energy dumped - min. load requirement",            "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_dump_teschg",     "Cycle thermal energy dumped - solar field",                      "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_dump_tot",        "Cycle thermal energy dumped total",                              "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_fossil",          "Fossil thermal power produced",                                  "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "q_gas",             "Fossil fuel used",                                               "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_par_fixed",       "Fixed parasitic losses",                                         "MWh",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_par_prod",        "Production-based parasitic losses",                              "MWh",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_par_tot",         "Total parasitic losses",                                         "MWh",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_par_online",      "Online parasitics",                                              "MWh",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "w_par_offline",     "Offline parasitics",                                             "MWh",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_energy",    "Monthly Energy",                                                 "kWh",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_w_gr",      "Total gross power production",                                   "kWh",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_sf",      "Solar field delivered thermal power",                            "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_to_pb",   "Thermal energy to the power conversion system",                  "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_to_tes",  "Thermal energy into storage",                                    "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_from_tes","Thermal energy from storage",                                    "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_hl_sf",   "Solar field thermal losses",                                     "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_hl_tes",  "Thermal losses from storage",                                    "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_dump_tot","Total dumped energy",                                            "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_startup", "Power conversion startup energy",                                "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
    var_info( SSC_OUTPUT,       SSC_ARRAY,       "monthly_q_fossil",  "Thermal energy supplied from aux firing",                        "MWt",          "",            "Generic CSP",    "*",                       "LENGTH=12",           "" ),
	var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_energy",     "Annual Energy",                                                  "kWh",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_w_gr",       "Total gross power production",                                   "kWh",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_sf",       "Solar field delivered thermal power",                            "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_to_pb",    "Thermal energy to the power conversion system",                  "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_to_tes",   "Thermal energy into storage",                                    "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_from_tes", "Thermal energy from storage",                                    "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_hl_sf",    "Solar field thermal losses",                                     "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_hl_tes",   "Thermal losses from storage",                                    "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_dump_tot", "Total dumped energy",                                            "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_startup",  "Power conversion startup energy",                                "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
    var_info( SSC_OUTPUT,       SSC_NUMBER,      "annual_q_fossil",   "Thermal energy supplied from aux firing",                        "MWht",          "",            "Generic CSP",    "*",                       "",                    "" ),
	var_info( SSC_OUTPUT,       SSC_NUMBER,      "conversion_factor", "Gross to Net Conversion Factor",                                 "%",            "",            "Calculated",     "*",                       "",                      "" ),
	var_info( SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "*", "", "" ),
	var_info( SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "", "*", "", "" ),
	var_info( SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "System heat rate", "MMBtu/MWh", "", "", "*", "", "" ),
	var_info( SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual fuel usage", "kWh", "", "", "*", "", "" ),
	var_info_invalid
)

class cm_tcsgeneric_solar(tcKernel):
    def __init__(self, prov: tcstypeprovider):
        super().__init__(prov)
        self.add_var_info(_cm_vtab_tcsgeneric_solar)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_sf_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        debug_mode = False
        weather = 0
        if debug_mode:
            weather = self.add_unit("trnsys_weatherreader", "TRNSYS weather reader")
        else:
            weather = self.add_unit("weatherreader", "TCS weather reader")

        tou = self.add_unit("tou_translator", "Time of Use Translator")

        type260_genericsolar = self.add_unit("sam_mw_gen_type260", "Generic solar model")

        if debug_mode:
            self.set_unit_value(weather, "file_name", "C:/svn_NREL/main/ssc/tcsdata/typelib/TRNSYS_weather_outputs/tucson_trnsys_weather.out")
            self.set_unit_value(weather, "i_hour", "TIME")
            self.set_unit_value(weather, "i_month", "month")
            self.set_unit_value(weather, "i_day", "day")
            self.set_unit_value(weather, "i_global", "GlobalHorizontal")
            self.set_unit_value(weather, "i_beam", "DNI")
            self.set_unit_value(weather, "i_diff", "DiffuseHorizontal")
            self.set_unit_value(weather, "i_tdry", "T_dry")
            self.set_unit_value(weather, "i_twet", "T_wet")
            self.set_unit_value(weather, "i_tdew", "T_dew")
            self.set_unit_value(weather, "i_wspd", "WindSpeed")
            self.set_unit_value(weather, "i_wdir", "WindDir")
            self.set_unit_value(weather, "i_rhum", "RelHum")
            self.set_unit_value(weather, "i_pres", "AtmPres")
            self.set_unit_value(weather, "i_snow", "SnowCover")
            self.set_unit_value(weather, "i_albedo", "GroundAlbedo")
            self.set_unit_value(weather, "i_poa", "POA")
            self.set_unit_value(weather, "i_solazi", "Azimuth")
            self.set_unit_value(weather, "i_solzen", "Zenith")
            self.set_unit_value(weather, "i_lat", "Latitude")
            self.set_unit_value(weather, "i_lon", "Longitude")
            self.set_unit_value(weather, "i_shift", "Shift")
        else:
            self.set_unit_value_ssc_string(weather, "file_name")
            self.set_unit_value_ssc_double(weather, "track_mode")    #, 1 )
            self.set_unit_value_ssc_double(weather, "tilt")          #, 0 )
            self.set_unit_value_ssc_double(weather, "azimuth")       #, 0 )

        self.set_unit_value_ssc_matrix(tou, "weekday_schedule") # tou values from control will be between 1 and 9
        self.set_unit_value_ssc_matrix(tou, "weekend_schedule")

        self.set_unit_value_ssc_double(type260_genericsolar, "latitude" ) #, 35)
        self.set_unit_value_ssc_double(type260_genericsolar, "longitude" ) #, -117)
        self.set_unit_value_ssc_double(type260_genericsolar, "istableunsorted")
        self.set_unit_value_ssc_matrix(type260_genericsolar, "OpticalTable" ) #, opt_data)
        self.set_unit_value_ssc_double(type260_genericsolar, "timezone" ) #, -8)
        self.set_unit_value_ssc_double(type260_genericsolar, "theta_stow" ) #, 170)
        self.set_unit_value_ssc_double(type260_genericsolar, "theta_dep" ) #, 10)
        self.set_unit_value_ssc_double(type260_genericsolar, "interp_arr" ) #, 1)
        self.set_unit_value_ssc_double(type260_genericsolar, "rad_type" ) #, 1)
        self.set_unit_value_ssc_double(type260_genericsolar, "solarm" ) #, solarm)
        self.set_unit_value_ssc_double(type260_genericsolar, "T_sfdes" ) #, T_sfdes)
        self.set_unit_value_ssc_double(type260_genericsolar, "irr_des" ) #, irr_des)
        self.set_unit_value_ssc_double(type260_genericsolar, "eta_opt_soil" ) #, eta_opt_soil)
        self.set_unit_value_ssc_double(type260_genericsolar, "eta_opt_gen" ) #, eta_opt_gen)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_sfhl_ref" ) #, f_sfhl_ref)
        self.set_unit_value_ssc_array(type260_genericsolar, "sfhlQ_coefs" ) #, [1,-0.1,0,0])
        self.set_unit_value_ssc_array(type260_genericsolar, "sfhlT_coefs" ) #, [1,0.005,0,0])
        self.set_unit_value_ssc_array(type260_genericsolar, "sfhlV_coefs" ) #, [1,0.01,0,0])
        self.set_unit_value_ssc_double(type260_genericsolar, "qsf_des" ) #, q_sf)
        self.set_unit_value_ssc_double(type260_genericsolar, "w_des" ) #, w_gr_des)
        self.set_unit_value_ssc_double(type260_genericsolar, "eta_des" ) #, eta_cycle_des)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_wmax" ) #, 1.05)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_wmin" ) #, 0.25)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_startup" ) #, 0.2)
        self.set_unit_value_ssc_double(type260_genericsolar, "eta_lhv" ) #, 0.9)
        self.set_unit_value_ssc_array(type260_genericsolar, "etaQ_coefs" ) #, [0.9,0.1,0,0,0])
        self.set_unit_value_ssc_array(type260_genericsolar, "etaT_coefs" ) #, [1,-0.002,0,0,0])
        self.set_unit_value_ssc_double(type260_genericsolar, "T_pcdes" ) #, 21)
        self.set_unit_value_ssc_double(type260_genericsolar, "PC_T_corr" ) #, 1)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_Wpar_fixed" ) #, f_Wpar_fixed)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_Wpar_prod" ) #, f_Wpar_prod)
        self.set_unit_value_ssc_array(type260_genericsolar, "Wpar_prodQ_coefs" ) #, [1,0,0,0])
        self.set_unit_value_ssc_array(type260_genericsolar, "Wpar_prodT_coefs" ) #, [1,0,0,0])
        self.set_unit_value_ssc_array(type260_genericsolar, "Wpar_prodD_coefs" ) #, [1,0,0,0])
        self.set_unit_value_ssc_double(type260_genericsolar, "hrs_tes" ) #, hrs_tes)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_charge" ) #, 0.98)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_disch" ) #, 0.98)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_etes_0" ) #, 0.1)
        self.set_unit_value_ssc_double(type260_genericsolar, "f_teshl_ref" ) #, 0.35)
        self.set_unit_value_ssc_array(type260_genericsolar, "teshlX_coefs" ) #, [1,0,0,0])
        self.set_unit_value_ssc_array(type260_genericsolar, "teshlT_coefs" ) #, [1,0,0,0])
        self.set_unit_value_ssc_double(type260_genericsolar, "ntod" ) #, 9)
        self.set_unit_value_ssc_array(type260_genericsolar, "disws" ) #, [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1])
        self.set_unit_value_ssc_array(type260_genericsolar, "diswos" ) #, [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1])
        self.set_unit_value_ssc_array(type260_genericsolar, "qdisp" ) #, [1,1,1,1,1,1,1,1,1])
        self.set_unit_value_ssc_array(type260_genericsolar, "fdisp" ) #, [0,0,0,0,0,0,0,0,0])
        self.set_unit_value_ssc_matrix(type260_genericsolar, "exergy_table")
        self.set_unit_value_ssc_double(type260_genericsolar, "storage_config") #Direct storage=0,Indirect storage=1
        self.set_unit_value_ssc_double(type260_genericsolar, "ibn" ) #, 0.)	#Beam-normal (DNI) irradiation
        self.set_unit_value_ssc_double(type260_genericsolar, "ibh" ) #, 0.)	#	Beam-horizontal irradiation
        self.set_unit_value_ssc_double(type260_genericsolar, "itoth" ) #, 0.)	#	Total horizontal irradiation
        self.set_unit_value_ssc_double(type260_genericsolar, "tdb" ) #, 15.)	#	Ambient dry-bulb temperature
        self.set_unit_value_ssc_double(type260_genericsolar, "twb" ) #, 10.)	#	Ambient wet-bulb temperature
        self.set_unit_value_ssc_double(type260_genericsolar, "vwind" ) #, 1.)	#	Wind velocity

        bConnected = self.connect(weather, "beam", type260_genericsolar, "ibn")
        bConnected &= self.connect(weather, "global", type260_genericsolar, "itoth")
        bConnected &= self.connect(weather, "poa_beam", type260_genericsolar, "ibh")
        bConnected &= self.connect(weather, "tdry", type260_genericsolar, "tdb")
        bConnected &= self.connect(weather, "twet", type260_genericsolar, "twb")
        bConnected &= self.connect(weather, "wspd", type260_genericsolar, "vwind")
        bConnected &= self.connect(weather, "lat", type260_genericsolar, "latitude")
        bConnected &= self.connect(weather, "lon", type260_genericsolar, "longitude")
        bConnected &= self.connect(weather, "tz", type260_genericsolar, "timezone")
        bConnected &= self.connect(tou, "tou_value", type260_genericsolar, "TOUPeriod")
        if not bConnected:
            raise exec_error("tcsgeneric_solar", util.format("there was a problem connecting outputs of one unit to inputs of another for the simulation."))

        hours: size_t = 8760
        sf_haf = sf_adjustment_factors(self)
        if not sf_haf.setup():
            raise exec_error("tcsgeneric_solar", "failed to setup sf adjustment factors: " + sf_haf.error())
        sf_adjust = self.allocate("sf_adjust", hours)
        for i in range(hours):
            sf_adjust[i] = sf_haf(i)
        self.set_unit_value_ssc_array(type260_genericsolar, "sf_adjust")
        if 0 > self.simulate(3600.0, hours * 3600.0, 3600.0):
            raise exec_error("tcsgeneric_solar", util.format("there was a problem simulating in tcsgeneric_solar."))
        if not self.set_all_output_arrays():
            raise exec_error("tcsgeneric_solar", util.format("there was a problem returning the results from the simulation."))

        count: size_t = 0
        enet = self.as_array("enet", &count)
        if not enet or count != 8760:
            raise exec_error("tcsgeneric_solar", "Failed to retrieve hourly net energy")

        haf = adjustment_factors(self, "adjust")
        if not haf.setup():
            raise exec_error("tcsgeneric_solar", "failed to setup adjustment factors: " + haf.error())
        hourly = self.allocate("gen", count)
        for i in range(count):
            hourly[i] = enet[i] * 1000 * haf(i) # convert from MWh to kWh

        self.accumulate_annual("gen",        "annual_energy")
        self.accumulate_annual("w_gr",                 "annual_w_gr", 1000) # convert from MWh to kWh
        self.accumulate_annual("q_sf",                 "annual_q_sf")
        self.accumulate_annual("q_to_pb",              "annual_q_to_pb")
        self.accumulate_annual("q_to_tes",             "annual_q_to_tes")
        self.accumulate_annual("q_from_tes",           "annual_q_from_tes")
        self.accumulate_annual("q_hl_sf",              "annual_q_hl_sf")
        self.accumulate_annual("q_hl_tes",             "annual_q_hl_tes")
        self.accumulate_annual("q_dump_tot",           "annual_q_dump_tot")
        self.accumulate_annual("q_startup",            "annual_q_startup")
        fuel_MWht = self.accumulate_annual("q_fossil",             "annual_q_fossil")
        self.accumulate_monthly("gen",       "monthly_energy")
        self.accumulate_monthly("w_gr",                "monthly_w_gr", 1000) # convert from MWh to kWh
        self.accumulate_monthly("q_sf",                "monthly_q_sf")
        self.accumulate_monthly("q_to_pb",             "monthly_q_to_pb")
        self.accumulate_monthly("q_to_tes",            "monthly_q_to_tes")
        self.accumulate_monthly("q_from_tes",          "monthly_q_from_tes")
        self.accumulate_monthly("q_hl_sf",             "monthly_q_hl_sf")
        self.accumulate_monthly("q_hl_tes",            "monthly_q_hl_tes")
        self.accumulate_monthly("q_dump_tot",          "monthly_q_dump_tot")
        self.accumulate_monthly("q_startup",           "monthly_q_startup")
        self.accumulate_monthly("q_fossil",            "monthly_q_fossil")

        ae = self.as_number("annual_energy")
        pg = self.as_number("annual_w_gr")
        convfactor = (pg != 0) ? 100 * ae / pg : 0
        self.assign("conversion_factor", convfactor)

        kWhperkW = 0.0
        nameplate = self.as_double("system_capacity")
        annual_energy = 0.0
        for i in range(8760):
            annual_energy += hourly[i]
        if nameplate > 0:
            kWhperkW = annual_energy / nameplate
        self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
        self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
        self.assign("system_heat_rate", ssc_number_t(3.413)) # samsim tcsgeneric_solar
        self.assign("annual_fuel_usage", var_data(ssc_number_t(fuel_MWht * 1000.0)))

def tcsgeneric_solar_module_entry(prov: tcstypeprovider) -> Int32:
    # DEFINE_TCS_MODULE_ENTRY( tcsgeneric_solar, "Generic CSP model using the generic solar TCS types.", 4 )
    # This function is the module entry point. It creates a module instance and returns success.
    var mod = cm_tcsgeneric_solar(prov)
    # Registration and module lifecycle handled by the framework.
    return 0