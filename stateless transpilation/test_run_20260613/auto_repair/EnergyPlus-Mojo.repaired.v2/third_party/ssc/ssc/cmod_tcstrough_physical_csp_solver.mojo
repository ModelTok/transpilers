"""
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
"""
from core import SSC_INPUT, SSC_NUMBER, SSC_STRING, SSC_ARRAY, SSC_MATRIX, SSC_OUTPUT, ssc_number_t, var_info, var_info_invalid
from tckernel import C_csp_weatherreader, C_csp_trough_collector_receiver, C_csp_two_tank_tes, C_csp_tou_block_schedules, C_csp_solver, C_csp_exception
from common import util, weatherfile, C_block_schedule_csp_ops, C_block_schedule_pricing
from lib_weatherfile import weather_header
from csp_solver_trough_collector_receiver import C_csp_trough_collector_receiver  # already imported above? ensure from csp_solver_pc_Rankine_indirect_224 import C_pc_Rankine_indirect_224
from csp_solver_two_tank_tes import C_csp_two_tank_tes
from csp_solver_tou_block_schedules import C_csp_tou_block_schedules
from csp_solver_core import compute_module, add_var_info, vtab_adjustment_factors, vtab_technology_outputs

static var _cm_vtab_trough_physical_csp_solver: var_info[] = [
    { SSC_INPUT, SSC_STRING, "file_name", "Local weather file with path", "none", "", "Weather", "*", "LOCAL_FILE", "" },
    { SSC_INPUT, SSC_NUMBER, "track_mode", "Tracking mode", "none", "", "Weather", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tilt", "Tilt angle of surface/axis", "none", "", "Weather", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "azimuth", "Azimuth angle of surface/axis", "none", "", "Weather", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "trough", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ppa_multiplier_model", "PPA multiplier model", "0/1", "0=diurnal,1=timestep", "Time of Delivery", "?=0", "INTEGER,MIN=0", "" },
    { SSC_INPUT, SSC_ARRAY, "dispatch_factors_ts", "Dispatch payment factor array", "", "", "Time of Delivery", "ppa_multiplier_model=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "nSCA", "Number of SCAs in a loop", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "nHCEt", "Number of HCE types", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "nColt", "Number of collector types", "none", "constant=4", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "nHCEVar", "Number of HCE variants per type", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "nLoops", "Number of loops in the field", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "eta_pump", "HTF pump efficiency", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "HDR_rough", "Header pipe roughness", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "theta_stow", "Stow angle", "deg", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "theta_dep", "Deploy angle", "deg", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "Row_Distance", "Spacing between rows (centerline to centerline)", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "FieldConfig", "Number of subfield headers", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_startup", "Required temperature of the system before the power block can be switched on", "C", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "P_ref", "Rated plant capacity", "MWe", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "m_dot_htfmin", "Minimum loop HTF flow rate", "kg/s", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "m_dot_htfmax", "Maximum loop HTF flow rate", "kg/s", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_loop_in_des", "Design loop inlet temperature", "C", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_loop_out", "Target loop outlet temperature", "C", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "Fluid", "Field HTF fluid ID number", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_fp", "Freeze protection temperature (heat trace activation temperature)", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "I_bn_des", "Solar irradiation at design", "C", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "V_hdr_max", "Maximum HTF velocity in the header at design", "W/m2", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "V_hdr_min", "Minimum HTF velocity in the header at design", "m/s", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "Pipe_hl_coef", "Loss coefficient from the header, runner pipe, and non-HCE piping", "m/s", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "SCA_drives_elec", "Tracking power, in Watts per SCA drive", "W/m2-K", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "fthrok", "Flag to allow partial defocusing of the collectors", "W/SCA", "", "solar_field", "*", "INTEGER", "" },
    { SSC_INPUT, SSC_NUMBER, "fthrctrl", "Defocusing strategy", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "water_usage_per_wash", "Water usage per wash", "L/m2_aper", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "washing_frequency", "Mirror washing frequency", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "accept_mode", "Acceptance testing mode?", "0/1", "no/yes", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "accept_init", "In acceptance testing mode - require steady-state startup", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "accept_loc", "In acceptance testing mode - temperature sensor location", "1/2", "hx/loop", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "solar_mult", "Solar multiple", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "mc_bal_hot", "Heat capacity of the balance of plant on the hot side", "kWht/K-MWt", "none", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "mc_bal_cold", "Heat capacity of the balance of plant on the cold side", "kWht/K-MWt", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "mc_bal_sca", "Non-HTF heat capacity associated with each SCA - per meter basis", "Wht/K-m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "W_aperture", "The collector aperture width (Total structural area used for shadowing)", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "A_aperture", "Reflective aperture area of the collector", "m2", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "TrackingError", "User-defined tracking error derate", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "GeomEffects", "User-defined geometry effects derate", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "Rho_mirror_clean", "User-defined clean mirror reflectivity", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "Dirt_mirror", "User-defined dirt on mirror derate", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "Error", "User-defined general optical error derate ", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "Ave_Focal_Length", "Average focal length of the collector ", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "L_SCA", "Length of the SCA ", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "L_aperture", "Length of a single mirror/HCE unit", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "ColperSCA", "Number of individual collector sections in an SCA ", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "Distance_SCA", "Piping distance between SCA's in the field", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "IAM_matrix", "IAM coefficients, matrix for 4 collectors", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "HCE_FieldFrac", "Fraction of the field occupied by this HCE type ", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "D_2", "Inner absorber tube diameter", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "D_3", "Outer absorber tube diameter", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "D_4", "Inner glass envelope diameter ", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "D_5", "Outer glass envelope diameter ", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "D_p", "Diameter of the absorber flow plug (optional) ", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "Flow_type", "Flow type through the absorber", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "Rough", "Roughness of the internal surface ", "m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "alpha_env", "Envelope absorptance ", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_11", "Absorber emittance for receiver type 1 variation 1", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_12", "Absorber emittance for receiver type 1 variation 2", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_13", "Absorber emittance for receiver type 1 variation 3", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_14", "Absorber emittance for receiver type 1 variation 4", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_21", "Absorber emittance for receiver type 2 variation 1", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_22", "Absorber emittance for receiver type 2 variation 2", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_23", "Absorber emittance for receiver type 2 variation 3", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_24", "Absorber emittance for receiver type 2 variation 4", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_31", "Absorber emittance for receiver type 3 variation 1", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_32", "Absorber emittance for receiver type 3 variation 2", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_33", "Absorber emittance for receiver type 3 variation 3", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_34", "Absorber emittance for receiver type 3 variation 4", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_41", "Absorber emittance for receiver type 4 variation 1", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_42", "Absorber emittance for receiver type 4 variation 2", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_43", "Absorber emittance for receiver type 4 variation 3", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "epsilon_3_44", "Absorber emittance for receiver type 4 variation 4", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "alpha_abs", "Absorber absorptance ", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "Tau_envelope", "Envelope transmittance", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "EPSILON_4", "Inner glass envelope emissivities (Pyrex) ", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "EPSILON_5", "Outer glass envelope emissivities (Pyrex) ", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "GlazingIntactIn", "Glazing intact (broken glass) flag {1=true, else=false}", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "P_a", "Annulus gas pressure", "torr", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "AnnulusGas", "Annulus gas type (1=air, 26=Ar, 27=H2)", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "AbsorberMaterial", "Absorber material type", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "Shadowing", "Receiver bellows shadowing loss factor", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "Dirt_HCE", "Loss due to dirt on the receiver envelope", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "Design_loss", "Receiver heat loss at design", "W/m", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "SCAInfoArray", "Receiver (,1) and collector (,2) type for each assembly in loop", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "SCADefocusArray", "Collector defocus order", "none", "", "solar_field", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "field_fl_props", "User defined field fluid property data", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "store_fl_props", "User defined storage fluid property data", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "store_fluid", "Material number for storage fluid", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tshours", "Equivalent full-load thermal storage hours", "hr", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "is_hx", "Heat exchanger (HX) exists (1=yes, 0=no)", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "dt_hot", "Hot side HX approach temp", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "dt_cold", "Cold side HX approach temp", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "hx_config", "HX configuration", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "q_max_aux", "Max heat rate of auxiliary heater", "MWt", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_set_aux", "Aux heater outlet temp set point", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "V_tank_hot_ini", "Initial hot tank fluid volume", "m3", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_tank_cold_ini", "Initial cold tank fluid temperature", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "vol_tank", "Total tank volume, including unusable HTF at bottom", "m3", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "h_tank", "Total height of tank (height of HTF when tank is full)", "m", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "h_tank_min", "Minimum allowable HTF height in storage tank", "m", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "u_tank", "Loss coefficient from the tank", "W/m2-K", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tank_pairs", "Number of equivalent tank pairs", "-", "", "controller", "*", "INTEGER", "" },
    { SSC_INPUT, SSC_NUMBER, "cold_tank_Thtr", "Minimum allowable cold tank HTF temp", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "hot_tank_Thtr", "Minimum allowable hot tank HTF temp", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tank_max_heat", "Rated heater capacity for tank heating", "MW", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "q_pb_design", "Design heat input to power block", "MWt", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "W_pb_design", "Rated plant capacity", "MWe", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "cycle_max_frac", "Maximum turbine over design operation fraction", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "cycle_cutoff_frac", "Minimum turbine operation fraction before shutdown", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "pb_pump_coef", "Pumping power to move 1kg of HTF through PB loop", "kW/kg", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tes_pump_coef", "Pumping power to move 1kg of HTF through tes loop", "kW/kg", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "pb_fixed_par", "Fraction of rated gross power constantly consumed", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "bop_array", "Coefficients for balance of plant parasitics calcs", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "aux_array", "Coefficients for auxiliary heater parasitics calcs", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "fossil_mode", "Fossil backup mode 1=Normal 2=Topping", "-", "", "controller", "*", "INTEGER", "" },
    { SSC_INPUT, SSC_NUMBER, "q_sby_frac", "Fraction of thermal power required for standby", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "t_standby_reset", "Maximum allowable time for PB standby operation", "hr", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "sf_type", "Solar field type, 1 = trough, 2 = tower", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tes_type", "1=2-tank, 2=thermocline", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "tslogic_a", "Dispatch logic without solar", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "tslogic_b", "Dispatch logic with solar", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "tslogic_c", "Dispatch logic for turbine load fraction", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_ARRAY, "ffrac", "Fossil dispatch logic", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tc_fill", "Thermocline fill material", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tc_void", "Thermocline void fraction", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "t_dis_out_min", "Min allowable hot side outlet temp during discharge", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "t_ch_out_max", "Max allowable cold side outlet temp during charge", "C", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "nodes", "Nodes modeled in the flow path", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "f_tc_cold", "0=entire tank is hot, 1=entire tank is cold", "-", "", "controller", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "weekday_schedule", "Dispatch 12mx24h schedule for week days", "", "", "tou_translator", "*", "", "" },
    { SSC_INPUT, SSC_MATRIX, "weekend_schedule", "Dispatch 12mx24h schedule for weekends", "", "", "tou_translator", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "pc_config", "0: Steam Rankine (224), 1: user defined", "-", "", "powerblock", "?=0", "INTEGER", "" },
    { SSC_INPUT, SSC_NUMBER, "eta_ref", "Reference conversion efficiency at design condition", "none", "", "powerblock", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "startup_time", "Time needed for power block startup", "hr", "", "powerblock", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "startup_frac", "Fraction of design thermal power needed for startup", "none", "", "powerblock", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "q_sby_frac", "Fraction of thermal power required for standby mode", "none", "", "powerblock", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "dT_cw_ref", "Reference condenser cooling water inlet/outlet T diff", "C", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_amb_des", "Reference ambient temperature at design point", "C", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "P_boil", "Boiler operating pressure", "bar", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "CT", "Flag for using dry cooling or wet cooling system", "none", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_approach", "Cooling tower approach temperature", "C", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "T_ITD_des", "ITD at design for dry system", "C", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "P_cond_ratio", "Condenser pressure ratio", "none", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "pb_bd_frac", "Power block blowdown steam fraction ", "none", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "P_cond_min", "Minimum condenser pressure", "inHg", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "n_pl_inc", "Number of part-load increments for the heat rejection system", "none", "", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_ARRAY, "F_wc", "Fraction indicating wet cooling use for hybrid system", "none", "constant=[0,0,0,0,0,0,0,0,0]", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "tech_type", "Turbine inlet pressure control flag (sliding=user, fixed=trough)", "1/2/3", "tower/trough/user", "powerblock", "pc_config=0", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_T_amb_des", "Ambient temperature at user-defined power cycle design point", "C", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_f_W_dot_cool_des", "Percent of user-defined power cycle design gross output consumed by cooling", "%", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_m_dot_water_cool_des", "Mass flow rate of water required at user-defined power cycle design point", "kg/s", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_T_htf_low", "Low level HTF inlet temperature for T_amb parametric", "C", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_T_htf_high", "High level HTF inlet temperature for T_amb parametric", "C", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_T_amb_low", "Low level ambient temperature for HTF mass flow rate parametric", "C", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_T_amb_high", "High level ambient temperature for HTF mass flow rate parametric", "C", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_m_dot_htf_low", "Low level normalized HTF mass flow rate for T_HTF parametric", "-", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_NUMBER, "ud_m_dot_htf_high", "High level normalized HTF mass flow rate for T_HTF parametric", "-", "", "user_defined_PC", "pc_config=1", "", "" },
    { SSC_INPUT, SSC_MATRIX, "ud_T_htf_ind_od", "Off design table of user-defined power cycle performance formed from parametric on T_htf_hot [C]", "", "", "user_defined_PC", "?=[[0]]", "", "" },
    { SSC_INPUT, SSC_MATRIX, "ud_T_amb_ind_od", "Off design table of user-defined power cycle performance formed from parametric on T_amb [C]", "", "", "user_defined_PC", "?=[[0]]", "", "" },
    { SSC_INPUT, SSC_MATRIX, "ud_m_dot_htf_ind_od", "Off design table of user-defined power cycle performance formed from parametric on m_dot_htf [ND]", "", "", "user_defined_PC", "?=[[0]]", "", "" },
    { SSC_INPUT, SSC_MATRIX, "ud_ind_od", "Off design user-defined power cycle performance as function of T_htf, m_dot_htf [ND], and T_amb", "", "", "user_defined_PC", "?=[[0]]", "", "" },
    { SSC_INPUT, SSC_NUMBER, "eta_lhv", "Fossil fuel lower heating value - Thermal power generated per unit fuel", "MW/MMBTU", "", "enet", "*", "", "" },
    { SSC_INPUT, SSC_NUMBER, "eta_tes_htr", "Thermal storage tank heater efficiency (fp_mode=1 only)", "none", "", "enet", "*", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "time_hr", "Time at end of timestep", "hr", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "solzen", "Resource Solar Zenith", "deg", "", "weather", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "beam", "Resource Beam normal irradiance", "W/m2", "", "weather", "", "", "" },
    { SSC_OUTPUT, SSC_MATRIX, "eta_map_out", "Solar field optical efficiencies", "", "", "heliostat", "", "", "COL_LABEL=OPTICAL_EFFICIENCY,ROW_LABEL=NO_ROW_LABEL" },
    { SSC_OUTPUT, SSC_MATRIX, "flux_maps_out", "Flux map intensities", "", "", "heliostat", "", "", "COL_LABEL=FLUX_MAPS,ROW_LABEL=NO_ROW_LABEL" },
    { SSC_OUTPUT, SSC_ARRAY, "defocus", "Field optical focus fraction", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "Q_thermal", "Rec. thermal power to HTF less piping loss", "MWt", "", "CR", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "m_dot_rec", "Rec. mass flow rate", "kg/hr", "", "CR", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_pb", "PC input energy", "MWt", "", "PC", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "m_dot_pc", "PC HTF mass flow rate", "kg/hr", "", "PC", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_pc_startup", "PC startup thermal energy", "MWht", "", "PC", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_pc_startup", "PC startup thermal power", "MWt", "", "PC", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "tank_losses", "TES thermal losses", "MWt", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_heater", "TES freeze protection power", "MWe", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "T_tes_hot", "TES hot temperature", "C", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "T_tes_cold", "TES cold temperature", "C", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dc_tes", "TES discharge thermal power", "MWt", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_ch_tes", "TES charge thermal power", "MWt", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "e_ch_tes", "TES charge state", "MWht", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "m_dot_tes_dc", "TES discharge mass flow rate", "kg/hr", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "m_dot_tes_ch", "TES charge mass flow rate", "kg/hr", "", "TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "pparasi", "Parasitic power heliostat drives", "MWe", "", "CR", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "P_tower_pump", "Parasitic power receiver/tower HTF pump", "MWe", "", "CR", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "htf_pump_power", "Parasitic power TES and Cycle HTF pump", "MWe", "", "PC-TES", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "P_cooling_tower_tot", "Parasitic power condenser operation", "MWe", "", "PC", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "P_fixed", "Parasitic power fixed load", "MWe", "", "System", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "P_plant_balance_tot", "Parasitic power generation-dependent load", "MWe", "", "System", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "P_out_net", "Total electric power to grid", "MWe", "", "System", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "tou_value", "CSP operating Time-of-use value", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "pricing_mult", "PPA price multiplier", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "n_op_modes", "Operating modes in reporting timestep", "", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "op_mode_1", "1st operating mode", "", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "op_mode_2", "2nd op. mode, if applicable", "", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "op_mode_3", "3rd op. mode, if applicable", "", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "m_dot_balance", "Relative mass flow balance error", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_balance", "Relative energy balance error", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_solve_state", "Dispatch solver state", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_solve_iter", "Dispatch iterations count", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_objective", "Dispatch objective function value", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_obj_relax", "Dispatch objective function - relaxed max", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_qsf_expected", "Dispatch expected solar field available energy", "MWt", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_qsfprod_expected", "Dispatch expected solar field generation", "MWt", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_qsfsu_expected", "Dispatch expected solar field startup enegy", "MWt", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_tes_expected", "Dispatch expected TES charge level", "MWht", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_pceff_expected", "Dispatch expected power cycle efficiency adj.", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_thermeff_expected", "Dispatch expected SF thermal efficiency adj.", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_qpbsu_expected", "Dispatch expected power cycle startup energy", "MWht", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_wpb_expected", "Dispatch expected power generation", "MWe", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_rev_expected", "Dispatch expected revenue factor", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_presolve_nconstr", "Dispatch number of constraints in problem", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_presolve_nvar", "Dispatch number of variables in problem", "", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "disp_solve_time", "Dispatch solver time", "sec", "", "tou", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_pc_sb", "Thermal power for PC standby", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_pc_min", "Thermal power for PC min operation", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_pc_max", "Max thermal power to PC", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_pc_target", "Target thermal power to PC", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "is_rec_su_allowed", "is receiver startup allowed", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "is_pc_su_allowed", "is power cycle startup allowed", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "is_pc_sb_allowed", "is power cycle standby allowed", "", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_est_cr_su", "Estimate rec. startup thermal power", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_est_cr_on", "Estimate rec. thermal power TO HTF", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_est_tes_dc", "Estimate max TES discharge thermal power", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "q_dot_est_tes_ch", "Estimate max TES charge thermal power", "MWt", "", "Controller", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "operating_modes_a", "First 3 operating modes tried", "", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "operating_modes_b", "Next 3 operating modes tried", "", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "operating_modes_c", "Final 3 operating modes tried", "", "", "Solver", "", "", "" },
    { SSC_OUTPUT, SSC_ARRAY, "gen", "Total electric power to grid w/ avail. derate", "kWe", "", "System", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual total electric power to grid", "kWhe", "", "System", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "annual_W_cycle_gross", "Electrical source - Power cycle gross output", "kWhe", "", "PC", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "conversion_factor", "Gross to Net Conversion Factor", "%", "", "PostProcess", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "PostProcess", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "annual_total_water_use", "Total Annual Water Usage: cycle + mirror washing", "m3", "", "PostProcess", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "disp_objective_ann", "Annual sum of dispatch objective func. value", "", "", "", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "disp_iter_ann", "Annual sum of dispatch solver iterations", "", "", "", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "disp_presolve_nconstr_ann", "Annual sum of dispatch problem constraint count", "", "", "", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "disp_presolve_nvar_ann", "Annual sum of dispatch problem variable count", "", "", "", "", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "disp_solve_time_ann", "Annual sum of dispatch solver time", "", "", "", "", "", "" },
    var_info_invalid
]

class cm_trough_physical_csp_solver(compute_module):
    def __init__(self):
        add_var_info(_cm_vtab_trough_physical_csp_solver)
        add_var_info(vtab_adjustment_factors)
        add_var_info(vtab_technology_outputs)

    def exec(self):
        var tes_type = as_integer("tes_type")
        if tes_type != 1:
            raise exec_error("Physical Trough CSP Solver", "The tes_type input must be = 1. Additional TES options may be added in future versions.\n")

        var wfile = make_shared[weatherfile](as_string("file_name"))
        if not wfile.ok():
            raise exec_error("Physical Trough", wfile.message())
        if wfile.has_message():
            log(wfile.message(), SSC_WARNING)

        var hdr: weather_header
        wfile.header(&hdr)

        var weather_reader = C_csp_weatherreader()
        weather_reader.m_weather_data_provider = wfile
        weather_reader.m_trackmode = 0
        weather_reader.m_tilt = 0.0
        weather_reader.m_azimuth = 0.0
        weather_reader.init()
        if weather_reader.has_error():
            raise exec_error("tcstrough_physical", weather_reader.get_error())

        var c_trough = C_csp_trough_collector_receiver()
        c_trough.m_nSCA = as_integer("nSCA")						#[-] Number of SCA's in a loop
        c_trough.m_nHCEt = as_integer("nHCEt")						#[-] Number of HCE types
        c_trough.m_nColt = as_integer("nColt")						#[-] Number of collector types
        c_trough.m_nHCEVar = as_integer("nHCEVar")					#[-] Number of HCE variants per t
        c_trough.m_nLoops = as_integer("nLoops")					#[-] Number of loops in the field
        c_trough.m_FieldConfig = as_integer("FieldConfig")			#[-] Number of subfield headers
        c_trough.m_Fluid = as_integer("Fluid")						#[-] Field HTF fluid number
        c_trough.m_fthrok = as_integer("fthrok")					#[-] Flag to allow partial defocusing of the collectors
        c_trough.m_fthrctrl = as_integer("fthrctrl")				#[-] Defocusing strategy
        c_trough.m_accept_loc = as_integer("accept_loc")			#[-] In acceptance testing mode - temperature sensor location (1=hx,2=loop)
        c_trough.m_HDR_rough = as_double("HDR_rough")				#[m] Header pipe roughness
        c_trough.m_theta_stow = as_double("theta_stow")			#[deg] stow angle
        c_trough.m_theta_dep = as_double("theta_dep")				#[deg] deploy angle
        c_trough.m_Row_Distance = as_double("Row_Distance")		#[m] Spacing between rows (centerline to centerline)
        c_trough.m_T_startup = as_double("T_startup")				#[C] The required temperature (converted to K in init) of the system before the power block can be switched on
        c_trough.m_m_dot_htfmin = as_double("m_dot_htfmin")		#[kg/s] Minimum loop HTF flow rate
        c_trough.m_m_dot_htfmax = as_double("m_dot_htfmax")		#[kg/s] Maximum loop HTF flow rate
        c_trough.m_T_loop_in_des = as_double("T_loop_in_des")		#[C] Design loop inlet temperature, converted to K in init
        c_trough.m_T_loop_out_des = as_double("T_loop_out")		#[C] Target loop outlet temperature, converted to K in init
        c_trough.m_field_fl_props = as_matrix("field_fl_props")	#[-] User-defined field HTF properties
        c_trough.m_T_fp = as_double("T_fp")						#[C] Freeze protection temperature (heat trace activation temperature), convert to K in init
        c_trough.m_I_bn_des = as_double("I_bn_des")				#[W/m^2] Solar irradiation at design
        c_trough.m_V_hdr_max = as_double("V_hdr_max")				#[m/s] Maximum HTF velocity in the header at design
        c_trough.m_V_hdr_min = as_double("V_hdr_min") 				#[m/s] Minimum HTF velocity in the header at design
        c_trough.m_Pipe_hl_coef = as_double("Pipe_hl_coef")		#[W/m2-K] Loss coefficient from the header, runner pipe, and non-HCE piping
        c_trough.m_SCA_drives_elec = as_double("SCA_drives_elec")  #[W/SCA] Tracking power, in Watts per SCA drive
        c_trough.m_ColTilt = as_double("tilt")						#[deg] Collector tilt angle (0 is horizontal, 90deg is vertical)
        c_trough.m_ColAz = as_double("azimuth") 					#[deg] Collector azimuth angle
        c_trough.m_accept_mode = as_integer("accept_mode")			#[-] Acceptance testing mode? (1=yes, 0=no)
        c_trough.m_accept_init = as_boolean("accept_init")			#[-] In acceptance testing mode - require steady-state startup
        c_trough.m_solar_mult = as_double("solar_mult")			#[-] Solar Multiple
        c_trough.m_mc_bal_hot_per_MW = as_double("mc_bal_hot")     #[kWht/K-MWt] The heat capacity of the balance of plant on the hot side
        c_trough.m_mc_bal_cold_per_MW = as_double("mc_bal_cold")	#[kWht/K-MWt] The heat capacity of the balance of plant on the cold side
        c_trough.m_mc_bal_sca = as_double("mc_bal_sca") 			#[Wht/K-m] Non-HTF heat capacity associated with each SCA - per meter basis

        var nval_W_aperture: Int = 0
        var W_aperture = as_array("W_aperture", &nval_W_aperture)
        c_trough.m_W_aperture.resize(nval_W_aperture)
        for i in range(nval_W_aperture):
            c_trough.m_W_aperture[i] = Float64(W_aperture[i])

        var nval_A_aperture: Int = 0
        var A_aperture = as_array("A_aperture", &nval_A_aperture)
        c_trough.m_A_aperture.resize(nval_A_aperture)
        for i in range(nval_A_aperture):
            c_trough.m_A_aperture[i] = Float64(A_aperture[i])

        var nval_TrackingError: Int = 0
        var TrackingError = as_array("TrackingError", &nval_TrackingError)
        c_trough.m_TrackingError.resize(nval_TrackingError)
        for i in range(nval_TrackingError):
            c_trough.m_TrackingError[i] = Float64(TrackingError[i])

        var nval_GeomEffects: Int = 0
        var GeomEffects = as_array("GeomEffects", &nval_GeomEffects)
        c_trough.m_GeomEffects.resize(nval_GeomEffects)
        for i in range(nval_GeomEffects):
            c_trough.m_GeomEffects[i] = Float64(GeomEffects[i])

        var nval_Rho_mirror_clean: Int = 0
        var Rho_mirror_clean = as_array("Rho_mirror_clean", &nval_Rho_mirror_clean)
        c_trough.m_Rho_mirror_clean.resize(nval_Rho_mirror_clean)
        for i in range(nval_Rho_mirror_clean):
            c_trough.m_Rho_mirror_clean[i] = Float64(Rho_mirror_clean[i])

        var nval_Dirt_mirror: Int = 0
        var Dirt_mirror = as_array("Dirt_mirror", &nval_Dirt_mirror)
        c_trough.m_Dirt_mirror.resize(nval_Dirt_mirror)
        for i in range(nval_Dirt_mirror):
            c_trough.m_Dirt_mirror[i] = Float64(Dirt_mirror[i])

        var nval_Error: Int = 0
        var Error = as_array("Error", &nval_Error)
        c_trough.m_Error.resize(nval_Error)
        for i in range(nval_Error):
            c_trough.m_Error[i] = Float64(Error[i])

        var nval_Ave_Focal_Length: Int = 0
        var Ave_Focal_Length = as_array("Ave_Focal_Length", &nval_Ave_Focal_Length)
        c_trough.m_Ave_Focal_Length.resize(nval_Ave_Focal_Length)
        for i in range(nval_Ave_Focal_Length):
            c_trough.m_Ave_Focal_Length[i] = Float64(Ave_Focal_Length[i])

        var nval_L_SCA: Int = 0
        var L_SCA = as_array("L_SCA", &nval_L_SCA)
        c_trough.m_L_SCA.resize(nval_L_SCA)
        for i in range(nval_L_SCA):
            c_trough.m_L_SCA[i] = Float64(L_SCA[i])

        var nval_L_aperture: Int = 0
        var L_aperture = as_array("L_aperture", &nval_L_aperture)
        c_trough.m_L_aperture.resize(nval_L_aperture)
        for i in range(nval_L_aperture):
            c_trough.m_L_aperture[i] = Float64(L_aperture[i])

        var nval_ColperSCA: Int = 0
        var ColperSCA = as_array("ColperSCA", &nval_ColperSCA)
        c_trough.m_ColperSCA.resize(nval_ColperSCA)
        for i in range(nval_ColperSCA):
            c_trough.m_ColperSCA[i] = Float64(ColperSCA[i])

        var nval_Distance_SCA: Int = 0
        var Distance_SCA = as_array("Distance_SCA", &nval_Distance_SCA)
        c_trough.m_Distance_SCA.resize(nval_Distance_SCA)
        for i in range(nval_Distance_SCA):
            c_trough.m_Distance_SCA[i] = Float64(Distance_SCA[i])

        c_trough.m_IAM_matrix = as_matrix("IAM_matrix")		#[-] IAM coefficients, matrix for 4 collectors
        c_trough.m_HCE_FieldFrac = as_matrix("HCE_FieldFrac")	#[-] Fraction of the field occupied by this HCE type
        c_trough.m_D_2 = as_matrix("D_2")                      #[m] Inner absorber tube diameter
        c_trough.m_D_3 = as_matrix("D_3")                      #[m] Outer absorber tube diameter
        c_trough.m_D_4 = as_matrix("D_4")                      #[m] Inner glass envelope diameter
        c_trough.m_D_5 = as_matrix("D_5")                      #[m] Outer glass envelope diameter
        c_trough.m_D_p = as_matrix("D_p")                      #[m] Diameter of the absorber flow plug (optional)
        c_trough.m_Flow_type = as_matrix("Flow_type")			#[-] Flow type through the absorber
        c_trough.m_Rough = as_matrix("Rough")					#[m] Roughness of the internal surface
        c_trough.m_alpha_env = as_matrix("alpha_env")			#[-] Envelope absorptance
        c_trough.m_epsilon_3_11 = as_matrix_transpose("epsilon_3_11")   #[-] Absorber emittance for receiver type 1 variation 1
        c_trough.m_epsilon_3_12 = as_matrix_transpose("epsilon_3_12") 	 #[-] Absorber emittance for receiver type 1 variation 2
        c_trough.m_epsilon_3_13 = as_matrix_transpose("epsilon_3_13") 	 #[-] Absorber emittance for receiver type 1 variation 3
        c_trough.m_epsilon_3_14 = as_matrix_transpose("epsilon_3_14") 	 #[-] Absorber emittance for receiver type 1 variation 4
        c_trough.m_epsilon_3_21 = as_matrix_transpose("epsilon_3_21") 	 #[-] Absorber emittance for receiver type 2 variation 1
        c_trough.m_epsilon_3_22 = as_matrix_transpose("epsilon_3_22") 	 #[-] Absorber emittance for receiver type 2 variation 2
        c_trough.m_epsilon_3_23 = as_matrix_transpose("epsilon_3_23") 	 #[-] Absorber emittance for receiver type 2 variation 3
        c_trough.m_epsilon_3_24 = as_matrix_transpose("epsilon_3_24") 	 #[-] Absorber emittance for receiver type 2 variation 4
        c_trough.m_epsilon_3_31 = as_matrix_transpose("epsilon_3_31") 	 #[-] Absorber emittance for receiver type 3 variation 1
        c_trough.m_epsilon_3_32 = as_matrix_transpose("epsilon_3_32") 	 #[-] Absorber emittance for receiver type 3 variation 2
        c_trough.m_epsilon_3_33 = as_matrix_transpose("epsilon_3_33") 	 #[-] Absorber emittance for receiver type 3 variation 3
        c_trough.m_epsilon_3_34 = as_matrix_transpose("epsilon_3_34") 	 #[-] Absorber emittance for receiver type 3 variation 4
        c_trough.m_epsilon_3_41 = as_matrix_transpose("epsilon_3_41") 	 #[-] Absorber emittance for receiver type 4 variation 1
        c_trough.m_epsilon_3_42 = as_matrix_transpose("epsilon_3_42") 	 #[-] Absorber emittance for receiver type 4 variation 2
        c_trough.m_epsilon_3_43 = as_matrix_transpose("epsilon_3_43") 	 #[-] Absorber emittance for receiver type 4 variation 3
        c_trough.m_epsilon_3_44 = as_matrix_transpose("epsilon_3_44") 	 #[-] Absorber emittance for receiver type 4 variation 4
        c_trough.m_alpha_abs = as_matrix("alpha_abs")                   #[-] Absorber absorptance
        c_trough.m_Tau_envelope = as_matrix("Tau_envelope")             #[-] Envelope transmittance
        c_trough.m_EPSILON_4 = as_matrix("EPSILON_4")                   #[-] Inner glass envelope emissivities
        c_trough.m_EPSILON_5 = as_matrix("EPSILON_5")                   #[-] Outer glass envelope emissivities

        var glazing_intact_double = as_matrix("GlazingIntactIn") #[-] Is the glazing intact?
        var n_gl_row = Int(glazing_intact_double.nrows())
        var n_gl_col = Int(glazing_intact_double.ncols())
        c_trough.m_GlazingIntact.resize(n_gl_row, n_gl_col)
        for i in range(n_gl_row):
            for j in range(n_gl_col):
                c_trough.m_GlazingIntact[i, j] = (glazing_intact_double[i, j] > 0)

        c_trough.m_P_a = as_matrix("P_a")		                         #[torr] Annulus gas pressure				 
        c_trough.m_AnnulusGas = as_matrix("AnnulusGas")		         #[-] Annulus gas type (1=air, 26=Ar, 27=H2)
        c_trough.m_AbsorberMaterial = as_matrix("AbsorberMaterial")	 #[-] Absorber material type
        c_trough.m_Shadowing = as_matrix("Shadowing")                   #[-] Receiver bellows shadowing loss factor
        c_trough.m_Dirt_HCE = as_matrix("Dirt_HCE")                     #[-] Loss due to dirt on the receiver envelope
        c_trough.m_Design_loss = as_matrix("Design_loss")               #[-] Receiver heat loss at design
        c_trough.m_SCAInfoArray = as_matrix("SCAInfoArray")			 #[-] Receiver (,1) and collector (,2) type for each assembly in loop 

        var nval_SCADefocusArray: Int = 0
        var SCADefocusArray = as_array("SCADefocusArray", &nval_SCADefocusArray)
        c_trough.m_SCADefocusArray.resize(nval_SCADefocusArray)
        for i in range(nval_SCADefocusArray):
            c_trough.m_SCADefocusArray[i] = Int(SCADefocusArray[i])

        var pb_tech_type = as_integer("pc_config")		#[-] 0: Steam Rankine (224), 1: user defined
        if pb_tech_type == 2:
            log("The sCO2 power cycle is not yet supported by the new CSP Solver and Dispatch Optimization models.\n", SSC_WARNING)
            return

        var power_cycle = C_pc_Rankine_indirect_224()
        var pc = &power_cycle.ms_params
        pc.m_P_ref = as_double("W_pb_design")                         #[MWe] Rated plant capacity
        pc.m_eta_ref = as_double("eta_ref")					        #[-] Reference conversion efficiency at design conditions
        pc.m_T_htf_hot_ref = as_double("T_loop_out")			        #[C] FIELD design outlet temperature
        pc.m_T_htf_cold_ref = as_double("T_loop_in_des")			    #[C] FIELD design inlet temperature
        pc.m_cycle_max_frac = as_double("cycle_max_frac")			    #[-]
        pc.m_cycle_cutoff_frac = as_double("cycle_cutoff_frac")	    #[-]
        pc.m_q_sby_frac = as_double("q_sby_frac")					    #[-]
        pc.m_startup_time = as_double("startup_time")				    #[hr]
        pc.m_startup_frac = as_double("startup_frac")				    #[-]
        pc.m_htf_pump_coef = as_double("pb_pump_coef")			    #[kW/kg/s]
        pc.m_pc_fl = as_integer("Fluid")							    #[-]
        pc.m_pc_fl_props = as_matrix("field_fl_props")                #[-]
        if pb_tech_type == 0:
            pc.m_dT_cw_ref = as_double("dT_cw_ref")			#[C]
            pc.m_T_amb_des = as_double("T_amb_des")			#[C]
            pc.m_P_boil = as_double("P_boil")					#[bar]
            pc.m_CT = as_integer("CT")						#[-]
            pc.m_tech_type = as_integer("tech_type")			#[-]					
            pc.m_T_approach = as_double("T_approach")			#[C/K]
            pc.m_T_ITD_des = as_double("T_ITD_des")			#[C/K]
            pc.m_P_cond_ratio = as_double("P_cond_ratio")		#[-]
            pc.m_pb_bd_frac = as_double("pb_bd_frac")			#[-]
            pc.m_P_cond_min = as_double("P_cond_min")			#[inHg]
            pc.m_n_pl_inc = as_integer("n_pl_inc")			#[-]
            var n_F_wc: Int = 0
            var p_F_wc = as_array("F_wc", &n_F_wc)	#[-]
            pc.m_F_wc.resize(n_F_wc, 0.0)
            for i in range(n_F_wc):
                pc.m_F_wc[i] = Float64(p_F_wc[i])
            pc.m_is_user_defined_pc = false
            pc.m_W_dot_cooling_des = Float64.nan
        elif pb_tech_type == 1:
            pc.m_is_user_defined_pc = true
            pc.m_T_amb_des = as