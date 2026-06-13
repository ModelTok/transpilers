from core import *
from tckernel import *
from common import *
from lib_weatherfile import *
from csp_solver_lf_dsg_collector_receiver import C_csp_lf_dsg_collector_receiver

# static var_info _cm_vtab_tcslinear_fresnel_dsg_csp_solver[] = {
var _cm_vtab_tcslinear_fresnel_dsg_csp_solver: List[var_info] = [
# /*	EXAMPLE LINES FOR INPUTS
#     { SSC_INPUT,        SSC_NUMBER,      "XXXXXXXXXXXXXX",    "Label",                                                                               "",              "",            "sca",            "*",                       "",                      "" },
#     { SSC_INPUT,        SSC_NUMBER,      "INTINTINTINT",      "Label",                                                                               "",              "",            "parasitic",      "*",                       "INTEGER",               "" },
#     { SSC_INPUT,        SSC_ARRAY,       "XXXXXXXXXXX",       "Number indicating the receiver type",                                                 "",              "",            "hce",            "*",                       "",                      "" },
#     { SSC_INPUT,        SSC_MATRIX,      "XXXXXXXXXXX",       "Label",                                                                               "",              "",            "tes",            "*",                       "",                      "" },
# */
    var_info(SSC_INPUT, SSC_NUMBER, "file_name", "local weather file path", "", "", "Weather", "*", "LOCAL_FILE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "track_mode", "Tracking mode", "", "", "Weather", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tilt", "Tilt angle of surface/axis", "", "", "Weather", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "azimuth", "Azimuth angle of surface/axis", "", "", "Weather", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "linear fresnelr", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "weekday_schedule", "12x24 Time of Use Values for week days", "", "", "tou_translator", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "weekend_schedule", "12x24 Time of Use Values for week end days", "", "", "tou_translator", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tes_hours", "Equivalent full-load thermal storage hours", "hr", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_max_aux", "Maximum heat rate of the auxiliary heater", "MW", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LHV_eff", "Fuel LHV efficiency (0..1)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "x_b_des", "Design point boiler outlet steam quality", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_turb_des", "Design-point turbine inlet pressure", "bar", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fP_hdr_c", "Average design-point cold header pressure drop fraction", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fP_sf_boil", "Design-point pressure drop across the solar field boiler fraction", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fP_boil_to_sh", "Design-point pressure drop between the boiler and superheater frac", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fP_sf_sh", "Design-point pressure drop across the solar field superheater frac", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fP_hdr_h", "Average design-point hot header pressure drop fraction", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_pb_des", "Design heat input to the power block", "MW", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cycle_max_fraction", "Maximum turbine over design operation fraction", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cycle_cutoff_frac", "Minimum turbine operation fraction before shutdown", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "t_sby", "Low resource standby period", "hr", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_sby_frac", "Fraction of thermal power required for standby", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "solarm", "Solar multiple", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "PB_pump_coef", "Pumping power required to move 1kg of HTF through power block flow", "kW/kg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "PB_fixed_par", "fraction of rated gross power consumed at all hours of the year", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "bop_array", "BOP_parVal, BOP_parPF, BOP_par0, BOP_par1, BOP_par2", "-", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "aux_array", "Aux_parVal, Aux_parPF, Aux_par0, Aux_par1, Aux_par2", "-", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fossil_mode", "Operation mode for the fossil backup {1=Normal,2=supp,3=toppin}", "none", "", "solarfield", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "I_bn_des", "Design point irradiation value", "W/m2", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_sh", "Does the solar field include a superheating section", "none", "", "solarfield", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_oncethru", "Flag indicating whether flow is once through with superheat", "none", "", "solarfield", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_multgeom", "Does the superheater have a different geometry from the boiler {1=yes}", "none", "", "solarfield", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nModBoil", "Number of modules in the boiler section", "none", "", "solarfield", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nModSH", "Number of modules in the superheater section", "none", "", "solarfield", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "nLoops", "Number of loops", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_pump", "Feedwater pump efficiency", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "latitude", "Site latitude resource page", "deg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "theta_stow", "stow angle", "deg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "theta_dep", "deploy angle", "deg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "m_dot_min", "Minimum loop flow rate", "kg/s", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_fp", "Freeze protection temperature (heat trace activation temperature)", "C", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "Pipe_hl_coef", "Loss coefficient from the header.. runner pipe.. and non-HCE pipin", "W/m2-K", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "SCA_drives_elec", "Tracking power.. in Watts per SCA drive", "W/m2", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "ColAz", "Collector azimuth angle", "deg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "e_startup", "Thermal inertia contribution per sq meter of solar field", "kJ/K-m2", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_amb_des_sf", "Design-point ambient temperature", "C", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "V_wind_max", "Maximum allowable wind velocity before safety stow", "m/s", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.lf.sf.water_per_wash", "Water usage per wash", "L/m2_aper", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "csp.lf.sf.washes_per_year", "Mirror washing frequency", "", "", "heliostat", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "ffrac", "Fossil dispatch logic - TOU periods", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "A_aperture", "(boiler, SH) Reflective aperture area of the collector module", "m^2", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "L_col", "(boiler, SH) Active length of the superheater section collector module", "m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "OptCharType", "(boiler, SH) The optical characterization method", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "IAM_T", "(boiler, SH) Transverse Incident angle modifiers (0,1,2,3,4 order terms)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "IAM_L", "(boiler, SH) Longitudinal Incident angle modifiers (0,1,2,3,4 order terms)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "TrackingError", "(boiler, SH) User-defined tracking error derate", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "GeomEffects", "(boiler, SH) User-defined geometry effects derate", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "rho_mirror_clean", "(boiler, SH) User-defined clean mirror reflectivity", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "dirt_mirror", "(boiler, SH) User-defined dirt on mirror derate", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "error", "(boiler, SH) User-defined general optical error derate", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "HLCharType", "(boiler, SH) Flag indicating the heat loss model type {1=poly.; 2=Forristall}", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "HL_dT", "(boiler, SH) Heat loss coefficient - HTF temperature (0,1,2,3,4 order terms)", "W/m-K^order", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "HL_W", "(boiler, SH) Heat loss coef adj wind velocity (0,1,2,3,4 order terms)", "1/(m/s)^order", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_2", "(boiler, SH) The inner absorber tube diameter", "m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_3", "(boiler, SH) The outer absorber tube diameter", "m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_4", "(boiler, SH) The inner glass envelope diameter", "m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_5", "(boiler, SH) The outer glass envelope diameter", "m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "D_p", "(boiler, SH) The diameter of the absorber flow plug (optional)", "m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Rough", "(boiler, SH) Roughness of the internal surface", "m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Flow_type", "(boiler, SH) The flow type through the absorber", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "AbsorberMaterial", "(boiler, SH) Absorber material type", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "HCE_FieldFrac", "(boiler, SH) The fraction of the field occupied by this HCE type (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "alpha_abs", "(boiler, SH) Absorber absorptance (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "b_eps_HCE1", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "b_eps_HCE2", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "b_eps_HCE3", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "b_eps_HCE4", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sh_eps_HCE1", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sh_eps_HCE2", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sh_eps_HCE3", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sh_eps_HCE4", "(temperature) Absorber emittance (eps)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "alpha_env", "(boiler, SH) Envelope absorptance (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "EPSILON_4", "(boiler, SH) Inner glass envelope emissivities (Pyrex) (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Tau_envelope", "(boiler, SH) Envelope transmittance (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "GlazingIntactIn", "(boiler, SH) The glazing intact flag {true=0; false=1} (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "AnnulusGas", "(boiler, SH) Annulus gas type {1=air; 26=Ar; 27=H2} (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "P_a", "(boiler, SH) Annulus gas pressure (4: # field fracs)", "torr", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Design_loss", "(boiler, SH) Receiver heat loss at design (4: # field fracs)", "W/m", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Shadowing", "(boiler, SH) Receiver bellows shadowing loss factor (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "Dirt_HCE", "(boiler, SH) Loss due to dirt on the receiver envelope (4: # field fracs)", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "b_OpticalTable", "Values of the optical efficiency table", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "sh_OpticalTable", "Values of the optical efficiency table", "none", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dnifc", "Forecast DNI", "W/m2", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "I_bn", "Beam normal radiation (input kJ/m2-hr)", "W/m2", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_db", "Dry bulb air temperature", "C", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_dp", "The dewpoint temperature", "C", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_amb", "Ambient pressure", "atm", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "V_wind", "Ambient windspeed", "m/s", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "m_dot_htf_ref", "Reference HTF flow rate at design conditions", "kg/hr", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "m_pb_demand", "Demand htf flow from the power block", "kg/hr", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "shift", "Shift in longitude from local standard meridian", "deg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "SolarAz_init", "Solar azimuth angle", "deg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "SolarZen", "Solar zenith angle", "deg", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_pb_out_init", "Fluid temperature from the power block", "C", "", "solarfield", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_ref", "Reference conversion efficiency at design condition", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_cold_ref", "Reference HTF outlet temperature at design", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dT_cw_ref", "Reference condenser cooling water inlet/outlet T diff", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_amb_des", "Reference ambient temperature at design point", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "q_sby_frac", "Fraction of thermal power required for standby mode", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_boil_des", "Boiler operating pressure @ design", "bar", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_rh_ref", "Reheater operating pressure at design", "bar", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rh_frac_ref", "Reheater flow fraction at design", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "CT", "Flag for using dry cooling or wet cooling system", "none", "", "powerblock", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "startup_time", "Time needed for power block startup", "hr", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "startup_frac", "Fraction of design thermal power needed for startup", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_approach", "Cooling tower approach temperature", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_ITD_des", "ITD at design for dry system", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_cond_ratio", "Condenser pressure ratio", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pb_bd_frac", "Power block blowdown steam fraction ", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_cond_min", "Minimum condenser pressure", "inHg", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "n_pl_inc", "Number of part-load increments for the heat rejection system", "none", "", "powerblock", "*", "INTEGER", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "F_wc", "Fraction indicating wet cooling use for hybrid system", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pc_mode", "Cycle part load control, from plant controller", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_hot", "Hot HTF inlet temperature, from storage tank", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "m_dot_st", "HTF mass flow rate", "kg/hr", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_wb", "Ambient wet bulb temperature", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "demand_var", "Control signal indicating operational mode", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "standby_control", "Control signal indicating standby mode", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_db_pwb", "Ambient dry bulb temperature", "C", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_amb_pwb", "Ambient pressure", "atm", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "relhum", "Relative humidity of the ambient air", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "f_recSU", "Fraction powerblock can run due to receiver startup", "none", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dp_b", "Pressure drop in boiler", "Pa", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dp_sh", "Pressure drop in superheater", "Pa", "", "powerblock", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dp_rh", "Pressure drop in reheater", "Pa", "", "powerblock", "*", "", ""),
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
    var_info(SSC_OUTPUT, SSC_ARRAY, "defocus", "Field collector focus fraction", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_opt_ave", "Field collector optical efficiency", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_thermal", "Field thermal efficiency", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta_sf", "Field efficiency total", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_inc_tot", "Field thermal power incident", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_loss_rec", "Field thermal power receiver loss", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_loss_piping", "Field thermal power header pipe loss", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_loss_sf", "Field thermal power loss", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_field_delivered", "Field thermal power produced", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_field", "Field steam mass flow rate", "kg/hr", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_b_tot", "Field steam mass flow rate - boiler", "kg/hr", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot", "Field steam mass flow rate - loop", "kg/s", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_sf_in", "Field steam pressure at inlet", "bar", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dP_tot", "Field steam pressure loss", "bar", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_field_in", "Field steam temperature at header inlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_loop_out", "Field steam temperature at collector outlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_field_out", "Field steam temperature at header outlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "eta", "Cycle efficiency (gross)", "", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_net", "Cycle electrical power output (net)", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_cycle_gross", "Cycle electrical power output (gross)", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_to_pb", "Cycle steam mass flow rate", "kg/hr", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_turb_in", "Cycle steam pressure at inlet", "bar", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_pb_in", "Cycle steam temperature at inlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_pb_out", "Cycle steam temperature at outlet", "C", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "E_bal_startup", "Cycle thermal energy startup", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_dump", "Cycle thermal energy dumped", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_to_pb", "Cycle thermal power input", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_makeup", "Cycle cooling water mass flow rate - makeup", "kg/hr", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_cond", "Condenser pressure", "Pa", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "f_bays", "Condenser fraction of operating bays", "none", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_aux_fluid", "Fossil thermal power produced", "MWt", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "m_dot_aux", "Fossil steam mass flow rate", "kg/hr", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "q_aux_fuel", "Fossil fuel usage", "MMBTU", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_pump", "Parasitic power solar field pump", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_col", "Parasitic power field collector drives", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_bop", "Parasitic power generation-dependent load", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_fixed", "Parasitic power fixed load", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_dot_aux", "Parasitic power auxiliary heater operation", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "W_cool_par", "Parasitic power condenser operation", "MWe", "", "Outputs", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "monthly_energy", "Monthly Energy", "kWh", "", "Linear Fresnel", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual Energy", "kWh", "", "Linear Fresnel", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_W_cycle_gross", "Electrical source - Power cycle gross output", "kWh", "", "Linear Fresnel", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "conversion_factor", "Gross to Net Conversion Factor", "%", "", "Calculated", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_total_water_use", "Total Annual Water Usage: cycle + mirror washing", "m3", "", "PostProcess", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "System heat rate", "MMBtu/MWh", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual fuel usage", "kWh", "", "", "*", "", ""),
    var_info_invalid,
]

class cm_tcslinear_fresnel_dsg_csp_solver(tcKernel):
    def __init__(self, prov: tcstypeprovider):
        tcKernel.__init__(self, prov)
        self.add_var_info(_cm_vtab_tcslinear_fresnel_dsg_csp_solver)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        var c_lf_dsg = C_csp_lf_dsg_collector_receiver()
        c_lf_dsg.m_tes_hours = self.as_double("tes_hours")  # TSHOURS
        c_lf_dsg.m_q_max_aux = self.as_double("q_max_aux") * 1.0E3  # q_max_aux
        c_lf_dsg.m_LHV_eff = self.as_double("LHV_eff")  # LHV_eff
        c_lf_dsg.m_T_set_aux = self.as_double("T_hot") + 273.15
        c_lf_dsg.m_T_field_in_des = self.as_double("T_cold_ref") + 273.15
        c_lf_dsg.m_T_field_out_des = self.as_double("T_hot") + 273.15
        c_lf_dsg.m_x_b_des = self.as_double("x_b_des")  # x_b_des
        c_lf_dsg.m_P_turb_des = self.as_double("P_turb_des")  # P_turb_des
        c_lf_dsg.m_fP_hdr_c = self.as_double("fP_hdr_c")  # fP_hdr_c
        c_lf_dsg.m_fP_sf_boil = self.as_double("fP_sf_boil")  # fP_sf_boil
        c_lf_dsg.m_fP_boil_to_sh = self.as_double("fP_boil_to_sh")  # fP_boil_to_SH
        c_lf_dsg.m_fP_sf_sh = self.as_double("fP_sf_sh")  # fP_sf_sh
        c_lf_dsg.m_fP_hdr_h = self.as_double("fP_hdr_h")  # fP_hdr_h
        c_lf_dsg.m_q_pb_des = self.as_double("q_pb_des") * 1000.0  # Q_ref = P_ref/eta_ref
        c_lf_dsg.m_W_pb_des = self.as_double("demand_var") * 1000.0
        c_lf_dsg.m_cycle_max_fraction = self.as_double("cycle_max_fraction")  # cycle_max_fraction
        c_lf_dsg.m_cycle_cutoff_frac = self.as_double("cycle_cutoff_frac")  # cycle_cutoff_frac
        c_lf_dsg.m_t_sby_des = self.as_double("t_sby")  # t_sby
        c_lf_dsg.m_q_sby_frac = self.as_double("q_sby_frac")  # q_sby_frac
        c_lf_dsg.m_solarm = self.as_double("solarm")  # solarm
        c_lf_dsg.m_PB_pump_coef = self.as_double("PB_pump_coef")  # PB_pump_coef
        c_lf_dsg.m_PB_fixed_par = self.as_double("PB_fixed_par")  # PB_fixed_par
        # c_lf_dsg.q_max_aux = as_double("T_startup", as_double("T_hot"))
        c_lf_dsg.m_fossil_mode = self.as_double("fossil_mode")  # fossil_mode
        c_lf_dsg.m_I_bn_des = self.as_double("I_bn_des")  # I_bn_des
        c_lf_dsg.m_is_sh = 0  # remove superheaters
        c_lf_dsg.m_is_oncethru = Bool(self.as_double("is_oncethru"))  # is_oncethru ? bool
        c_lf_dsg.m_is_multgeom = Bool(self.as_double("is_multgeom"))  # is_multgeom
        c_lf_dsg.m_nModBoil = self.as_integer("nModBoil")  # nModBoil
        c_lf_dsg.m_nModSH = self.as_integer("nModSH")  # nModSH
        c_lf_dsg.m_nLoops = self.as_integer("nLoops")  # nLoops
        c_lf_dsg.m_eta_pump = self.as_double("eta_pump")  # eta_pump
        c_lf_dsg.m_latitude = self.as_double("latitude") * 0.0174533  # latitude
        c_lf_dsg.m_theta_stow = self.as_double("theta_stow") * 0.0174533  # theta_stow
        c_lf_dsg.m_theta_dep = self.as_double("theta_dep") * 0.0174533  # theta_dep
        c_lf_dsg.m_m_dot_min = self.as_double("m_dot_min")  # m_dot_min
        c_lf_dsg.m_T_field_ini = self.as_double("T_cold_ref") + 275.15
        c_lf_dsg.m_T_fp = self.as_double("T_fp") + 273.15  # T_fp
        c_lf_dsg.m_Pipe_hl_coef = self.as_double("Pipe_hl_coef")  # Pipe_hl_coef
        c_lf_dsg.m_SCA_drives_elec = self.as_double("SCA_drives_elec")  # SCA_drives_elec
        c_lf_dsg.m_ColAz = self.as_double("ColAz") * 0.0174533  # ColAz
        c_lf_dsg.m_e_startup = self.as_double("e_startup")  # e_startup
        c_lf_dsg.m_T_amb_des_sf = self.as_double("T_amb_des_sf") + 273.15  # T_amb_des_sf
        c_lf_dsg.m_V_wind_max = self.as_double("V_wind_max")  # V_wind_max

        var nval_bop_array: Int = -1
        var bop_array = self.as_array("bop_array", &nval_bop_array)
        c_lf_dsg.m_bop_array.resize(nval_bop_array)
        for i in range(nval_bop_array):
            c_lf_dsg.m_bop_array[i] = Float64(bop_array[i])

        var nval_aux_array: Int = -1
        var aux_array = self.as_array("aux_array", &nval_aux_array)
        c_lf_dsg.m_aux_array.resize(nval_aux_array)
        for i in range(nval_aux_array):
            c_lf_dsg.m_aux_array[i] = Float64(aux_array[i])

        var nval_ffrac: Int = -1
        var ffrac = self.as_array("ffrac", &nval_ffrac)
        c_lf_dsg.m_ffrac.resize(nval_ffrac)
        for i in range(nval_ffrac):
            c_lf_dsg.m_ffrac[i] = Float64(ffrac[i])

        var m_n_rows_matrix: Float64 = 1.0
        if c_lf_dsg.m_is_multgeom:
            m_n_rows_matrix = 2.0
        c_lf_dsg.m_n_rows_matrix = m_n_rows_matrix

        c_lf_dsg.m_A_aperture = self.as_matrix("A_aperture")  # A_aper
        c_lf_dsg.m_L_col = self.as_matrix("L_col")  # L_col
        c_lf_dsg.m_OptCharType = self.as_matrix("OptCharType")  # OptCharType
        c_lf_dsg.m_IAM_T = self.as_matrix("IAM_T")  # IAM_T
        c_lf_dsg.m_IAM_L = self.as_matrix("IAM_L")  # IAM_L
        c_lf_dsg.m_TrackingError = self.as_matrix("TrackingError")  # TrackingError
        c_lf_dsg.m_GeomEffects = self.as_matrix("GeomEffects")  # GeomEffects
        c_lf_dsg.m_rho_mirror_clean = self.as_matrix("rho_mirror_clean")  # rho_mirror_clean
        c_lf_dsg.m_dirt_mirror = self.as_matrix("dirt_mirror")  # dirt_mirror
        c_lf_dsg.m_error = self.as_matrix("error")  # error
        c_lf_dsg.m_HLCharType = self.as_matrix("HLCharType")  # HLCharType
        c_lf_dsg.m_HL_dT = self.as_matrix("HL_dT")  # HL_dT
        c_lf_dsg.m_HL_W = self.as_matrix("HL_W")  # HL_W
        c_lf_dsg.m_D_2 = self.as_matrix("D_2")  # D_2
        c_lf_dsg.m_D_3 = self.as_matrix("D_3")  # D_3
        c_lf_dsg.m_D_4 = self.as_matrix("D_4")  # D_4
        c_lf_dsg.m_D_5 = self.as_matrix("D_5")  # D_5
        c_lf_dsg.m_D_p = self.as_matrix("D_p")  # D_p
        c_lf_dsg.m_Rough = self.as_matrix("Rough")  # Rough
        c_lf_dsg.m_Flow_type = self.as_matrix("Flow_type")  # Flow_type
        c_lf_dsg.m_AbsorberMaterial_in = self.as_matrix("AbsorberMaterial")
        c_lf_dsg.m_HCE_FieldFrac = self.as_matrix("HCE_FieldFrac")  # HCE_FieldFrac
        c_lf_dsg.m_alpha_abs = self.as_matrix("alpha_abs")  # alpha_abs
        c_lf_dsg.m_b_eps_HCE1 = self.as_matrix("b_eps_HCE1")  # b_eps_HCE1
        c_lf_dsg.m_b_eps_HCE2 = self.as_matrix("b_eps_HCE2")  # b_eps_HCE2
        c_lf_dsg.m_b_eps_HCE3 = self.as_matrix("b_eps_HCE3")  # b_eps_HCE3
        c_lf_dsg.m_b_eps_HCE4 = self.as_matrix("b_eps_HCE4")  # b_eps_HCE4
        if c_lf_dsg.m_is_multgeom != 0:
            c_lf_dsg.m_sh_eps_HCE1 = self.as_matrix("sh_eps_HCE1")  # s_eps_HCE1
            c_lf_dsg.m_sh_eps_HCE2 = self.as_matrix("sh_eps_HCE2")  # s_eps_HCE2
            c_lf_dsg.m_sh_eps_HCE3 = self.as_matrix("sh_eps_HCE3")  # s_eps_HCE3
            c_lf_dsg.m_sh_eps_HCE4 = self.as_matrix("sh_eps_HCE4")  # s_eps_HCE4

        c_lf_dsg.m_alpha_env = self.as_matrix("alpha_env")  # alpha_env) [-] Envelope absorptance
        c_lf_dsg.m_EPSILON_4 = self.as_matrix("EPSILON_4")  # EPSILON_4) [-] Inner glass envelope emissivities (Pyrex)
        c_lf_dsg.m_Tau_envelope = self.as_matrix("Tau_envelope")  # Tau_envelope) [-] Envelope transmittance
        c_lf_dsg.m_GlazingIntactIn = Bool(self.as_matrix("GlazingIntactIn"))  # GlazingIntactIn) [-] Is the glazing intact?
        c_lf_dsg.m_AnnulusGas_in = self.as_matrix("AnnulusGas")  # AnnulusGas)
        c_lf_dsg.m_P_a = self.as_matrix("P_a")  # P_a) [torr] Annulus gas pressure
        c_lf_dsg.m_Design_loss = self.as_matrix("Design_loss")  # Design_loss) [W/m] Receiver heat loss at design
        c_lf_dsg.m_Shadowing = self.as_matrix("Shadowing")  # Shadowing) [-] Receiver bellows shadowing loss factor
        c_lf_dsg.m_Dirt_HCE = self.as_matrix("Dirt_HCE")  # Dirt_HCE) [-] Loss due to dirt on the receiver envelope
        c_lf_dsg.m_b_OpticalTable = self.as_matrix("b_OpticalTable")  # opt_data) [-] Boiler Optical Table
        c_lf_dsg.m_sh_OpticalTable = self.as_matrix("sh_OpticalTable")  # opt_data)
        c_lf_dsg.m_is_multgeom = False  # single geometry is used
        c_lf_dsg.m_is_sh = False  # no superheater

# DEFINE_TCS_MODULE_ENTRY(tcslinear_fresnel_dsg_csp_solver, "CSP model using the linear fresnel TCS types.", 4)
def tcslinear_fresnel_dsg_csp_solver():  # placeholder for module entry
