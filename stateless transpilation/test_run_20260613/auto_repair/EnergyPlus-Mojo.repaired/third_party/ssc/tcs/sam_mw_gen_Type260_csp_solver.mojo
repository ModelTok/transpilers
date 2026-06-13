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
from csp_solver_gen_collector_receiver import *
from csp_solver_pc_gen import *
from csp_solver_util import *
/*
************************************************************************
 Object: Generic solar model
 Simulation Studio Model: Type260
 Author: Michael J. Wagner
 Date:	 May 29, 2013
 COPYRIGHT 2013 NATIONAL RENEWABLE ENERGY LABORATORY
*/
enum{
	P_LATITUDE,
	P_LONGITUDE,
	P_TIMEZONE,
	P_THETA_STOW,
	P_THETA_DEP,
	P_INTERP_ARR,
	P_RAD_TYPE,
	P_SOLARM,
	P_T_SFDES,
	P_IRR_DES,
	P_ETA_OPT_SOIL,
	P_ETA_OPT_GEN,
	P_F_SFHL_REF,
	P_SFHLQ_COEFS,
	P_SFHLT_COEFS,
	P_SFHLV_COEFS,
	P_QSF_DES,
	P_W_DES,
	P_ETA_DES,
	P_F_WMAX,
	P_F_WMIN,
	P_F_STARTUP,
	P_ETA_LHV,
	P_ETAQ_COEFS,
	P_ETAT_COEFS,
	P_T_PCDES,
	P_PC_T_CORR,
	P_F_WPAR_FIXED,
	P_F_WPAR_PROD,
	P_WPAR_PRODQ_COEFS,
	P_WPAR_PRODT_COEFS,
	P_WPAR_PRODD_COEFS,
	P_HRS_TES,
	P_F_CHARGE,
	P_F_DISCH,
	P_F_ETES_0,
	P_F_TESHL_REF,
	P_TESHLX_COEFS,
	P_TESHLT_COEFS,
	P_NTOD,
	P_DISWS,
	P_DISWOS,
	P_QDISP,
	P_FDISP,
    P_ISTABLEUNSORTED,
	P_OPTICALTABLE,
    P_ADJUST,
    P_EXERGY_TABLE,
    P_STORAGE_CONFIG,
	I_IBN,
	I_IBH,
	I_ITOTH,
	I_TDB,
	I_TWB,
	I_VWIND,
	I_TOUPeriod,
	O_IRR_USED,
	O_HOUR_OF_DAY,
	O_DAY_OF_YEAR,
	O_DECLINATION,
	O_SOLTIME,
	O_HRANGLE,
	O_SOLALT,
	O_SOLAZ,
	O_ETA_OPT_SF,
	O_F_SFHL_QDNI,
	O_F_SFHL_TAMB,
	O_F_SFHL_VWIND,
	O_Q_HL_SF,
	O_Q_SF,
	O_Q_INC,
	O_PBMODE,
	O_PBSTARTF,
	O_Q_TO_PB,
	O_Q_STARTUP,
	O_Q_TO_TES,
	O_Q_FROM_TES,
	O_E_IN_TES,
	O_Q_HL_TES,
	O_Q_DUMP_TESFULL,
	O_Q_DUMP_TESCHG,
	O_Q_DUMP_UMIN,
	O_Q_DUMP_TOT,
	O_Q_FOSSIL,
	O_Q_GAS,
	O_F_EFFPC_QTPB,
	O_F_EFFPC_TAMB,
	O_ETA_CYCLE,
	O_W_GR_SOLAR,
	O_W_GR_FOSSIL,
	O_W_GR,
	O_W_PAR_FIXED,
	O_W_PAR_PROD,
	O_W_PAR_TOT,
	O_W_PAR_ONLINE,
	O_W_PAR_OFFLINE,
	O_ENET,
	N_MAX
};
var sam_mw_gen_type260_variables: StaticTuple[tcsvarinfo, N_MAX] = [
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_LATITUDE, "latitude", "Site latitude", "deg", "", "", "35"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_LONGITUDE, "longitude", "Site longitude", "deg", "", "", "-117"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TIMEZONE, "timezone", "Site timezone", "hr", "", "", "-8"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_THETA_STOW, "theta_stow", "Solar elevation angle at which the solar field stops operating", "deg", "", "", "170"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_THETA_DEP, "theta_dep", "Solar elevation angle at which the solar field begins operating", "deg", "", "", "10"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_INTERP_ARR, "interp_arr", "Interpolate the array or find nearest neighbor? (1=interp,2=no)", "none", "", "", "1"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_RAD_TYPE, "rad_type", "Solar resource radiation type (1=DNI,2=horiz.beam,3=tot.horiz)", "none", "", "", "1"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_SOLARM, "solarm", "Solar multiple", "none", "", "", "2"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_SFDES, "T_sfdes", "Solar field design point temperature (dry bulb)", "C", "", "", "25"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_IRR_DES, "irr_des", "Irradiation design point", "W/m2", "", "", "950"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_OPT_SOIL, "eta_opt_soil", "Soiling optical derate factor", "none", "", "", "0.95"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_OPT_GEN, "eta_opt_gen", "General/other optical derate", "none", "", "", "0.99"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_SFHL_REF, "f_sfhl_ref", "Reference solar field thermal loss fraction", "MW/MWcap", "", "", "0.071591"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_SFHLQ_COEFS, "sfhlQ_coefs", "Irr-based solar field thermal loss adjustment coefficients", "1/MWt", "", "", "1,-0.1,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_SFHLT_COEFS, "sfhlT_coefs", "Temp.-based solar field thermal loss adjustment coefficients", "1/C", "", "", "1,0.005,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_SFHLV_COEFS, "sfhlV_coefs", "Wind-based solar field thermal loss adjustment coefficients", "1/(m/s)", "", "", "1,0.01,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_QSF_DES, "qsf_des", "Solar field thermal production at design", "MWt", "", "", "628"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_W_DES, "w_des", "Design power cycle gross output", "MWe", "", "", "110"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_DES, "eta_des", "Design power cycle gross efficiency", "none", "", "", "0.35"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_WMAX, "f_wmax", "Maximum over-design power cycle operation fraction", "none", "", "", "1.05"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_WMIN, "f_wmin", "Minimum part-load power cycle operation fraction", "none", "", "", "0.25"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_STARTUP, "f_startup", "Equivalent full-load hours required for power system startup", "hours", "", "", "0.2"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_LHV, "eta_lhv", "Fossil backup lower heating value efficiency", "none", "", "", "0.9"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_ETAQ_COEFS, "etaQ_coefs", "Part-load power conversion efficiency adjustment coefficients", "1/MWt", "", "", "0.9,0.1,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_ETAT_COEFS, "etaT_coefs", "Temp.-based power conversion efficiency adjustment coefs.", "1/C", "", "", "1,-0.002,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_PCDES, "T_pcdes", "Power conversion reference temperature", "C", "", "", "21"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PC_T_CORR, "PC_T_corr", "Power conversion temperature correction mode (1=wetb, 2=dryb)", "none", "", "", "1"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_WPAR_FIXED, "f_Wpar_fixed", "Fixed capacity-based parasitic loss fraction", "MWe/MWcap", "", "", "0.0055"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_WPAR_PROD, "f_Wpar_prod", "Production-based parasitic loss fraction", "MWe/MWe", "", "", "0.08"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_WPAR_PRODQ_COEFS, "Wpar_prodQ_coefs", "Part-load production parasitic adjustment coefs.", "1/MWe", "", "", "1,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_WPAR_PRODT_COEFS, "Wpar_prodT_coefs", "Temp.-based production parasitic adjustment coefs.", "1/C", "", "", "0,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_WPAR_PRODD_COEFS, "Wpar_prodD_coefs", "DNI-based production parasitic adjustment coefs.", "m2/W", "", "", "0,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_HRS_TES, "hrs_tes", "Equivalent full-load hours of storage", "hours", "", "", "6"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_CHARGE, "f_charge", "Storage charging energy derate", "none", "", "", "0.98"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_DISCH, "f_disch", "Storage discharging energy derate", "none", "", "", "0.98"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_ETES_0, "f_etes_0", "Initial fractional charge level of thermal storage (0..1)", "none", "", "", "0.1"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_F_TESHL_REF, "f_teshl_ref", "Reference heat loss from storage per max stored capacity", "kWt/MWhr-stored", "", "", "0.35"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_TESHLX_COEFS, "teshlX_coefs", "Charge-based thermal loss adjustment - constant coef.", "1/MWhr-stored", "", "", "1,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_TESHLT_COEFS, "teshlT_coefs", "Temp.-based thermal loss adjustment - constant coef.", "1/C", "", "", "1,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_NTOD, "ntod", "Number of time-of-dispatch periods in the dispatch schedule", "none", "", "", "9"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_DISWS, "disws", "Time-of-dispatch control for with-solar conditions", "none", "", "", "0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_DISWOS, "diswos", "Time-of-dispatch control for without-solar conditions", "none", "", "", "0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_QDISP, "qdisp", "TOD power output control factors", "none", "", "", "1,1,1,1,1,1,1,1,1"),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_FDISP, "fdisp", "Fossil backup output control factors", "none", "", "", "0,0,0,0,0,0,0,0,0"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ISTABLEUNSORTED, "istableunsorted", "Is optical table unsorted? (1=yes, 0=no)", "none", "", "", "0"),
	tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_OPTICALTABLE, "OpticalTable", "Optical table", "none", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_ADJUST, "sf_adjust", "Time series solar field production adjustment", "none", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_EXERGY_TABLE, "exergy_table", "Exergy penalty as a function of TES charge state", "none", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_STORAGE_CONFIG, "storage_config", "Thermal energy storage configuration", "none", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_IBN, "ibn", "Beam-normal (DNI) irradiation", "W/m2", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_IBH, "ibh", "Beam-horizontal irradiation", "W/m2", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_ITOTH, "itoth", "Total horizontal irradiation", "W/m2", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TDB, "tdb", "Ambient dry-bulb temperature", "C", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TWB, "twb", "Ambient wet-bulb temperature", "C", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_VWIND, "vwind", "Wind velocity", "m/s", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TOUPeriod, "TOUPeriod", "The time-of-use period", "", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_IRR_USED, "irr_used", "Irradiation value used in simulation", "W/m2", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_HOUR_OF_DAY, "hour_of_day", "Hour of the day", "hour", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DAY_OF_YEAR, "day_of_year", "Day of the year", "day", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DECLINATION, "declination", "Declination angle", "deg", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLTIME, "soltime", "[hour] Solar time of the day", "hour", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_HRANGLE, "hrangle", "Hour angle", "deg", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLALT, "solalt", "Solar elevation angle", "deg", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLAZ, "solaz", "Solar azimuth angle (-180..180, 0deg=South)", "deg", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_OPT_SF, "eta_opt_sf", "Solar field optical efficiency", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_F_SFHL_QDNI, "f_sfhl_qdni", "Solar field load-based thermal loss correction", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_F_SFHL_TAMB, "f_sfhl_tamb", "Solar field temp.-based thermal loss correction", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_F_SFHL_VWIND, "f_sfhl_vwind", "Solar field wind-based thermal loss correction", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_HL_SF, "q_hl_sf", "Solar field thermal losses", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_SF, "q_sf", "Solar field delivered thermal power", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_INC, "q_inc", "Qdni - Solar incident energy, before all losses", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_PBMODE, "pbmode", "Power conversion mode", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_PBSTARTF, "pbstartf", "Flag indicating power system startup", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_TO_PB, "q_to_pb", "Thermal energy to the power conversion system", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_STARTUP, "q_startup", "Power conversion startup energy", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_TO_TES, "q_to_tes", "Thermal energy into storage", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_FROM_TES, "q_from_tes", "Thermal energy from storage", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_E_IN_TES, "e_in_tes", "Energy in storage", "MWt-hr", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_HL_TES, "q_hl_tes", "Thermal losses from storage", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_DUMP_TESFULL, "q_dump_tesfull", "Dumped energy  exceeding storage charge level max", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_DUMP_TESCHG, "q_dump_teschg", "Dumped energy exceeding exceeding storage charge rate", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_DUMP_UMIN, "q_dump_umin", "Dumped energy from falling below min. operation fraction", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_DUMP_TOT, "q_dump_tot", "Total dumped energy", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_FOSSIL, "q_fossil", "thermal energy supplied from aux firing", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_GAS, "q_gas", "Energy content of fuel required to supply Qfos", "MWt", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_F_EFFPC_QTPB, "f_effpc_qtpb", "Load-based conversion efficiency correction", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_F_EFFPC_TAMB, "f_effpc_tamb", "Temp-based conversion efficiency correction", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_CYCLE, "eta_cycle", "Adjusted power conversion efficiency", "none", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_GR_SOLAR, "w_gr_solar", "Power produced from the solar component", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_GR_FOSSIL, "w_gr_fossil", "Power produced from the fossil component", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_GR, "w_gr", "Total gross power production", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_PAR_FIXED, "w_par_fixed", "Fixed parasitic losses", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_PAR_PROD, "w_par_prod", "Production-based parasitic losses", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_PAR_TOT, "w_par_tot", "Total parasitic losses", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_PAR_ONLINE, "w_par_online", "Online parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_PAR_OFFLINE, "w_par_offline", "Offline parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ENET, "enet", "Net electric output", "MWe", "", "", ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
]
var zen_scale: Float64 = 1.570781477
var az_scale: Float64 = 6.283125908
class sam_mw_gen_type260(tcstypeinterface):
    var mc_gen_cr: C_csp_gen_collector_receiver
    var mp_params: Pointer[C_csp_gen_collector_receiver.S_params]
    var mc_cr_des_solved: C_csp_collector_receiver.S_csp_cr_solved_params
    var mc_gen_pc: C_pc_gen
    var mp_pc_params: Pointer[C_pc_gen.S_params]
    var mc_pc_des_solved: C_pc_gen.S_solved_params
    var pi: Float64
    var Pi: Float64
    var d2r: Float64
    var r2d: Float64
    var g: Float64
    var mtoinch: Float64
    var eta_lhv: Float64
    var T_pcdes: Float64
    var PC_T_corr: Int
    var f_Wpar_fixed: Float64
    var f_Wpar_prod: Float64
    var Wpar_prodQ_coefs: Pointer[Float64]
    var nval_Wpar_prodQ_coefs: Int
    var Wpar_prodT_coefs: Pointer[Float64]
    var nval_Wpar_prodT_coefs: Int
    var Wpar_prodD_coefs: Pointer[Float64]
    var nval_Wpar_prodD_coefs: Int
    var hrs_tes: Float64
    var f_charge: Float64
    var f_disch: Float64
    var f_etes_0: Float64
    var f_teshl_ref: Float64
    var teshlX_coefs: Pointer[Float64]
    var nval_teshlX_coefs: Int
    var teshlT_coefs: Pointer[Float64]
    var nval_teshlT_coefs: Int
    var ntod: Int
    var storage_config: Int
    var nval_tod_sched: Int
    var disws: Pointer[Float64]
    var nval_disws: Int
    var diswos: Pointer[Float64]
    var nval_diswos: Int
    var qdisp: Pointer[Float64]
    var nval_qdisp: Int
    var fdisp: Pointer[Float64]
    var nval_fdisp: Int
    var sf_adjust: Pointer[Float64]
    var nval_sf_adjust: Int
    var exergy_table_in: Pointer[Float64]
    var nrow_exergy_table: Int
    var ncol_exergy_table: Int
    var exergy_table_T: util.matrix_t[Float64]
    var pbmode: Int
    var m_q_des: Float64
    var m_qttmin: Float64
    var m_qttmax: Float64
    var m_q_startup: Float64
    var m_e_in_tes: Float64
    var m_q_startup_used: Float64
    var m_q_startup_remain: Float64
    var dt: Float64
    var etesmax: Float64
    var ptsmax: Float64
    var pfsmax: Float64
    var etes0: Float64
    var pbmode0: Int
    var is_sf_init: Bool
    var p_q_dot_field_inc: Pointer[Float64]
    var p_eta_field: Pointer[Float64]
    var p_q_dot_rec_inc: Pointer[Float64]
    var p_eta_thermal: Pointer[Float64]
    var p_pc_eta_thermal: Pointer[Float64]

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.p_q_dot_field_inc = Pointer[Float64].alloc(8760)
        self.mc_gen_cr.mc_reported_outputs.assign(C_csp_gen_collector_receiver.E_Q_DOT_FIELD_INC, self.p_q_dot_field_inc, 8760)
        self.p_eta_field = Pointer[Float64].alloc(8760)
        self.mc_gen_cr.mc_reported_outputs.assign(C_csp_gen_collector_receiver.E_ETA_FIELD, self.p_eta_field, 8760)
        self.p_q_dot_rec_inc = Pointer[Float64].alloc(8760)
        self.mc_gen_cr.mc_reported_outputs.assign(C_csp_gen_collector_receiver.E_Q_DOT_REC_INC, self.p_q_dot_rec_inc, 8760)
        self.p_eta_thermal = Pointer[Float64].alloc(8760)
        self.mc_gen_cr.mc_reported_outputs.assign(C_csp_gen_collector_receiver.E_ETA_THERMAL, self.p_eta_thermal, 8760)
        self.p_pc_eta_thermal = Pointer[Float64].alloc(8760)
        self.mc_gen_pc.mc_reported_outputs.assign(C_pc_gen.E_ETA_THERMAL, self.p_pc_eta_thermal, 8760)
        self.Pi = acos(-1.)
        self.pi = self.Pi
        self.r2d = 180. / self.pi
        self.d2r = self.pi / 180.
        self.g = 9.81
        self.mtoinch = 39.3700787
        self.mp_params = self.mc_gen_cr.ms_params.ptr()
        self.mp_pc_params = self.mc_gen_pc.ms_params.ptr()
        self.is_sf_init = False
        self.eta_lhv = Float64.NaN
        self.PC_T_corr = -1
        self.T_pcdes = Float64.NaN
        self.f_Wpar_fixed = Float64.NaN
        self.f_Wpar_prod = Float64.NaN
        self.Wpar_prodQ_coefs = Pointer[Float64]()
        self.nval_Wpar_prodQ_coefs = -1
        self.Wpar_prodT_coefs = Pointer[Float64]()
        self.nval_Wpar_prodT_coefs = -1
        self.Wpar_prodD_coefs = Pointer[Float64]()
        self.nval_Wpar_prodD_coefs = -1
        self.hrs_tes = Float64.NaN
        self.f_charge = Float64.NaN
        self.f_disch = Float64.NaN
        self.f_etes_0 = Float64.NaN
        self.f_teshl_ref = Float64.NaN
        self.teshlX_coefs = Pointer[Float64]()
        self.nval_teshlX_coefs = -1
        self.teshlT_coefs = Pointer[Float64]()
        self.nval_teshlT_coefs = -1
        self.ntod = -1
        self.storage_config = -1
        self.nval_tod_sched = -1
        self.disws = Pointer[Float64]()
        self.nval_disws = -1
        self.diswos = Pointer[Float64]()
        self.nval_diswos = -1
        self.qdisp = Pointer[Float64]()
        self.nval_qdisp = -1
        self.fdisp = Pointer[Float64]()
        self.nval_fdisp = -1
        self.sf_adjust = Pointer[Float64]()
        self.nval_sf_adjust = -1
        self.exergy_table_in = Pointer[Float64]()
        self.nrow_exergy_table = -1
        self.ncol_exergy_table = -1
        self.pbmode = -1
        self.m_q_des = Float64.NaN
        self.m_qttmin = Float64.NaN
        self.m_qttmax = Float64.NaN
        self.m_q_startup = Float64.NaN
        self.m_e_in_tes = Float64.NaN

    def __del__(owned self):
        del self.p_q_dot_field_inc
        del self.p_eta_field
        del self.p_q_dot_rec_inc
        del self.p_eta_thermal

    def init(inout self) -> Int:
        self.mp_params.m_latitude = self.value(P_LATITUDE)
        self.mp_params.m_longitude = self.value(P_LONGITUDE)
        self.mp_params.m_theta_stow = self.value(P_THETA_STOW)
        self.mp_params.m_theta_dep = self.value(P_THETA_DEP)
        self.mp_params.m_interp_arr = Int(self.value(P_INTERP_ARR))
        self.mp_params.m_rad_type = Int(self.value(P_RAD_TYPE))
        self.mp_params.m_solarm = self.value(P_SOLARM)
        self.mp_params.m_T_sfdes = self.value(P_T_SFDES)
        self.mp_params.m_irr_des = self.value(P_IRR_DES)
        self.mp_params.m_eta_opt_soil = self.value(P_ETA_OPT_SOIL)
        self.mp_params.m_eta_opt_gen = self.value(P_ETA_OPT_GEN)
        self.mp_params.m_f_sfhl_ref = self.value(P_F_SFHL_REF)
        self.mp_params.m_qsf_des = self.value(P_QSF_DES)
        self.mp_params.m_is_table_unsorted = self.value(P_ISTABLEUNSORTED) == 1.0
        var n_sfhlQ_coefs: Int = 0
        var pt_sfhlQ_coefs = self.value(P_SFHLQ_COEFS, n_sfhlQ_coefs)
        self.mp_params.mv_sfhlQ_coefs.resize(n_sfhlQ_coefs)
        for i in range(n_sfhlQ_coefs):
            self.mp_params.mv_sfhlQ_coefs[i] = pt_sfhlQ_coefs[i]
        var n_sfhlT_coefs: Int = 0
        var pt_sfhlT_coefs = self.value(P_SFHLT_COEFS, n_sfhlT_coefs)
        self.mp_params.mv_sfhlT_coefs.resize(n_sfhlT_coefs)
        for i in range(n_sfhlT_coefs):
            self.mp_params.mv_sfhlT_coefs[i] = pt_sfhlT_coefs[i]
        var n_sfhlV_coefs: Int = 0
        var pt_sfhlV_coefs = self.value(P_SFHLV_COEFS, n_sfhlV_coefs)
        self.mp_params.mv_sfhlV_coefs.resize(n_sfhlV_coefs)
        for i in range(n_sfhlV_coefs):
            self.mp_params.mv_sfhlV_coefs[i] = pt_sfhlV_coefs[i]
        var n_row_opt_table: Int = 0
        var n_col_opt_table: Int = 0
        var pt_opt_table_in = self.value(P_OPTICALTABLE, n_row_opt_table, n_col_opt_table)
        self.mp_params.m_optical_table.assign(pt_opt_table_in, n_row_opt_table, n_col_opt_table)
        self.mp_pc_params.m_W_dot_des = self.value(P_W_DES)
        self.mp_pc_params.m_eta_des = self.value(P_ETA_DES)
        self.mp_pc_params.m_f_wmax = self.value(P_F_WMAX)
        self.mp_pc_params.m_f_wmin = self.value(P_F_WMIN)
        self.mp_pc_params.m_f_startup = self.value(P_F_STARTUP)
        self.mp_pc_params.m_T_pc_des = self.value(P_T_PCDES)
        self.mp_pc_params.m_PC_T_corr = Int(self.value(P_PC_T_CORR))
        var n_etaQ_coefs: Int = 0
        var pt_etaQ_coefs = self.value(P_ETAQ_COEFS, n_etaQ_coefs)
        self.mp_pc_params.mv_etaQ_coefs.resize(n_etaQ_coefs)
        for i in range(n_etaQ_coefs):
            self.mp_pc_params.mv_etaQ_coefs[i] = pt_etaQ_coefs[i]
        var n_etaT_coefs: Int = 0
        var pt_etaT_coefs = self.value(P_ETAT_COEFS, n_etaT_coefs)
        self.mp_pc_params.mv_etaT_coefs.resize(n_etaT_coefs)
        for i in range(n_etaT_coefs):
            self.mp_pc_params.mv_etaT_coefs[i] = pt_etaT_coefs[i]
        self.dt = self.time_step() / 3600.0
        self.eta_lhv = self.value(P_ETA_LHV)
        self.PC_T_corr = Int(self.value(P_PC_T_CORR))
        self.T_pcdes = self.value(P_T_PCDES) + 273.15
        self.f_Wpar_fixed = self.value(P_F_WPAR_FIXED)
        self.f_Wpar_prod = self.value(P_F_WPAR_PROD)
        self.Wpar_prodQ_coefs = self.value(P_WPAR_PRODQ_COEFS, self.nval_Wpar_prodQ_coefs)
        self.Wpar_prodT_coefs = self.value(P_WPAR_PRODT_COEFS, self.nval_Wpar_prodT_coefs)
        self.Wpar_prodD_coefs = self.value(P_WPAR_PRODD_COEFS, self.nval_Wpar_prodD_coefs)
        self.hrs_tes = self.value(P_HRS_TES)
        self.f_charge = self.value(P_F_CHARGE)
        self.f_disch = self.value(P_F_DISCH)
        self.f_etes_0 = self.value(P_F_ETES_0)
        self.f_teshl_ref = self.value(P_F_TESHL_REF)
        self.teshlX_coefs = self.value(P_TESHLX_COEFS, self.nval_teshlX_coefs)
        self.teshlT_coefs = self.value(P_TESHLT_COEFS, self.nval_teshlT_coefs)
        self.ntod = Int(self.value(P_NTOD))
        self.storage_config = Int(self.value(P_STORAGE_CONFIG))
        self.disws = self.value(P_DISWS, self.nval_disws)
        self.diswos = self.value(P_DISWOS, self.nval_diswos)
        self.qdisp = self.value(P_QDISP, self.nval_qdisp)
        self.fdisp = self.value(P_FDISP, self.nval_fdisp)
        self.sf_adjust = self.value(P_ADJUST, self.nval_sf_adjust)
        self.exergy_table_in = self.value(P_EXERGY_TABLE, self.nrow_exergy_table, self.ncol_exergy_table)
        self.exergy_table_T.resize(2, self.nrow_exergy_table)
        for i in range(2):
            for j in range(self.nrow_exergy_table):
                self.exergy_table_T.at(i, j) = TCS_MATRIX_INDEX(self.var(P_EXERGY_TABLE), j, i)
        self.mp_params.m_latitude = self.value(P_LATITUDE)
        self.mp_params.m_longitude = self.value(P_LONGITUDE)
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            var init_inputs: C_csp_collector_receiver.S_csp_cr_init_inputs
            self.mc_gen_cr.init(init_inputs, self.mc_cr_des_solved)
            self.mc_gen_pc.init(self.mc_pc_des_solved)
        except C_csp_exception as csp_exception:
            while self.mc_gen_cr.mc_csp_messages.get_message(out_type, out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_gen_cr.mc_csp_messages.get_message(out_type, out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        self.m_q_des = self.mc_pc_des_solved.m_q_dot_des
        self.m_qttmin = self.m_q_des * self.mc_pc_des_solved.m_cutoff_frac
        self.m_qttmax = self.m_q_des * self.mc_pc_des_solved.m_max_frac
        self.m_q_startup = self.mc_pc_des_solved.m_q_startup
        self.f_teshl_ref *= 0.001
        self.etesmax = self.hrs_tes * self.m_q_des
        for i in range(self.ntod):
            self.disws[i] *= self.etesmax
            self.diswos[i] *= self.etesmax
            self.qdisp[i] *= self.m_q_des
            self.fdisp[i] *= self.m_q_des
        self.ptsmax = self.m_q_des * self.mp_params.m_solarm
        self.pfsmax = self.ptsmax / self.f_disch * self.mc_pc_des_solved.m_max_frac
        self.etes0 = self.f_etes_0 * self.etesmax
        self.pbmode0 = 0
        self.m_q_startup_remain = self.mc_pc_des_solved.m_q_startup
        return 1

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        var ibn: Float64 = self.value(I_IBN)
        var ibh: Float64 = self.value(I_IBH)
        var itoth: Float64 = self.value(I_ITOTH)
        var tdb: Float64 = self.value(I_TDB)
        var twb: Float64 = self.value(I_TWB)
        var vwind: Float64 = self.value(I_VWIND)
        var longitude: Float64 = self.value(P_LONGITUDE) * self.d2r
        var timezone: Float64 = self.value(P_TIMEZONE)
        var shift: Float64 = longitude - timezone * 15.0 * self.d2r
        var touperiod: Int = Int(self.value(I_TOUPeriod)) - 1
        var weather: C_csp_weatherreader.S_outputs
        weather.m_beam = ibn
        weather.m_hor_beam = ibh
        weather.m_global = itoth
        weather.m_tdry = tdb
        weather.m_twet = twb
        weather.m_wspd = vwind
        weather.m_shift = shift / self.d2r
        tdb += 273.15
        twb += 273.15
        var cr_htf_state_in: C_csp_solver_htf_1state
        var cr_inputs: C_csp_collector_receiver.S_csp_cr_inputs
        var cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver
        var sim_info: C_csp_solver_sim_info
        cr_inputs.m_field_control = 1.0
        cr_inputs.m_input_operation_mode = C_csp_collector_receiver.ON
        cr_inputs.m_adjust = self.sf_adjust[Int(time / step)]
        sim_info.ms_ts.m_time = time
        sim_info.ms_ts.m_step = step
        sim_info.m_tou = touperiod
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.mc_gen_cr.call(weather, cr_htf_state_in, cr_inputs, cr_out_solver, sim_info)
        except C_csp_exception as csp_exception:
            while self.mc_gen_cr.mc_csp_messages.get_message(out_type, out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        var irr_used: Float64 = 0.0
        match self.mp_params.m_rad_type:
            case 1:
                irr_used = ibn
            case 2:
                irr_used = ibh
            case 3:
                irr_used = itoth
        var dispatch: util.matrix_t[Float64] = util.matrix_t[Float64](self.ntod)
        if irr_used > 0.0:
            for i in range(self.ntod):
                dispatch.at(i) = self.disws[i]
        else:
            for i in range(self.ntod):
                dispatch.at(i) = self.diswos[i]
        var eta_opt_sf: Float64 = self.mc_gen_cr.mc_reported_outputs.value(C_csp_gen_collector_receiver.E_ETA_FIELD)
        var q_sf: Float64 = cr_out_solver.m_q_thermal
        var q_to_tes: Float64 = 0.0
        var q_from_tes: Float64 = 0.0
        self.m_e_in_tes = 0.0
        var q_hl_tes: Float64 = 0.0
        var q_to_pb: Float64 = 0.0
        var q_dump_tesfull: Float64 = 0.0
        var q_dump_umin: Float64 = 0.0
        var q_dump_teschg: Float64 = 0.0
        var q_startup: Float64 = 0.0
        var pbstartf: Int = 0
        self.m_q_startup_used = self.m_q_startup_remain
        if self.hrs_tes <= 0.0:
            if (self.pbmode0 == 0) or (self.pbmode0 == 1):
                if q_sf > 0:
                    if q_sf > (self.m_q_startup_used / self.dt):
                        q_to_pb = q_sf - self.m_q_startup_used / self.dt
                        q_startup = self.m_q_startup_used / self.dt
                        self.pbmode = 2
                        pbstartf = 1
                        self.m_q_startup_used = 0.0
                    else:
                        q_to_pb = 0.0
                        self.m_q_startup_used = self.m_q_startup_remain - q_sf * self.dt
                        q_startup = q_sf
                        self.pbmode = 1
                        pbstartf = 0
                else:
                    self.m_q_startup_used = self.m_q_startup
                    self.pbmode = 0
                    pbstartf = 0
            else:
                if q_sf > 0:
                    q_to_pb = q_sf
                    self.pbmode = 2
                    pbstartf = 0
                else:
                    q_to_pb = 0.0
                    self.pbmode = 0
                    pbstartf = 0
                    self.m_q_startup_used = self.m_q_startup_remain
            if q_to_pb < self.m_qttmin:
                q_dump_umin = q_to_pb
                q_to_pb = 0.0
                self.pbmode = 0
            if q_to_pb > self.m_qttmax:
                q_dump_teschg = q_to_pb - self.m_qttmax
                q_to_pb = self.m_qttmax
        else:
            q_startup = 0.0
            pbstartf = 0
            q_dump_teschg = 0.0
            q_from_tes = 0.0
            if self.pbmode0 == 0:
                var EtesA: Float64 = max(0.0, self.etes0 - dispatch.at(touperiod))
                if (EtesA >= self.m_q_startup / self.dt) and (q_sf + max(EtesA - self.m_q_startup / self.dt, 0.0) >= self.qdisp[touperiod]):
                    self.pbmode = 1
                    q_startup = self.m_q_startup / self.dt
                    q_to_pb = self.qdisp[touperiod]
                    var q_to_cycle_total: Float64 = q_startup + q_to_pb
                    if q_sf > q_to_pb:
                        q_to_tes = q_sf - q_to_pb
                        q_from_tes = q_startup
                        if q_to_tes > self.ptsmax:
                            q_dump_teschg = q_to_tes - self.ptsmax
                            q_to_tes = self.ptsmax
                    else:
                        q_to_tes = 0.0
                        q_from_tes = q_startup + (1.0 - q_sf / q_to_pb) * min(self.pfsmax, self.m_q_des)
                        if q_from_tes > self.pfsmax:
                            q_from_tes = self.pfsmax
                        q_to_pb = q_sf + (1.0 - q_sf / q_to_pb) * min(self.pfsmax, self.m_q_des)
                    self.m_e_in_tes = self.etes0 - q_startup + (q_sf - q_to_pb) * self.dt
                    self.pbmode = 2
                    pbstartf = 1
                else:
                    q_to_tes = q_sf
                    q_from_tes = 0.0
                    self.m_e_in_tes = self.etes0 + q_to_tes * self.dt
                    q_to_pb = 0.0
            else:
                if (q_sf + max(0.0, self.etes0 - dispatch.at(touperiod)) / self.dt) > self.qdisp[touperiod]:
                    q_to_pb = self.qdisp[touperiod]
                    if q_sf > q_to_pb:
                        q_to_tes = q_sf - q_to_pb
                        q_from_tes = 0.0
                        if q_to_tes > self.ptsmax:
                            q_dump_teschg = q_to_tes - self.ptsmax
                            q_to_tes = self.ptsmax
                    else:
                        q_to_tes = 0.0
                        q_from_tes = (1.0 - q_sf / q_to_pb) * min(self.pfsmax, self.m_q_des)
                        if q_from_tes > self.pfsmax:
                            q_from_tes = min(self.pfsmax, self.m_q_des)
                        q_to_pb = q_from_tes + q_sf
                    self.m_e_in_tes = self.etes0 + (q_sf - q_to_pb - q_dump_teschg) * self.dt
                    if (self.m_e_in_tes > self.etesmax) and (q_to_pb < self.m_qttmax):
                        if (self.m_e_in_tes - self.etesmax) / self.dt < (self.m_qttmax - q_to_pb):
                            q_to_pb = q_to_pb + (self.m_e_in_tes - self.etesmax) / self.dt
                            self.m_e_in_tes = self.etesmax
                        else:
                            self.m_e_in_tes = self.m_e_in_tes - (self.m_qttmax - q_to_pb) * self.dt
                            q_to_pb = self.m_qttmax
                        q_to_tes = q_sf - q_to_pb
                else:
                    if (q_sf + max(0.0, self.etes0 - dispatch.at(touperiod)) * self.dt) > self.m_qttmin:
                        q_from_tes = max(0.0, self.etes0 - dispatch.at(touperiod)) * self.dt
                        q_to_pb = q_sf + q_from_tes
                        q_to_tes = 0.0
                        self.m_e_in_tes = self.etes0 - q_from_tes
                    else:
                        q_to_pb = 0.0
                        q_from_tes = 0.0
                        q_to_tes = q_sf
                        self.m_e_in_tes = self.etes0 + q_to_tes * self.dt
            if q_to_pb > 0:
                self.pbmode = 2
            else:
                self.pbmode = 0
            var f_EtesAve: Float64 = max((self.m_e_in_tes + self.etes0) / 2.0 / self.etesmax, 0.0)
            var f_teshlX: Float64 = 0.0
            var f_teshlT: Float64 = 0.0
            for i in range(self.nval_teshlX_coefs):
                f_teshlX += self.teshlX_coefs[i] * pow(f_EtesAve, i)
            for i in range(self.nval_teshlT_coefs):
                f_teshlT += self.teshlT_coefs[i] * pow(self.mp_params.m_T_sfdes - tdb, i)
            q_hl_tes = self.f_teshl_ref * self.etesmax * (f_teshlX + f_teshlT)
            self.m_e_in_tes = max(self.m_e_in_tes - q_hl_tes * self.dt, 0.0)
            if self.m_e_in_tes > self.etesmax:
                q_dump_tesfull = (self.m_e_in_tes - self.etesmax) / self.dt
                self.m_e_in_tes = self.etesmax
                q_to_tes = q_to_tes - q_dump_tesfull
            else:
                q_dump_tesfull = 0.0
            if q_to_pb < self.m_qttmin:
                q_dump_umin = q_to_pb
                q_to_pb = 0.0
                self.pbmode = 0
            else:
                q_dump_umin = 0.0
            self.pbmode0 = self.pbmode
        var q_fossil: Float64 = Float64.NaN
        var q_gas: Float64 = q_fossil
        if q_to_pb < self.fdisp[touperiod]:
            q_fossil = self.fdisp[touperiod] - q_to_pb
            q_gas = q_fossil / self.eta_lhv
        else:
            q_fossil = 0.0
            q_gas = 0.0
        q_to_pb = q_to_pb + q_fossil
        var T_htf_cold_fixed: Float64 = Float64.NaN
        var T_htf_hot_fixed: Float64 = Float64.NaN
        var cp_htf_fixed: Float64 = Float64.NaN
        self.mc_gen_pc.get_fixed_properties(T_htf_cold_fixed, T_htf_hot_fixed, cp_htf_fixed)
        var m_dot_htf: Float64 = q_to_pb * 1.0E3 / (cp_htf_fixed * (T_htf_hot_fixed - T_htf_cold_fixed)) * 3600.0
        var pc_htf_state_in: C_csp_solver_htf_1state
        pc_htf_state_in.m_temp = T_htf_hot_fixed - 273.15
        var pc_control_inputs: C_csp_power_cycle.S_control_inputs
        pc_control_inputs.m_m_dot = m_dot_htf
        var pc_out_solver: C_csp_power_cycle.S_csp_pc_out_solver
        self.mc_gen_pc.call(weather, pc_htf_state_in, pc_control_inputs, pc_out_solver, sim_info)
        var exergy_adj: Float64 = 1.0
        if self.exergy_table_T.ncols() > 1:
            exergy_adj = CSP.interp(self.exergy_table_T.at(0, 0).ptr(), self.exergy_table_T.at(1, 0).ptr(), self.m_e_in_tes / self.etesmax, 0, self.nrow_exergy_table - 1, (self.exergy_table_T.at(0, 1) > self.exergy_table_T.at(0, 0)))
        else:
            exergy_adj = self.exergy_table_T.at(1, 0)
        if self.storage_config == 1:
            var weight: Float64 = 0.0
            if q_to_pb > 0.0:
                weight = q_from_tes / q_to_pb
            exergy_adj = (1.0 - weight) + weight * exergy_adj
        var eta_cycle_raw: Float64 = self.mc_gen_pc.mc_reported_outputs.value(C_pc_gen.E_ETA_THERMAL)
        var eta_cycle: Float64 = (eta_cycle_raw / self.mp_pc_params.m_eta_des + exergy_adj - 1.0) * self.mp_pc_params.m_eta_des
        var w_gr: Float64
        if eta_cycle > 0.0:
            w_gr = pc_out_solver.m_P_cycle / eta_cycle_raw * eta_cycle
        else:
            w_gr = 0.0
            eta_cycle = 0.0
        var w_gr_solar: Float64 = (q_to_pb - q_fossil) * eta_cycle
        var w_par_fixed: Float64 = self.f_Wpar_fixed * self.mc_pc_des_solved.m_W_dot_des
        var qnorm: Float64 = pc_out_solver.m_q_dot_htf / self.m_q_des
        var wpar_prodq: Float64 = 0.0
        var wpar_prodt: Float64 = 0.0
        var wpar_prodd: Float64 = 0.0
        for i in range(self.nval_Wpar_prodQ_coefs):
            wpar_prodq += self.Wpar_prodQ_coefs[i] * pow(qnorm, i)
        var tnorm: Float64 = Float64.NaN
        if self.PC_T_corr == 1:
            tnorm = twb - self.T_pcdes
        else:
            tnorm = tdb - self.T_pcdes
        for i in range(self.nval_Wpar_prodT_coefs):
            wpar_prodt += self.Wpar_prodT_coefs[i] * pow(tnorm, i)
        var dnorm: Float64 = irr_used / self.mp_params.m_irr_des
        for i in range(self.nval_Wpar_prodD_coefs):
            wpar_prodd += self.Wpar_prodD_coefs[i] * pow(dnorm, i)
        var wpar_adj: Float64 = (wpar_prodq + wpar_prodt + wpar_prodd)
        if wpar_adj < 0.0:
            wpar_adj = 0.0
        var w_par_prod: Float64 = self.f_Wpar_prod * w_gr * wpar_adj
        var w_par_tot: Float64 = w_par_fixed + w_par_prod
        var w_par_online: Float64 = Float64.NaN
        var w_par_offline: Float64 = Float64.NaN
        if w_gr > 0.0:
            w_par_online = w_par_tot
            w_par_offline = 0.0
        else:
            w_par_online = 0.0
            w_par_offline = w_par_tot
        var enet: Float64 = w_gr - w_par_tot
        var q_inc: Float64 = self.mc_gen_cr.mc_reported_outputs.value(C_csp_gen_collector_receiver.E_Q_DOT_FIELD_INC)
        var q_rec_inc: Float64 = self.mc_gen_cr.mc_reported_outputs.value(C_csp_gen_collector_receiver.E_Q_DOT_REC_INC)
        var q_dump_tot: Float64 = q_dump_tesfull + q_dump_teschg + q_dump_umin
        var w_gr_fossil: Float64 = w_gr - w_gr_solar
        var f_sfhl_qdni: Float64 = self.mc_gen_cr.mc_reported_outputs.value(C_csp_gen_collector_receiver.E_F_SFHL_QDNI)
        var f_sfhl_tamb: Float64 = self.mc_gen_cr.mc_reported_outputs.value(C_csp_gen_collector_receiver.E_F_SFHL_QTDRY)
        var f_sfhl_vwind: Float64 = self.mc_gen_cr.mc_reported_outputs.value(C_csp_gen_collector_receiver.E_F_SFHL_QWSPD)
        self.value(O_IRR_USED, irr_used)
        self.value(O_ETA_OPT_SF, eta_opt_sf)
        self.value(O_F_SFHL_QDNI, f_sfhl_qdni)
        self.value(O_F_SFHL_TAMB, f_sfhl_tamb)
        self.value(O_F_SFHL_VWIND, f_sfhl_vwind)
        self.value(O_Q_HL_SF, q_sf > 0.0 ? q_rec_inc - cr_out_solver.m_q_thermal : 0.0)
        self.value(O_Q_SF, q_sf)
        self.value(O_Q_INC, q_inc)
        self.value(O_PBMODE, self.pbmode)
        self.value(O_PBSTARTF, pbstartf)
        self.value(O_Q_TO_PB, q_to_pb)
        self.value(O_Q_STARTUP, q_startup)
        self.value(O_Q_TO_TES, q_to_tes)
        self.value(O_Q_FROM_TES, q_from_tes)
        self.value(O_E_IN_TES, self.m_e_in_tes)
        self.value(O_Q_HL_TES, q_hl_tes)
        self.value(O_Q_DUMP_TESFULL, q_dump_tesfull)
        self.value(O_Q_DUMP_TESCHG, q_dump_teschg)
        self.value(O_Q_DUMP_UMIN, q_dump_umin)
        self.value(O_Q_DUMP_TOT, q_dump_tot)
        self.value(O_Q_FOSSIL, q_fossil)
        self.value(O_Q_GAS, q_gas)
        self.value(O_ETA_CYCLE, eta_cycle)
        self.value(O_W_GR_SOLAR, w_gr_solar)
        self.value(O_W_GR_FOSSIL, w_gr_fossil)
        self.value(O_W_GR, w_gr)
        self.value(O_W_PAR_FIXED, w_par_fixed)
        self.value(O_W_PAR_PROD, w_par_prod)
        self.value(O_W_PAR_TOT, w_par_tot)
        self.value(O_W_PAR_ONLINE, w_par_online)
        self.value(O_W_PAR_OFFLINE, w_par_offline)
        self.value(O_ENET, enet)
        return 0

    def converged(inout self, time: Float64) -> Int:
        self.etes0 = self.m_e_in_tes
        self.pbmode0 = self.pbmode
        self.m_q_startup_remain = self.m_q_startup_used
        return 0

TCS_IMPLEMENT_TYPE(sam_mw_gen_type260, "Generic Solar Model", "Mike Wagner", 1, sam_mw_gen_type260_variables, NULL, 1)