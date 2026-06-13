from tcstype import *
from sam_csp_util import *
from water_properties import *
from sam_csp_util import *
from math import *
from csp_solver_lf_dsg_collector_receiver import C_csp_lf_dsg_collector_receiver
from csp_solver_util import *
from csp_solver_core import *

enum P_TESHOURS: pass
enum P_Q_MAX_AUX: pass
enum P_LHV_EFF: pass
enum P_T_SET_AUX: pass
enum P_T_FIELD_IN_DES: pass
enum P_T_FIELD_OUT_DES: pass
enum P_X_B_DES: pass
enum P_P_TURB_DES: pass
enum P_FP_HDR_C: pass
enum P_FP_SF_BOIL: pass
enum P_FP_BOIL_TO_SH: pass
enum P_FP_SF_SH: pass
enum P_FP_HDR_H: pass
enum P_Q_PB_DES: pass
enum P_W_PB_DES: pass
enum P_CYCLE_MAX_FRAC: pass
enum P_CYCLE_CUTOFF_FRAC: pass
enum P_T_SBY: pass
enum P_Q_SBY_FRAC: pass
enum P_SOLARM: pass
enum P_PB_PUMP_COEF: pass
enum P_PB_FIXED_PAR: pass
enum P_BOP_ARRAY: pass
enum P_AUX_ARRAY: pass
enum P_T_STARTUP: pass
enum P_FOSSIL_MODE: pass
enum P_I_BN_DES: pass
enum P_IS_SH: pass
enum P_IS_ONCETHRU: pass
enum P_IS_MULTGEOM: pass
enum P_NMODBOIL: pass
enum P_NMODSH: pass
enum P_NLOOPS: pass
enum P_ETA_PUMP: pass
enum P_LATITUDE: pass
enum P_THETA_STOW: pass
enum P_THETA_DEP: pass
enum P_M_DOT_MIN: pass
enum P_T_FIELD_INI: pass
enum P_T_FP: pass
enum P_PIPE_HL_COEF: pass
enum P_SCA_DRIVES_ELEC: pass
enum P_COLAZ: pass
enum P_E_STARTUP: pass
enum P_T_AMB_DES_SF: pass
enum P_V_WIND_MAX: pass
enum P_FFRAC: pass
enum P_A_APERTURE: pass
enum P_L_COL: pass
enum P_OPTCHARTYPE: pass
enum P_IAM_T: pass
enum P_IAM_L: pass
enum P_TRACKINGERROR: pass
enum P_GEOMEFFECTS: pass
enum P_RHO_MIRROR_CLEAN: pass
enum P_DIRT_MIRROR: pass
enum P_ERROR: pass
enum P_HLCHARTYPE: pass
enum P_HL_DT: pass
enum P_HL_W: pass
enum P_D_2: pass
enum P_D_3: pass
enum P_D_4: pass
enum P_D_5: pass
enum P_D_p: pass
enum P_ROUGH: pass
enum P_FLOW_TYPE: pass
enum P_ABSORBER_MAT: pass
enum P_HCE_FIELDFRAC: pass
enum P_ALPHA_ABS: pass
enum P_B_EPS_HCE1: pass
enum P_B_EPS_HCE2: pass
enum P_B_EPS_HCE3: pass
enum P_B_EPS_HCE4: pass
enum P_SH_EPS_HCE1: pass
enum P_SH_EPS_HCE2: pass
enum P_SH_EPS_HCE3: pass
enum P_SH_EPS_HCE4: pass
enum P_ALPHA_ENV: pass
enum P_EPSILON_4: pass
enum P_TAU_ENVELOPE: pass
enum P_GLAZINGINTACTIN: pass
enum P_ANNULUSGAS: pass
enum P_P_A: pass
enum P_DESIGN_LOSS: pass
enum P_SHADOWING: pass
enum P_DIRT_HCE: pass
enum P_B_OPTICALTABLE: pass
enum P_SH_OPTICALTABLE: pass
enum PO_A_APER_TOT: pass
enum I_DNIFC: pass
enum I_I_BN: pass
enum I_T_DB: pass
enum I_T_DP: pass
enum I_P_AMB: pass
enum I_V_WIND: pass
enum I_M_DOT_HTF_REF: pass
enum I_M_PB_DEMAND: pass
enum I_SHIFT: pass
enum I_SOLARAZ: pass
enum I_SOLARZEN: pass
enum I_T_PB_OUT: pass
enum I_TOUPERIOD: pass
enum O_CYCLE_PL_CONTROL: pass
enum O_DP_TOT: pass
enum O_DP_HDR_C: pass
enum O_DP_SF_BOIL: pass
enum O_DP_BOIL_TO_SH: pass
enum O_DP_SF_SH: pass
enum O_DP_HDR_H: pass
enum O_E_BAL_STARTUP: pass
enum O_E_FIELD: pass
enum O_E_FP_TOT: pass
enum O_ETA_OPT_AVE: pass
enum O_ETA_THERMAL: pass
enum O_ETA_SF: pass
enum O_DEFOCUS: pass
enum O_M_DOT_AUX: pass
enum O_M_DOT_FIELD: pass
enum O_M_DOT_B_TOT: pass
enum O_M_DOT: pass
enum O_M_DOT_TO_PB: pass
enum O_P_TURB_IN: pass
enum O_Q_LOSS_PIPING: pass
enum O_Q_AUX_FLUID: pass
enum O_Q_AUX_FUEL: pass
enum O_Q_DUMP: pass
enum O_Q_FIELD_DELIVERED: pass
enum O_Q_INC_TOT: pass
enum O_Q_LOSS_REC: pass
enum O_Q_LOSS_SF: pass
enum O_Q_TO_PB: pass
enum O_SOLARALT: pass
enum O_SOLARAZ: pass
enum O_PHI_T: pass
enum O_THETA_L: pass
enum O_STANDBY_CONTROL: pass
enum O_T_FIELD_IN: pass
enum O_T_FIELD_OUT: pass
enum O_T_LOOP_OUT: pass
enum O_T_PB_IN: pass
enum O_W_DOT_AUX: pass
enum O_W_DOT_BOP: pass
enum O_W_DOT_COL: pass
enum O_W_DOT_FIXED: pass
enum O_W_DOT_PUMP: pass
enum O_W_DOT_PAR_TOT: pass
enum O_P_SF_IN: pass
enum N_MAX: pass

var sam_mw_lf_type261_steam_variables: List[tcsvarinfo] = List[tcsvarinfo]()
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TESHOURS, "tes_hours", "Equivalent full-load thermal storage hours", "hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Q_MAX_AUX, "q_max_aux", "Maximum heat rate of the auxiliary heater", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_LHV_EFF, "LHV_eff", "Fuel LHV efficiency (0..1)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_SET_AUX, "T_set_aux", "Aux heater outlet temperature set point", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_FIELD_IN_DES, "T_field_in_des", "Field design inlet temperature", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_FIELD_OUT_DES, "T_field_out_des", "Field loop outlet design temperature", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_X_B_DES, "x_b_des", "Design point boiler outlet steam quality", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_P_TURB_DES, "P_turb_des", "Design-point turbine inlet pressure", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FP_HDR_C, "fP_hdr_c", "Average design-point cold header pressure drop fraction", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FP_SF_BOIL, "fP_sf_boil", "Design-point pressure drop across the solar field boiler fraction", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FP_BOIL_TO_SH, "fP_boil_to_sh", "Design-point pressure drop between the boiler and superheater frac", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FP_SF_SH, "fP_sf_sh", "Design-point pressure drop across the solar field superheater frac", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FP_HDR_H, "fP_hdr_h", "Average design-point hot header pressure drop fraction", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Q_PB_DES, "q_pb_des", "Design heat input to the power block", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_W_PB_DES, "W_pb_des", "Rated plant capacity", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_CYCLE_MAX_FRAC, "cycle_max_fraction", "Maximum turbine over design operation fraction", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_CYCLE_CUTOFF_FRAC, "cycle_cutoff_frac", "Minimum turbine operation fraction before shutdown", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_SBY, "t_sby", "Low resource standby period", "hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Q_SBY_FRAC, "q_sby_frac", "Fraction of thermal power required for standby", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_SOLARM, "solarm", "Solar multiple", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PB_PUMP_COEF, "PB_pump_coef", "Pumping power required to move 1kg of HTF through power block flow", "kW/kg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PB_FIXED_PAR, "PB_fixed_par", "fraction of rated gross power consumed at all hours of the year", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_BOP_ARRAY, "bop_array", "BOP_parVal, BOP_parPF, BOP_par0, BOP_par1, BOP_par2", "-", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_AUX_ARRAY, "aux_array", "Aux_parVal, Aux_parPF, Aux_par0, Aux_par1, Aux_par2", "-", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_STARTUP, "T_startup", "Startup temperature (same as field startup)", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FOSSIL_MODE, "fossil_mode", "Operation mode for the fossil backup {1=Normal,2=supp,3=toppin}", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_I_BN_DES, "I_bn_des", "Design point irradiation value", "W/m2", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_IS_SH, "is_sh", "Does the solar field include a superheating section", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_IS_ONCETHRU, "is_oncethru", "Flag indicating whether flow is once through with superheat", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_IS_MULTGEOM, "is_multgeom", "Does the superheater have a different geometry from the boiler {1=yes}", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_NMODBOIL, "nModBoil", "Number of modules in the boiler section", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_NMODSH, "nModSH", "Number of modules in the superheater section", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_NLOOPS, "nLoops", "Number of loops", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_PUMP, "eta_pump", "Feedwater pump efficiency", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_LATITUDE, "latitude", "Site latitude read from weather file", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_THETA_STOW, "theta_stow", "stow angle", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_THETA_DEP, "theta_dep", "deploy angle", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_M_DOT_MIN, "m_dot_min", "Minimum loop flow rate", "kg/s", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_FIELD_INI, "T_field_ini", "Initial field temperature", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_FP, "T_fp", "Freeze protection temperature (heat trace activation temperature)", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PIPE_HL_COEF, "Pipe_hl_coef", "Loss coefficient from the header.. runner pipe.. and non-HCE pipin", "W/m2-K", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_SCA_DRIVES_ELEC, "SCA_drives_elec", "Tracking power.. in Watts per SCA drive", "W/m2", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_COLAZ, "ColAz", "Collector azimuth angle", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_E_STARTUP, "e_startup", "Thermal inertia contribution per sq meter of solar field", "kJ/K-m2", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_AMB_DES_SF, "T_amb_des_sf", "Design-point ambient temperature", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_V_WIND_MAX, "V_wind_max", "Maximum allowable wind velocity before safety stow", "m/s", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_FFRAC, "ffrac", "Fossil dispatch logic - TOU periods", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_A_APERTURE, "A_aperture", "(boiler, SH) Reflective aperture area of the collector module", "m^2", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_L_COL, "L_col", "(boiler, SH) Active length of the superheater section collector module", "m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_OPTCHARTYPE, "OptCharType", "(boiler, SH) The optical characterization method", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_IAM_T, "IAM_T", "(boiler, SH) Transverse Incident angle modifiers (0,1,2,3,4 order terms)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_IAM_L, "IAM_L", "(boiler, SH) Longitudinal Incident angle modifiers (0,1,2,3,4 order terms)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_TRACKINGERROR, "TrackingError", "(boiler, SH) User-defined tracking error derate", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_GEOMEFFECTS, "GeomEffects", "(boiler, SH) User-defined geometry effects derate", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_RHO_MIRROR_CLEAN, "rho_mirror_clean", "(boiler, SH) User-defined clean mirror reflectivity", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_DIRT_MIRROR, "dirt_mirror", "(boiler, SH) User-defined dirt on mirror derate", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_ERROR, "error", "(boiler, SH) User-defined general optical error derate", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_HLCHARTYPE, "HLCharType", "(boiler, SH) Flag indicating the heat loss model type {1=poly.; 2=Forristall}", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_HL_DT, "HL_dT", "(boiler, SH) Heat loss coefficient - HTF temperature (0,1,2,3,4 order terms)", "W/m-K^order", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_HL_W, "HL_W", "(boiler, SH) Heat loss coef adj wind velocity (0,1,2,3,4 order terms)", "1/(m/s)^order", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_D_2, "D_2", "(boiler, SH) The inner absorber tube diameter", "m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_D_3, "D_3", "(boiler, SH) The outer absorber tube diameter", "m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_D_4, "D_4", "(boiler, SH) The inner glass envelope diameter", "m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_D_5, "D_5", "(boiler, SH) The outer glass envelope diameter", "m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_D_p, "D_p", "(boiler, SH) The diameter of the absorber flow plug (optional)", "m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_ROUGH, "Rough", "(boiler, SH) Roughness of the internal surface", "m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_FLOW_TYPE, "Flow_type", "(boiler, SH) The flow type through the absorber", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_ABSORBER_MAT, "AbsorberMaterial", "(boiler, SH) Absorber material type", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_HCE_FIELDFRAC, "HCE_FieldFrac", "(boiler, SH) The fraction of the field occupied by this HCE type (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_ALPHA_ABS, "alpha_abs", "(boiler, SH) Absorber absorptance (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_B_EPS_HCE1, "b_eps_HCE1", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_B_EPS_HCE2, "b_eps_HCE2", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_B_EPS_HCE3, "b_eps_HCE3", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_B_EPS_HCE4, "b_eps_HCE4", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_SH_EPS_HCE1, "sh_eps_HCE1", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_SH_EPS_HCE2, "sh_eps_HCE2", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_SH_EPS_HCE3, "sh_eps_HCE3", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_SH_EPS_HCE4, "sh_eps_HCE4", "(temperature) Absorber emittance (eps)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_ALPHA_ENV, "alpha_env", "(boiler, SH) Envelope absorptance (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_EPSILON_4, "EPSILON_4", "(boiler, SH) Inner glass envelope emissivities (Pyrex) (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_TAU_ENVELOPE, "Tau_envelope", "(boiler, SH) Envelope transmittance (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_GLAZINGINTACTIN, "GlazingIntactIn", "(boiler, SH) The glazing intact flag {true=0; false=1} (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_ANNULUSGAS, "AnnulusGas", "(boiler, SH) Annulus gas type {1=air; 26=Ar; 27=H2} (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_P_A, "P_a", "(boiler, SH) Annulus gas pressure (4: # field fracs)", "torr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_DESIGN_LOSS, "Design_loss", "(boiler, SH) Receiver heat loss at design (4: # field fracs)", "W/m", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_SHADOWING, "Shadowing", "(boiler, SH) Receiver bellows shadowing loss factor (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_DIRT_HCE, "Dirt_HCE", "(boiler, SH) Loss due to dirt on the receiver envelope (4: # field fracs)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_B_OPTICALTABLE, "b_OpticalTable", "Values of the optical efficiency table", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_SH_OPTICALTABLE, "sh_OpticalTable", "Values of the optical efficiency table", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_PARAM, TCS_NUMBER, PO_A_APER_TOT, "A_aper_tot", "Total solar field aperture area", "m^2", "", "", "-1.23"))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_DNIFC, "dnifc", "Forecast DNI", "W/m2", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_I_BN, "I_bn", "Beam normal radiation (input kJ/m2-hr)", "W/m2", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_DB, "T_db", "Dry bulb air temperature", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_DP, "T_dp", "The dewpoint temperature", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_AMB, "P_amb", "Ambient pressure", "atm", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_V_WIND, "V_wind", "Ambient windspeed", "m/s", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_M_DOT_HTF_REF, "m_dot_htf_ref", "Reference HTF flow rate at design conditions", "kg/hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_M_PB_DEMAND, "m_pb_demand", "Demand htf flow from the power block", "kg/hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_SHIFT, "shift", "Shift in longitude from local standard meridian", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_SOLARAZ, "SolarAz", "Solar azimuth angle", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_SOLARZEN, "SolarZen", "Solar zenith angle", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_PB_OUT, "T_pb_out", "Fluid temperature from the power block", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TOUPERIOD, "TOUPeriod", "Time of use period", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_CYCLE_PL_CONTROL, "cycle_pl_control", "Part-load control flag - used by Type224", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DP_TOT, "dP_tot", "Total HTF pressure drop", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DP_HDR_C, "dP_hdr_c", "Average cold header pressure drop", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DP_SF_BOIL, "dP_sf_boil", "Pressure drop across the solar field boiler", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DP_BOIL_TO_SH, "dP_boil_to_SH", "Pressure drop between the boiler and superheater", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DP_SF_SH, "dP_sf_sh", "Pressure drop across the solar field superheater", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DP_HDR_H, "dP_hdr_h", "Average hot header pressure drop", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_E_BAL_STARTUP, "E_bal_startup", "Startup energy consumed", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_E_FIELD, "E_field", "Accumulated internal energy in the entire solar field", "MW-hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_E_FP_TOT, "E_fp_tot", "Freeze protection energy", "J", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_OPT_AVE, "eta_opt_ave", "collector equivalent optical efficiency", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_THERMAL, "eta_thermal", "Solar field thermal efficiency (power out/ANI)", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_SF, "eta_sf", "Total solar field collection efficiency", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DEFOCUS, "defocus", "The fraction of focused aperture area in the solar field", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_AUX, "m_dot_aux", "Auxiliary heater mass flow rate", "kg/hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_FIELD, "m_dot_field", "Flow rate from the field", "kg/hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_B_TOT, "m_dot_b_tot", "Flow rate within the boiler section", "kg/hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT, "m_dot", "Flow rate in a single loop", "kg/s", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_TO_PB, "m_dot_to_pb", "Flow rate delivered to the power block", "kg/hr", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_TURB_IN, "P_turb_in", "Pressure at the turbine inlet", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_LOSS_PIPING, "q_loss_piping", "Pipe heat loss in the hot header and the hot runner", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_AUX_FLUID, "q_aux_fluid", "Thermal energy provided to the fluid passing through the aux heater", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_AUX_FUEL, "q_aux_fuel", "Heat content of fuel required to provide aux firing", "MMBTU", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_DUMP, "q_dump", "Dumped thermal energy", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_FIELD_DELIVERED, "q_field_delivered", "Total solar field thermal power delivered", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_INC_TOT, "q_inc_tot", "Total power incident on the field", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_LOSS_REC, "q_loss_rec", "Total Receiver thermal losses", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_LOSS_SF, "q_loss_sf", "Total solar field thermal losses", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_TO_PB, "q_to_pb", "Thermal energy to the power block", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLARALT, "SolarAlt", "Solar altitude used in optical calculations", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLARAZ, "SolarAz", "Solar azimuth used in optical calculations", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_PHI_T, "phi_t", "Transversal solar incidence angle", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_THETA_L, "theta_L", "Longitudinal solar incidence angle", "deg", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_STANDBY_CONTROL, "standby_control", "Standby control flag - used by Type224", "none", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_FIELD_IN, "T_field_in", "HTF temperature into the collector field header", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_FIELD_OUT, "T_field_out", "HTF Temperature from the field", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_LOOP_OUT, "T_loop_out", "Loop outlet temperature", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_PB_IN, "T_pb_in", "HTF Temperature to the power block", "C", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_AUX, "W_dot_aux", "Parasitic power associated with operation of the aux boiler", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_BOP, "W_dot_bop", "parasitic power as a function of power block load", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_COL, "W_dot_col", "Parasitic electric power consumed by the collectors", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_FIXED, "W_dot_fixed", "Fixed parasitic power losses.. for every hour of operation", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_PUMP, "W_dot_pump", "Required solar field pumping power", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_PAR_TOT, "W_dot_par_tot", "Total parasitics", "MW", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_SF_IN, "P_sf_in", "Solar field inlet pressure", "bar", "", "", ""))
sam_mw_lf_type261_steam_variables.append(tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0))

class sam_mw_lf_type261_steam(tcstypeinterface):
    var dsg_lf: C_csp_lf_dsg_collector_receiver
    var dsg_weather: C_csp_weatherreader.S_outputs
    var dsg_htf_state_in: C_csp_solver_htf_1state
    var dsg_inputs: C_csp_collector_receiver.S_csp_cr_inputs
    var dsg_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver
    var dsg_sim_info: C_csp_solver_sim_info

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cst, ti)
        self.dsg_lf = C_csp_lf_dsg_collector_receiver()
        self.dsg_weather = C_csp_weatherreader.S_outputs()
        self.dsg_htf_state_in = C_csp_solver_htf_1state()
        self.dsg_inputs = C_csp_collector_receiver.S_csp_cr_inputs()
        self.dsg_out_solver = C_csp_collector_receiver.S_csp_cr_out_solver()
        self.dsg_sim_info = C_csp_solver_sim_info()

    def __del__(owned self):

    def turb_pres_frac(self, m_dot_nd: Float64, fmode: Int, ffrac: Float64, fP_min: Float64) -> Float64:
        #Take a mass flow fraction, fossil backup fraction, fossil fill mode, and minimum turbine fraction
        #and calculate the corresponding fraction of the design point pressure at which the turbine 
        #will operate
        if fmode == 1:
            # Backup minimum level - parallel
            return max(fP_min, max(m_dot_nd, ffrac))
        elif fmode == 2:
            # Supplemental Operation - parallel
            return max(fP_min, max(m_dot_nd, min(1.0, m_dot_nd + ffrac)))
        elif fmode == 3:
            # Temperature topping mode - series
            return max(fP_min, m_dot_nd)
        return 0.0

    def set_matrix_t(self, idx: Int, inout class_matrix: util.matrix_t[Float64]):
        var n_rows: Int = -1
        var n_cols: Int = -1
        var data: Pointer[Float64] = value(idx, &n_rows, &n_cols)
        class_matrix.resize(n_rows, n_cols)
        for r in range(n_rows):
            for c in range(n_cols):
                class_matrix[r, c] = TCS_MATRIX_INDEX(var(idx), r, c)

    def set_matrix_t(self, idx: Int, inout class_matrix: util.matrix_t[Int]):
        var n_rows: Int = -1
        var n_cols: Int = -1
        var data: Pointer[Float64] = value(idx, &n_rows, &n_cols)
        class_matrix.resize(n_rows, n_cols)
        for r in range(n_rows):
            for c in range(n_cols):
                class_matrix[r, c] = Int(TCS_MATRIX_INDEX(var(idx), r, c))

    def set_matrix_t(self, idx: Int, inout class_matrix: util.matrix_t[Bool]):
        var n_rows: Int = -1
        var n_cols: Int = -1
        var data: Pointer[Float64] = value(idx, &n_rows, &n_cols)
        class_matrix.resize(n_rows, n_cols)
        for r in range(n_rows):
            for c in range(n_cols):
                class_matrix[r, c] = Bool(TCS_MATRIX_INDEX(var(idx), r, c))

    def init(self) -> Int:
        self.dsg_lf.m_q_max_aux = value(P_Q_MAX_AUX) * 1.0E3
        self.dsg_lf.m_LHV_eff = value(P_Q_MAX_AUX)
        self.dsg_lf.m_T_set_aux = value(P_T_SET_AUX) + 273.15
        self.dsg_lf.m_T_field_in_des = value(P_T_FIELD_IN_DES) + 273.15
        self.dsg_lf.m_T_field_out_des = value(P_T_FIELD_OUT_DES) + 273.15
        self.dsg_lf.m_x_b_des = value(P_X_B_DES)
        self.dsg_lf.m_P_turb_des = value(P_P_TURB_DES)
        self.dsg_lf.m_fP_hdr_c = value(P_FP_HDR_C)
        self.dsg_lf.m_fP_sf_boil = value(P_FP_SF_BOIL)
        self.dsg_lf.m_fP_boil_to_sh = value(P_FP_BOIL_TO_SH)
        self.dsg_lf.m_fP_sf_sh = value(P_FP_SF_SH)
        self.dsg_lf.m_fP_hdr_h = value(P_FP_HDR_H)
        self.dsg_lf.m_q_pb_des = value(P_Q_PB_DES) * 1000.0
        self.dsg_lf.m_W_pb_des = value(P_W_PB_DES) * 1000.0
        self.dsg_lf.m_m_dot_max_frac = 3.0
        self.dsg_lf.m_m_dot_min_frac = 0.0
        self.dsg_lf.m_cycle_max_fraction = value(P_CYCLE_MAX_FRAC)
        self.dsg_lf.m_cycle_cutoff_frac = value(P_CYCLE_CUTOFF_FRAC)
        self.dsg_lf.m_t_sby_des = value(P_T_SBY)
        self.dsg_lf.m_q_sby_frac = value(P_Q_SBY_FRAC)
        self.dsg_lf.m_PB_fixed_par = value(P_PB_FIXED_PAR)
        self.dsg_lf.m_fossil_mode = Int(value(P_FOSSIL_MODE))
        self.dsg_lf.m_I_bn_des = value(P_I_BN_DES)
        self.dsg_lf.m_is_oncethru = Bool(value(P_IS_ONCETHRU))
        self.dsg_lf.m_is_sh_target = True
        self.dsg_lf.m_is_multgeom = Bool(value(P_IS_MULTGEOM))
        self.dsg_lf.m_nModBoil = Int(value(P_NMODBOIL))
        self.dsg_lf.m_nModSH = Int(value(P_NMODSH))
        self.dsg_lf.m_nLoops = Int(value(P_NLOOPS))
        self.dsg_lf.m_eta_pump = value(P_ETA_PUMP)
        self.dsg_lf.m_latitude = value(P_LATITUDE) * 0.0174533
        self.dsg_lf.m_theta_stow = value(P_THETA_STOW) * 0.0174533
        self.dsg_lf.m_theta_dep = value(P_THETA_DEP) * 0.0174533
        self.dsg_lf.m_T_field_ini = value(P_T_FIELD_INI) + 275.15
        self.dsg_lf.m_T_fp = value(P_T_FP) + 273.15
        self.dsg_lf.m_Pipe_hl_coef = value(P_PIPE_HL_COEF)
        self.dsg_lf.m_SCA_drives_elec = value(P_SCA_DRIVES_ELEC)
        self.dsg_lf.m_ColAz = value(P_COLAZ) * 0.0174533
        self.dsg_lf.m_e_startup = value(P_E_STARTUP)
        self.dsg_lf.m_T_amb_des_sf = value(P_T_AMB_DES_SF) + 273.15
        self.dsg_lf.m_V_wind_max = value(P_V_WIND_MAX)
        var nval_bop_array: Int = -1
        var bop_array: Pointer[Float64] = value(P_BOP_ARRAY, &nval_bop_array)
        self.dsg_lf.m_bop_array.resize(nval_bop_array)
        for i in range(nval_bop_array):
            self.dsg_lf.m_bop_array[i] = bop_array[i]
        var nval_aux_array: Int = -1
        var aux_array: Pointer[Float64] = value(P_AUX_ARRAY, &nval_aux_array)
        self.dsg_lf.m_aux_array.resize(nval_aux_array)
        for i in range(nval_aux_array):
            self.dsg_lf.m_aux_array[i] = Float64(aux_array[i])
        var nval_ffrac: Int = -1
        var ffrac: Pointer[Float64] = value(P_FFRAC, &nval_ffrac)
        self.dsg_lf.m_ffrac.resize(nval_ffrac)
        for i in range(nval_ffrac):
            self.dsg_lf.m_ffrac[i] = Float64(ffrac[i])
        self.set_matrix_t(P_A_APERTURE, self.dsg_lf.m_A_aperture)
        self.set_matrix_t(P_L_COL, self.dsg_lf.m_L_col)
        self.set_matrix_t(P_OPTCHARTYPE, self.dsg_lf.m_OptCharType)
        self.set_matrix_t(P_IAM_T, self.dsg_lf.m_IAM_T)
        self.set_matrix_t(P_IAM_L, self.dsg_lf.m_IAM_L)
        self.set_matrix_t(P_TRACKINGERROR, self.dsg_lf.m_TrackingError)
        self.set_matrix_t(P_GEOMEFFECTS, self.dsg_lf.m_GeomEffects)
        self.set_matrix_t(P_RHO_MIRROR_CLEAN, self.dsg_lf.m_rho_mirror_clean)
        self.set_matrix_t(P_DIRT_MIRROR, self.dsg_lf.m_dirt_mirror)
        self.set_matrix_t(P_ERROR, self.dsg_lf.m_error)
        self.set_matrix_t(P_HLCHARTYPE, self.dsg_lf.m_HLCharType)
        self.set_matrix_t(P_HL_DT, self.dsg_lf.m_HL_dT)
        self.set_matrix_t(P_HL_W, self.dsg_lf.m_HL_W)
        self.set_matrix_t(P_D_2, self.dsg_lf.m_D_2)
        self.set_matrix_t(P_D_3, self.dsg_lf.m_D_3)
        self.set_matrix_t(P_D_4, self.dsg_lf.m_D_4)
        self.set_matrix_t(P_D_5, self.dsg_lf.m_D_5)
        self.set_matrix_t(P_D_p, self.dsg_lf.m_D_p)
        self.set_matrix_t(P_ROUGH, self.dsg_lf.m_Rough)
        self.set_matrix_t(P_FLOW_TYPE, self.dsg_lf.m_Flow_type)
        self.set_matrix_t(P_ABSORBER_MAT, self.dsg_lf.m_AbsorberMaterial_in)
        self.set_matrix_t(P_HCE_FIELDFRAC, self.dsg_lf.m_HCE_FieldFrac)
        self.set_matrix_t(P_ALPHA_ABS, self.dsg_lf.m_alpha_abs)
        self.set_matrix_t(P_B_EPS_HCE1, self.dsg_lf.m_b_eps_HCE1)
        self.set_matrix_t(P_B_EPS_HCE2, self.dsg_lf.m_b_eps_HCE2)
        self.set_matrix_t(P_B_EPS_HCE3, self.dsg_lf.m_b_eps_HCE3)
        self.set_matrix_t(P_B_EPS_HCE4, self.dsg_lf.m_b_eps_HCE4)
        if self.dsg_lf.m_is_multgeom != 0:
            self.set_matrix_t(P_SH_EPS_HCE1, self.dsg_lf.m_sh_eps_HCE1)
            self.set_matrix_t(P_SH_EPS_HCE2, self.dsg_lf.m_sh_eps_HCE2)
            self.set_matrix_t(P_SH_EPS_HCE3, self.dsg_lf.m_sh_eps_HCE3)
            self.set_matrix_t(P_SH_EPS_HCE4, self.dsg_lf.m_sh_eps_HCE4)
        self.set_matrix_t(P_ALPHA_ENV, self.dsg_lf.m_alpha_env)
        self.set_matrix_t(P_EPSILON_4, self.dsg_lf.m_EPSILON_4)
        self.set_matrix_t(P_TAU_ENVELOPE, self.dsg_lf.m_Tau_envelope)
        self.set_matrix_t(P_GLAZINGINTACTIN, self.dsg_lf.m_GlazingIntactIn)
        self.set_matrix_t(P_ANNULUSGAS, self.dsg_lf.m_AnnulusGas_in)
        self.set_matrix_t(P_P_A, self.dsg_lf.m_P_a)
        self.set_matrix_t(P_DESIGN_LOSS, self.dsg_lf.m_Design_loss)
        self.set_matrix_t(P_SHADOWING, self.dsg_lf.m_Shadowing)
        self.set_matrix_t(P_DIRT_HCE, self.dsg_lf.m_Dirt_HCE)
        self.set_matrix_t(P_B_OPTICALTABLE, self.dsg_lf.m_b_OpticalTable)
        self.set_matrix_t(P_SH_OPTICALTABLE, self.dsg_lf.m_sh_OpticalTable)
        var solved_params: C_csp_collector_receiver.S_csp_cr_solved_params
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            var init_inputs: C_csp_collector_receiver.S_csp_cr_init_inputs
            self.dsg_lf.init(init_inputs, solved_params)
        except C_csp_exception as csp_exception:
            while self.dsg_lf.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    message(TCS_WARNING, out_msg)
            message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.dsg_lf.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                message(TCS_WARNING, out_msg)
        value(PO_A_APER_TOT, solved_params.m_A_aper_total)
        return 0

    def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
        self.dsg_weather.m_beam = value(I_I_BN)
        self.dsg_weather.m_tdry = value(I_T_DB)
        self.dsg_weather.m_wspd = value(I_V_WIND)
        self.dsg_weather.m_pres = value(I_P_AMB)
        self.dsg_weather.m_tdew = value(I_T_DP)
        self.dsg_htf_state_in.m_temp = value(I_T_PB_OUT)
        self.dsg_weather.m_solazi = value(I_SOLARAZ)
        self.dsg_weather.m_shift = value(I_SHIFT)
        self.dsg_weather.m_solzen = value(I_SOLARZEN)
        self.dsg_sim_info.m_tou = Int(value(I_TOUPERIOD))
        self.dsg_sim_info.ms_ts.m_time = time
        self.dsg_sim_info.ms_ts.m_step = step
        self.dsg_inputs.m_input_operation_mode = C_csp_collector_receiver.E_csp_cr_modes.ON
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.dsg_lf.call(self.dsg_weather,
                self.dsg_htf_state_in,
                self.dsg_inputs,
                self.dsg_out_solver,
                self.dsg_sim_info)
        except C_csp_exception as csp_exception:
            while self.dsg_lf.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    message(TCS_WARNING, out_msg)
            message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        var cycle_pl_control: Float64 = 2.0
        value(O_CYCLE_PL_CONTROL, cycle_pl_control)
        value(O_T_FIELD_OUT, self.dsg_out_solver.m_T_salt_hot)
        value(O_M_DOT_TO_PB, self.dsg_out_solver.m_m_dot_salt_tot)
        value(O_STANDBY_CONTROL, self.dsg_out_solver.m_standby_control)
        value(O_DP_SF_SH, self.dsg_out_solver.m_dP_sf_sh)
        value(O_W_DOT_PAR_TOT, self.dsg_out_solver.m_W_dot_col_tracking + self.dsg_out_solver.m_W_dot_htf_pump)
        value(O_DP_TOT, 0.0)
        value(O_DP_HDR_C, 0.0)
        value(O_DP_SF_BOIL, 0.0)
        value(O_DP_BOIL_TO_SH, 0.0)
        value(O_DP_HDR_H, 0.0)
        value(O_E_BAL_STARTUP, 0.0)
        value(O_E_FIELD, 0.0)
        value(O_E_FP_TOT, 0.0)
        value(O_ETA_OPT_AVE, 0.0)
        value(O_ETA_THERMAL, 0.0)
        value(O_ETA_SF, 0.0)
        value(O_DEFOCUS, 0.0)
        value(O_M_DOT_AUX, 0.0)
        value(O_M_DOT_FIELD, 0.0)
        value(O_M_DOT_B_TOT, 0.0)
        value(O_M_DOT, 0.0)
        value(O_P_TURB_IN, 0.0)
        value(O_Q_LOSS_PIPING, 0.0)
        value(O_Q_AUX_FLUID, 0.0)
        value(O_Q_AUX_FUEL, 0.0)
        value(O_Q_DUMP, 0.0)
        value(O_Q_FIELD_DELIVERED, 0.0)
        value(O_Q_INC_TOT, 0.0)
        value(O_Q_LOSS_REC, 0.0)
        value(O_Q_LOSS_SF, 0.0)
        value(O_Q_TO_PB, 0.0)
        value(O_SOLARALT, 0.0)
        value(O_SOLARAZ, 0.0)
        value(O_PHI_T, 0.0)
        value(O_THETA_L, 0.0)
        value(O_T_FIELD_IN, 0.0)
        value(O_T_LOOP_OUT, 0.0)
        value(O_T_PB_IN, 0.0)
        value(O_W_DOT_AUX, 0.0)
        value(O_W_DOT_BOP, 0.0)
        value(O_W_DOT_COL, 0.0)
        value(O_W_DOT_FIXED, 0.0)
        value(O_W_DOT_PUMP, 0.0)
        value(O_P_SF_IN, 0.0)
        return 0

    def converged(self, time: Float64) -> Int:
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.dsg_lf.converged()
        except C_csp_exception as csp_exception:
            while self.dsg_lf.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    message(TCS_WARNING, out_msg)
            message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.dsg_lf.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                message(TCS_WARNING, out_msg)
        return 0

TCS_IMPLEMENT_TYPE(sam_mw_lf_type261_steam, "Linear Fresnel Steam Receiver", "Ty Neises", 1, sam_mw_lf_type261_steam_variables, None, 1)