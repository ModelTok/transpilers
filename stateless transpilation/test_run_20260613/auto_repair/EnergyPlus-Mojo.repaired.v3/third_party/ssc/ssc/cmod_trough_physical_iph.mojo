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
from lib_util import *
from common import *
from csp_solver_core import *
from csp_solver_trough_collector_receiver import *
from csp_solver_pc_heat_sink import *
from csp_solver_two_tank_tes import *
from csp_solver_tou_block_schedules import *

static var _cm_vtab_trough_physical_process_heat: List[var_info] = List[var_info](
    var_info(SSC_INPUT, SSC_STRING, "file_name", "Local weather file with path", "none", "", "Weather", "*", "LOCAL_FILE", ""),
    var_info(SSC_INPUT, SSC_TABLE, "solar_resource_data", "Weather resource data in memory", "", "", "Weather", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "track_mode", "Tracking mode", "none", "", "Weather", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tilt", "Tilt angle of surface/axis", "none", "", "Weather", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "azimuth", "Azimuth angle of surface/axis", "none", "", "Weather", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "I_bn_des", "Solar irradiation at design", "C", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "solar_mult", "Solar multiple", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_loop_in_des", "Design loop inlet temperature", "C", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_loop_out", "Target loop outlet temperature", "C", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_pb_design", "Design heat input to power block", "MWt", "", "controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tshours", "Equivalent full-load thermal storage hours", "hr", "", "system_design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nSCA", "Number of SCAs in a loop", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nHCEt", "Number of HCE types", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nColt", "Number of collector types", "none", "constant=4", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nHCEVar", "Number of HCE variants per type", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nLoops", "Number of loops in the field", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_pump", "HTF pump efficiency", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HDR_rough", "Header pipe roughness", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "theta_stow", "Stow angle", "deg", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "theta_dep", "Deploy angle", "deg", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Row_Distance", "Spacing between rows (centerline to centerline)", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "FieldConfig", "Number of subfield headers", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_model_heat_sink_piping", "Should model consider piping through heat sink?", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "L_heat_sink_piping", "Length of piping (full mass flow) through heat sink (if applicable)", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "m_dot_htfmin", "Minimum loop HTF flow rate", "kg/s", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "m_dot_htfmax", "Maximum loop HTF flow rate", "kg/s", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Fluid", "Field HTF fluid ID number", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wind_stow_speed", "Trough wind stow speed", "m/s", "", "solar_field", "?=50", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "field_fl_props", "User defined field fluid property data", "-", "", "controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_fp", "Freeze protection temperature (heat trace activation temperature)", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Pipe_hl_coef", "Loss coefficient from the header, runner pipe, and non-HCE piping", "m/s", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "SCA_drives_elec", "Tracking power, in Watts per SCA drive", "W/m2-K", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "water_usage_per_wash", "Water usage per wash", "L/m2_aper", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "washing_frequency", "Mirror washing frequency", "-/year", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "accept_mode", "Acceptance testing mode?", "0/1", "no/yes", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "accept_init", "In acceptance testing mode - require steady-state startup", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "accept_loc", "In acceptance testing mode - temperature sensor location", "1/2", "hx/loop", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "mc_bal_hot", "Heat capacity of the balance of plant on the hot side", "kWht/K-MWt", "none", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "mc_bal_cold", "Heat capacity of the balance of plant on the cold side", "kWht/K-MWt", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "mc_bal_sca", "Non-HTF heat capacity associated with each SCA - per meter basis", "Wht/K-m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "W_aperture", "The collector aperture width (Total structural area used for shadowing)", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "A_aperture", "Reflective aperture area of the collector", "m2", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "TrackingError", "User-defined tracking error derate", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "GeomEffects", "User-defined geometry effects derate", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "Rho_mirror_clean", "User-defined clean mirror reflectivity", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "Dirt_mirror", "User-defined dirt on mirror derate", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "Error", "User-defined general optical error derate ", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "Ave_Focal_Length", "Average focal length of the collector ", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "L_SCA", "Length of the SCA ", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "L_aperture", "Length of a single mirror/HCE unit", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "ColperSCA", "Number of individual collector sections in an SCA ", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "Distance_SCA", "Piping distance between SCA's in the field", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "IAM_matrix", "IAM coefficients, matrix for 4 collectors", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "HCE_FieldFrac", "Fraction of the field occupied by this HCE type ", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_2", "Inner absorber tube diameter", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_3", "Outer absorber tube diameter", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_4", "Inner glass envelope diameter ", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_5", "Outer glass envelope diameter ", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_p", "Diameter of the absorber flow plug (optional) ", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Flow_type", "Flow type through the absorber", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Rough", "Roughness of the internal surface ", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "alpha_env", "Envelope absorptance ", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_11", "Absorber emittance for receiver type 1 variation 1", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_12", "Absorber emittance for receiver type 1 variation 2", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_13", "Absorber emittance for receiver type 1 variation 3", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_14", "Absorber emittance for receiver type 1 variation 4", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_21", "Absorber emittance for receiver type 2 variation 1", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_22", "Absorber emittance for receiver type 2 variation 2", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_23", "Absorber emittance for receiver type 2 variation 3", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_24", "Absorber emittance for receiver type 2 variation 4", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_31", "Absorber emittance for receiver type 3 variation 1", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_32", "Absorber emittance for receiver type 3 variation 2", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_33", "Absorber emittance for receiver type 3 variation 3", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_34", "Absorber emittance for receiver type 3 variation 4", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_41", "Absorber emittance for receiver type 4 variation 1", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_42", "Absorber emittance for receiver type 4 variation 2", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_43", "Absorber emittance for receiver type 4 variation 3", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "epsilon_3_44", "Absorber emittance for receiver type 4 variation 4", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "alpha_abs", "Absorber absorptance ", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Tau_envelope", "Envelope transmittance", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "EPSILON_4", "Inner glass envelope emissivities (Pyrex) ", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "EPSILON_5", "Outer glass envelope emissivities (Pyrex) ", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "GlazingIntactIn", "Glazing intact (broken glass) flag {1=true, else=false}", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "P_a", "Annulus gas pressure", "torr", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "AnnulusGas", "Annulus gas type (1=air, 26=Ar, 27=H2)", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "AbsorberMaterial", "Absorber material type", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Shadowing", "Receiver bellows shadowing loss factor", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Dirt_HCE", "Loss due to dirt on the receiver envelope", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Design_loss", "Receiver heat loss at design", "W/m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "SCAInfoArray", "Receiver (,1) and collector (,2) type for each assembly in loop", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "SCADefocusArray", "Collector defocus order", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pb_pump_coef", "Pumping power to move 1kg of HTF through PB loop", "kW/kg", "", "controller", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "init_hot_htf_percent", "Initial fraction of avail. vol that is hot", "%", "", "TES", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "h_tank", "Total height of tank (height of HTF when tank is full", "m", "", "TES", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cold_tank_max_heat", "Rated heater capacity for cold tank heating", "MW", "", "TES", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "u_tank", "Loss coefficient from the tank", "W/m2-K", "", "TES", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tank_pairs", "Number of equivalent tank pairs", "-", "", "TES", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cold_tank_Thtr", "Minimum allowable cold tank HTF temp", "C", "", "TES", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "h_tank_min", "Minimum allowable HTF height in storage tank", "m", "", "TES_2tank", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "hot_tank_Thtr", "Minimum allowable hot tank HTF temp", "C", "", "TES_2tank", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "hot_tank_max_heat", "Rated heater capacity for hot tank heating", "MW", "", "TES_2tank", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "weekday_schedule", "12x24 CSP operation Time-of-Use Weekday schedule", "-", "", "tou", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "weekend_schedule", "12x24 CSP operation Time-of-Use Weekend schedule", "-", "", "tou", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "dispatch_sched_weekday", "12x24 PPA pricing Weekday schedule", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "dispatch_sched_weekend", "12x24 PPA pricing Weekend schedule", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_tod_pc_target_also_pc_max", "Is the TOD target cycle heat input also the max cycle heat input?", "", "", "tou", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_dispatch", "Allow dispatch optimization?", "-", "", "tou", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_write_ampl_dat", "Write AMPL data files for dispatch run", "-", "", "tou", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_ampl_engine", "Run dispatch optimization with external AMPL engine", "-", "", "tou", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_STRING, "ampl_data_dir", "AMPL data file directory", "-", "", "tou", "?=''", "", ""),
    var_info(SSC_INPUT, SSC_STRING, "ampl_exec_call", "System command to run AMPL code", "-", "", "tou", "?='ampl sdk_solution.run'", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_frequency", "Frequency for dispatch optimization calculations", "hour", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_steps_per_hour", "Time steps per hour for dispatch optimization calculations", "-", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_horizon", "Time horizon for dispatch optimization", "hour", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_max_iter", "Max. no. dispatch optimization iterations", "-", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_timeout", "Max. dispatch optimization solve duration", "s", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_mip_gap", "Dispatch optimization solution tolerance", "-", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_spec_presolve", "Dispatch optimization presolve heuristic", "-", "", "tou", "?=-1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_spec_bb", "Dispatch optimization B&B heuristic", "-", "", "tou", "?=-1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_reporting", "Dispatch optimization reporting level", "-", "", "tou", "?=-1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_spec_scaling", "Dispatch optimization scaling heuristic", "-", "", "tou", "?=-1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_time_weighting", "Dispatch optimization future time discounting factor", "-", "", "tou", "?=0.99", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_rsu_cost", "Receiver startup cost", "$", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_csu_cost", "Heat sink startup cost", "$", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "disp_pen_delta_w", "Dispatch heat production change penalty", "$/kWt-change", "", "tou", "is_dispatch=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_rec_standby", "Receiver standby energy consumption", "kWt", "", "tou", "?=9e99", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_rec_heattrace", "Receiver heat trace energy consumption during startup", "kWe-hr", "", "tou", "?=0.0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_wlim_series", "Use time-series net heat generation limits", "", "", "tou", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "wlim_series", "Time series net heat generation limits", "kWt", "", "tou", "is_wlim_series=1", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "f_turb_tou_periods", "Dispatch logic for heat sink load fraction", "-", "", "tou", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "ppa_multiplier_model", "PPA multiplier model", "0/1", "0=diurnal,1=timestep", "tou", "?=0", "INTEGER,MIN=0", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dispatch_factors_ts", "Dispatch payment factor array", "", "", "tou", "ppa_multiplier_model=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor1", "Dispatch payment factor 1", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor2", "Dispatch payment factor 2", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor3", "Dispatch payment factor 3", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor4", "Dispatch payment factor 4", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor5", "Dispatch payment factor 5", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor6", "Dispatch payment factor 6", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor7", "Dispatch payment factor 7", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor8", "Dispatch payment factor 8", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dispatch_factor9", "Dispatch payment factor 9", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_dispatch_series", "Use time-series dispatch factors", "", "", "tou", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dispatch_series", "Time series dispatch factors", "", "", "tou", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pb_fixed_par", "Fraction of rated gross power constantly consumed", "MWe/MWcap", "", "system", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "bop_array", "Balance of plant parasitic power fraction, mult frac and const, linear and quad coeff", "", "", "system", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "aux_array", "Auxiliary heater, mult frac and const, linear and quad coeff", "", "", "system", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "calc_design_pipe_vals", "Calculate temps and pressures at design conditions for runners and headers", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "V_hdr_cold_max", "Maximum HTF velocity in the cold headers at design", "m/s", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "V_hdr_cold_min", "Minimum HTF velocity in the cold headers at design", "m/s", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "V_hdr_hot_max", "Maximum HTF velocity in the hot headers at design", "m/s", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "V_hdr_hot_min", "Minimum HTF velocity in the hot headers at design", "m/s", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "N_max_hdr_diams", "Maximum number of diameters in each of the hot and cold headers", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "L_rnr_pb", "Length of runner pipe in power block", "m", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "L_rnr_per_xpan", "Threshold length of straight runner pipe without an expansion loop", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "L_xpan_hdr", "Compined perpendicular lengths of each header expansion loop", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "L_xpan_rnr", "Compined perpendicular lengths of each runner expansion loop", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Min_rnr_xpans", "Minimum number of expansion loops per single-diameter runner section", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "northsouth_field_sep", "North/south separation between subfields. 0 = SCAs are touching", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "N_hdr_per_xpan", "Number of collector loops per expansion loop", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "offset_xpan_hdr", "Location of first header expansion loop. 1 = after first collector loop", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "K_cpnt", "Interconnect component minor loss coefficients, row=intc, col=cpnt", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_cpnt", "Interconnect component diameters, row=intc, col=cpnt", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "L_cpnt", "Interconnect component lengths, row=intc, col=cpnt", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Type_cpnt", "Interconnect component type, row=intc, col=cpnt", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "custom_sf_pipe_sizes", "Use custom solar field pipe diams, wallthks, and lengths", "none", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sf_rnr_diams", "Custom runner diameters", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sf_rnr_wallthicks", "Custom runner wall thicknesses", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sf_rnr_lengths", "Custom runner lengths", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sf_hdr_diams", "Custom header diameters", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sf_hdr_wallthicks", "Custom header wall thicknesses", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sf_hdr_lengths", "Custom header lengths", "m", "", "solar_field", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tanks_in_parallel", "Tanks are in parallel, not in series, with solar field", "-", "", "controller", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "time_hr", "Time at end of timestep", "hr", "", "Solver", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "month", "Resource Month", "", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "hour_day", "Resource Hour of Day", "", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "solazi", "Resource Solar Azimuth", "deg", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "solzen", "Resource Solar Zenith", "deg", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "beam", "Resource Beam normal irradiance", "W/m2", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tdry", "Resource Dry bulb temperature", "C", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "twet", "Resource Wet bulb temperature", "C", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wspd", "Resource Wind Speed", "m/s", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pres", "Resource Pressure", "mbar", "", "weather", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "Theta_ave", "Field collector solar incidence angle", "deg", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "CosTh_ave", "Field collector cosine efficiency", "", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "IAM_ave", "Field collector incidence angle modifier", "", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "RowShadow_ave", "Field collector row shadowing loss", "", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "EndLoss_ave", "Field collector optical end loss", "", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dni_costh", "Field collector DNI-cosine product", "W/m2", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "EqOpteff", "Field optical efficiency before defocus", "", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "SCAs_def", "Field fraction of focused SCAs", "", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_inc_sf_tot", "Field thermal power incident", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "qinc_costh", "Field thermal power incident after cosine", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dot_rec_inc", "Receiver thermal power incident", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dot_rec_thermal_loss", "Receiver thermal losses", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dot_rec_abs", "Receiver thermal power absorbed", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dot_piping_loss", "Field piping thermal losses", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "e_dot_field_int_energy", "Field change in material/htf internal energy", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dot_htf_sf_out", "Field thermal power leaving in HTF", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dot_freeze_prot", "Field freeze protection required", "MWt", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_loop", "Receiver mass flow rate", "kg/s", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_field_recirc", "Field total mass flow recirculated", "kg/s", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_field_delivered", "Field total mass flow delivered", "kg/s", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_field_cold_in", "Field timestep-averaged inlet temperature", "C", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_rec_cold_in", "Loop timestep-averaged inlet temperature", "C", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_rec_hot_out", "Loop timestep-averaged outlet temperature", "C", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_field_hot_out", "Field timestep-averaged outlet temperature", "C", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "deltaP_field", "Field pressure drop", "bar", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_sca_track", "Field collector tracking power", "MWe", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_field_pump", "Field htf pumping power", "MWe", "", "trough_field", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dot_to_heat_sink", "Heat sink thermal power", "MWt", "", "Heat_Sink", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_pc_pump", "Heat sink pumping power", "MWe", "", "Heat_Sink", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_htf_heat_sink", "Heat sink HTF mass flow", "kg/s", "", "Heat_Sink", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_heat_sink_in", "Heat sink HTF inlet temp", "C", "", "Heat_Sink", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_heat_sink_out", "Heat sink HTF outlet temp", "C", "", "Heat_Sink", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tank_losses", "TES thermal losses", "MWt", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_tes_heater", "TES freeze protection power", "MWe", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_tes_hot", "TES hot temperature", "C", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_tes_cold", "TES cold temperature", "C", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "mass_tes_cold", "TES cold tank mass (end)", "kg", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "mass_tes_hot", "TES hot tank mass (end)", "kg", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dc_tes", "TES discharge thermal power", "MWt", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_ch_tes", "TES charge thermal power", "MWt", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "e_ch_tes", "TES charge state", "MWht", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_cr_to_tes_hot", "Mass flow: field to hot TES", "kg/s", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_tes_hot_out", "Mass flow: TES hot out", "kg/s", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_pc_to_tes_cold", "Mass flow: cycle to cold TES", "kg/s", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_tes_cold_out", "Mass flow: TES cold out", "kg/s", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_field_to_cycle", "Mass flow: field to cycle", "kg/s", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_cycle_to_field", "Mass flow: cycle to field", "kg/s", "", "TES", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_parasitic_tot", "System total electrical parasitic", "MWe", "", "Heat_Sink", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "op_mode_1", "1st operating mode", "", "", "Solver", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "op_mode_2", "2nd op. mode, if applicable", "", "", "Solver", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "op_mode_3", "3rd op. mode, if applicable", "", "", "Solver", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_balance", "Relative mass flow balance error", "", "", "Controller", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_balance", "Relative energy balance error", "", "", "Controller", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual Net Thermal Energy Production w/ avail derate", "kWt-hr", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_gross_energy", "Annual Gross Thermal Energy Production w/ avail derate", "kWt-hr", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_thermal_consumption", "Annual thermal freeze protection required", "kWt-hr", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_electricity_consumption", "Annual electricity consumption w/ avail derate", "kWe-hr", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_total_water_use", "Total Annual Water Usage", "m^3", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_field_freeze_protection", "Annual thermal power for field freeze protection", "kWt-hr", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_tes_freeze_protection", "Annual thermal power for TES freeze protection", "kWt-hr", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "Post-process", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWht/kWt", "", "Post-process", "*", "", ""),
    var_info_invalid
)

class cm_trough_physical_process_heat(compute_module):
    def __init__(owned self):
        add_var_info(_cm_vtab_trough_physical_process_heat)
        add_var_info(vtab_adjustment_factors)

    def exec(owned self):
        weather_reader: C_csp_weatherreader
        if is_assigned("file_name"):
            weather_reader.m_weather_data_provider = make_shared[weatherfile](as_string("file_name"))
            if weather_reader.m_weather_data_provider.has_message():
                log(weather_reader.m_weather_data_provider.message(), SSC_WARNING)
        if is_assigned("solar_resource_data"):
            weather_reader.m_weather_data_provider = make_shared[weatherdata](lookup("solar_resource_data"))
            if weather_reader.m_weather_data_provider.has_message():
                log(weather_reader.m_weather_data_provider.message(), SSC_WARNING)
        weather_reader.m_filename = as_string("file_name")
        weather_reader.m_trackmode = 0
        weather_reader.m_tilt = 0.0
        weather_reader.m_azimuth = 0.0
        weather_reader.init()
        if weather_reader.has_error():
            throw exec_error("trough_physical_iph", weather_reader.get_error())
        nhourssim: Float64 = 8760.0
        sim_setup: C_csp_solver.S_sim_setup
        sim_setup.m_sim_time_start = 0.0
        sim_setup.m_sim_time_end = nhourssim * 3600.0
        steps_per_hour: size = 1
        n_wf_records: size = weather_reader.m_weather_data_provider.nrecords()
        steps_per_hour = n_wf_records / 8760
        n_steps_fixed: size = steps_per_hour * 8760
        sim_setup.m_report_step = 3600.0 / Float64(steps_per_hour)
        c_trough: C_csp_trough_collector_receiver
        c_trough.m_nSCA = as_integer("nSCA")
        c_trough.m_nHCEt = as_integer("nHCEt")
        c_trough.m_nColt = as_integer("nColt")
        c_trough.m_nHCEVar = as_integer("nHCEVar")
        c_trough.m_nLoops = as_integer("nLoops")
        c_trough.m_FieldConfig = as_integer("FieldConfig")
        c_trough.m_L_power_block_piping = as_double("L_heat_sink_piping")
        c_trough.m_include_fixed_power_block_runner = as_boolean("is_model_heat_sink_piping")
        c_trough.m_eta_pump = as_double("eta_pump")
        c_trough.m_Fluid = as_integer("Fluid")
        c_trough.m_fthrctrl = 2
        c_trough.m_accept_loc = as_integer("accept_loc")
        c_trough.m_HDR_rough = as_double("HDR_rough")
        c_trough.m_theta_stow = as_double("theta_stow")
        c_trough.m_theta_dep = as_double("theta_dep")
        c_trough.m_Row_Distance = as_double("Row_Distance")
        T_loop_in_des: Float64 = as_double("T_loop_in_des")
        c_trough.m_T_loop_in_des = T_loop_in_des
        T_loop_out_des: Float64 = as_double("T_loop_out")
        c_trough.m_T_loop_out_des = T_loop_out_des
        T_startup: Float64 = 0.67 * T_loop_in_des + 0.33 * T_loop_out_des
        c_trough.m_T_startup = T_startup
        c_trough.m_m_dot_htfmin = as_double("m_dot_htfmin")
        c_trough.m_m_dot_htfmax = as_double("m_dot_htfmax")
        c_trough.m_field_fl_props = as_matrix("field_fl_props")
        c_trough.m_T_fp = as_double("T_fp")
        c_trough.m_I_bn_des = as_double("I_bn_des")
        c_trough.m_V_hdr_cold_max = as_double("V_hdr_cold_max")
        c_trough.m_V_hdr_cold_min = as_double("V_hdr_cold_min")
        c_trough.m_V_hdr_hot_max = as_double("V_hdr_hot_max")
        c_trough.m_V_hdr_hot_min = as_double("V_hdr_hot_min")
        c_trough.m_Pipe_hl_coef = as_double("Pipe_hl_coef")
        c_trough.m_SCA_drives_elec = as_double("SCA_drives_elec")
        c_trough.m_ColTilt = as_double("tilt")
        c_trough.m_ColAz = as_double("azimuth")
        c_trough.m_wind_stow_speed = as_double("wind_stow_speed")
        c_trough.m_accept_mode = as_integer("accept_mode")
        c_trough.m_accept_init = as_boolean("accept_init")
        c_trough.m_solar_mult = as_double("solar_mult")
        c_trough.m_mc_bal_hot_per_MW = as_double("mc_bal_hot")
        c_trough.m_mc_bal_cold_per_MW = as_double("mc_bal_cold")
        c_trough.m_mc_bal_sca = as_double("mc_bal_sca")
        nval_W_aperture: size = 0
        W_aperture: Pointer[ssc_number_t] = as_array("W_aperture", &nval_W_aperture)
        c_trough.m_W_aperture.resize(nval_W_aperture)
        for i in range(nval_W_aperture):
            c_trough.m_W_aperture[i] = Float64(W_aperture[i])
        nval_A_aperture: size = 0
        A_aperture: Pointer[ssc_number_t] = as_array("A_aperture", &nval_A_aperture)
        c_trough.m_A_aperture.resize(nval_A_aperture)
        for i in range(nval_A_aperture):
            c_trough.m_A_aperture[i] = Float64(A_aperture[i])
        nval_TrackingError: size = 0
        TrackingError: Pointer[ssc_number_t] = as_array("TrackingError", &nval_TrackingError)
        c_trough.m_TrackingError.resize(nval_TrackingError)
        for i in range(nval_TrackingError):
            c_trough.m_TrackingError[i] = Float64(TrackingError[i])
        nval_GeomEffects: size = 0
        GeomEffects: Pointer[ssc_number_t] = as_array("GeomEffects", &nval_GeomEffects)
        c_trough.m_GeomEffects.resize(nval_GeomEffects)
        for i in range(nval_GeomEffects):
            c_trough.m_GeomEffects[i] = Float64(GeomEffects[i])
        nval_Rho_mirror_clean: size = 0
        Rho_mirror_clean: Pointer[ssc_number_t] = as_array("Rho_mirror_clean", &nval_Rho_mirror_clean)
        c_trough.m_Rho_mirror_clean.resize(nval_Rho_mirror_clean)
        for i in range(nval_Rho_mirror_clean):
            c_trough.m_Rho_mirror_clean[i] = Float64(Rho_mirror_clean[i])
        nval_Dirt_mirror: size = 0
        Dirt_mirror: Pointer[ssc_number_t] = as_array("Dirt_mirror", &nval_Dirt_mirror)
        c_trough.m_Dirt_mirror.resize(nval_Dirt_mirror)
        for i in range(nval_Dirt_mirror):
            c_trough.m_Dirt_mirror[i] = Float64(Dirt_mirror[i])
        nval_Error: size = 0
        Error: Pointer[ssc_number_t] = as_array("Error", &nval_Error)
        c_trough.m_Error.resize(nval_Error)
        for i in range(nval_Error):
            c_trough.m_Error[i] = Float64(Error[i])
        nval_Ave_Focal_Length: size = 0
        Ave_Focal_Length: Pointer[ssc_number_t] = as_array("Ave_Focal_Length", &nval_Ave_Focal_Length)
        c_trough.m_Ave_Focal_Length.resize(nval_Ave_Focal_Length)
        for i in range(nval_Ave_Focal_Length):
            c_trough.m_Ave_Focal_Length[i] = Float64(Ave_Focal_Length[i])
        nval_L_SCA: size = 0
        L_SCA: Pointer[ssc_number_t] = as_array("L_SCA", &nval_L_SCA)
        c_trough.m_L_SCA.resize(nval_L_SCA)
        for i in range(nval_L_SCA):
            c_trough.m_L_SCA[i] = Float64(L_SCA[i])
        nval_L_aperture: size = 0
        L_aperture: Pointer[ssc_number_t] = as_array("L_aperture", &nval_L_aperture)
        c_trough.m_L_aperture.resize(nval_L_aperture)
        for i in range(nval_L_aperture):
            c_trough.m_L_aperture[i] = Float64(L_aperture[i])
        nval_ColperSCA: size = 0
        ColperSCA: Pointer[ssc_number_t] = as_array("ColperSCA", &nval_ColperSCA)
        c_trough.m_ColperSCA.resize(nval_ColperSCA)
        for i in range(nval_ColperSCA):
            c_trough.m_ColperSCA[i] = Float64(ColperSCA[i])
        nval_Distance_SCA: size = 0
        Distance_SCA: Pointer[ssc_number_t] = as_array("Distance_SCA", &nval_Distance_SCA)
        c_trough.m_Distance_SCA.resize(nval_Distance_SCA)
        for i in range(nval_Distance_SCA):
            c_trough.m_Distance_SCA[i] = Float64(Distance_SCA[i])
        c_trough.m_IAM_matrix = as_matrix("IAM_matrix")
        c_trough.m_HCE_FieldFrac = as_matrix("HCE_FieldFrac")
        c_trough.m_D_2 = as_matrix("D_2")
        c_trough.m_D_3 = as_matrix("D_3")
        c_trough.m_D_4 = as_matrix("D_4")
        c_trough.m_D_5 = as_matrix("D_5")
        c_trough.m_D_p = as_matrix("D_p")
        c_trough.m_Flow_type = as_matrix("Flow_type")
        c_trough.m_Rough = as_matrix("Rough")
        c_trough.m_alpha_env = as_matrix("alpha_env")
        c_trough.m_epsilon_3_11 = as_matrix_transpose("epsilon_3_11")
        c_trough.m_epsilon_3_12 = as_matrix_transpose("epsilon_3_12")
        c_trough.m_epsilon_3_13 = as_matrix_transpose("epsilon_3_13")
        c_trough.m_epsilon_3_14 = as_matrix_transpose("epsilon_3_14")
        c_trough.m_epsilon_3_21 = as_matrix_transpose("epsilon_3_21")
        c_trough.m_epsilon_3_22 = as_matrix_transpose("epsilon_3_22")
        c_trough.m_epsilon_3_23 = as_matrix_transpose("epsilon_3_23")
        c_trough.m_epsilon_3_24 = as_matrix_transpose("epsilon_3_24")
        c_trough.m_epsilon_3_31 = as_matrix_transpose("epsilon_3_31")
        c_trough.m_epsilon_3_32 = as_matrix_transpose("epsilon_3_32")
        c_trough.m_epsilon_3_33 = as_matrix_transpose("epsilon_3_33")
        c_trough.m_epsilon_3_34 = as_matrix_transpose("epsilon_3_34")
        c_trough.m_epsilon_3_41 = as_matrix_transpose("epsilon_3_41")
        c_trough.m_epsilon_3_42 = as_matrix_transpose("epsilon_3_42")
        c_trough.m_epsilon_3_43 = as_matrix_transpose("epsilon_3_43")
        c_trough.m_epsilon_3_44 = as_matrix_transpose("epsilon_3_44")
        c_trough.m_alpha_abs = as_matrix("alpha_abs")
        c_trough.m_Tau_envelope = as_matrix("Tau_envelope")
        c_trough.m_EPSILON_4 = as_matrix("EPSILON_4")
        c_trough.m_EPSILON_5 = as_matrix("EPSILON_5")
        glazing_intact_double: util.matrix_t[Float64] = as_matrix("GlazingIntactIn")
        n_gl_row: Int = Int(glazing_intact_double.nrows())
        n_gl_col: Int = Int(glazing_intact_double.ncols())
        c_trough.m_GlazingIntact.resize(n_gl_row, n_gl_col)
        for i in range(n_gl_row):
            for j in range(n_gl_col):
                c_trough.m_GlazingIntact(i, j) = glazing_intact_double(i, j) > 0
        c_trough.m_P_a = as_matrix("P_a")
        c_trough.m_AnnulusGas = as_matrix("AnnulusGas")
        c_trough.m_AbsorberMaterial = as_matrix("AbsorberMaterial")
        c_trough.m_Shadowing = as_matrix("Shadowing")
        c_trough.m_Dirt_HCE = as_matrix("Dirt_HCE")
        c_trough.m_Design_loss = as_matrix("Design_loss")
        c_trough.m_SCAInfoArray = as_matrix("SCAInfoArray")
        c_trough.m_calc_design_pipe_vals = as_boolean("calc_design_pipe_vals")
        c_trough.m_L_rnr_pb = as_double("L_rnr_pb")
        c_trough.m_N_max_hdr_diams = as_double("N_max_hdr_diams")
        c_trough.m_L_rnr