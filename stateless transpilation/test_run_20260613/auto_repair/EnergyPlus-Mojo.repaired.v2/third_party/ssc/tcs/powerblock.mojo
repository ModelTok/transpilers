//  BSD-3-Clause
//  Copyright 2019 Alliance for Sustainable Energy, LLC
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided
//  that the following conditions are met :
//  1.	Redistributions of source code must retain the above copyright notice, this list of conditions
//  and the following disclaimer.
//  2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
//  and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse
//  or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
//  DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
//  OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from htf_props import HTFProperties
from lib_util import util
from lib_physics import physics
from water_properties import water_state, water_TP, water_PQ, water_TQ
from sam_csp_util import CSP

struct S_Indirect_PB_Parameters:
    var P_ref: Float64                     # design electric power output (MW)
    var eta_ref: Float64                   # design conversion efficiency (%)
    var T_htf_hot_ref: Float64             # design HTF inlet temperature (deg C)
    var T_htf_cold_ref: Float64            # design HTF output temperature (deg C)
    var dT_cw_ref: Float64                 # design temp difference between cooling water inlet/outlet (C)
    var T_amb_des: Float64                 # design ambient temperature (C)
    var htfProps: HTFProperties            # class for HTF props
    var q_sby_frac: Float64                # fraction of thermal power required for standby mode (%)
    var P_boil: Float64                    # boiler operating pressure (bar)
    var CT: Int32                          # integer flag for cooling technology type {1=evaporative cooling, 2=air cooling, 3=hybrid cooling}
    var startup_time: Float64              # time needed for power block startup (hours)
    var startup_frac: Float64              # fraction of design thermal power needed for startup (%)
    var tech_type: Int32                   # Flag indicating which coef. set to use. (1=tower,2=trough,3=user)
    var T_approach: Float64                # cooling tower approach temp (C)
    var T_ITD_des: Float64                 # design ITD for dry system (C)
    var P_cond_ratio: Float64              # condenser pressure ratio
    var pb_bd_frac: Float64                # blowdown steam fraction (%)
    var P_cond_min: Float64                # minimum condenser pressure (inches Hg)
    var n_pl_inc: Int32                    # Number of part-load increments for the heat rejection system
    var F_wc: SIMD[Float64, 9]            # hybrid cooling dispatch fractions 1 thru 9 (array index 0-8)

    def __init__(inout self):
        self.P_ref = 0.0
        self.eta_ref = 0.0
        self.T_htf_hot_ref = 0.0
        self.T_htf_cold_ref = 0.0
        self.dT_cw_ref = 0.0
        self.T_amb_des = 0.0
        self.htfProps = HTFProperties()
        self.q_sby_frac = 0.0
        self.P_boil = 0.0
        self.CT = 0
        self.startup_time = 0.0
        self.startup_frac = 0.0
        self.tech_type = 0
        self.T_approach = 0.0
        self.T_ITD_des = 0.0
        self.P_cond_ratio = 0.0
        self.pb_bd_frac = 0.0
        self.P_cond_min = 0.0
        self.n_pl_inc = 0
        for i in range(9):
            self.F_wc[i] = 0.0

struct S_Indirect_PB_Inputs:
    var mode: Int32                        # 1| mode | Cycle part load control, from plant controller | none | none
    var T_htf_hot: Float64                 # 2| T_htf_hot | Hot HTF inlet temperature, from storage tank | C | K
    var m_dot_htf: Float64                 # 3| m_dot_htf | HTF mass flow rate | kg/hr | kg/hr
    var T_wb: Float64                      # 4| T_wb | Ambient wet bulb temperature | C | C
    var demand_var: Float64                # 5| demand_var | Control signal indicating operational mode | none | none
    var standby_control: Int32            # 6| standby_control | Control signal indicating standby mode (1=norm,2=standby,3=shutdown) | none | none
    var T_db: Float64                      # 7| T_db | Ambient dry bulb temperature | C | C
    var P_amb: Float64                     # 8| P_amb | Ambient pressure | atm | Pa
    var TOU: Int32                         # 9| TOU | Current Time-of-use period (0-8, for hybrid cooling only) | none | none
    var rel_humidity: Float64              #10| | Relative humidity of the ambient air | none | none

    def __init__(inout self):
        self.mode = 0
        self.standby_control = 0
        self.TOU = 0
        self.T_htf_hot = 0.0
        self.m_dot_htf = 0.0
        self.T_wb = 0.0
        self.demand_var = 0.0
        self.T_db = 0.0
        self.P_amb = 0.0
        self.rel_humidity = 0.0

struct S_Indirect_PB_Outputs:
    var P_cycle: Float64                   #  1| P_cycle | Cycle power output | MWe | kWe
    var eta: Float64                       #  2| eta | Cycle thermal efficiency | none | none
    var T_htf_cold: Float64                #  3| T_htf_cold | Heat transfer fluid outlet temperature | C | C
    var m_dot_makeup: Float64              #  4| m_dot_makeup | Cooling water makeup flow rate | kg/hr | kg/s
    var m_dot_demand: Float64              #  5| m_dot_demand | HTF required flow rate to meet power load | kg/hr | kg/hr
    var m_dot_htf: Float64                 #  6| m_dot_htf | Actual HTF flow rate passing through the power cycle | kg/hr | kg/hr
    var m_dot_htf_ref: Float64             #  7| m_dot_htf_ref | Calculated reference HTF flow rate at design | kg/hr | kg/hr
    var W_cool_par: Float64                #  8| W_cool_par | Cooling system parasitic load | MWe | MWe
    var P_ref: Float64                     #  9| P_ref | Reference power level output at design (mirror param) | MWe | kWe
    var f_hrsys: Float64                   # 10| f_hrsys | Fraction of operating heat rejection system | none | none
    var P_cond: Float64                    # 11| P_cond | Condenser pressure | Pa | Pa

    def __init__(inout self):
        self.P_cycle = 0.0
        self.eta = 0.0
        self.T_htf_cold = 0.0
        self.m_dot_makeup = 0.0
        self.m_dot_demand = 0.0
        self.m_dot_htf = 0.0
        self.m_dot_htf_ref = 0.0
        self.W_cool_par = 0.0
        self.P_ref = 0.0
        self.f_hrsys = 0.0
        self.P_cond = 0.0

struct S_Indirect_PB_Stored:  // these values are stored from timestep to timestep, only updated when the timestep changes
    var iLastStandbyControl: Int32
    var dStartupTimeRemaining: Float64
    var dLastP_Cycle: Float64
    var dStartupEnergyRemaining: Float64

    def __init__(inout self):
        self.iLastStandbyControl = 0
        self.dStartupTimeRemaining = 0.0
        self.dLastP_Cycle = 0.0
        self.dStartupEnergyRemaining = 0.0

struct C_Indirect_PB:
    var m_lCurrentSecondsFromStart: Int
    var m_dHoursSinceLastStep: Float64
    var m_iLastStandbyControl: Int32        //=STORED(1)
    var m_dStartupRemain: Float64           //=STORED(2)
    var m_dLastPCycle: Float64              //=STORED(3)
    var m_dStartupERemain: Float64          //=STORED(4)
    var m_dStartupEnergy: Float64
    var m_dDeltaEnthalpySteam: Float64
    var m_F_wcMin: Float64
    var m_F_wcMax: Float64
    var m_strWarningMsg: String
    var m_strLastError: String
    var m_pbi: S_Indirect_PB_Inputs
    var m_pbp: S_Indirect_PB_Parameters
    var m_pbo: S_Indirect_PB_Outputs
    var m_sv: S_Indirect_PB_Stored
    var m_db: List[List[Float64]]
    var m_bInitialized: Bool
    var m_bFirstCall: Bool
    var eta_adj: Float64
    var T_hot_diff: Float64
    var eta_acfan_s: Float64
    var eta_acfan: Float64
    var C_air: Float64
    var drift_loss_frac: Float64
    var blowdown_frac: Float64
    var dP_evap: Float64
    var eta_pump: Float64
    var eta_pcw_s: Float64
    var eta_wcfan: Float64
    var eta_wcfan_s: Float64
    var P_ratio_wcfan: Float64
    var mass_ratio_wcfan: Float64
    var Q_reject_des: Float64
    var q_ac_des: Float64
    var m_dot_acair_des: Float64
    var q_wc_des: Float64
    var c_cw: Float64
    var m_dot_cw_des: Float64

    def __init__(inout self):
        // inputs
        self.m_pbi.demand_var = 0.0
        self.m_pbi.m_dot_htf = 0.0
        self.m_pbi.mode = 0
        self.m_pbi.P_amb = 0.0
        self.m_pbi.standby_control = 0
        self.m_pbi.T_db = 0.0
        self.m_pbi.T_htf_hot = 0.0
        self.m_pbi.T_wb = 0.0
        self.m_pbi.TOU = 0
        self.m_pbo.P_cycle = 0.0
        self.m_pbo.eta = 0.0
        self.m_pbo.T_htf_cold = 0.0
        self.m_pbo.m_dot_demand = 0.0
        self.m_pbo.m_dot_makeup = 0.0
        self.m_pbo.W_cool_par = 0.0
        self.m_pbo.f_hrsys = 0.0
        self.m_pbo.P_cond = 0.0
        self.m_pbo.m_dot_htf = 0.0
        self.m_pbo.m_dot_htf_ref = 0.0
        self.m_pbo.P_ref = 0.0
        self.m_bInitialized = False
        self.m_bFirstCall = True
        self.m_dDeltaEnthalpySteam = 0.0
        self.m_iLastStandbyControl = 0
        self.m_dLastPCycle = 0.0
        self.m_dStartupEnergy = 0.0
        self.m_dStartupERemain = 0.0
        self.m_dStartupRemain = 0.0
        self.m_lCurrentSecondsFromStart = 0  // hours
        self.m_F_wcMax = 0.0
        self.m_F_wcMin = 0.0
        self.m_strLastError = ""
        self.m_strWarningMsg = ""
        self.m_sv.dLastP_Cycle = 0.0
        self.m_sv.dStartupEnergyRemaining = 0.0
        self.m_sv.dStartupTimeRemaining = 0.0
        self.m_sv.iLastStandbyControl = 1

    def InitializeForParameters(inout self, pbp: S_Indirect_PB_Parameters) -> Bool:
        self.m_bInitialized = False
        self.m_pbp = pbp
        if self.m_pbp.tech_type == 1:
            //	Power tower applications
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.20000, 0.25263, 0.30526, 0.35789, 0.41053, 0.46316, 0.51579, 0.56842, 0.62105, 0.67368, 0.72632, 0.77895, 0.83158, 0.88421, 0.93684, 0.98947, 1.04211, 1.09474, 1.14737, 1.20000],
                [0.16759, 0.21750, 0.26932, 0.32275, 0.37743, 0.43300, 0.48910, 0.54545, 0.60181, 0.65815, 0.71431, 0.77018, 0.82541, 0.88019, 0.93444, 0.98886, 1.04378, 1.09890, 1.15425, 1.20982],
                [0.19656, 0.24969, 0.30325, 0.35710, 0.41106, 0.46497, 0.51869, 0.57215, 0.62529, 0.67822, 0.73091, 0.78333, 0.83526, 0.88694, 0.93838, 0.98960, 1.04065, 1.09154, 1.14230, 1.19294],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [1.07401, 1.04917, 1.03025, 1.01488, 1.00201, 0.99072, 0.98072, 0.97174, 0.96357, 0.95607, 0.94914, 0.94269, 0.93666, 0.93098, 0.92563, 0.92056, 0.91573, 0.91114, 0.90675, 0.90255],
                [1.00880, 1.00583, 1.00355, 1.00168, 1.00010, 0.99870, 0.99746, 0.99635, 0.99532, 0.99438, 0.99351, 0.99269, 0.99193, 0.99121, 0.99052, 0.98988, 0.98926, 0.98867, 0.98810, 0.98756],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [0.09403, 0.16542, 0.23861, 0.31328, 0.38901, 0.46540, 0.54203, 0.61849, 0.69437, 0.76928, 0.84282, 0.91458, 0.98470, 1.05517, 1.12536, 1.19531, 1.26502, 1.33450, 1.40376, 1.47282],
                [0.10659, 0.18303, 0.25848, 0.33316, 0.40722, 0.48075, 0.55381, 0.62646, 0.69873, 0.77066, 0.84228, 0.91360, 0.98464, 1.05542, 1.12596, 1.19627, 1.26637, 1.33625, 1.40593, 1.47542],
                [0.20000, 0.25263, 0.30526, 0.35789, 0.41053, 0.46316, 0.51579, 0.56842, 0.62105, 0.67368, 0.72632, 0.77895, 0.83158, 0.88421, 0.93684, 0.98947, 1.04211, 1.09474, 1.14737, 1.20000],
                [1.03323, 1.04058, 1.04456, 1.04544, 1.04357, 1.03926, 1.03282, 1.02446, 1.01554, 1.00944, 1.00487, 1.00169, 0.99986, 0.99926, 0.99980, 1.00027, 1.00021, 1.00015, 1.00006, 0.99995],
                [0.98344, 0.98630, 0.98876, 0.99081, 0.99247, 0.99379, 0.99486, 0.99574, 0.99649, 0.99716, 0.99774, 0.99826, 0.99877, 0.99926, 0.99972, 1.00017, 1.00060, 1.00103, 1.00143, 1.00182],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [0.99269, 0.99520, 0.99718, 0.99882, 1.00024, 1.00150, 1.00264, 1.00368, 1.00464, 1.00554, 1.00637, 1.00716, 1.00790, 1.00840, 1.00905, 1.00965, 1.01022, 1.01075, 1.01126, 1.01173],
                [0.99768, 0.99861, 0.99933, 0.99992, 1.00043, 1.00087, 1.00127, 1.00164, 1.00197, 1.00227, 1.00255, 1.00282, 1.00307, 1.00331, 1.00353, 1.00375, 1.00395, 1.00415, 1.00433, 1.00451],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [1.00812, 1.00513, 1.00294, 1.00128, 0.99980, 0.99901, 0.99855, 0.99836, 0.99846, 0.99883, 0.99944, 1.00033, 1.00042, 1.00056, 1.00069, 1.00081, 1.00093, 1.00104, 1.00115, 1.00125],
                [1.09816, 1.07859, 1.06487, 1.05438, 1.04550, 1.03816, 1.03159, 1.02579, 1.02061, 1.01587, 1.01157, 1.00751, 1.00380, 1.00033, 0.99705, 0.99400, 0.99104, 0.98832, 0.98565, 0.98316]
            )
            self.m_db = dTemp
        elif self.m_pbp.tech_type == 2:
            //  Low temperature parabolic trough applications
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000],
                [0.08547, 0.14823, 0.21378, 0.28166, 0.35143, 0.42264, 0.49482, 0.56747, 0.64012, 0.71236, 0.78378, 0.85406, 0.92284, 0.98989, 1.05685, 1.12369, 1.19018, 1.25624, 1.32197, 1.38744],
                [0.10051, 0.16934, 0.23822, 0.30718, 0.37623, 0.44534, 0.51443, 0.58338, 0.65209, 0.72048, 0.78848, 0.85606, 0.92317, 0.98983, 1.05604, 1.12182, 1.18718, 1.25200, 1.31641, 1.38047],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [1.08827, 1.06020, 1.03882, 1.02145, 1.00692, 0.99416, 0.98288, 0.97273, 0.96350, 0.95504, 0.94721, 0.93996, 0.93314, 0.92673, 0.92069, 0.91496, 0.90952, 0.90433, 0.89938, 0.89464],
                [1.01276, 1.00877, 1.00570, 1.00318, 1.00106, 0.99918, 0.99751, 0.99601, 0.99463, 0.99335, 0.99218, 0.99107, 0.99004, 0.98907, 0.98814, 0.98727, 0.98643, 0.98563, 0.98487, 0.98413],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [0.09307, 0.16421, 0.23730, 0.31194, 0.38772, 0.46420, 0.54098, 0.61763, 0.69374, 0.76896, 0.84287, 0.91511, 0.98530, 1.05512, 1.12494, 1.19447, 1.26373, 1.33273, 1.40148, 1.46999],
                [0.10741, 0.18443, 0.26031, 0.33528, 0.40950, 0.48308, 0.55610, 0.62861, 0.70066, 0.77229, 0.84354, 0.91443, 0.98497, 1.05520, 1.12514, 1.19478, 1.26416, 1.33329, 1.40217, 1.47081],
                [0.10000, 0.16842, 0.23684, 0.30526, 0.37368, 0.44211, 0.51053, 0.57895, 0.64737, 0.71579, 0.78421, 0.85263, 0.92105, 0.98947, 1.05789, 1.12632, 1.19474, 1.26316, 1.33158, 1.40000],
                [1.01749, 1.03327, 1.04339, 1.04900, 1.05051, 1.04825, 1.04249, 1.03343, 1.02126, 1.01162, 1.00500, 1.00084, 0.99912, 0.99966, 0.99972, 0.99942, 0.99920, 0.99911, 0.99885, 0.99861],
                [0.99137, 0.99297, 0.99431, 0.99564, 0.99681, 0.99778, 0.99855, 0.99910, 0.99948, 0.99971, 0.99984, 0.99989, 0.99993, 0.99993, 0.99992, 0.99992, 0.99992, 1.00009, 1.00010, 1.00012],
                [3000.00, 4263.16, 5526.32, 6789.47, 8052.63, 9315.79, 10578.95, 11842.11, 13105.26, 14368.42, 15631.58, 16894.74, 18157.89, 19421.05, 20684.21, 21947.37, 23210.53, 24473.68, 25736.84, 27000.00],
                [0.99653, 0.99756, 0.99839, 0.99906, 0.99965, 1.00017, 1.00063, 1.00106, 1.00146, 1.00183, 1.00218, 1.00246, 1.00277, 1.00306, 1.00334, 1.00361, 1.00387, 1.00411, 1.00435, 1.00458],
                [0.99760, 0.99831, 0.99888, 0.99934, 0.99973, 1.00008, 1.00039, 1.00067, 1.00093, 1.00118, 1.00140, 1.00161, 1.00180, 1.00199, 1.00217, 1.00234, 1.00250, 1.00265, 1.00280, 1.00294],
                [0.10000, 0.17368, 0.24737, 0.32105, 0.39474, 0.46842, 0.54211, 0.61579, 0.68947, 0.76316, 0.83684, 0.91053, 0.98421, 1.05789, 1.13158, 1.20526, 1.27895, 1.35263, 1.42632, 1.50000],
                [1.01994, 1.01645, 1.01350, 1.01073, 1.00801, 1.00553, 1.00354, 1.00192, 1.00077, 0.99995, 0.99956, 0.99957, 1.00000, 0.99964, 0.99955, 0.99945, 0.99937, 0.99928, 0.99919, 0.99918],
                [1.02055, 1.01864, 1.01869, 1.01783, 1.01508, 1.01265, 1.01031, 1.00832, 1.00637, 1.00454, 1.00301, 1.00141, 1.00008, 0.99851, 0.99715, 0.99586, 0.99464, 0.99347, 0.99227, 0.99177]
            )
            self.m_db = dTemp
        elif self.m_pbp.tech_type == 3:
            //  Sliding pressure power cycle formulation
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.10000, 0.21111, 0.32222, 0.43333, 0.54444, 0.65556, 0.76667, 0.87778, 0.98889, 1.10000],
                [0.89280, 0.90760, 0.92160, 0.93510, 0.94820, 0.96110, 0.97370, 0.98620, 0.99860, 1.01100],
                [0.93030, 0.94020, 0.94950, 0.95830, 0.96690, 0.97520, 0.98330, 0.99130, 0.99910, 1.00700],
                [4000.00, 6556.00, 9111.00, 11677.0, 14222.0, 16778.0, 19333.0, 21889.0, 24444.0, 27000.0],
                [1.04800, 1.01400, 0.99020, 0.97140, 0.95580, 0.94240, 0.93070, 0.92020, 0.91060, 0.90190],
                [0.99880, 0.99960, 1.00000, 1.00100, 1.00100, 1.00100, 1.00100, 1.00200, 1.00200, 1.00200],
                [0.20000, 0.31667, 0.43333, 0.55000, 0.66667, 0.78333, 0.90000, 1.01667, 1.13333, 1.25000],
                [0.16030, 0.27430, 0.39630, 0.52310, 0.65140, 0.77820, 0.90060, 1.01600, 1.12100, 1.21400],
                [0.22410, 0.34700, 0.46640, 0.58270, 0.69570, 0.80550, 0.91180, 1.01400, 1.11300, 1.20700],
                [0.10000, 0.21111, 0.32222, 0.43333, 0.54444, 0.65556, 0.76667, 0.87778, 0.98889, 1.10000],
                [1.05802, 1.05127, 1.04709, 1.03940, 1.03297, 1.02480, 1.01758, 1.00833, 1.00180, 0.99307],
                [1.03671, 1.03314, 1.02894, 1.02370, 1.01912, 1.01549, 1.01002, 1.00486, 1.00034, 0.99554],
                [4000.00, 6556.00, 9111.00, 11677.0, 14222.0, 16778.0, 19333.0, 21889.0, 24444.0, 27000.0],
                [1.00825, 0.98849, 0.99742, 1.02080, 1.02831, 1.03415, 1.03926, 1.04808, 1.05554, 1.05862],
                [1.01838, 1.02970, 0.99785, 0.99663, 0.99542, 0.99183, 0.98897, 0.99299, 0.99013, 0.98798], // tweaked entry #4 to be the average of 3 and 5. it was an outlier in the simulation. mjw 3.31.11
                [0.20000, 0.31667, 0.43333, 0.55000, 0.66667, 0.78333, 0.90000, 1.01667, 1.13333, 1.25000],
                [1.43311, 1.27347, 1.19090, 1.13367, 1.09073, 1.05602, 1.02693, 1.00103, 0.97899, 0.95912],
                [0.48342, 0.64841, 0.64322, 0.74366, 0.76661, 0.82764, 0.97792, 1.15056, 1.23117, 1.31179]  // tweaked entry #9 to be the average of 8 and 10. it was an outlier in the simulation mjw 3.31.11
            )
            self.m_db = dTemp
        elif self.m_pbp.tech_type == 4:
            //	Geothermal applications - Isopentane Rankine cycle
            var dTemp: List[List[Float64]] = List[List[Float64]](
                [0.50000, 0.53158, 0.56316, 0.59474, 0.62632, 0.65789, 0.68947, 0.72105, 0.75263, 0.78421, 0.81579, 0.84737, 0.87895, 0.91053, 0.94211, 0.97368, 1.00526, 1.03684, 1.06842, 1.10000],
                [0.55720, 0.58320, 0.60960, 0.63630, 0.66330, 0.69070, 0.71840, 0.74630, 0.77440, 0.80270, 0.83130, 0.85990, 0.88870, 0.91760, 0.94670, 0.97570, 1.00500, 1.03400, 1.06300, 1.09200],
                [0.67620, 0.69590, 0.71570, 0.73570, 0.75580, 0.77600, 0.79630, 0.81670, 0.83720, 0.85780, 0.87840, 0.89910, 0.91990, 0.94070, 0.96150, 0.98230, 1.00300, 1.02400, 1.04500, 1.06600],
                [35000.00, 46315.79, 57631.58, 68947.37, 80263.16, 91578.95, 102894.74, 114210.53, 125526.32, 136842.11, 148157.89, 159473.68, 170789.47, 182105.26, 193421.05, 204736.84, 216052.63, 227368.42, 238684.21, 250000.00],
                [1.94000, 1.77900, 1.65200, 1.54600, 1.45600, 1.37800, 1.30800, 1.24600, 1.18900, 1.13700, 1.08800, 1.04400, 1.00200, 0.96290, 0.92620, 0.89150, 0.85860, 0.82740, 0.79770, 0.76940],
                [1.22400, 1.19100, 1.16400, 1.14000, 1.11900, 1.10000, 1.08300, 1.06700, 1.05200, 1.03800, 1.02500, 1.01200, 1.00000, 0.98880, 0.97780, 0.96720, 0.95710, 0.94720, 0.93770, 0.92850],
                [0.80000, 0.81316, 0.82632, 0.83947, 0.85263, 0.86579, 0.87895, 0.89211, 0.90526, 0.91842, 0.93158, 0.94474, 0.95789, 0.97105, 0.98421, 0.99737, 1.01053, 1.02368, 1.03684, 1.05000],
                [0.84760, 0.85880, 0.86970, 0.88050, 0.89120, 0.90160, 0.91200, 0.92210, 0.93220, 0.94200, 0.95180, 0.96130, 0.97080, 0.98010, 0.98920, 0.99820, 1.00700, 1.01600, 1.02400, 1.03300],
                [0.89590, 0.90350, 0.91100, 0.91840, 0.92570, 0.93290, 0.93990, 0.94680, 0.95370, 0.96040, 0.96700, 0.97350, 0.97990, 0.98620, 0.99240, 0.99850, 1.00400, 1.01000, 1.01500, 1.02100],
                [0.50000, 0.53158, 0.56316, 0.59474, 0.62632, 0.65789, 0.68947, 0.72105, 0.75263, 0.78421, 0.81579, 0.84737, 0.87895, 0.91053, 0.94211, 0.97368, 1.00526, 1.03684, 1.06842, 1.10000],
                [0.79042, 0.80556, 0.82439, 0.84177, 0.85786, 0.87485, 0.88898, 0.90182, 0.91783, 0.93019, 0.93955, 0.95105, 0.96233, 0.97150, 0.98059, 0.98237, 0.99829, 1.00271, 1.02084, 1.02413],
                [0.67400, 0.69477, 0.71830, 0.73778, 0.75991, 0.78079, 0.80052, 0.82622, 0.88152, 0.92737, 0.93608, 0.94800, 0.95774, 0.96653, 0.97792, 0.99852, 0.99701, 1.01295, 1.02825, 1.04294],
                [35000.00, 46315.79, 57631.58, 68947.37, 80263.16, 91578.95, 102894.74, 114210.53, 125526.32, 136842.11, 148157.89, 159473.68, 170789.47, 182105.26, 193421.05, 204736.84, 216052.63, 227368.42, 238684.21, 250000.00],
                [0.80313, 0.82344, 0.83980, 0.86140, 0.87652, 0.89274, 0.91079, 0.92325, 0.93832, 0.95229, 0.97004, 0.98211, 1.00399, 1.01514, 1.03494, 1.04962, 1.06646, 1.08374, 1.10088, 1.11789],
                [0.93426, 0.94458, 0.94618, 0.95878, 0.96352, 0.96738, 0.97058, 0.98007, 0.98185, 0.99048, 0.99144, 0.99914, 1.00696, 1.00849, 1.01573, 1.01973, 1.01982, 1.02577, 1.02850, 1.03585],
                [0.80000, 0.81316, 0.82632, 0.83947, 0.85263, 0.86579, 0.87895, 0.89211, 0.90526, 0.91842, 0.93158, 0.94474, 0.95789, 0.97105, 0.98421, 0.99737, 1.01053, 1.02368, 1.03684, 1.05000],
                [1.06790, 1.06247, 1.05688, 1.05185, 1.04687, 1.04230, 1.03748, 1.03281, 1.02871, 1.02473, 1.02050, 1.01639, 1.01204, 1.00863, 1.00461, 1.00051, 0.99710, 0.99352, 0.98974, 0.98692],
                [1.02335, 1.02130, 1.02041, 1.01912, 1.01655, 1.01601, 1.01379, 1.01431, 1.01321, 1.01207, 1.01129, 1.00784, 1.00548, 1.00348, 1.00183, 0.99982, 0.99698, 0.99457, 0.99124, 0.99016]
            )
            self.m_db = dTemp
        else:
            self.m_strLastError = "Power block (Type 224) encountered an unkown technology type when trying to initialize."
            return False

        self.m_pbp.P_ref = self.m_pbp.P_ref * 1000.0  //P_ref = PAR(1)*1000. !Convert from MW to kW
        self.m_pbp.P_cond_min = physics.InHgToPa(self.m_pbp.P_cond_min)  //P_cond_min = PAR(19)*3386. !Convert inHg to Pa
        for i in range(9):
            self.m_F_wcMax = self.dmax1(self.m_F_wcMax, self.m_pbp.F_wc[i])
            self.m_F_wcMin = self.dmin1(self.m_F_wcMin, self.m_pbp.F_wc[i])
        if (self.m_F_wcMax > 1.0) or (self.m_F_wcMin < 0.0):
            self.m_strLastError = "Hybrid dispatch values must be between zero and one."
            return False
        if self.m_pbp.P_boil > 220.0:
            self.m_pbp.P_boil = 220.0  // Set to 220 bar, 22 MPa
            self.m_strWarningMsg = "Boiler pressure provided by the user requires a supercritical system. The pressure value has been reset to 220 bar."

        var h_st_hot: Float64
        var h_st_cold: Float64
        /* Use FIT water props to calculate enthalpy rise over economizer/boiler/superheater
        if(!physics.EnthalpyFromTempAndPressure(m_pbp.T_htf_hot_ref - GetFieldToTurbineTemperatureDropC() + 273.15, m_pbp.P_boil, h_st_hot))
        {
            m_strLastError = "Could not calculate the enthalpy for the given temperature and pressure.";
            return false;
        }
        if(!physics.EnthalpyFromTempAndPressure(274 + 273.15, m_pbp.P_boil, h_st_cold))
        {
            m_strLastError = "Could not calculate the enthalpy for the given temperature and pressure.";
            return false;
        }
        h_st_cold = h_st_cold - 4.91*100.0;
        m_dDeltaEnthalpySteam = (h_st_hot - h_st_cold);		// [kJ/kg]
        */
        var wp: water_state
        water_TP(self.m_pbp.T_htf_hot_ref - self.GetFieldToTurbineTemperatureDropC() + 273.15, self.m_pbp.P_boil * 100.0, &wp)  // Get hot side enthalpy [kJ/kg] using Steam Props
        h_st_hot = wp.enth
        water_PQ(self.m_pbp.P_boil * 100.0, 0.0, &wp)
        h_st_cold = wp.enth
        self.m_dDeltaEnthalpySteam = h_st_hot - h_st_cold + 4.91 * 100.0
        self.m_dStartupEnergy = self.m_pbp.startup_frac * self.m_pbp.P_ref / self.m_pbp.eta_ref  // [kWt]
        self.m_bInitialized = True
        return True

    def SetNewTime(inout self, lTimeInSeconds: Int) -> Bool:
        if lTimeInSeconds < self.m_lCurrentSecondsFromStart:
            self.m_strLastError = "New time was earlier than the last time."
            return False
        if lTimeInSeconds > self.m_lCurrentSecondsFromStart:
            self.Step(lTimeInSeconds)
        return True

    def Step(inout self, lNewSecondsFromStart: Int):
        self.m_dHoursSinceLastStep = (Float64(lNewSecondsFromStart) - Float64(self.m_lCurrentSecondsFromStart)) / 3600.0
        self.m_lCurrentSecondsFromStart = lNewSecondsFromStart
        self.m_sv.iLastStandbyControl = self.m_pbi.standby_control  // STORED(1)=standby_control
        self.m_sv.dStartupTimeRemaining = self.m_dStartupRemain
        self.m_sv.dStartupEnergyRemaining = self.m_dStartupERemain  // STORED(4)= startup_e_remain
        return

    def Execute(inout self, lSecondsFromStart: Int, pbi: S_Indirect_PB_Inputs) -> Bool:
        if not self.m_bInitialized:
            return False
        if not self.SetNewTime(lSecondsFromStart):
            return False
        if (pbi.TOU < 0) or (pbi.TOU > 8):
            self.m_strLastError = "The power block inputs contained an invalid time-of-use period. The value encountered was " + util.to_string(pbi.TOU) + " and it should be >=0 and <=8."
            return False
        self.m_pbi = pbi
        self.m_iLastStandbyControl = self.m_sv.iLastStandbyControl  //last_standby_control=STORED(1)
        self.m_dStartupRemain = self.m_sv.dStartupTimeRemaining  //startup_remain=STORED(2)
        self.m_dStartupERemain = self.m_sv.dStartupEnergyRemaining  //startup_e_remain=STORED(4)
        if self.m_pbi.mode == 1:
            self.m_pbi.demand_var = self.m_pbi.demand_var * 1000.0  // If the mode is to operate in power demand, convert from MW to kW
        var m_dot_st_bd: Float64 = 0.0
        if self.m_pbi.standby_control == 1:
            // The cycle is in normal operation
            self.RankineCycle(self.m_pbp.P_ref, self.m_pbp.eta_ref, self.m_pbp.T_htf_hot_ref, self.m_pbp.T_htf_cold_ref, self.m_pbi.T_db, self.m_pbi.T_wb, self.m_pbi.P_amb, self.m_pbp.dT_cw_ref, physics.SPECIFIC_HEAT_LIQUID_WATER,
                         self.m_pbi.T_htf_hot, self.m_pbi.m_dot_htf, self.m_pbi.mode, self.m_pbi.demand_var, self.m_pbp.P_boil, self.m_pbp.T_amb_des, self.m_pbp.T_approach, self.m_pbp.F_wc[self.m_pbi.TOU],
                         self.m_F_wcMin, self.m_F_wcMax, self.m_pbp.T_ITD_des, self.m_pbp.P_cond_ratio, self.m_pbp.P_cond_min,
                         self.m_pbo.P_cycle, self.m_pbo.eta, self.m_pbo.T_htf_cold, self.m_pbo.m_dot_demand, self.m_pbo.m_dot_htf_ref, self.m_pbo.m_dot_makeup, self.m_pbo.W_cool_par, self.m_pbo.f_hrsys, self.m_pbo.P_cond)
            if ((self.m_pbo.eta > 1.0) or (self.m_pbo.eta < 0.0)) or ((self.m_pbo.T_htf_cold > self.m_pbi.T_htf_hot) or (self.m_pbo.T_htf_cold < self.m_pbp.T_htf_cold_ref - 50.0)):
                self.m_pbo.P_cycle = 0.0
                self.m_pbo.eta = 0.0
                self.m_pbo.T_htf_cold = self.m_pbp.T_htf_cold_ref
                self.m_pbo.m_dot_demand = 0.0
                self.m_pbo.m_dot_makeup = 0.0
                self.m_pbo.W_cool_par = 0.0
                self.m_pbo.f_hrsys = 0.0
                self.m_pbo.P_cond = 0.0
            if self.m_pbp.tech_type != 4:
                m_dot_st_bd = self.m_pbo.P_cycle / self.dmax1((self.m_pbo.eta * self.m_dDeltaEnthalpySteam), 1.0e-6) * self.m_pbp.pb_bd_frac
            else:
                m_dot_st_bd = 0  // Added Aug 3, 2011 for Isopentane Rankine cycle
        elif self.m_pbi.standby_control == 2:
            // The cycle is in standby operation
            var c_htf: Float64 = self.m_pbp.htfProps.Cp( physics.CelciusToKelvin((self.m_pbi.T_htf_hot + self.m_pbp.T_htf_cold_ref) / 2.0) )
            var q_tot: Float64 = self.m_pbp.P_ref / self.m_pbp.eta_ref
            var q_sby_needed: Float64 = q_tot * self.m_pbp.q_sby_frac
            var m_dot_sby: Float64 = q_sby_needed / (c_htf * (self.m_pbi.T_htf_hot - self.m_pbp.T_htf_cold_ref)) * 3600.0
            self.m_pbo.P_cycle = 0.0
            self.m_pbo.eta = 0.0
            self.m_pbo.T_htf_cold = self.m_pbp.T_htf_cold_ref
            self.m_pbo.m_dot_demand = m_dot_sby
            self.m_pbo.m_dot_makeup = 0.0
            self.m_pbo.W_cool_par = 0.0
            self.m_pbo.f_hrsys = 0.0
            self.m_pbo.P_cond = 0.0
        elif self.m_pbi.standby_control == 3:
            // The cycle has been completely shut down
            self.m_pbo.P_cycle = 0.0
            self.m_pbo.eta = 0.0
            self.m_pbo.T_htf_cold = self.m_pbp.T_htf_cold_ref  // Changed from m_pbi.T_htf_hot 12/18/2009 was causing problems with T250
            self.m_pbo.m_dot_demand = 0.0
            self.m_pbo.m_dot_makeup = 0.0
            self.m_pbo.W_cool_par = 0.0
            self.m_pbo.f_hrsys = 0.0
            self.m_pbo.P_cond = 0.0
        if (self.m_iLastStandbyControl == 3) and (self.m_pbi.standby_control == 1):
            self.m_dStartupRemain = self.m_pbp.startup_time
            self.m_dStartupERemain = self.m_dStartupEnergy
        if self.m_pbo.P_cycle > 0.0:
            if ((self.m_iLastStandbyControl == 3) and (self.m_pbi.standby_control == 1)) or ((self.m_dStartupRemain + self.m_dStartupERemain) > 0.0):
                var Q_cycle: Float64 = self.m_pbo.P_cycle / self.m_pbo.eta
                /*
                double startup_e_used;
                if( m_dStartupERemain < Q_cycle*m_dHoursSinceLastStep )
                {
                    startup_e_used = m_dStartupERemain;
                    if( dmin1(1.0, m_dStartupRemain/m_dHoursSinceLastStep) > startup_e_used/(Q_cycle*m_dHoursSinceLastStep) )
                    {
                        double f_st = 1.0 - dmin1(1.0, m_dStartupRemain/m_dHoursSinceLastStep);
                        m_pbo.P_cycle *= f_st;
                    }
                    else
                        m_pbo.P_cycle -= (startup_e_used * m_pbo.eta);
                }
                else
                {
                    startup_e_used = Q_cycle * m_dHoursSinceLastStep;
                    m_pbo.P_cycle = 0.0;
                }
                */
                var startup_e_used: Float64 = self.dmin1(Q_cycle * self.m_dHoursSinceLastStep, self.m_dStartupERemain)  // The used startup energy is the less of the energy to the power block and the remaining startup requirement
                var f_st: Float64 = 1.0 - self.dmax1(self.dmin1(1.0, self.m_dStartupRemain / self.m_dHoursSinceLastStep), startup_e_used / (Q_cycle * self.m_dHoursSinceLastStep))
                self.m_pbo.P_cycle = self.m_pbo.P_cycle * f_st
                self.m_pbo.m_dot_demand = self.m_pbo.m_dot_demand * (1.0 - self.dmax1(self.dmin1(1.0, self.m_dStartupRemain / self.m_dHoursSinceLastStep) - startup_e_used / (Q_cycle * self.m_dHoursSinceLastStep), 0.0))
                self.m_pbo.eta = self.m_pbp.eta_ref  // Using reference efficiency because starting up during this timestep
                self.m_pbo.T_htf_cold = self.m_pbp.T_htf_cold_ref
                self.m_dStartupRemain = self.dmax1(self.m_dStartupRemain - self.m_dHoursSinceLastStep, 0.0)
                self.m_dStartupERemain = self.dmax1(self.m_dStartupERemain - startup_e_used, 0.0)
        self.m_pbo.P_cycle = self.m_pbo.P_cycle / 1000.0
        self.m_pbo.m_dot_makeup = (self.m_pbo.m_dot_makeup + m_dot_st_bd) * 3600.0
        self.m_pbo.P_ref = self.m_pbo.P_ref / 1000.0
        return (self.m_strLastError == "") ? True : False

    /*double C_Indirect_PB::f_Tsat_p(double P)
    {
        double Pg = 0, T = 9999.9, err = 999.9, Tg = 0;
        if(P-Pg > 1) Tg = 25.0;
        for (int i=0; i<30; i++)
        {	// iterative loop to solve for Pg = P and return T. T cannot be expressed in terms of P.
            Pg = f_psat_T(Tg);
            err = (P-Pg)/P;
            T = Tg;
            if( (fabs(err) < 1.0E-6) ) break;
            Tg = T + (err * 25.0);
        }
        return T;
     }
     */
    /*double C_Indirect_PB::specheat(int fnum, double T, double P)
    {
        double  Td; //xlo, xhi,;
        Td = T - 273.15;
        switch(fnum)
        {
            case 1: return 1.03749 - 0.000305497*T + 7.49335E-07*T*T - 3.39363E-10*T*T*T; break;	//	1.) Air
            case 2: return 0.368455 + 0.000399548*T - 1.70558E-07*T*T; break;	// EES					2.) Stainless_AISI316
            case 3: return 4.181; break;  //															3.) Water (liquid)
            case 4: return 1; break;  //																4.) Steam
            case 5: return 1; break;  //																5.) CO2
            case 6:  return 1.156; break; //															6.) Salt (68% KCl, 32% MgCl2)
            case 7:  return 1.507; break; //															7.) Salt (8% NaF, 92% NaBF4)
            case 8:  return 1.306; break; //															8.) Salt (25% KF, 75% KBF4)
            case 9:  return 9.127; break; //															9.) Salt (31% RbF, 69% RbBF4)
            case 10: return 2.010; break; //															10.) Salt (46.5% LiF, 11.5%NaF, 42%KF)
            case 11: return 1.239; break; //															11.) Salt (49% LiF, 29% NaF, 29% ZrF4)
            case 12: return 1.051; break; //															12.) Salt (58% KF, 42% ZrF4)
            case 13: return 8.918; break; //															13.) Salt (58% LiCl, 42% RbCl)
            case 14: return 1.080; break; //															14.) Salt (58% NaCl, 42% MgCl2)
            case 15: return 1.202; break; //															15.) Salt (59.5% LiCl, 40.5% KCl)
            case 16: return 1.172; break; //															16.) Salt (59.5% NaF, 40.5% ZrF4)
            case 17: return -1E-10*T*T*T + 2E-07*T*T + 5E-06*T + 1.4387; break; //						17.) Salt (60% NaNO3, 40% KNO3)
            case 18: return (1443. + 0.172 * (T-273.15))/1000.0; break;									// Heat Capacity of Nitrate Salt, [J/kg/K]
            case 19: return (3.88 * (T-273.15) + 1606.0)/1000.0; break;									// Specific Heat of Caloria HT 43 [J/kgC]
            case 20: return dmax1(1536 - 0.2624 * Td - 0.0001139 * Td * Td, 1000.0)/1000.0; break;		// Heat Capacity of HITEC XL Nitrate Salt, [J/kg/K]
            case 21: return (1.509 + 0.002496 * Td + 0.0000007888 * Td*Td); break;		 				// Specific Heat of Therminol Oil, J/kg/K
            case 22: return (1560 - 0.0 * Td)/1000.0; break;											// Heat Capacity of HITEC Salt, [J/kg/K]
            case 23: return (-0.00053943*Td*Td + 3.2028*Td + 1589.2)/1000.0