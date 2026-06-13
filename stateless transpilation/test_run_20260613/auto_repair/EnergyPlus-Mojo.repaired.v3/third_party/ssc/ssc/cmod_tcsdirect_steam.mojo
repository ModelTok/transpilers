# /**
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
# """

from core import *
from tckernel import *
from common import *
from AutoPilot_API import *
from SolarField import *
from IOUtil import *
from csp_common import *

# static var_info _cm_vtab_tcsdirect_steam[] = {
var _cm_vtab_tcsdirect_steam: List[var_info] = [
# 	EXAMPLE LINES FOR INPUTS
#     { SSC_INPUT,        SSC_NUMBER,      "XXXXXXXXXXXXXX",      "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" },
#     { SSC_INPUT,        SSC_NUMBER,      "INTINTINTINT",        "Label",                                                          "",             "",            "parasitic",      "*",                       "INTEGER",               "" },
#     { SSC_INPUT,        SSC_ARRAY,       "XXXXXXXXXXX",         "Number indicating the receiver type",                            "",             "",            "hce",            "*",                       "",                      "" },
#     { SSC_INPUT,        SSC_MATRIX,      "XXXXXXXXXXX",         "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" },
# 														     
    var_info(SSC_INPUT, SSC_STRING, "solar_resource_file", "local weather file path", "", "", "Weather", "*", "LOCAL_FILE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "direct steam tower", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "weekday_schedule", "12x24 Time of Use Values for week days", "", "", "tou_translator", "*", "", ""), 
    var_info(SSC_INPUT, SSC_MATRIX, "weekend_schedule", "12x24 Time of Use Values for week end days", "", "", "tou_translator", "*", "", ""), 
    var_info(SSC_INPUT, SSC_NUMBER, "run_type", "Run type", "-", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "helio_width", "Heliostat width", "m", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "helio_height", "Heliostat height", "m", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "helio_optical_error", "Heliostat optical error", "rad", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "helio_active_fraction", "Heliostat active frac.", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "helio_reflectance", "Heliostat reflectance", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_absorptance", "Receiver absorptance", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_aspect", "Receiver aspect ratio", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_height", "Receiver height", "m", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_hl_perm2", "Receiver design heatloss", "kW/m2", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "land_bound_type", "Land boundary type", "", "", "heliostat", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "land_max", "Land max boundary", "-ORm", "", "heliostat", "?=7.5", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "land_min", "Land min boundary", "-ORm", "", "heliostat", "?=0.75", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "land_bound_table", "Land boundary table", "m", "", "heliostat", "?", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "land_bound_list", "Boundary table listing", "", "", "heliostat", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dni_des", "Design-point DNI", "W/m2", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "p_start", "Heliostat startup energy", "kWe-hr", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "p_track", "Heliostat tracking energy", "kWe", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "hel_stow_deploy", "Stow/deploy elevation", "deg", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "v_wind_max", "Max. wind velocity", "m/s", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "interp_nug", "Interpolation nugget", "", "", "heliostat", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "interp_beta", "Interpolation beta coef.", "", "", "heliostat", "?=1.99", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_flux_x", "Flux map X resolution", "", "", "heliostat", "?=12", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_flux_y", "Flux map Y resolution", "", "", "heliostat", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dens_mirror", "Ratio of reflective area to profile", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "helio_positions", "Heliostat position table", "m", "", "heliostat", "run_type=1", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "helio_aim_points", "Heliostat aim point table", "m", "", "heliostat", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "N_hel", "Number of heliostats", "", "", "heliostat", "?", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "eta_map", "Field efficiency array", "", "", "heliostat", "?", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "flux_positions", "Flux map sun positions", "deg", "", "heliostat", "?", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "flux_maps", "Flux map intensities", "", "", "heliostat", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "c_atm_0", "Attenuation coefficient 0", "", "", "heliostat", "?=0.006789", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "c_atm_1", "Attenuation coefficient 1", "", "", "heliostat", "?=0.1046", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "c_atm_2", "Attenuation coefficient 2", "", "", "heliostat", "?=-0.0107", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "c_atm_3", "Attenuation coefficient 3", "", "", "heliostat", "?=0.002845", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_facet_x", "Number of heliostat facets - X", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_facet_y", "Number of heliostat facets - Y", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "focus_type", "Heliostat focus method", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cant_type", "Heliostat cant method", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_flux_days", "No. days in flux map lookup", "", "", "heliostat", "?=8", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "delta_flux_hrs", "Hourly frequency in flux map lookup", "", "", "heliostat", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "water_usage_per_wash", "Water usage per wash", "L/m2_aper", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "washing_frequency", "Mirror washing frequency", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "H_rec", "The height of the receiver", "m", "", "receiver", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "THT", "The height of the tower (hel. pivot to rec equator)", "m", "", "receiver", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_design", "Receiver thermal design power", "MW", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "calc_fluxmaps", "Include fluxmap calculations", "", "", "heliostat", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tower_fixed_cost", "Tower fixed cost", "$", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tower_exp", "Tower cost scaling exponent", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_ref_cost", "Receiver reference cost", "$", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_ref_area", "Receiver reference area for cost scale", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_cost_exp", "Receiver cost scaling exponent", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "site_spec_cost", "Site improvement cost", "$/m2", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "heliostat_spec_cost", "Heliostat field cost", "$/m2", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "plant_spec_cost", "Power cycle specific cost", "$/kWe", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "bop_spec_cost", "BOS specific cost", "$/kWe", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tes_spec_cost", "Thermal energy storage cost", "$/kWht", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "land_spec_cost", "Total land area cost", "$/acre", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "contingency_rate", "Contingency for cost overrun", "%", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "sales_tax_rate", "Sales tax rate", "%", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "sales_tax_frac", "Percent of cost to which sales tax applies", "%", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cost_sf_fixed", "Solar field fixed cost", "$", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fossil_spec_cost", "Fossil system specific cost", "$/kWe", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_optimize", "Do SolarPILOT optimization", "", "", "heliostat", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "flux_max", "Maximum allowable flux", "", "", "heliostat", "?=1000", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "opt_init_step", "Optimization initial step size", "", "", "heliostat", "?=0.05", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "opt_max_iter", "Max. number iteration steps", "", "", "heliostat", "?=200", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "opt_conv_tol", "Optimization convergence tol", "", "", "heliostat", "?=0.001", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "opt_flux_penalty", "Optimization flux overage penalty", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "opt_algorithm", "Optimization algorithm", "", "", "heliostat", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "check_max_flux", "Check max flux at design point", "", "", "heliostat", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.per_acre", "EPC cost per acre", "$/acre", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.percent", "EPC cost percent of direct", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.per_watt", "EPC cost per watt", "$/W", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.fixed", "EPC fixed", "$", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.per_acre", "PLM cost per acre", "$/acre", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.percent", "PLM cost percent of direct", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.per_watt", "PLM cost per watt", "$/W", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.fixed", "PLM fixed", "$", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.sf.fixed_land_area", "Fixed land area", "acre", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.pt.sf.land_overhead_factor", "Land overhead factor", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "total_installed_cost", "Total installed cost", "$", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fossil_mode", "Fossil model: 1=Normal, 2=Supplemental", "-", "", "dsg_controller", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_pb_design", "Heat rate into powerblock at design", "MW", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_aux_max", "Maximum heat rate of auxiliary heater", "MW", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "lhv_eff", "Aux Heater lower heating value efficiency", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "h_tower", "Tower Height", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_panels", "Number of panels", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "flowtype", "Code for flow pattern through rec.", "-", "", "dsg_controller", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "d_rec", "Diameter of Receiver", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_rec_des", "Design-point thermal power", "MW", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "f_rec_min", "Minimum receiver absorbed power fraction", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_qf_delay", "Receiver start-up delay fraction of thermal energy of receiver running at design for 1 hour", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_su_delay", "Receiver start-up delay time", "hr", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "f_pb_cutoff", "Cycle cut-off fraction", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "f_pb_sb", "Cycle minimum standby fraction", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "t_standby_ini", "Power block standby time", "hr", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "x_b_target", "Target boiler outlet quality", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_rec_pump", "Feedwater pump efficiency", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_hp_in_des", "Design HP Turbine Inlet Pressure", "bar", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_hp_out_des", "Design HP Turbine Outlet Pressure", "bar", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "f_mdotrh_des", "Design reheat mass flow rate fraction", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "p_cycle_design", "Design Cycle Power", "MW", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "ct", "Cooling Type", "-", "", "dsg_controller", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_amb_des", "Design ambient temperature (power cycle)", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dT_cw_ref", "Reference condenser water dT", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_approach", "Approach temperature for wet cooling", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_ITD_des", "Approach temperature for dry cooling", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "hl_ffact", "Heat Loss Fudge FACTor", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "h_boiler", "Height of boiler", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "d_t_boiler", "O.D. of boiler tubes", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "th_t_boiler", "Thickness of boiler tubes", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_emis", "Emissivity of receiver tubes", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rec_absorptance", "Absorptance of receiver tubes", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "mat_boiler", "Numerical code for tube material", "-", "", "dsg_controller", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "h_sh", "Height of superheater", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "d_sh", "O.D. of superheater tubes", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "th_sh", "Thickness of superheater tubes", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "mat_sh", "Numerical code for superheater material", "-", "", "dsg_controller", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_sh_out_des", "Target superheater outlet temperature", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "h_rh", "Height of reheater", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "d_rh", "O.D. of reheater tubes", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "th_rh", "Thickness of reheater tubes", "m", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "mat_rh", "Numerical code for reheater material", "-", "", "dsg_controller", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_rh_out_des", "Target reheater outlet temperature", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cycle_max_frac", "Cycle maximum overdesign fraction", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "A_sf", "Solar field area", "m^2", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "ffrac", "Fossil dispatch logic", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_b_in_init", "Initial Boiler inlet pressure", "bar", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "f_mdot_rh_init", "Reheat mass flow rate fraction", "-", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_hp_out", "HP turbine outlet pressure", "bar", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_hp_out", "HP turbine outlet temperature", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_rh_target", "Target reheater outlet temp.", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_fw_init", "Initial Feedwater outlet temperature", "C", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_cond_init", "Condenser pressure", "Pa", "", "dsg_controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_ref", "Reference output electric power at design condition", "MW", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_ref", "Reference conversion efficiency at design condition", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_hot_ref", "Reference HTF inlet temperature at design", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_cold_ref", "Reference HTF outlet temperature at design", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dT_cw_ref", "Reference condenser cooling water inlet/outlet T diff", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_amb_des", "Reference ambient temperature at design point", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_sby_frac", "Fraction of thermal power required for standby mode", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_boil_des", "Boiler operating pressure @ design", "bar", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_rh_ref", "Reheater operating pressure at design", "bar", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rh_frac_ref", "Reheater flow fraction at design", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "startup_time", "Time needed for power block startup", "hr", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "startup_frac", "Fraction of design thermal power needed for startup", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_ITD_des", "ITD at design for dry system", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_cond_ratio", "Condenser pressure ratio", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pb_bd_frac", "Power block blowdown steam fraction ", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_cond_min", "Minimum condenser pressure", "inHg", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_pl_inc", "Number of part-load increments for the heat rejection system", "none", "", "powerblock", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "F_wc", "Fraction indicating wet cooling use for hybrid system", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_hot", "Hot HTF inlet temperature, from storage tank", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Piping_loss", "Thermal loss per meter of piping", "Wt/m", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Piping_length", "Total length of exposed piping", "m", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "piping_length_mult", "Piping length multiplier", "", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "piping_length_add", "Piping constant length", "m", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Design_power", "Power production at design conditions", "MWe", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "design_eff", "Power cycle efficiency at design", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pb_fixed_par", "Fixed parasitic load - runs at all times", "MWe/MWcap", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "aux_par", "Aux heater, boiler parasitic", "MWe/MWcap", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "aux_par_f", "Aux heater, boiler parasitic - multiplying fraction", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "aux_par_0", "Aux heater, boiler parasitic - constant coefficient", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "aux_par_1", "Aux heater, boiler parasitic - linear coefficient", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "aux_par_2", "Aux heater, boiler parasitic - quadratic coefficient", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "bop_par", "Balance of plant parasitic power fraction", "MWe/MWcap", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "bop_par_f", "Balance of plant parasitic power fraction - mult frac", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "bop_par_0", "Balance of plant parasitic power fraction - const coeff", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "bop_par_1", "Balance of plant parasitic power fraction - linear coeff", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "bop_par_2", "Balance of plant parasitic power fraction - quadratic coeff", "none", "", "parasitics", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "month", "Resource Month", "", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "hour", "Resource Hour of Day", "", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "solazi", "Resource Solar Azimuth", "deg", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "solzen", "Resource Solar Zenith", "deg", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "beam", "Resource Beam normal irradiance", "W/m2", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tdry", "Resource Dry bulb temperature", "C", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "twet", "Resource Wet bulb temperature", "C", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wspd", "Resource Wind Speed", "m/s", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pres", "Resource Pressure", "mbar", "", "weather", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tou_value", "Resource Time-of-use value", "", "", "tou", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_field", "Field optical efficiency", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "defocus", "Field optical focus fraction", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_b_conv", "Receiver boiler power loss to convection", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_b_rad", "Receiver boiler power loss to radiation", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_b_abs", "Receiver boiler power absorbed", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_b_in", "Receiver boiler pressure inlet", "kPa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_b_out", "Receiver boiler pressure outlet", "kPa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_drop_b", "Receiver boiler pressure drop", "Pa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_b", "Receiver boiler thermal efficiency", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_b_in", "Receiver boiler temperature inlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_boiling", "Receiver boiler temperature drum", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_max_b_surf", "Receiver boiler temperature surface max", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_sh", "Receiver superheater mass flow rate", "kg/hr", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_sh_conv", "Receiver superheater power loss to convection", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_sh_rad", "Receiver superheater power loss to radiation", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_sh_abs", "Receiver superheater power absorbed", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_sh_out", "Receiver superheater pressure outlet", "kPa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dP_sh", "Receiver superheater pressure drop", "Pa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_max_sh_surf", "Receiver superheater temperature surface max", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_sh", "Receiver superheater thermal efficiency", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "v_sh_max", "Receiver superheater velocity at outlet", "m/s", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "f_mdot_rh", "Receiver reheater mass flow rate fraction", "-", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_rh_conv", "Receiver reheater power loss to convection", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_rh_rad", "Receiver reheater power loss to radiation", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_rh_abs", "Receiver reheater power absorbed", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_rh_in", "Receiver reheater pressure inlet", "kPa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_rh_out", "Receiver reheater pressure outlet", "kPa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dP_rh", "Receiver reheater pressure drop", "Pa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_rh", "Receiver reheater thermal efficiency", "-", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_rh_in", "Receiver reheater temperature inlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_rh_out", "Receiver reheater temperature outlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_max_rh_surf", "Receiver reheater temperature surface max", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "v_rh_max", "Receiver reheater velocity at outlet", "m/s", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_inc_full", "Receiver power incident (excl. defocus)", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_abs_rec", "Receiver power absorbed total", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_rad_rec", "Receiver power loss to radiation total", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_conv_rec", "Receiver power loss to convection total", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_therm_in_rec", "Receiver power to steam total", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_rec", "Receiver thermal efficiency", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_aux", "Auxiliary mass flow rate", "kg/hr", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_aux", "Auxiliary heat rate delivered to cycle", "MW", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_aux_fuel", "Fuel energy rate to aux heater", "MMBTU", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_out_net", "Cycle electrical power output (net)", "MWe", "", "Net_E_Calc", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_cycle", "Cycle electrical power output (gross)", "MWe", "", "Net_E_Calc", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_fw", "Cycle temperature feedwater outlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_makeup", "Cycle mass flow rate cooling water makeup", "kg/hr", "", "Type250", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_cond", "Condenser pressure", "Pa", "", "Type250", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "f_bays", "Condenser fraction of operating bays", "", "", "Type250", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_boost", "Parasitic power receiver boost pump", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pparasi", "Parasitic power heliostat drives", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_plant_balance_tot", "Parasitic power generation-dependent load", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_fixed", "Parasitic power fixed load", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_cooling_tower_tot", "Parasitic power condenser operation", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_piping_tot", "Parasitic power equiv. header pipe losses", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_parasitics", "Parasitic power total consumption", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual Energy", "kWh", "", "Type228", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_W_cycle_gross", "Electrical source - Power cycle gross output", "kWh", "", "Type228", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_total_water_use", "Total Annual Water Usage: cycle + mirror washing", "m3", "", "PostProcess", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "conversion_factor", "Gross to Net Conversion Factor", "%", "", "Calculated", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "System heat rate", "MMBtu/MWh", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual fuel usage", "kWh", "", "", "*", "", ""),
    var_info_invalid
]

class cm_tcsdirect_steam(tcKernel):
    def __init__(self, prov: tcstypeprovider):
        tcKernel.__init__(self, prov)
        self.add_var_info(_cm_vtab_tcsdirect_steam)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)
        self.add_var_info(vtab_sf_adjustment_factors)

    def exec(self):
        debug_mode = False
        weather = 0
        if debug_mode:
            weather = self.add_unit("trnsys_weatherreader", "TRNSYS weather reader")
        else:
            weather = self.add_unit("weatherreader", "TCS weather reader")
        tou = self.add_unit("tou_translator", "Time of Use Translator")
        type_hel_field = self.add_unit("sam_mw_pt_heliostatfield")
        type265_dsg_controller = self.add_unit("sam_dsg_controller_type265")
        type234_powerblock = self.add_unit("sam_mw_type234")
        type228_parasitics = self.add_unit("sam_mw_pt_type228")
        if debug_mode:
            self.set_unit_value(weather, "file_name", "C:/svn_NREL/main/ssc/tcsdata/typelib/TRNSYS_weather_outputs/daggett_trnsys_weather.out")
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
            self.set_unit_value(weather, "file_name", self.as_string("solar_resource_file"))
            self.set_unit_value(weather, "track_mode", 0.0)
            self.set_unit_value(weather, "tilt", 0.0)
            self.set_unit_value(weather, "azimuth", 0.0)
        self.set_unit_value_ssc_matrix(tou, "weekday_schedule") # tou values from control will be between 1 and 9
        self.set_unit_value_ssc_matrix(tou, "weekend_schedule")
        self.set_unit_value_ssc_double(type_hel_field, "run_type") # , 0);	//0=auto, 1=user-type_hel_field, 2=user data
        self.set_unit_value_ssc_double(type_hel_field, "helio_width") # , 12.);
        self.set_unit_value_ssc_double(type_hel_field, "helio_height") # , 12.);
        self.set_unit_value_ssc_double(type_hel_field, "helio_optical_error") # , 0.00153);
        self.set_unit_value_ssc_double(type_hel_field, "helio_active_fraction") # , 0.97);
        self.set_unit_value_ssc_double(type_hel_field, "helio_reflectance") # , 0.90);
        self.set_unit_value_ssc_double(type_hel_field, "rec_absorptance") # , 0.94);
        is_optimize = self.as_boolean("is_optimize")
        """ 
        Any parameter that's dependent on the size of the solar field must be recalculated here 
        if the optimization is happening within the cmod
        """
        H_rec: Float64
        d_rec: Float64
        rec_aspect: Float64
        THT: Float64
        A_sf: Float64
        if is_optimize:
            self.message("Sorry, auto-optimization of Direct Steam systems is still under development and not yet available. Please optimize within the Solar Field page!", SSC_ERROR)
            return
            # solarpilot_invoke spi = solarpilot_invoke(self)
            # spi.run()
            # H_rec = spi.recs.front().rec_height.val
            # rec_aspect = spi.recs.front().rec_aspect.Val()
            # THT = spi.sf.tht.val
            # nr = int(spi.layout.heliostat_positions.size())
            # ssc_hl = self.allocate("helio_positions", nr, 2)
            # for i in range(nr):
            #     ssc_hl[i*2] = ssc_number_t(spi.layout.heliostat_positions[i].location.x)
            #     ssc_hl[i*2+1] = ssc_number_t(spi.layout.heliostat_positions[i].location.y)
            # A_sf = self.as_double("helio_height") * self.as_double("helio_width") * self.as_double("dens_mirror") * float(nr)
            # piping_length = THT * self.as_double("piping_length_mult") + self.as_double("piping_length_add")
            # self.assign("H_rec", var_data(ssc_number_t(H_rec)))
            # self.assign("rec_height", var_data(ssc_number_t(H_rec)))
            # self.assign("rec_aspect", var_data(ssc_number_t(rec_aspect)))
            # self.assign("d_rec", var_data(ssc_number_t(H_rec/rec_aspect)))
            # self.assign("THT", var_data(ssc_number_t(THT)))
            # self.assign("h_tower", var_data(ssc_number_t(THT)))
            # self.assign("A_sf", var_data(ssc_number_t(A_sf)))
            # self.assign("Piping_length", var_data(ssc_number_t(piping_length)))
            # total_direct_cost = 0.0
            # A_rec: Float64
            # switch spi.recs.front().rec_type.mapval():
            #     case var_receiver.REC_TYPE.EXTERNAL_CYLINDRICAL:
            #         h = spi.recs.front().rec_height.val
            #         d = h / spi.recs.front().rec_aspect.Val()
            #         A_rec = h * d * 3.1415926
            #         break
            #     case var_receiver.REC_TYPE.FLAT_PLATE:
            #         h = spi.recs.front().rec_height.val
            #         w = h / spi.recs.front().rec_aspect.Val()
            #         A_rec = h * w
            #         break
            # receiver = self.as_double("rec_ref_cost") * pow(A_rec/self.as_double("rec_ref_area"), self.as_double("rec_cost_exp"))
            # storage = self.as_double("q_pb_design") * self.as_double("tshours") * self.as_double("tes_spec_cost") * 1000.0
            # P_ref = self.as_double("P_ref") * 1000.0  # kWe
            # power_block = P_ref * (self.as_double("plant_spec_cost") + self.as_double("bop_spec_cost"))
            # site_improvements = A_sf * self.as_double("site_spec_cost")
            # heliostats = A_sf * self.as_double("heliostat_spec_cost")
            # cost_fixed = self.as_double("cost_sf_fixed")
            # fossil = P_ref * self.as_double("fossil_spec_cost")
            # tower = self.as_double("tower_fixed_cost") * exp(self.as_double("tower_exp") * (THT + 0.5*(-H_rec + self.as_double("helio_height"))))
            # total_direct_cost = (1.0 + self.as_double("contingency_rate")/100.0) * (
            #     site_improvements + heliostats + power_block + 
            #     cost_fixed + storage + fossil + tower + receiver)
            # land_area = spi.land.land_area.Val() * self.as_double("csp.pt.sf.land_overhead_factor") + self.as_double("csp.pt.sf.fixed_land_area")
            # cost_epc = ( 
            #     self.as_double("csp.pt.cost.epc.per_acre") * land_area
            #     + self.as_double("csp.pt.cost.epc.percent") * total_direct_cost / 100.0
            #     + P_ref * 1000.0 * self.as_double("csp.pt.cost.epc.per_watt") 
            #     + self.as_double("csp.pt.cost.epc.fixed"))
            # cost_plm = ( 
            #     self.as_double("csp.pt.cost.plm.per_acre") * land_area
            #     + self.as_double("csp.pt.cost.plm.percent") * total_direct_cost / 100.0
            #     + P_ref * 1000.0 * self.as_double("csp.pt.cost.plm.per_watt") 
            #     + self.as_double("csp.pt.cost.plm.fixed"))
            # cost_sales_tax = self.as_double("sales_tax_rate")/100.0 * total_direct_cost * self.as_double("sales_tax_frac")/100.0
            # total_indirect_cost = cost_epc + cost_plm + cost_sales_tax
            # total_installed_cost = total_direct_cost + total_indirect_cost
            # self.assign("total_installed_cost", var_data(ssc_number_t(total_installed_cost)))
        else:
            H_rec = self.as_double("H_rec")
            rec_aspect = self.as_double("rec_aspect")
            THT = self.as_double("THT")
            A_sf = self.as_double("A_sf")
        d_rec = H_rec / rec_aspect
        self.set_unit_value_ssc_double(type_hel_field, "rec_height", H_rec)
        self.set_unit_value_ssc_double(type_hel_field, "rec_aspect", rec_aspect)
        self.set_unit_value_ssc_double(type_hel_field, "h_tower", THT)
        self.set_unit_value_ssc_double(type_hel_field, "rec_hl_perm2")
        self.set_unit_value_ssc_double(type_hel_field, "q_design", self.as_double("Q_rec_des"))
        self.set_unit_value_ssc_double(type_hel_field, "dni_des")
        self.set_unit_value(type_hel_field, "weather_file", self.as_string("solar_resource_file"))
        self.set_unit_value_ssc_double(type_hel_field, "land_bound_type")
        self.set_unit_value_ssc_double(type_hel_field, "land_max")
        self.set_unit_value_ssc_double(type_hel_field, "land_min")
        self.set_unit_value_ssc_double(type_hel_field, "p_start")
        self.set_unit_value_ssc_double(type_hel_field, "p_track")
        self.set_unit_value_ssc_double(type_hel_field, "hel_stow_deploy")
        self.set_unit_value_ssc_double(type_hel_field, "v_wind_max")
        self.set_unit_value_ssc_double(type_hel_field, "n_flux_x")
        self.set_unit_value_ssc_double(type_hel_field, "n_flux_y")
        self.set_unit_value_ssc_double(type_hel_field, "dens_mirror")
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_0")
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_1")
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_2")
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_3")
        self.set_unit_value_ssc_double(type_hel_field, "n_facet_x")
        self.set_unit_value_ssc_double(type_hel_field, "n_facet_y")
        self.set_unit_value_ssc_double(type_hel_field, "focus_type")
        self.set_unit_value_ssc_double(type_hel_field, "cant_type")
        self.set_unit_value_ssc_double(type_hel_field, "n_flux_days")
        self.set_unit_value_ssc_double(type_hel_field, "delta_flux_hrs")
        run_type = int(self.get_unit_value_number(type_hel_field, "run_type"))
        # if(run_type == 0){
        # }
        # else 
        if run_type == 1:
            self.set_unit_value_ssc_matrix(type_hel_field, "helio_positions")
        elif run_type == 2:
            self.set_unit_value_ssc_matrix(type_hel_field, "eta_map")
            self.set_unit_value_ssc_matrix(type_hel_field, "flux_positions")
            self.set_unit_value_ssc_matrix(type_hel_field, "flux_maps")
        bConnected = self.connect(weather, "wspd", type_hel_field, "vwind")
        self.set_unit_value_ssc_double(type_hel_field, "field_control", 1.0)
        self.set_unit_value_ssc_double(weather, "solzen", 90.0) # initialize to be on the horizon
        bConnected = bConnected and self.connect(weather, "solzen", type_hel_field, "solzen")
        bConnected = bConnected and self.connect(weather, "solazi", type_hel_field, "solaz")
        sf_haf = sf_adjustment_factors(self)
        if not sf_haf.setup():
            raise exec_error("tcsgeneric_solar", "failed to setup sf adjustment factors: " + sf_haf.error())
        sf_adjust = self.allocate("sf_adjust", 8760)
        for i in range(8760):
            sf_adjust[i] = sf_haf(i)
        self.set_unit_value_ssc_array(type_hel_field, "sf_adjust")
        self.set_unit_value_ssc_double(type265_dsg_controller, "fossil_mode")
        self.set_unit_value_ssc_double(type265_dsg_controller, "q_pb_design")
        self.set_unit_value_ssc_double(type265_dsg_controller, "q_aux_max")
        self.set_unit_value_ssc_double(type265_dsg_controller, "lhv_eff")
        self.set_unit_value_ssc_double(type265_dsg_controller, "h_tower", THT)
        self.set_unit_value_ssc_double(type265_dsg_controller, "n_panels")
        self.set_unit_value_ssc_double(type265_dsg_controller, "flowtype")
        self.set_unit_value_ssc_double(type265_dsg_controller, "d_rec", d_rec)
        self.set_unit_value_ssc_double(type265_dsg_controller, "q_rec_des")
        self.set_unit_value_ssc_double(type265_dsg_controller, "f_rec_min")
        self.set_unit_value_ssc_double(type265_dsg_controller, "rec_qf_delay")
        self.set_unit_value_ssc_double(type265_dsg_controller, "rec_su_delay")
        self.set_unit_value_ssc_double(type265_dsg_controller, "f_pb_cutoff")
        self.set_unit_value_ssc_double(type265_dsg_controller, "f_pb_sb")
        self.set_unit_value_ssc_double(type265_dsg_controller, "t_standby_ini")
        self.set_unit_value_ssc_double(type265_dsg_controller, "x_b_target")
        self.set_unit_value_ssc_double(type265_dsg_controller, "eta_rec_pump")
        self.set_unit_value_ssc_double(type265_dsg_controller, "P_hp_in_des")
        self.set_unit_value_ssc_double(type265_dsg_controller, "P_hp_out_des")
        self.set_unit_value_ssc_double(type265_dsg_controller, "f_mdotrh_des")
        self.set_unit_value_ssc_double(type265_dsg_controller, "p_cycle_design")
        self.set_unit_value_ssc_double(type265_dsg_controller, "ct")
        self.set_unit_value_ssc_double(type265_dsg_controller, "T_amb_des")
        self.set_unit_value_ssc_double(type265_dsg_controller, "dT_cw_ref")
        self.set_unit_value_ssc_double(type265_dsg_controller, "T_approach")
        self.set_unit_value_ssc_double(type265_dsg_controller, "T_ITD_des")
        self.set_unit_value_ssc_double(type265_dsg_controller, "hl_ffact")
        self.set_unit_value_ssc_double(type265_dsg_controller, "h_boiler")
        self.set_unit_value_ssc_double(type265_dsg_controller, "d_t_boiler")
        self.set_unit_value_ssc_double(type265_dsg_controller, "th_t_boiler")
        self.set_unit_value_ssc_double(type265_dsg_controller, "emis_boiler", "rec_emis")
        self.set_unit_value_ssc_double(type265_dsg_controller, "abs_boiler", "rec_absorptance")
        self.set_unit_value_ssc_double(type265_dsg_controller, "mat_boiler")
        self.set_unit_value_ssc_double(type265_dsg_controller, "h_sh")
        self.set_unit_value_ssc_double(type265_dsg_controller, "d_sh")
        self.set_unit_value_ssc_double(type265_dsg_controller, "th_sh")
        self.set_unit_value_ssc_double(type265_dsg_controller, "emis_sh", "rec_emis")
        self.set_unit_value_ssc_double(type265_dsg_controller, "abs_sh", "rec_absorptance")
        self.set_unit_value_ssc_double(type265_dsg_controller, "mat_sh")
        self.set_unit_value_ssc_double(type265_dsg_controller, "T_sh_out_des")
        self.set_unit_value_ssc_double(type265_dsg_controller, "h_rh")
        self.set_unit_value_ssc_double(type265_dsg_controller, "d_rh")
        self.set_unit_value_ssc_double(type265_dsg_controller, "th_rh")
        self.set_unit_value_ssc_double(type265_dsg_controller, "emis_rh", "rec_emis")
        self.set_unit_value_