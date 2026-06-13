from tcstype import *
from htf_props import *
from waterprop import *
from sam_csp_util import *

alias TCS_PARAM: Int = 0
alias TCS_INPUT: Int = 1
alias TCS_OUTPUT: Int = 2
alias TCS_INVALID: Int = 3
alias TCS_NUMBER: Int = 0
alias TCS_ARRAY: Int = 1
alias TCS_MATRIX: Int = 2

@value
struct tcsvarinfo:
    var vartype: Int
    var datatype: Int
    var index: Int
    var name: String
    var description: String
    var units: String
    var group: String
    var label: String
    var default_value: String

enum VarIndex: Int:
    P_P_REF = 0
    P_ETA_REF = 1
    P_T_HOT_REF = 2
    P_T_COLD_REF = 3
    P_DT_HX_REF = 4
    P_DT_CW_REF = 5
    P_QGEO_FRAC_REF = 6
    P_T_AMB_DES = 7
    P_Q_SBY_FRAC = 8
    P_CT = 9
    P_STARTUP_TIME = 10
    P_STARTUP_FRAC = 11
    P_T_APPROACH = 12
    P_T_ITD_DES = 13
    P_P_COND_RATIO = 14
    P_PB_BD_FRAC = 15
    P_P_COND_MIN = 16
    P_N_PL_INC = 17
    P_F_WC = 18
    P_FLUID = 19
    P_FLUID_PROPS = 20
    I_MODE = 21
    I_T_HOT = 22
    I_M_DOT_HTF = 23
    I_T_WB = 24
    I_DEMAND_VAR = 25
    I_STANDBY_CONTROL = 26
    I_T_DB = 27
    I_P_AMB = 28
    I_TOU = 29
    I_RH = 30
    I_F_RECSU = 31
    O_P_CYCLE = 32
    O_Q_SOLAR = 33
    O_Q_GEO = 34
    O_ETA = 35
    O_T_COLD = 36
    O_M_DOT_MAKEUP = 37
    O_M_DOT_DEMAND = 38
    O_M_DOT_OUT = 39
    O_M_DOT_REF = 40
    O_W_COOL_PAR = 41
    O_P_REF_OUT = 42
    O_F_BAYS = 43
    O_P_COND = 44
    N_MAX = 45

var sam_geothermal_hybrid_pb_vars: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_REF, "P_ref", "Reference output electric power at design condition", "MW", "", "", "111"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_ETA_REF, "eta_ref", "Reference conversion efficiency at design condition", "none", "", "", "0.3774"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_HOT_REF, "T_hot_ref", "Reference HTF inlet temperature at design", "C", "", "", "391"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_COLD_REF, "T_cold_ref", "Reference HTF outlet temperature at design", "C", "", "", "293"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_DT_HX_REF, "dT_hx_ref", "Reference superheater hot side temperature diff", "C", "", "", "20"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_DT_CW_REF, "dT_cw_ref", "Reference condenser cooling water inlet/outlet T diff", "C", "", "", "10"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_QGEO_FRAC_REF, "qgeo_frac_ref", "Reference geothermal power input fraction", "none", "", "", ".1"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_AMB_DES, "T_amb_des", "Reference ambient temperature at design point", "C", "", "", "20"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_Q_SBY_FRAC, "q_sby_frac", "Fraction of thermal power required for standby mode", "none", "", "", "0.2"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_CT, "CT", "Flag for using dry cooling or wet cooling system", "none", "", "", "1"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_STARTUP_TIME, "startup_time", "Time needed for power block startup", "hr", "", "", "0.5"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_STARTUP_FRAC, "startup_frac", "Fraction of design thermal power needed for startup", "none", "", "", "0.2"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_APPROACH, "T_approach", "Cooling tower approach temperature", "C", "", "", "5"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_T_ITD_DES, "T_ITD_des", "ITD at design for dry system", "C", "", "", "16"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_COND_RATIO, "P_cond_ratio", "Condenser pressure ratio", "none", "", "", "1.0028"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_PB_BD_FRAC, "pb_bd_frac", "Power block blowdown steam fraction ", "none", "", "", "0.02"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_P_COND_MIN, "P_cond_min", "Minimum condenser pressure", "inHg", "", "", "1.25"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_N_PL_INC, "n_pl_inc", "Number of part-load increments for the heat rejection system", "none", "", "", "2"),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY, VarIndex.P_F_WC, "F_wc", "Fraction indicating wet cooling use for hybrid system", "none", "9 indices for each TOU Period", "", "0,0,0,0,0,0,0,0,0"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, VarIndex.P_FLUID, "HTF", "Heat transfer fluid type", "none", "", "", "21"),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, VarIndex.P_FLUID_PROPS, "HTF_props", "User defined field fluid property data", "none", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_MODE, "mode", "Cycle part load control, from plant controller", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_HOT, "T_hot", "Hot HTF inlet temperature, from storage tank", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_M_DOT_HTF, "m_dot_htf", "HTF mass flow rate", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_WB, "T_wb", "Ambient wet bulb temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_DEMAND_VAR, "demand_var", "Control signal indicating operational mode", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_STANDBY_CONTROL, "standby_control", "Control signal indicating standby mode", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_T_DB, "T_db", "Ambient dry bulb temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_P_AMB, "P_amb", "Ambient pressure", "atm", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_TOU, "TOU", "Current Time-of-use period", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_RH, "relhum", "Relative humidity of the ambient air", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, VarIndex.I_F_RECSU, "f_recSU", "Fraction powerblock can run due to receiver startup", "none", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_CYCLE, "P_cycle", "Cycle power output", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_Q_SOLAR, "q_solar", "Thermal load from solar", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_Q_GEO, "q_geo", "Thermal load from geothermal", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_ETA, "eta", "Cycle thermal efficiency", "none", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_T_COLD, "T_cold", "Heat transfer fluid outlet temperature ", "C", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_MAKEUP, "m_dot_makeup", "Cooling water makeup flow rate", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_DEMAND, "m_dot_demand", "HTF required flow rate to meet power load", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_OUT, "m_dot_out", "Actual HTF flow rate passing through the power cycle", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_M_DOT_REF, "m_dot_ref", "Calculated reference HTF flow rate at design", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_W_COOL_PAR, "W_cool_par", "Cooling system parasitic load", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_REF_OUT, "P_ref_out", "Reference power level output at design (mirror param)", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_F_BAYS, "f_bays", "Fraction of operating heat rejection bays", "none", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, VarIndex.O_P_COND, "P_cond", "Condenser pressure", "Pa", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, VarIndex.N_MAX, "0", "0", "0", "0", "0", "0")
)

struct block_t[type: AnyType]:
    var data: List[type]
    var nx: Int
    var ny: Int
    var nz: Int

    def __init__(inout self):
        self.data = List[type]()
        self.nx = 0
        self.ny = 0
        self.nz = 0

    def __init__(inout self, arr: List[type], nx: Int, ny: Int, nz: Int):
        self.data = arr
        self.nx = nx
        self.ny = ny
        self.nz = nz

    def assign(inout self, arr: List[type], nx: Int, ny: Int, nz: Int):
        self.data = arr
        self.nx = nx
        self.ny = ny
        self.nz = nz

    def at(self, i: Int, j: Int, k: Int) -> type:
        return self.data[k * self.nx * self.ny + j * self.nx + i]

struct matrix_t[type: AnyType]:
    var data: List[type]
    var nrows: Int
    var ncols: Int

    def __init__(inout self, nrows: Int, ncols: Int, val: type):
        self.nrows = nrows
        self.ncols = ncols
        self.data = List[type](val, nrows * ncols)

    def at(self, r: Int, c: Int) -> type:
        return self.data[r * self.ncols + c]

struct lookup_range:
    var nsteps: Int
    var varmax: Float64
    var varmin: Float64
    var delta: Float64

struct sam_geothermal_hybrid_pb(tcstypeinterface):
    var m_htfProps: HTFProperties
    var wp: property_info
    var m_P_ref: Float64
    var m_eta_ref: Float64
    var m_T_hot_ref: Float64
    var m_T_cold_ref: Float64
    var m_dT_hx_ref: Float64
    var m_dT_cw_ref: Float64
    var m_T_amb_des: Float64
    var m_q_sby_frac: Float64
    var m_qgeo_frac_ref: Float64
    var m_CT: Int
    var m_startup_time: Float64
    var m_startup_frac: Float64
    var m_T_approach: Float64
    var m_T_ITD_des: Float64
    var m_P_cond_ratio: Float64
    var m_pb_bd_frac: Float64
    var m_P_cond_min: Float64
    var m_n_pl_inc: Int
    var m_F_wc: List[Float64]
    var m_HTF: Int
    var m_F_wcmin: Float64
    var m_F_wcmax: Float64
    var m_startup_energy: Float64
    var m_Psat_ref: Float64
    var m_eta_adj: Float64
    var m_q_dot_ref: Float64
    var m_q_solar_ref: Float64
    var m_q_geo_ref: Float64
    var m_m_dot_ref: Float64
    var m_q_dot_st_ref: Float64
    var m_P_boil_des: Float64
    var m_Solar_Thermal_Norm: block_t[Float64]
    var m_PB_Power_Nominal_Norm: block_t[Float64]
    var m_GeoThermal_Norm: block_t[Float64]
    var m_mdot: lookup_range
    var m_Thot: lookup_range
    var m_pcond: lookup_range
    var m_standby_control_prev: Int
    var m_standby_control: Int
    var m_time_su_prev: Float64
    var m_time_su: Float64
    var m_E_su_prev: Float64
    var m_E_su: Float64

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.m_P_ref = Float64(0/0)
        self.m_eta_ref = Float64(0/0)
        self.m_T_hot_ref = Float64(0/0)
        self.m_T_cold_ref = Float64(0/0)
        self.m_dT_hx_ref = Float64(0/0)
        self.m_dT_cw_ref = Float64(0/0)
        self.m_T_amb_des = Float64(0/0)
        self.m_q_sby_frac = Float64(0/0)
        self.m_qgeo_frac_ref = Float64(0/0)
        self.m_CT = -1
        self.m_startup_time = Float64(0/0)
        self.m_startup_frac = Float64(0/0)
        self.m_T_approach = Float64(0/0)
        self.m_T_ITD_des = Float64(0/0)
        self.m_P_cond_ratio = Float64(0/0)
        self.m_pb_bd_frac = Float64(0/0)
        self.m_P_cond_min = Float64(0/0)
        self.m_n_pl_inc = -1
        self.m_F_wc = List[Float64](Float64(0/0), 9)
        self.m_HTF = -1
        self.m_F_wcmin = Float64(0/0)
        self.m_F_wcmax = Float64(0/0)
        self.m_startup_energy = Float64(0/0)
        self.m_Psat_ref = Float64(0/0)
        self.m_eta_adj = Float64(0/0)
        self.m_q_dot_ref = Float64(0/0)
        self.m_q_solar_ref = Float64(0/0)
        self.m_q_geo_ref = Float64(0/0)
        self.m_m_dot_ref = Float64(0/0)
        self.m_standby_control_prev = -1
        self.m_standby_control = -1
        self.m_time_su_prev = Float64(0/0)
        self.m_time_su = Float64(0/0)
        self.m_E_su_prev = Float64(0/0)
        self.m_E_su = Float64(0/0)
        self.m_P_boil_des = Float64(0/0)

    def __del__(inout self):

    def init(inout self) -> Int:
        var tstep = self.time_step()
        self.m_P_ref = self.value(VarIndex.P_P_REF) * 1.0e3  # [kW] Reference output electric power at design condition
        self.m_eta_ref = self.value(VarIndex.P_ETA_REF)  # [-] Reference conversion efficiency at design condition
        self.m_T_hot_ref = self.value(VarIndex.P_T_HOT_REF)  # [C] Reference inlet temperature at design
        self.m_T_cold_ref = self.value(VarIndex.P_T_COLD_REF)  # [C] Reference outlet temperature at design
        self.m_dT_hx_ref = self.value(VarIndex.P_DT_HX_REF)  # [C] Reference hot side superheater temp diff
        self.m_dT_cw_ref = self.value(VarIndex.P_DT_CW_REF)  # [C] Reference condenser cooling water inlet/outlet Temp difference
        self.m_T_amb_des = self.value(VarIndex.P_T_AMB_DES)  # [C] Reference ambient temperature at design point
        self.m_q_sby_frac = self.value(VarIndex.P_Q_SBY_FRAC)  # [-] Fraction of thermal power required for standby mode
        self.m_qgeo_frac_ref = self.value(VarIndex.P_QGEO_FRAC_REF)  # [-] Reference geothermal power input fraction
        self.m_CT = Int(self.value(VarIndex.P_CT))  # [-] Flag for using dry cooling or wet cooling system
        self.m_startup_time = self.value(VarIndex.P_STARTUP_TIME)  # [hr] Time needed for power block startup
        self.m_startup_frac = self.value(VarIndex.P_STARTUP_FRAC)  # [-] Fraction of design thermal power needed for startup
        self.m_T_approach = self.value(VarIndex.P_T_APPROACH)  # [C] Cooling tower approach temperature
        self.m_T_ITD_des = self.value(VarIndex.P_T_ITD_DES)  # [C] ITD at design for dry system
        self.m_P_cond_ratio = self.value(VarIndex.P_P_COND_RATIO)  # [-] Condenser pressure ratio
        self.m_pb_bd_frac = self.value(VarIndex.P_PB_BD_FRAC)  # [-] Power block blowdown steam fraction
        self.m_P_cond_min = self.value(VarIndex.P_P_COND_MIN) * 3386.388667  # [inHg] Minimum condenser pressure
        self.m_n_pl_inc = Int(self.value(VarIndex.P_N_PL_INC))  # [-] Number of part-load increments for the heat rejection system
        self.m_HTF = Int(self.value(VarIndex.P_FLUID))  # [-] Heat transfer fluid number
        var F_wc_in: Pointer[Float64] = self.value_array(VarIndex.P_F_WC)  # Fraction indicating wet cooling use for hybrid system
        var nval_F_wc: Int = 9
        if nval_F_wc != 9:
            return -1
        self.m_F_wcmax = 0.0
        self.m_F_wcmin = 1.0
        for i in range(9):
            self.m_F_wc[i] = F_wc_in[i]
            self.m_F_wcmin = min(self.m_F_wcmin, self.m_F_wc[i])
            self.m_F_wcmax = max(self.m_F_wcmax, self.m_F_wc[i])
        if self.m_HTF != HTFProperties.User_defined:
            self.m_htfProps.SetFluid(self.m_HTF)
        else:
            var nrows: Int = 0
            var ncols: Int = 0
            var fl_mat: Pointer[Float64] = self.value_matrix(VarIndex.P_FLUID_PROPS, &nrows, &ncols)
            if fl_mat != nil and nrows > 2 and ncols == 7:
                var mat = matrix_t[Float64](nrows, ncols, 0.0)
                for r in range(nrows):
                    for c in range(ncols):
                        mat.at(r, c) = TCS_MATRIX_INDEX(self.var(VarIndex.P_FLUID_PROPS), r, c)
                if not self.m_htfProps.SetUserDefinedFluid(mat):
                    self.message(self.m_htfProps.UserFluidErrMessage(), nrows, ncols)
                    return -1
        self.m_P_boil_des = 75.0  # bar -- from the IpsePro simulations
        self.m_startup_energy = self.m_startup_frac * self.m_P_ref / self.m_eta_ref  # [kWt]
        self.m_standby_control_prev = 3
        self.m_time_su_prev = self.m_startup_time
        self.m_E_su_prev = self.m_startup_energy
        self.m_time_su = self.m_time_su_prev
        self.m_E_su = self.m_E_su_prev
        self.Set_PB_coefficients()
        self.Set_PB_ref_values()
        return 0

    def Set_PB_coefficients(inout self):
        /* 
        Design mass flow rate: 106.1 kg/s
        Design T_in: 375 C
        Design P_condensing: 0.102 bar
        */
        self.m_mdot.nsteps = 6
        self.m_mdot.varmax = 1.0
        self.m_mdot.varmin = 59.8 / 119.6
        self.m_mdot.delta = (self.m_mdot.varmax - self.m_mdot.varmin) / (Float64(self.m_mdot.nsteps) - 1.0)
        self.m_pcond.nsteps = 15
        self.m_pcond.varmax = 20000.0
        self.m_pcond.varmin = 6000.0
        self.m_pcond.delta = (self.m_pcond.varmax - self.m_pcond.varmin) / (Float64(self.m_pcond.nsteps) - 1.0)
        self.m_Thot.nsteps = 3
        self.m_Thot.varmax = 375.0
        self.m_Thot.varmin = 325.0
        self.m_Thot.delta = (self.m_Thot.varmax - self.m_Thot.varmin) / (Float64(self.m_Thot.nsteps) - 1.0)
        const Solar_Thermal_Norm_data: List[Float64] = List[Float64](
            # blocks for constant turbine inlet temperature
            0.5281, 0.6226, 0.7145, 0.8041, 0.8913, 0.9764,
            0.5281, 0.6226, 0.7145, 0.8041, 0.8913, 0.9764,
            0.5281, 0.6226, 0.7145, 0.8041, 0.8914, 0.9764,
            0.5281, 0.6226, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6226, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6226, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6226, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6226, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6225, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6225, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6225, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6225, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6225, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6225, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5281, 0.6225, 0.7145, 0.8041, 0.8914, 0.9765,
            0.5328, 0.6284, 0.7217, 0.8127, 0.9017, 0.9888,
            0.5328, 0.6284, 0.7217, 0.8127, 0.9018, 0.9888,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8128, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7217, 0.8127, 0.9018, 0.9889,
            0.5328, 0.6284, 0.7216, 0.8127, 0.9018, 0.9889,
            0.5327, 0.6284, 0.7216, 0.8127, 0.9018, 0.9889,
            0.5375, 0.6343, 0.7288, 0.8212, 0.9117, 1.0003,
            0.5375, 0.6343, 0.7288, 0.8212, 0.9117, 1.0003,
            0.5375, 0.6343, 0.7288, 0.8212, 0.9117, 1.0003,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0003,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8213, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8212, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8212, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8212, 0.9117, 1.0004,
            0.5375, 0.6343, 0.7288, 0.8212, 0.9117, 1.0004
        )  # end of data.
        self.m_Solar_Thermal_Norm.assign(Solar_Thermal_Norm_data, self.m_pcond.nsteps, self.m_mdot.nsteps, self.m_Thot.nsteps)

        const PB_Power_Nominal_Norm_data: List[Float64] = List[Float64](
            # blocks for constant turbine inlet temperature
            0.5140, 0.6113, 0.7050, 0.7948, 0.8818, 0.9663,
            0.5088, 0.6073, 0.7020, 0.7932, 0.8807, 0.9653,
            0.5018, 0.6024, 0.6981, 0.7901, 0.8787, 0.9641,
            0.4939, 0.5961, 0.6935, 0.7862, 0.8756, 0.9618,
            0.4854, 0.5889, 0.6874, 0.7818, 0.8717, 0.9586,
            0.4770, 0.5808, 0.6805, 0.7762, 0.8674, 0.9548,
            0.4692, 0.5723, 0.6730, 0.7697, 0.8621, 0.9504,
            0.4615, 0.5640, 0.6650, 0.7625, 0.8558, 0.9454,
            0.4545, 0.5562, 0.6566, 0.7546, 0.8489, 0.9393,
            0.4475, 0.5486, 0.6484, 0.7465, 0.8415, 0.9327,
            0.4410, 0.5414, 0.6407, 0.7383, 0.8338, 0.9258,
            0.4345, 0.5345, 0.6331, 0.7303, 0.8255, 0.9180,
            0.4280, 0.5277, 0.6259, 0.7226, 0.8175, 0.9104,
            0.4220, 0.5214, 0.6191, 0.7152, 0.8095, 0.9020,
            0.4164, 0.5151, 0.6122, 0.7078, 0.8019, 0.8942,
            0.5232, 0.6226, 0.7184, 0.8107, 0.9003, 0.9876,
            0.5180, 0.6186, 0.7154, 0.8090, 0.8992, 0.9866,
            0.5110, 0.6137, 0.7115, 0.8059, 0.8972, 0.9855,
            0.5031, 0.6074, 0.7070, 0.8021, 0.8941, 0.9832,
            0.4946, 0.6002, 0.7010, 0.7977, 0.8903, 0.9800,
            0.4863, 0.5921, 0.6941, 0.7921, 0.8859, 0.9762,
            0.4784, 0.5836, 0.6865, 0.7856, 0.8807, 0.9719,
            0.4708, 0.5754, 0.6786, 0.7785, 0.8744, 0.9669,
            0.4637, 0.5675, 0.6701, 0.7706, 0.8675, 0.9609,
            0.4567, 0.5599, 0.6620, 0.7625, 0.8602, 0.9543,
            0.4503, 0.5527, 0.6542, 0.7543, 0.8524, 0.9474,
            0.4438, 0.5458, 0.6467, 0.7462, 0.8442, 0.9396,
            0.4373, 0.5390, 0.6394, 0.7385, 0.8362, 0.9321,
            0.4312, 0.5327, 0.6326, 0.7311, 0.8282, 0.9237,
            0.4256, 0.5264, 0.6257, 0.7238, 0.8206, 0.9159,
            0.5326, 0.6343, 0.7323, 0.8268, 0.9188, 1.0086,
            0.5274, 0.6303, 0.7293, 0.8251, 0.9177, 1.0076,
            0.5205, 0.6254, 0.7254, 0.8221, 0.9158, 1.0065,
            0.5126, 0.6191, 0.7209, 0.8182, 0.9126, 1.0043,
            0.5041, 0.6119, 0.7149, 0.8138, 0.9089, 1.0011,
            0.4958, 0.6038, 0.7080, 0.8084, 0.9045, 0.9973,
            0.4879, 0.5953, 0.7005, 0.8018, 0.8993, 0.9930,
            0.4802, 0.5871, 0.6926, 0.7947, 0.8930, 0.9880,
            0.4732, 0.5792, 0.6841, 0.7868, 0.8862, 0.9821,
            0.4662, 0.5716, 0.6759, 0.7788, 0.8789, 0.9755,
            0.4597, 0.5644, 0.6681, 0.7705, 0.8711, 0.9686,
            0.4532, 0.5575, 0.6606, 0.7625, 0.8629, 0.9609,
            0.4467, 0.5507, 0.6533, 0.7548, 0.8549, 0.9534,
            0.4407, 0.5444, 0.6465, 0.7474, 0.8469, 0.9450,
            0.4350, 0.5381, 0.6396, 0.7400, 0.8392, 0.9371
        )  # end of data.
        self.m_PB_Power_Nominal_Norm.assign(PB_Power_Nominal_Norm_data, self.m_pcond.nsteps, self.m_mdot.nsteps, self.m_Thot.nsteps)

        const GeoThermal_Norm_data: List[Float64] = List[Float64](
            # blocks for constant turbine inlet temperature
            0.5876, 0.6935, 0.7973, 0.8992, 0.9991, 1.0973,
            0.5721, 0.6752, 0.7762, 0.8754, 0.9727, 1.0683,
            0.5584, 0.6590, 0.7576, 0.8545, 0.9494, 1.0428,
            0.5461, 0.6445, 0.7410, 0.8357, 0.9286, 1.0198,
            0.5349, 0.6314, 0.7258, 0.8186, 0.9096, 0.9990,
            0.5247, 0.6193, 0.7120, 0.8030, 0.8922, 0.9799,
            0.5152, 0.6081, 0.6991, 0.7885, 0.8762, 0.9623,
            0.5064, 0.5977, 0.6872, 0.7751, 0.8612, 0.9459,
            0.4981, 0.5879, 0.6760, 0.7625, 0.8472, 0.9305,
            0.4903, 0.5787, 0.6655, 0.7506, 0.8341, 0.9161,
            0.4832, 0.5703, 0.6557, 0.7393, 0.8213, 0.9018,
            0.4763, 0.5622, 0.6463, 0.7288, 0.8096, 0.8890,
            0.4697, 0.5545, 0.6375, 0.7188, 0.7985, 0.8768,
            0.4635, 0.5471, 0.6290, 0.7092, 0.7879, 0.8652,
            0.4575, 0.5401, 0.6209, 0.7001, 0.7778, 0.8541,
            0.5881, 0.6944, 0.7986, 0.9011, 1.0020, 1.1014,
            0.5726, 0.6761, 0.7775, 0.8773, 0.9755, 1.0723,
            0.5589, 0.6599, 0.7589, 0.8563, 0.9522, 1.0466,
            0.5466, 0.6454, 0.7422, 0.8375, 0.9313, 1.0236,
            0.5354, 0.6322, 0.7271, 0.8204, 0.9123, 1.0027,
            0.5251, 0.6201, 0.7132, 0.8047, 0.8948, 0.9835,
            0.5157, 0.6089, 0.7003, 0.7902, 0.8787, 0.9658,
            0.5068, 0.5985, 0.6883, 0.7768, 0.8637, 0.9494,
            0.4986, 0.5887, 0.6771, 0.7641, 0.8497, 0.9339,
            0.4908, 0.5795, 0.6666, 0.7523, 0.8365, 0.9194,
            0.4836, 0.5711, 0.6568, 0.7409, 0.8237, 0.9051,
            0.4767, 0.5629, 0.6474, 0.7304, 0.8120, 0.8923,
            0.4702, 0.5552, 0.6385, 0.7204, 0.8008, 0.8800,
            0.4639, 0.5478, 0.6300, 0.7108, 0.7902, 0.8683,
            0.4580, 0.5408, 0.6219, 0.7016, 0.7800, 0.8572,
            0.5887, 0.6953, 0.7998, 0.9028, 1.0042, 1.1042,
            0.5731, 0.6769, 0.7787, 0.8790, 0.9777, 1.0750,
            0.5594, 0.6607, 0.7601, 0.8579, 0.9543, 1.0493,
            0.5471, 0.6461, 0.7433, 0.8391, 0.9333, 1.0262,
            0.5359, 0.6329, 0.7282, 0.8219, 0.9143, 1.0053,
            0.5256, 0.6208, 0.7142, 0.8062, 0.8968, 0.9861,
            0.5161, 0.6096, 0.7014, 0.7917, 0.8806, 0.9683,
            0.5073, 0.5992, 0.6894, 0.7782, 0.8656, 0.9518,
            0.4990, 0.5894, 0.6782, 0.7656, 0.8516, 0.9363,
            0.4912, 0.5802, 0.6676, 0.7537, 0.8383, 0.9218,
            0.4838, 0.5717, 0.6578, 0.7424, 0.8259, 0.9081,
            0.4768, 0.5636, 0.6484, 0.7317, 0.8140, 0.8951,
            0.4702, 0.5559, 0.6395, 0.7216, 0.8027, 0.8827,
            0.4643, 0.5485, 0.6310, 0.7119, 0.7920, 0.8709,
            0.4584, 0.5414, 0.6229, 0.7027, 0.7817, 0.8596
        )  # end of data.
        self.m_GeoThermal_Norm.assign(GeoThermal_Norm_data, self.m_pcond.nsteps, self.m_mdot.nsteps, self.m_Thot.nsteps)

    def Set_PB_ref_values(inout self) -> Bool:
        /*The user provides a reference efficiency, ambient temperature, and cooling system parameters. Using
        this information, we have to adjust the provided reference efficiency to match the normalized efficiency
        that is part of the power block regression coefficients. I.e. if the user provides a ref. ambient temperature
        of 25degC, but the power block coefficients indicate that the normalized efficiency equals 1.0 at an ambient 
        temp of 20degC, we have to adjust the user's efficiency value back to the coefficient set.*/
        if self.m_CT == 1:
            water_TQ(self.m_dT_cw_ref + 3.0 + self.m_T_approach + self.m_T_amb_des, 1.0, &self.wp)
            self.m_Psat_ref = self.wp.P * 1000.0  # [Pa]
        elif self.m_CT == 2 or self.m_CT == 3:
            water_TQ(self.m_T_ITD_des + self.m_T_amb_des, 1.0, &self.wp)
            self.m_Psat_ref = self.wp.P * 1000.0  # [Pa]
        var qtot = self.m_P_ref / self.m_eta_ref  # total thermal contribution includes both solar and geothermal sources
        var qndtot = 1.0 + self.m_qgeo_frac_ref  # the total non-dimensional thermal fraction includes the solar fraction (1) plus the fraction of geothermal relative to solar (qgeo/qsolar)
        var qsol_nd_ref = 1.0 / qndtot  # The actual fraction of thermal energy supplied by solar at design
        var qgeo_nd_ref = self.m_qgeo_frac_ref / qndtot  # The actual fraction thermal energy supplied by geothermal at design
        self.m_q_solar_ref = qsol_nd_ref * qtot  # The dimensional amount of thermal energy supplied by solar at design
        self.m_q_geo_ref = qgeo_nd_ref * qtot  # The dimensional amount of thermal energy supplied by geothermal at design
        var wnet_nd_adj: Float64
        var qsol_nd_adj: Float64
        var qgeo_nd_adj: Float64
        self.CycleMap(self.m_Psat_ref, self.m_T_hot_ref - self.m_dT_hx_ref, 1.0, wnet_nd_adj, qsol_nd_adj, qgeo_nd_adj)  # Look up the performance at the specified design-point condenser condition
        var qfrac = (qsol_nd_adj * self.m_q_solar_ref + qgeo_nd_adj * self.m_q_geo_ref) / qtot  # What is fraction of total thermal energy
        self.m_eta_adj = self.m_eta_ref * qfrac / wnet_nd_adj  # The reference efficiency, adjusted for the user-specified condenser conditions
        self.m_q_dot_ref = self.m_P_ref / self.m_eta_adj  # [kW] The reference heat flow
        var c_htf_ref = self.m_htfProps.Cp((self.m_T_hot_ref + self.m_T_cold_ref) / 2.0 + 273.15)
        self.m_m_dot_ref = self.m_q_solar_ref / (c_htf_ref * (self.m_T_hot_ref - self.m_T_cold_ref))
        return True

    def CycleMap(self, pcond: Float64, Tin: Float64, mdot_ND: Float64, inout wnet_ND: Float64, inout qsolar_ND: Float64, inout qgeo_ND: Float64) -> Bool:
        /* 
        Evaluate the cycle performance map using the inputs provided. 
        INPUTS:
        pcond		[Pa]	Condenser inlet pressure
        Tin			[C]		Solar field HTF inlet temperature
        mdot_ND		[-]		Non-dimensional mass flow rate of solar field HTF to the cycle
        ---- Variables set by this method ----
        wnet_ND		[-]		Fraction of design-point power provided by the cycle
        qsolar_ND	[-]		Fraction of design-point heat contributed by the solar field, relative to design solar contribution ONLY
        qgeo_ND		[-]		Fraction of design-point heat contributed by the geothermal heat source, relative to design geothermal contribution ONLY
        RETURNS:
        BOOL	Did the method successfully set output variables?
        */
        try:
            var find_pcond = (pcond - self.m_pcond.varmin) / self.m_pcond.delta
            var find_mdot = (mdot_ND - self.m_mdot.varmin) / self.m_mdot.delta
            var find_Thot = (Tin - self.m_Thot.varmin) / self.m_Thot.delta
            var ilo_pcond = min(max(0, Int(find_pcond)), self.m_pcond.nsteps - 2)
            var ilo_mdot = min(max(0, Int(find_mdot)), self.m_mdot.nsteps - 2)
            var ilo_Thot = min(max(0, Int(find_Thot)), self.m_Thot.nsteps - 2)
            var f_pcond = find_pcond - Float64(ilo_pcond)
            var f_mdot = find_mdot - Float64(ilo_mdot)
            var f_Thot = find_Thot - Float64(ilo_Thot)
            var datas: List[Pointer[block_t[Float64]]] = List[Pointer[block_t[Float64]]](&self.m_PB_Power_Nominal_Norm, &self.m_Solar_Thermal_Norm, &self.m_GeoThermal_Norm)
            var outputs: List[Pointer[Float64]] = List[Pointer[Float64]](&wnet_ND, &qsolar_ND, &qgeo_ND)
            for d in range(len(datas)):
                var dat: block_t[Float64] = datas[d][]
                var intcube: List[List[List[Float64]]] = List[List[List[Float64]]]()
                for i in range(ilo_Thot, ilo_Thot + 2):
                    var iuse = min(i, self.m_Thot.nsteps - 1)
                    var row_mdot: List[List[Float64]] = List[List[Float64]]()
                    for j in range(ilo_mdot, ilo_mdot + 2):
                        var juse = min(j, self.m_mdot.nsteps - 1)
                        var col_pcond: List[Float64] = List[Float64]()
                        for k in range(ilo_pcond, ilo_pcond + 2):
                            var kuse = min(k, self.m_pcond.nsteps - 1)
                            col_pcond.append(dat.at(kuse, juse, iuse))
                        row_mdot.append(col_pcond)
                    intcube.append(row_mdot)
                var intsquare: List[List[Float64]] = List[List[Float64]](2, List[Float64](2, 0.0))
                for j in range(2):
                    for k in range(2):
                        intsquare[j][k] = intcube[0][j][k] + (intcube[1][j][k] - intcube[0][j][k]) * f_Thot
                var intline: List[Float64] = List[Float64](2, 0.0)
                for k in range(2):
                    intline[k] = intsquare[0][k] + (intsquare[1][k] - intsquare[0][k]) * f_mdot
                outputs[d][] = intline[0] + (intline[1] - intline[0]) * f_pcond
        except:
            return False
        return True

    def GeoCSP_RankineCycle(self, T_db: Float64, T_wb: Float64, P_amb: Float64, T_hot: Float64, m_dot_htf: Float64, mode: Int, demand_var: Float64, F_wc_tou: Float64,
                            inout P_cycle: Float64, inout Q_solar: Float64, inout Q_geo: Float64, inout eta: Float64, inout T_cold: Float64, inout m_dot_demand: Float64, inout m_dot_makeup: Float64,
                            inout W_cool_par: Float64, inout f_hrsys: Float64, inout P_cond: Float64) -> Bool:
        var m_dot_htf_local = m_dot_htf / 3600.0  # [kg/s] Mass flow rate, convert from [kg/hr]
        var m_dot_ND = m_dot_htf_local / self.m_m_dot_ref
        water_PQ(self.m_P_boil_des * 100.0, 0.5, &self.wp)
        var T_ref = self.wp.T
        var T_hot_ND = (T_hot - T_ref) / (self.m_T_hot_ref - T_ref)
        var q_reject_est = self.m_q_dot_ref * 1000.0 * (1.0 - self.m_eta_adj) * m_dot_ND * T_hot_ND
        var T_cond: Float64
        var m_dot_air: Float64
        var W_cool_parhac: Float64
        var W_cool_parhwc: Float64
        if self.m_CT == 1:
            CSP.evap_tower(1, self