from python import Python
from math import acos, asin, atan, cos, sin, tan, sqrt, fabs, fmod, ceil, floor, pow, pi as math_pi
from memory import memset, memcpy
from sys import info as sys_info
from tcstype import *
from sam_csp_util import *
from util import *

# Constants
const zen_scale: Float64 = 1.570781477
const az_scale: Float64 = 6.283125908

# Enums
enum P_LATITUDE: Int32 = 0
enum P_LONGITUDE: Int32 = 1
enum P_TIMEZONE: Int32 = 2
enum P_THETA_STOW: Int32 = 3
enum P_THETA_DEP: Int32 = 4
enum P_INTERP_ARR: Int32 = 5
enum P_RAD_TYPE: Int32 = 6
enum P_SOLARM: Int32 = 7
enum P_T_SFDES: Int32 = 8
enum P_IRR_DES: Int32 = 9
enum P_ETA_OPT_SOIL: Int32 = 10
enum P_ETA_OPT_GEN: Int32 = 11
enum P_F_SFHL_REF: Int32 = 12
enum P_SFHLQ_COEFS: Int32 = 13
enum P_SFHLT_COEFS: Int32 = 14
enum P_SFHLV_COEFS: Int32 = 15
enum P_QSF_DES: Int32 = 16
enum P_W_DES: Int32 = 17
enum P_ETA_DES: Int32 = 18
enum P_F_WMAX: Int32 = 19
enum P_F_WMIN: Int32 = 20
enum P_F_STARTUP: Int32 = 21
enum P_ETA_LHV: Int32 = 22
enum P_ETAQ_COEFS: Int32 = 23
enum P_ETAT_COEFS: Int32 = 24
enum P_T_PCDES: Int32 = 25
enum P_PC_T_CORR: Int32 = 26
enum P_F_WPAR_FIXED: Int32 = 27
enum P_F_WPAR_PROD: Int32 = 28
enum P_WPAR_PRODQ_COEFS: Int32 = 29
enum P_WPAR_PRODT_COEFS: Int32 = 30
enum P_HRS_TES: Int32 = 31
enum P_F_CHARGE: Int32 = 32
enum P_F_DISCH: Int32 = 33
enum P_F_ETES_0: Int32 = 34
enum P_F_TESHL_REF: Int32 = 35
enum P_TESHLX_COEFS: Int32 = 36
enum P_TESHLT_COEFS: Int32 = 37
enum P_NTOD: Int32 = 38
enum P_DISWS: Int32 = 39
enum P_DISWOS: Int32 = 40
enum P_QDISP: Int32 = 41
enum P_FDISP: Int32 = 42
enum P_ISTABLEUNSORTED: Int32 = 43
enum P_OPTICALTABLE: Int32 = 44
enum I_IBN: Int32 = 45
enum I_IBH: Int32 = 46
enum I_ITOTH: Int32 = 47
enum I_TDB: Int32 = 48
enum I_TWB: Int32 = 49
enum I_VWIND: Int32 = 50
enum I_TOUPeriod: Int32 = 51
enum O_IRR_USED: Int32 = 52
enum O_HOUR_OF_DAY: Int32 = 53
enum O_DAY_OF_YEAR: Int32 = 54
enum O_DECLINATION: Int32 = 55
enum O_SOLTIME: Int32 = 56
enum O_HRANGLE: Int32 = 57
enum O_SOLALT: Int32 = 58
enum O_SOLAZ: Int32 = 59
enum O_ETA_OPT_SF: Int32 = 60
enum O_F_SFHL_QDNI: Int32 = 61
enum O_F_SFHL_TAMB: Int32 = 62
enum O_F_SFHL_VWIND: Int32 = 63
enum O_Q_HL_SF: Int32 = 64
enum O_Q_SF: Int32 = 65
enum O_Q_INC: Int32 = 66
enum O_PBMODE: Int32 = 67
enum O_PBSTARTF: Int32 = 68
enum O_Q_TO_PB: Int32 = 69
enum O_Q_STARTUP: Int32 = 70
enum O_Q_TO_TES: Int32 = 71
enum O_Q_FROM_TES: Int32 = 72
enum O_E_IN_TES: Int32 = 73
enum O_Q_HL_TES: Int32 = 74
enum O_Q_DUMP_TESFULL: Int32 = 75
enum O_Q_DUMP_TESCHG: Int32 = 76
enum O_Q_DUMP_UMIN: Int32 = 77
enum O_Q_DUMP_TOT: Int32 = 78
enum O_Q_FOSSIL: Int32 = 79
enum O_Q_GAS: Int32 = 80
enum O_F_EFFPC_QTPB: Int32 = 81
enum O_F_EFFPC_TAMB: Int32 = 82
enum O_ETA_CYCLE: Int32 = 83
enum O_W_GR_SOLAR: Int32 = 84
enum O_W_GR_FOSSIL: Int32 = 85
enum O_W_GR: Int32 = 86
enum O_W_PAR_FIXED: Int32 = 87
enum O_W_PAR_PROD: Int32 = 88
enum O_W_PAR_TOT: Int32 = 89
enum O_W_PAR_ONLINE: Int32 = 90
enum O_W_PAR_OFFLINE: Int32 = 91
enum O_ENET: Int32 = 92
enum N_MAX: Int32 = 93

# Variable info array (simplified - would need proper TCS integration)
var sam_mw_gen_type260_variables: List[tcsvarinfo] = List[tcsvarinfo]()

@value
struct sam_mw_gen_type260(tcstypeinterface):
    var optical_table: OpticalDataTable
    var optical_table_uns: Pointer[GaussMarkov]
    var eff_scale: Float64
    var pi: Float64
    var Pi: Float64
    var d2r: Float64
    var r2d: Float64
    var g: Float64
    var mtoinch: Float64
    var latitude: Float64
    var longitude: Float64
    var timezone: Float64
    var theta_stow: Float64
    var theta_dep: Float64
    var interp_arr: Int32
    var rad_type: Int32
    var solarm: Float64
    var T_sfdes: Float64
    var irr_des: Float64
    var eta_opt_soil: Float64
    var eta_opt_gen: Float64
    var f_sfhl_ref: Float64
    var sfhlQ_coefs: Pointer[Float64]
    var nval_sfhlQ_coefs: Int32
    var sfhlT_coefs: Pointer[Float64]
    var nval_sfhlT_coefs: Int32
    var sfhlV_coefs: Pointer[Float64]
    var nval_sfhlV_coefs: Int32
    var qsf_des: Float64
    var w_des: Float64
    var eta_des: Float64
    var f_wmax: Float64
    var f_wmin: Float64
    var f_startup: Float64
    var eta_lhv: Float64
    var etaQ_coefs: Pointer[Float64]
    var nval_etaQ_coefs: Int32
    var etaT_coefs: Pointer[Float64]
    var nval_etaT_coefs: Int32
    var T_pcdes: Float64
    var PC_T_corr: Float64
    var f_Wpar_fixed: Float64
    var f_Wpar_prod: Float64
    var Wpar_prodQ_coefs: Pointer[Float64]
    var nval_Wpar_prodQ_coefs: Int32
    var Wpar_prodT_coefs: Pointer[Float64]
    var nval_Wpar_prodT_coefs: Int32
    var hrs_tes: Float64
    var f_charge: Float64
    var f_disch: Float64
    var f_etes_0: Float64
    var f_teshl_ref: Float64
    var teshlX_coefs: Pointer[Float64]
    var nval_teshlX_coefs: Int32
    var teshlT_coefs: Pointer[Float64]
    var nval_teshlT_coefs: Int32
    var ntod: Int32
    var nval_tod_sched: Int32
    var disws: Pointer[Float64]
    var nval_disws: Int32
    var diswos: Pointer[Float64]
    var nval_diswos: Int32
    var qdisp: Pointer[Float64]
    var nval_qdisp: Int32
    var fdisp: Pointer[Float64]
    var nval_fdisp: Int32
    var istableunsorted: Bool
    var OpticalTable_in: Pointer[Float64]
    var nrow_OpticalTable: Int32
    var ncol_OpticalTable: Int32
    var ibn: Float64
    var ibh: Float64
    var itoth: Float64
    var tdb: Float64
    var twb: Float64
    var vwind: Float64
    var irr_used: Float64
    var hour_of_day: Float64
    var day_of_year: Float64
    var declination: Float64
    var soltime: Float64
    var hrangle: Float64
    var solalt: Float64
    var solaz: Float64
    var eta_opt_sf: Float64
    var f_sfhl_qdni: Float64
    var f_sfhl_tamb: Float64
    var f_sfhl_vwind: Float64
    var q_hl_sf: Float64
    var q_sf: Float64
    var q_inc: Float64
    var pbmode: Int32
    var pbstartf: Int32
    var q_to_pb: Float64
    var q_startup: Float64
    var q_to_tes: Float64
    var q_from_tes: Float64
    var e_in_tes: Float64
    var q_hl_tes: Float64
    var q_dump_tesfull: Float64
    var q_dump_teschg: Float64
    var q_dump_umin: Float64
    var q_dump_tot: Float64
    var q_fossil: Float64
    var q_gas: Float64
    var f_effpc_qtpb: Float64
    var f_effpc_tamb: Float64
    var eta_cycle: Float64
    var w_gr_solar: Float64
    var w_gr_fossil: Float64
    var w_gr: Float64
    var w_par_fixed: Float64
    var w_par_prod: Float64
    var w_par_tot: Float64
    var w_par_online: Float64
    var w_par_offline: Float64
    var enet: Float64
    var OpticalTable: util.matrix_t[Float64]
    var dt: Float64
    var start_time: Float64
    var q_des: Float64
    var etesmax: Float64
    var omega: Float64
    var dec: Float64
    var eta_opt_ref: Float64
    var f_qsf: Float64
    var qttmin: Float64
    var qttmax: Float64
    var ptsmax: Float64
    var pfsmax: Float64
    var etes0: Float64
    var q_startup_remain: Float64
    var q_startup_used: Float64
    var pbmode0: Int32
    var is_sf_init: Bool

    def __init__(inout self, cxt: Pointer[tcscontext], ti: Pointer[tcstypeinfo]):
        tcstypeinterface.__init__(self, cxt, ti)
        self.Pi = acos(-1.0)
        self.pi = self.Pi
        self.r2d = 180.0 / self.pi
        self.d2r = self.pi / 180.0
        self.g = 9.81
        self.mtoinch = 39.3700787
        self.is_sf_init = False
        self.latitude = Float64(Float64.NaN)
        self.longitude = Float64(Float64.NaN)
        self.timezone = Float64(Float64.NaN)
        self.theta_stow = Float64(Float64.NaN)
        self.theta_dep = Float64(Float64.NaN)
        self.interp_arr = -1
        self.rad_type = -1
        self.solarm = Float64(Float64.NaN)
        self.T_sfdes = Float64(Float64.NaN)
        self.irr_des = Float64(Float64.NaN)
        self.eta_opt_soil = Float64(Float64.NaN)
        self.eta_opt_gen = Float64(Float64.NaN)
        self.f_sfhl_ref = Float64(Float64.NaN)
        self.sfhlQ_coefs = Pointer[Float64]()
        self.nval_sfhlQ_coefs = -1
        self.sfhlT_coefs = Pointer[Float64]()
        self.nval_sfhlT_coefs = -1
        self.sfhlV_coefs = Pointer[Float64]()
        self.nval_sfhlV_coefs = -1
        self.qsf_des = Float64(Float64.NaN)
        self.w_des = Float64(Float64.NaN)
        self.eta_des = Float64(Float64.NaN)
        self.f_wmax = Float64(Float64.NaN)
        self.f_wmin = Float64(Float64.NaN)
        self.f_startup = Float64(Float64.NaN)
        self.eta_lhv = Float64(Float64.NaN)
        self.etaQ_coefs = Pointer[Float64]()
        self.nval_etaQ_coefs = -1
        self.etaT_coefs = Pointer[Float64]()
        self.nval_etaT_coefs = -1
        self.T_pcdes = Float64(Float64.NaN)
        self.PC_T_corr = Float64(Float64.NaN)
        self.f_Wpar_fixed = Float64(Float64.NaN)
        self.f_Wpar_prod = Float64(Float64.NaN)
        self.Wpar_prodQ_coefs = Pointer[Float64]()
        self.nval_Wpar_prodQ_coefs = -1
        self.Wpar_prodT_coefs = Pointer[Float64]()
        self.nval_Wpar_prodT_coefs = -1
        self.hrs_tes = Float64(Float64.NaN)
        self.f_charge = Float64(Float64.NaN)
        self.f_disch = Float64(Float64.NaN)
        self.f_etes_0 = Float64(Float64.NaN)
        self.f_teshl_ref = Float64(Float64.NaN)
        self.teshlX_coefs = Pointer[Float64]()
        self.nval_teshlX_coefs = -1
        self.teshlT_coefs = Pointer[Float64]()
        self.nval_teshlT_coefs = -1
        self.ntod = -1
        self.nval_tod_sched = -1
        self.disws = Pointer[Float64]()
        self.nval_disws = -1
        self.diswos = Pointer[Float64]()
        self.nval_diswos = -1
        self.qdisp = Pointer[Float64]()
        self.nval_qdisp = -1
        self.fdisp = Pointer[Float64]()
        self.nval_fdisp = -1
        self.OpticalTable_in = Pointer[Float64]()
        self.nrow_OpticalTable = -1
        self.ncol_OpticalTable = -1
        self.istableunsorted = False
        self.optical_table_uns = Pointer[GaussMarkov]()
        self.eff_scale = 1.0
        self.ibn = Float64(Float64.NaN)
        self.ibh = Float64(Float64.NaN)
        self.itoth = Float64(Float64.NaN)
        self.tdb = Float64(Float64.NaN)
        self.twb = Float64(Float64.NaN)
        self.vwind = Float64(Float64.NaN)
        self.irr_used = Float64(Float64.NaN)
        self.hour_of_day = Float64(Float64.NaN)
        self.day_of_year = Float64(Float64.NaN)
        self.declination = Float64(Float64.NaN)
        self.soltime = Float64(Float64.NaN)
        self.hrangle = Float64(Float64.NaN)
        self.solalt = Float64(Float64.NaN)
        self.solaz = Float64(Float64.NaN)
        self.eta_opt_sf = Float64(Float64.NaN)
        self.f_sfhl_qdni = Float64(Float64.NaN)
        self.f_sfhl_tamb = Float64(Float64.NaN)
        self.f_sfhl_vwind = Float64(Float64.NaN)
        self.q_hl_sf = Float64(Float64.NaN)
        self.q_sf = Float64(Float64.NaN)
        self.q_inc = Float64(Float64.NaN)
        self.pbmode = -1
        self.pbstartf = -1
        self.q_to_pb = Float64(Float64.NaN)
        self.q_startup = Float64(Float64.NaN)
        self.q_to_tes = Float64(Float64.NaN)
        self.q_from_tes = Float64(Float64.NaN)
        self.e_in_tes = Float64(Float64.NaN)
        self.q_hl_tes = Float64(Float64.NaN)
        self.q_dump_tesfull = Float64(Float64.NaN)
        self.q_dump_teschg = Float64(Float64.NaN)
        self.q_dump_umin = Float64(Float64.NaN)
        self.q_dump_tot = Float64(Float64.NaN)
        self.q_fossil = Float64(Float64.NaN)
        self.q_gas = Float64(Float64.NaN)
        self.f_effpc_qtpb = Float64(Float64.NaN)
        self.f_effpc_tamb = Float64(Float64.NaN)
        self.eta_cycle = Float64(Float64.NaN)
        self.w_gr_solar = Float64(Float64.NaN)
        self.w_gr_fossil = Float64(Float64.NaN)
        self.w_gr = Float64(Float64.NaN)
        self.w_par_fixed = Float64(Float64.NaN)
        self.w_par_prod = Float64(Float64.NaN)
        self.w_par_tot = Float64(Float64.NaN)
        self.w_par_online = Float64(Float64.NaN)
        self.w_par_offline = Float64(Float64.NaN)
        self.enet = Float64(Float64.NaN)

    def __del__(owned self):
        if self.optical_table_uns:
            del self.optical_table_uns

    def init(inout self) -> Int32:
        # --Initialization call-- 
        # Do any setup required here.
        # Get the values of the inputs and parameters
        self.dt = self.time_step() / 3600.0
        self.start_time = -1.0
        self.latitude = self.value(P_LATITUDE)  # Site latitude [deg]
        self.longitude = self.value(P_LONGITUDE)  # Site longitude [deg]
        self.timezone = self.value(P_TIMEZONE)  # Site timezone [hr]
        self.theta_stow = self.value(P_THETA_STOW)  # Solar elevation angle at which the solar field stops operating [deg]
        self.theta_dep = self.value(P_THETA_DEP)  # Solar elevation angle at which the solar field begins operating [deg]
        self.interp_arr = Int32(self.value(P_INTERP_ARR))  # Interpolate the array or find nearest neighbor? (1=interp,2=no) [none]
        self.rad_type = Int32(self.value(P_RAD_TYPE))  # Solar resource radiation type (1=DNI,2=horiz.beam,3=tot.horiz) [none]
        self.solarm = self.value(P_SOLARM)  # Solar multiple [none]
        self.T_sfdes = self.value(P_T_SFDES)  # Solar field design point temperature (dry bulb) [C]
        self.irr_des = self.value(P_IRR_DES)  # Irradiation design point [W/m2]
        self.eta_opt_soil = self.value(P_ETA_OPT_SOIL)  # Soiling optical derate factor [none]
        self.eta_opt_gen = self.value(P_ETA_OPT_GEN)  # General/other optical derate [none]
        self.f_sfhl_ref = self.value(P_F_SFHL_REF)  # Reference solar field thermal loss fraction [MW/MWcap]
        self.sfhlQ_coefs = self.value(P_SFHLQ_COEFS, &self.nval_sfhlQ_coefs)  # Irr-based solar field thermal loss adjustment coefficients [1/MWt]
        self.sfhlT_coefs = self.value(P_SFHLT_COEFS, &self.nval_sfhlT_coefs)  # Temp.-based solar field thermal loss adjustment coefficients [1/C]
        self.sfhlV_coefs = self.value(P_SFHLV_COEFS, &self.nval_sfhlV_coefs)  # Wind-based solar field thermal loss adjustment coefficients [1/(m/s)]
        self.qsf_des = self.value(P_QSF_DES)  # Solar field thermal production at design [MWt]
        self.w_des = self.value(P_W_DES)  # Design power cycle gross output [MWe]
        self.eta_des = self.value(P_ETA_DES)  # Design power cycle gross efficiency [none]
        self.f_wmax = self.value(P_F_WMAX)  # Maximum over-design power cycle operation fraction [none]
        self.f_wmin = self.value(P_F_WMIN)  # Minimum part-load power cycle operation fraction [none]
        self.f_startup = self.value(P_F_STARTUP)  # Equivalent full-load hours required for power system startup [hours]
        self.eta_lhv = self.value(P_ETA_LHV)  # Fossil backup lower heating value efficiency [none]
        self.etaQ_coefs = self.value(P_ETAQ_COEFS, &self.nval_etaQ_coefs)  # Part-load power conversion efficiency adjustment coefficients [1/MWt]
        self.etaT_coefs = self.value(P_ETAT_COEFS, &self.nval_etaT_coefs)  # Temp.-based power conversion efficiency adjustment coefs. [1/C]
        self.T_pcdes = self.value(P_T_PCDES)  # Power conversion reference temperature [C]
        self.PC_T_corr = self.value(P_PC_T_CORR)  # Power conversion temperature correction mode (1=wetb, 2=dryb) [none]
        self.f_Wpar_fixed = self.value(P_F_WPAR_FIXED)  # Fixed capacity-based parasitic loss fraction [MWe/MWcap]
        self.f_Wpar_prod = self.value(P_F_WPAR_PROD)  # Production-based parasitic loss fraction [MWe/MWe]
        self.Wpar_prodQ_coefs = self.value(P_WPAR_PRODQ_COEFS, &self.nval_Wpar_prodQ_coefs)  # Part-load production parasitic adjustment coefs. [1/MWe]
        self.Wpar_prodT_coefs = self.value(P_WPAR_PRODT_COEFS, &self.nval_Wpar_prodT_coefs)  # Temp.-based production parasitic adjustment coefs. [1/C]
        self.hrs_tes = self.value(P_HRS_TES)  # Equivalent full-load hours of storage [hours]
        self.f_charge = self.value(P_F_CHARGE)  # Storage charging energy derate [none]
        self.f_disch = self.value(P_F_DISCH)  # Storage discharging energy derate [none]
        self.f_etes_0 = self.value(P_F_ETES_0)  # Initial fractional charge level of thermal storage (0..1) [none]
        self.f_teshl_ref = self.value(P_F_TESHL_REF)  # Reference heat loss from storage per max stored capacity [kWt/MWhr-stored]
        self.teshlX_coefs = self.value(P_TESHLX_COEFS, &self.nval_teshlX_coefs)  # Charge-based thermal loss adjustment - constant coef. [1/MWhr-stored]
        self.teshlT_coefs = self.value(P_TESHLT_COEFS, &self.nval_teshlT_coefs)  # Temp.-based thermal loss adjustment - constant coef. [1/C]
        self.ntod = Int32(self.value(P_NTOD))  # Number of time-of-dispatch periods in the dispatch schedule [none]
        self.disws = self.value(P_DISWS, &self.nval_disws)  # Time-of-dispatch control for with-solar conditions [none]
        self.diswos = self.value(P_DISWOS, &self.nval_diswos)  # Time-of-dispatch control for without-solar conditions [none]
        self.qdisp = self.value(P_QDISP, &self.nval_qdisp)  # touperiod power output control factors [none]
        self.fdisp = self.value(P_FDISP, &self.nval_fdisp)  # Fossil backup output control factors [none]
        self.OpticalTable_in = self.value(P_OPTICALTABLE, &self.nrow_OpticalTable, &self.ncol_OpticalTable)  # Optical table [none]
        self.istableunsorted = self.value(P_ISTABLEUNSORTED) == 1.0
        self.OpticalTable.assign(self.OpticalTable_in, self.nrow_OpticalTable, self.ncol_OpticalTable)
        self.latitude *= self.d2r
        self.longitude *= self.d2r
        self.theta_stow *= self.d2r
        self.theta_dep *= self.d2r
        self.T_sfdes += 273.15
        self.T_pcdes += 273.15
        self.f_teshl_ref *= 0.001
        self.q_des = self.w_des / self.eta_des  # [MWt]
        self.etesmax = self.hrs_tes * self.q_des  # [MW-hr]
        for i in range(self.ntod):
            self.disws[i] *= self.etesmax
            self.diswos[i] *= self.etesmax
            self.qdisp[i] *= self.q_des
            self.fdisp[i] *= self.q_des
        # 
        # Set up the optical table object..
        # The input should be defined as follows:
        # - Data of size nx, ny
        # - OpticalTable of size (nx+1)*(ny+1)
        # - First nx+1 values (row 1) are x-axis values, not data, starting at index 1
        # - First value of remaining ny rows are y-axis values, not data
        # - Data is contained in cells i,j : where i>1, j>1
        # A second option using an unstructured array is also possible. The data should be defined as:
        # - N rows
        # - 3 values per row
        # - Azimuth, Zenith, Efficiency point
        # If the OpticalTableUns is given data, it will be used by default.
        if not self.istableunsorted:
            # 
            # Standard azimuth-elevation table
            # 
            if (self.nrow_OpticalTable < 5 and self.ncol_OpticalTable > 3) or (self.ncol_OpticalTable == 3 and self.nrow_OpticalTable > 4):
                self.message(TCS_WARNING, "The optical efficiency table option flag may not match the specified table format. If running SSC, ensure \"IsTableUnsorted\""
                    " =0 if regularly-spaced azimuth-zenith matrix is used and =1 if azimuth,zenith,efficiency points are specified.")
            if self.nrow_OpticalTable <= 0 or self.ncol_OpticalTable <= 0:
                return -1
            var xax = Pointer[Float64].alloc(self.ncol_OpticalTable - 1)
            var yax = Pointer[Float64].alloc(self.nrow_OpticalTable - 1)
            var data = Pointer[Float64].alloc((self.ncol_OpticalTable - 1) * (self.nrow_OpticalTable - 1))
            for i in range(1, self.ncol_OpticalTable):
                xax[i - 1] = self.OpticalTable.at(0, i) * self.d2r
            for j in range(1, self.nrow_OpticalTable):
                yax[j - 1] = self.OpticalTable.at(j, 0) * self.d2r
            for j in range(1, self.nrow_OpticalTable):
                for i in range(1, self.ncol_OpticalTable):
                    data[i - 1 + (self.ncol_OpticalTable - 1) * (j - 1)] = self.OpticalTable.at(j, i)
            self.optical_table.AddXAxis(xax, self.ncol_OpticalTable - 1)
            self.optical_table.AddYAxis(yax, self.nrow_OpticalTable - 1)
            self.optical_table.AddData(data)
            del xax
            del yax
            del data
        else:
            # 
            # Use the unstructured data table
            # 
            # 
            # ------------------------------------------------------------------------------
            # Create the regression fit on the efficiency map
            # ------------------------------------------------------------------------------
            # 
            if self.ncol_OpticalTable != 3:
                self.message(TCS_ERROR, "The heliostat field efficiency file is not formatted correctly. Type expects 3 columns"
                    " (zenith angle, azimuth angle, efficiency value) and instead has %d cols.", self.ncol_OpticalTable)
                return -1
            var sunpos: MatDoub
            var effs: List[Float64]
            sunpos.resize(self.nrow_OpticalTable, VectDoub(2))
            effs.resize(self.nrow_OpticalTable)
            var eff_maxval: Float64 = -9.0e9
            for i in range(self.nrow_OpticalTable):
                sunpos.at(i).at(0) = TCS_MATRIX_INDEX(self.var(P_OPTICALTABLE), i, 0) / az_scale * self.pi / 180.0
                sunpos.at(i).at(1) = TCS_MATRIX_INDEX(self.var(P_OPTICALTABLE), i, 1) / zen_scale * self.pi / 180.0
                var eff: Float64 = TCS_MATRIX_INDEX(self.var(P_OPTICALTABLE), i, 2)
                effs.at(i) = eff
                if eff > eff_maxval:
                    eff_maxval = eff
            self.eff_scale = eff_maxval
            for i in range(self.nrow_OpticalTable):
                effs.at(i) /= self.eff_scale
            var vgram: Powvargram = Powvargram(sunpos, effs, 1.99, 0.0)
            self.optical_table_uns = GaussMarkov(sunpos, effs, vgram)
            var err_fit: Float64 = 0.0
            var npoints: Int32 = Int32(sunpos.size())
            for i in range(npoints):
                var zref: Float64 = effs.at(i)
                var zfit: Float64 = self.optical_table_uns.interp(sunpos.at(i))
                var dz: Float64 = zref - zfit
                err_fit += dz * dz
            err_fit = sqrt(err_fit)
            if err_fit > 0.01:
                self.message(TCS_WARNING, "The heliostat field interpolation function fit is poor! (err_fit=%f RMS)", err_fit)
        self.qttmin = self.q_des * self.f_wmin
        self.qttmax = self.q_des * self.f_wmax
        self.ptsmax = self.q_des * self.solarm
        self.pfsmax = self.ptsmax / self.f_disch * self.f_wmax
        self.etes0 = self.f_etes_0 * self.etesmax  # [MW-hr] Initial value in thermal storage. This keeps track of energy in thermal storage, or e_in_tes
        self.pbmode0 = 0  # [-] initial value of power block operation mode pbmode
        self.q_startup_remain = self.f_startup * self.q_des  # [MW-hr] Initial value of turbine startup energy q_startup_used
        return True

    def init_sf(inout self):
        self.omega = 0.0  # solar noon
        self.dec = 23.45 * self.d2r  # declination at summer solstice
        self.solalt = asin(sin(self.dec) * sin(self.latitude) + cos(self.latitude) * cos(self.dec) * cos(self.omega))
        var opt_des: Float64
        if self.istableunsorted:
            var sunpos: List[Float64]
            sunpos.push_back(0.0)
            sunpos.push_back((self.pi / 2.0 - self.solalt) / zen_scale)
            opt_des = self.optical_table_uns.interp(sunpos) * self.eff_scale
        else:
            if self.interp_arr == 1:
                opt_des = self.optical_table.interpolate(0.0, max(self.pi / 2.0 - self.solalt, 0.0))
            else:
                opt_des = self.optical_table.nearest(0.0, max(self.pi / 2.0 - self.solalt, 0.0))
        self.eta_opt_ref = self.eta_opt_soil * self.eta_opt_gen * opt_des
        self.f_qsf = self.qsf_des / (self.irr_des * self.eta_opt_ref * (1.0 - self.f_sfhl_ref))  # [MWt/([W/m2] * [-] * [-])]
        return

    def call(inout self, time: Float64, step: Float64, ncall: Int32) -> Int32:
        # 
        # -- Standard timestep call --
        # *get inputs
        # *do calculations
        # *set outputs
        # 
        if self.start_time < 0.0:
            self.start_time = self.current_time()
        if not self.is_sf_init:
            self.latitude = self.value(P_LATITUDE) * self.d2r
            self.longitude = self.value(P_LONGITUDE) * self.d2r
            self.timezone = self.value(P_TIMEZONE)
            self.init_sf()
            self.is_sf_init = True
        self.ibn = self.value(I_IBN)  # Beam-normal (DNI) irradiation [W/m^2]
        self.ibh = self.value(I_IBH)  # Beam-horizontal irradiation [W/m^2]
        self.itoth = self.value(I_ITOTH)  # Total horizontal irradiation [W/m^2]
        self.tdb = self.value(I_TDB)  # Ambient dry-bulb temperature [C]
        self.twb = self.value(I_TWB)  # Ambient wet-bulb temperature [C]
        self.vwind = self.value(I_VWIND)  # Wind velocity [m/s]
        var shift: Float64 = self.longitude - self.timezone * 15.0 * self.d2r
        var touperiod: Int32 = Int32(self.value(I_TOUPeriod)) - 1  # control value between 1 & 9, have to change to 0-8 for array index
        self.tdb += 273.15
        self.twb += 273.15
        if self.rad_type == 1:
            self.irr_used = self.ibn  # [W/m2]
        elif self.rad_type == 2:
            self.irr_used = self.ibh  # [W/m2]
        elif self.rad_type == 3:
            self.irr_used = self.itoth  # [W/m2]
        var dispatch: util.matrix_t[Float64] = util.matrix_t[Float64](self.ntod)
        if self.irr_used > 0.0:
            for i in range(self.ntod):
                dispatch.at(i) = self.disws[i]
        else:
            for i in range(self.ntod):
                dispatch.at(i) = self.diswos[i]
        self.hour_of_day = fmod(time / 3600.0, 24.0)  # hour_of_day of the day (1..24)
        self.day_of_year = ceil(time / 3600.0 / 24.0)  # Day of the year
        var B: Float64 = (self.day_of_year - 1.0) * 360.0 / 365.0 * self.pi / 180.0
        var EOT: Float64 = 229.2 * (0.000075 + 0.001868 * cos(B) - 0.032077 * sin(B) - 0.014615 * cos(B * 2.0) - 0.04089 * sin(B * 2.0))
        self.dec = 23.45 * sin(360.0 * (284.0 + self.day_of_year) / 365.0 * self.pi / 180.0) * self.pi / 180.0
        var SolarNoon: Float64 = 12.0 - ((shift) * 180.0 / self.pi) / 15.0 - EOT / 60.0
        # double TSnow;
        # if ((hour_of_day - int(hour_of_day)) == 0.00){
        #     TSnow = 1.0;
        # }
        # else{
        #     TSnow = (hour_of_day - floor(hour_of_day))/dt + 1.;
        # }
        self.theta_dep = max(self.theta_dep, 1.0e-6)
        var DepHr1: Float64 = cos(self.latitude) / tan(self.theta_dep)
        var DepHr2: Float64 = -tan(self.dec) * sin(self.latitude) / tan(self.theta_dep)
        var DepHr3: Float64 = (1.0 if tan(self.pi - self.theta_dep) < 0.0 else -1.0) * acos((DepHr1 * DepHr2 + sqrt(DepHr1 * DepHr1 - DepHr2 * DepHr2 + 1.0)) / (DepHr1 * DepHr1 + 1.0)) * 180.0 / self.pi / 15.0
        var DepTime: Float64 = SolarNoon + DepHr3
        self.theta_stow = max(self.theta_stow, 1.0e-6)
        var StwHr1: Float64 = cos(self.latitude) / tan(self.theta_stow)
        var StwHr2: Float64 = -tan(self.dec) * sin(self.latitude) / tan(self.theta_stow)
        var StwHr3: Float64 = (1.0 if tan(self.pi - self.theta_stow) < 0.0 else -1.0) * acos((StwHr1 * StwHr2 + sqrt(StwHr1 * StwHr1 - StwHr2 * StwHr2 + 1.0)) / (StwHr1 * StwHr1 + 1.0)) * 180.0 / self.pi / 15.0
        var StwTime: Float64 = SolarNoon + StwHr3
        var HrA: Float64 = self.hour_of_day - self.dt
        var HrB: Float64 = self.hour_of_day
        var Ftrack: Float64
        var MidTrack: Float64
        if (HrB > DepTime) and (HrA < StwTime):
            if HrA < DepTime:
                Ftrack = (HrB - DepTime) * self.dt
                MidTrack = HrB - Ftrack * 0.5 * self.dt
            elif HrB > StwTime:
                Ftrack = (StwTime - HrA) * self.dt
                MidTrack = HrA + Ftrack * 0.5 * self.dt
            else:
                Ftrack = 1.0
                MidTrack = HrA + 0.5 * self.dt
        else:
            Ftrack = 0.0
            MidTrack = HrA + 0.5 * self.dt
        var StdTime: Float64 = MidTrack
        self.soltime = StdTime + ((shift) * 180.0 / self.pi) / 15.0 + EOT / 60.0
        self.omega = (self.soltime - 12.0) * 15.0 * self.pi / 180.0
        self.solalt = asin(sin(self.dec) * sin(self.latitude) + cos(self.latitude) * cos(self.dec) * cos(self.omega))
        self.solaz = (1.0 if self.omega < 0.0 else -1.0) * fabs(acos(min(1.0, (cos(self.pi / 2.0 - self.solalt) * sin(self.latitude) - sin(self.dec)) / (sin(self.pi / 2.0 - self.solalt) * cos(self.latitude)))))
        var opt_val: Float64
        if self.istableunsorted:
            var sunpos: List[Float64]
            sunpos.push_back(self.solaz / az_scale)
            sunpos.push_back((self.pi / 2.0 - self.solalt) / zen_scale)
            opt_val = self.optical_table_uns.interp(sunpos) * self.eff_scale
        else:
            if self.interp_arr == 1:
                opt_val = self.optical_table.interpolate(self.solaz, max(self.pi / 2.0 - self.solalt, 0.0))
            else:
                opt_val = self.optical_table.nearest(self.solaz, max(self.pi / 2.0 - self.solalt, 0.0))
        var eta_arr: Float64 = max(opt_val * Ftrack, 0.0)  # mjw 7.25.11 limit zenith to <90, otherwise the interpolation error message gets called during night hours.
        self.eta_opt_sf = eta_arr * self.eta_opt_soil * self.eta_opt_gen
        self.f_sfhl_qdni = 0.0
        self.f_sfhl_tamb = 0.0
        self.f_sfhl_vwind = 0.0
        for i in range(self.nval_sfhlQ_coefs):
            self.f_sfhl_qdni += self.sfhlQ_coefs[i] * pow(self.irr_used / self.irr_des, i)
        for i in range(self.nval_sfhlT_coefs):
            self.f_sfhl_tamb += self.sfhlT_coefs[i] * pow(self.tdb - self.T_sfdes, i)
        for i in range(self.nval_sfhlV_coefs):
            self.f_sfhl_vwind += self.sfhlV_coefs[i] * pow(self.vwind, i)
        var f_sfhl: Float64 = 1.0 - self.f_sfhl_ref * self.f_sfhl_qdni * self.f_sfhl_tamb * self.f_sfhl_vwind  # This ratio indicates the sf thermal efficiency
        self.q_hl_sf = self.f_qsf * self.irr_used * (1.0 - f_sfhl) * self.eta_opt_sf  # [MWt]
        self.q_sf = self.f_qsf * f_sfhl * self.eta_opt_sf * self.irr_used  # [MWt]
        self.q_to_tes = 0.0  # | Energy to Thermal Storage 
        self.q_from_tes = 0.0  # | Energy from Thermal Storage
        self.e_in_tes = 0.0  # | Energy in Thermal Storage
        self.q_hl_tes = 0.0  # | Energy losses from Thermal Storage
        self.q_to_pb = 0.0  # | Energy to the Power Block
        self.q_dump_tesfull = 0.0  # | Energy dumped because the thermal storage is full
        self.q_dump_umin = 0.0  # | Indicator of being below minimum operation level
        self.q_dump_teschg = 0.0  # | The amount of energy dumped (more than turbine and storage)
        self.q_startup = 0.0  # | The energy needed to startup the turbine
        self.pbstartf = 0  # | is 1 during the period when powerblock starts up otherwise 0
        self.q_startup_used = self.q_startup_remain  # | Turbine startup energy for this timestep is equal to the remaining previous energy
        if self.hrs_tes <= 0.0:  # No Storage
            if (self.pbmode0 == 0) or (self.pbmode0 == 1):  # if plant is not already operating in last timestep
                if self.q_sf > 0.0:
                    if self.q_sf > (self.q_startup_used / self.dt):  #  Starts plant as exceeds startup energy needed
                        self.q_to_pb = self.q_sf - self.q_startup_used / self.dt
                        self.q_startup = self.q_startup_used / self.dt
                        self.pbmode = 2  # Power block mode.. 2=starting up
                        self.pbstartf = 1  # Flag indicating whether the power block starts up in this time period
                        self.q_startup_used = 0.0  # mjw 5-31-13 Reset to zero to handle cases where Qsf-TurSue leads to Qttb < Qttmin
                    else:  #  Plant starting up but not enough energy to make it run - will probably finish in the next timestep
                        self.q_to_pb = 0.0
                        self.q_startup_used = self.q_startup_remain - self.q_sf * self.dt
                        self.q_startup = self.q_sf
                        self.pbmode = 1
                        self.pbstartf = 0
                else:  # No solar field output so still need same amount of energy as before and nothing changes
                    self.q_startup_used = self.f_startup * self.q_des
                    self.pbmode = 0
                    self.pbstartf = 0
            else:  # if the powerblock mode is already 2 (running previous timestep)
                if self.q_sf > 0.0:  # Plant operated last hour_of_day and this one
                    self.q_to_pb = self.q_sf  # all power goes from solar field to the powerblock
                    self.pbmode = 2  # powerblock continuing to operate
                    self.pbstartf = 0  # powerblock did not start during this timestep
                else:  #  Plant operated last hour_of_day but not this one
                    self.q_to_pb = 0.0  # No energy to the powerblock
                    self.pbmode = 0  # turned off powrblock
                    self.pbstartf = 0  # it didn't start this timeperiod 
                    self.q_startup_used = self.q_startup_remain
            if self.q_to_pb < self.qttmin:  # Energy to powerblock less than the minimum that the turbine can run at
                self.q_dump_umin = self.q_to_pb  # The minimum energy (less than the minimum)
                self.q_to_pb = 0.0  # Energy to PB is now 0
                self.pbmode = 0  # PB turned off
            if self.q_to_pb > self.qttmax:  # Energy to powerblock greater than what the PB can handle (max)
                self.q_dump_teschg = self.q_to_pb - self.qttmax  # The energy dumped 
                self.q_to_pb = self.qttmax  # the energy to the PB is exactly the maximum
        else:  # With thermal storage    
            self.q_startup = 0.0
            self.pbstartf = 0
            self.q_dump_teschg = 0.0
            self.q_from_tes = 0.0
            if self.pbmode0 == 0:
                var EtesA: Float64 = max(0.0, self.etes0 - dispatch.at(touperiod))
                if (self.q_sf + EtesA >= self.qdisp[touperiod]) or (self.q_sf > self.ptsmax):
                    self.pbmode = 1
                    self.q_startup = self.f_startup * self.q_des / self.dt
                    self.q_to_pb = self.qdisp[touperiod]  # set the energy to powerblock equal to the load for this TOU period
                    if self.q_sf > self.q_to_pb:  # if solar field output is greater than what the necessary load ?
                        self.q_to_tes = self.q_sf - self.q_to_pb  # the extra goes to thermal storage
                        self.q_from_tes = self.q_startup  # Use the energy from thermal storage to startup the power cycle
                        if self.q_to_tes > self.ptsmax:  # if q to thermal storage exceeds thermal storage max rate Added 9-10-02
                            self.q_dump_teschg = self.q_to_tes - self.ptsmax  # then dump the excess for this period Added 9-10-02
                            self.q_to_tes = self.ptsmax
                    else:  # q_sf less than the powerblock requirement
                        self.q_to_tes = 0.0
                        self.q_from_tes = self.q_startup + (1.0 - self.q_sf / self.q_to_pb) * min(self.pfsmax, self.q_des)
                        if self.q_from_tes > self.pfsmax:
                            self.q_from_tes = self.pfsmax
                        self.q_to_pb = self.q_sf + (1.0 - self.q_sf / self.q_to_pb) * min(self.pfsmax, self.q_des)
                    self.e_in_tes = self.etes0 - self.q_startup + (self.q_sf - self.q_to_pb) * self.dt  # thermal storage energy is initial + what was left 
                    self.pbmode = 2  # powerblock is now running
                    self.pbstartf = 1  # the powerblock turns on during this timeperiod.
                else:  # Store energy not enough stored to start plant
                    self.q_to_tes = self.q_sf  # everything goes to thermal storage
                    self.q_from_tes = 0.0  # nothing from thermal storage
                    self.e_in_tes = self.etes0 + self.q_to_tes * self.dt
                    self.q_to_pb = 0.0
            else:
                if (self.q_sf + max(0.0, self.etes0 - dispatch.at(touperiod)) / self.dt) > self.qdisp[touperiod]:  # if there is sufficient energy to operate at dispatch target output
                    self.q_to_pb = self.qdisp[touperiod]
                    if self.q_sf > self.q_to_pb:
                        self.q_to_tes = self.q_sf - self.q_to_pb  # extra from what is needed put in thermal storage
                        self.q_from_tes = 0.0
                        if self.q_to_tes > self.ptsmax:  # check if max power rate to storage exceeded
                            self.q_dump_teschg = self.q_to_tes - self.ptsmax  # if so, dump extra 
                            self.q_to_tes = self.ptsmax
                    else:  # solar field outptu less than what powerblock needs
                        self.q_to_tes = 0.0
                        self.q_from_tes = (1.0 - self.q_sf / self.q_to_pb) * min(self.pfsmax, self.q_des)
                        if self.q_from_tes > self.pfsmax:
                            self.q_from_tes = min(self.pfsmax, self.q_des)
                        self.q_to_pb = self.q_from_tes + self.q_sf
                    self.e_in_tes = self.etes0 + (self.q_sf - self.q_to_pb - self.q_dump_teschg) * self.dt  # energy of thermal storage is the extra
                    if (self.e_in_tes > self.etesmax) and (self.q_to_pb < self.qttmax):  # qttmax (MWt) - power to turbine max
                        if (self.e_in_tes - self.etesmax) / self.dt < (self.qttmax - self.q_to_pb):
                            self.q_to_pb = self.q_to_pb + (self.e_in_tes - self.etesmax) / self.dt
                            self.e_in_tes = self.etesmax
                        else:
                            self.e_in_tes = self.e_in_tes - (self.qttmax - self.q_to_pb) * self.dt  # should this be etes0 instead of e_in_tes on RHS ??
                            self.q_to_pb = self.qttmax
                        self.q_to_tes = self.q_sf - self.q_to_pb
                else:  # Empties tes to dispatch level if above min load level
                    if (self.q_sf + max(0.0, self.etes0 - dispatch.at(touperiod)) * self.dt) > self.qttmin:
                        self.q_from_tes = max(0.0, self.etes0 - dispatch.at(touperiod)) * self.dt
                        self.q_to_pb = self.q_sf + self.q_from_tes
                        self.q_to_tes = 0.0
                        self.e_in_tes = self.etes0 - self.q_from_tes
                    else:
                        self.q_to_pb = 0.0
                        self.q_from_tes = 0.0
                        self.q_to_tes = self.q_sf
                        self.e_in_tes = self.etes0 + self.q_to_tes * self.dt
            if self.q_to_pb > 0.0:
                self.pbmode = 2
            else:
                self.pbmode = 0
            var f_EtesAve: Float64 = max((self.e_in_tes + self.etes0) / 2.0 / self.etesmax, 0.0)
            var f_teshlX: Float64 = 0.0
            var f_teshlT: Float64 = 0.0
            for i in range(self.nval_teshlX_coefs):
                f_teshlX += self.teshlX_coefs[i] * pow(f_EtesAve, i)  # Charge adjustment factor
            for i in range(self.nval_teshlT_coefs):
                f_teshlT += self.teshlT_coefs[i] * pow(self.T_sfdes - self.tdb, i)
            self.q_hl_tes = self.f_teshl_ref * self.etesmax * f_teshlX * f_teshlT
            self.e_in_tes = max(self.e_in_tes - self.q_hl_tes * self.dt, 0.0)  # Adjust the energy in thermal storage according to TES thermal losses
            if self.e_in_tes > self.etesmax:  # trying to put in more than storage can handle
                self.q_dump_tesfull = (self.e_in_tes - self.etesmax) / self.dt  # this is the amount dumped when storage is completely full
                self.e_in_tes = self.etesmax
                self.q_to_tes = self.q_to_tes - self.q_dump_tesfull
            else:
                self.q_dump_tesfull = 0.0  # nothing is dumped if not overfilled
            if self.q_to_pb < self.qttmin:
                self.q_dump_umin = self.q_to_pb
                self.q_to_pb = 0.0
                self.pbmode = 0
            else:
                self.q_dump_umin = 0.0
            self.pbmode0 = self.pbmode
        if self.q_to_pb < self.fdisp[touperiod]:
            # If the thermal power dispatched to the power cycle is less than the level in the fossil control
            self.q_fossil = self.fdisp[touperiod] - self.q_to_pb  # then the fossil used is the fossil control value minus what's provided by the solar field
            self.q_gas = self.q_fossil / self.eta_lhv  # Calculate the required fossil heat content based on the LHV efficiency
        else:
            self.q_fossil = 0.0
            self.q_gas = 0.0
        self.q_to_pb = self.q_to_pb + self.q_fossil
        var qnorm: Float64 = self.q_to_pb / self.q_des  # The normalized thermal energy flow
        var tnorm: Float64
        if self.PC_T_corr == 1.0:  # Select the dry or wet bulb temperature as the driving difference
            tnorm = self.twb - self.T_pcdes
        else:
            tnorm = self.tdb - self.T_pcdes
        self.f_effpc_qtpb = 0.0
        self.f_effpc_tamb = 0.0
        for i in range(self.nval_etaQ_coefs):
            self.f_effpc_qtpb += self.etaQ_coefs[i] * pow(qnorm, i)
        for i in range(self.nval_etaT_coefs):
            self.f_effpc_tamb += self.etaT_coefs[i] * pow(tnorm, i)
        self.eta_cycle = self.eta_des * self.f_effpc_qtpb * self.f_effpc_tamb  # Adjusted power conversion efficiency
        if self.q_to_pb <= 0.0:
            self.eta_cycle = 0.0  # Set conversion efficiency to zero when the power block isn't operating
        self.w_gr = self.q_to_pb * self.eta_cycle
        self.w_gr_solar = (self.q_to_pb - self.q_fossil) * self.eta_cycle
        self.w_par_fixed = self.f_Wpar_fixed * self.w_des  # Fixed parasitic loss based on plant capacity
        var wpar_prodq: Float64 = 0.0
        var wpar_prodt: Float64 = 0.0
        for i in range(self.nval_Wpar_prodQ_coefs):
            wpar_prodq += self.Wpar_prodQ_coefs[i] * pow(qnorm, i)  # Power block part-load correction factor
        for i in range(self.nval_Wpar_prodT_coefs):
            wpar_prodt += self.Wpar_prodT_coefs[i] * pow(tnorm, i)  # Temperature correction factor
        self.w_par_prod = self.f_Wpar_prod * self.w_gr * wpar_prodq * wpar_prodt
        self.w_par_tot = self.w_par_fixed + self.w_par_prod  # Total parasitic loss
        if self.w_gr > 0.0:
            self.w_par_online = self.w_par_tot
            self.w_par_offline = 0.0
        else:
            self.w_par_online = 0.0
            self.w_par_offline = self.w_par_tot
        self.enet = self.w_gr - self.w_par_tot
        self.declination = self.dec * self.r2d  # [deg] Declination angle
        self.hrangle = self.omega * self.r2d  # [deg] hour_of_day angle
        self.solalt = max(self.solalt * self.r2d, 0.0)  # [deg] Solar elevation angle
        self.solaz = self.solaz * self.r2d  # [deg] Solar azimuth angle (-180..180, 0deg=South)
        self.q_inc = self.f_qsf * self.irr_used  # [MWt] Qdni - Solar incident energy, before all losses
        self.q_dump_tot = self.q_dump_tesfull + self.q_dump_teschg + self.q_dump_umin  # [MWt] Total dumped energy
        self.w_gr_fossil = self.w_gr - self.w_gr_solar  # [MWe] Power produced from the fossil component
        self.value(O_IRR_USED, self.irr_used)  # [W/m2] Irradiation value used in simulation
        self.value(O_HOUR_OF_DAY, self.hour_of_day)  # [hour_of_day] hour_of_day of the day
        self.value(O_DAY_OF_YEAR, self.day_of_year)  # [day] Day of the year
        self.value(O_DECLINATION, self.declination)  # [deg] Declination angle
        self.value(O_SOLTIME, self.soltime)  # [hour_of_day] [hour_of_day] Solar time of the day
        self.value(O_HRANGLE, self.hrangle)  # [deg] hour_of_day angle
        self.value(O_SOLALT, self.solalt)  # [deg] Solar elevation angle
        self.value(O_SOLAZ, self.solaz)  # [deg] Solar azimuth angle (-180..180, 0deg=South)
        self.value(O_ETA_OPT_SF, self.eta_opt_sf)  # [none] Solar field optical efficiency
        self.value(O_F_SFHL_QDNI, self.f_sfhl_qdni)  # [none] Solar field load-based thermal loss correction
        self.value(O_F_SFHL_TAMB, self.f_sfhl_tamb)  # [none] Solar field temp.-based thermal loss correction
        self.value(O_F_SFHL_VWIND, self.f_sfhl_vwind)  # [none] Solar field wind-based thermal loss correction
        self.value(O_Q_HL_SF, self.q_hl_sf)  # [MWt] Solar field thermal losses
        self.value(O_Q_SF, self.q_sf)  # [MWt] Solar field delivered thermal power
        self.value(O_Q_INC, self.q_inc)  # [MWt] Qdni - Solar incident energy, before all losses
        self.value(O_PBMODE, self.pbmode)  # [none] Power conversion mode
        self.value(O_PBSTARTF, self.pbstartf)  # [none] Flag indicating power system startup
        self.value(O_Q_TO_PB, self.q_to_pb)  # [MWt] Thermal energy to the power conversion system
        self.value(O_Q_STARTUP, self.q_startup)  # [MWt] Power conversion startup energy
        self.value(O_Q_TO_TES, self.q_to_tes)  # [MWt] Thermal energy into storage
        self.value(O_Q_FROM_TES, self.q_from_tes)  # [MWt] Thermal energy from storage
        self.value(O_E_IN_TES, self.e_in_tes)  # [MWt-hr] Energy in storage
        self.value(O_Q_HL_TES, self.q_hl_tes)  # [MWt] Thermal losses from storage
        self.value(O_Q_DUMP_TESFULL, self.q_dump_tesfull)  # [MWt] Dumped energy  exceeding storage charge level max
        self.value(O_Q_DUMP_TESCHG, self.q_dump_teschg)  # [MWt] Dumped energy exceeding exceeding storage charge rate
        self.value(O_Q_DUMP_UMIN, self.q_dump_umin)  # [MWt] Dumped energy from falling below min. operation fraction
        self.value(O_Q_DUMP_TOT, self.q_dump_tot)  # [MWt] Total dumped energy
        self.value(O_Q_FOSSIL, self.q_fossil)  # [MWt] thermal energy supplied from aux firing
        self.value(O_Q_GAS, self.q_gas)  # [MWt] Energy content of fuel required to supply Qfos
        self.value(O_F_EFFPC_QTPB, self.f_effpc_qtpb)  # [none] Load-based conversion efficiency correction
        self.value(O_F_EFFPC_TAMB, self.f_effpc_tamb)  # [none] Temp-based conversion efficiency correction
        self.value(O_ETA_CYCLE, self.eta_cycle)  # [none] Adjusted power conversion efficiency
        self.value(O_W_GR_SOLAR, self.w_gr_solar)  # [MWe] Power produced from the solar component
        self.value(O_W_GR_FOSSIL, self.w_gr_fossil)  # [MWe] Power produced from the fossil component
        self.value(O_W_GR, self.w_gr)  # [MWe] Total gross power production
        self.value(O_W_PAR_FIXED, self.w_par_fixed)  # [MWe] Fixed parasitic losses
        self.value(O_W_PAR_PROD, self.w_par_prod)  # [MWe] Production-based parasitic losses
        self.value(O_W_PAR_TOT, self.w_par_tot)  # [MWe] Total parasitic losses
        self.value(O_W_PAR_ONLINE, self.w_par_online)  # [MWe] Online parasitics
        self.value(O_W_PAR_OFFLINE, self.w_par_offline)  # [MWe] Offline parasitics
        self.value(O_ENET, self.enet)  # [MWe] Net electric output
        return 0

    def converged(inout self, time: Float64) -> Int32:
        # 
        # -- Post-convergence call --
        # Update values that should be transferred to the next time step
        # 
        self.etes0 = self.e_in_tes
        self.pbmode0 = self.pbmode
        self.q_startup_remain = self.q_startup_used
        return 0

# TCS_IMPLEMENT_TYPE( sam_mw_gen_type260, "Generic Solar Model", "Mike Wagner", 1, sam_mw_gen_type260_variables, NULL, 1 );