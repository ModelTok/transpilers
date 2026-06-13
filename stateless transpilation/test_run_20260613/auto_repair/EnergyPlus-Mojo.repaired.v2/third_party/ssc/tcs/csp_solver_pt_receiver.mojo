/*******************************************************************************************************
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  (“Alliance”) under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
*
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
*
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
*
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as “System Advisor Model” or “SAM”. Except
*  to comply with the foregoing, the terms “System Advisor Model”, “SAM”, or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
*
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/

from csp_solver_util import *
from htf_props import *
from csp_solver_core import *
from Ambient import *
from definitions import *

struct C_pt_receiver:
    # Public members
    var csp_messages: C_csp_messages        # Class to save messages for upstream classes
    var m_h_tower: Float64                  # [m] height of the tower
    var m_epsilon: Float64                  # [-] emissivity of the receiver panels
    var m_T_htf_hot_des: Float64            # [C] hot outlet HTF temperature at design, converted to [K] in init()
    var m_T_htf_cold_des: Float64           # [C] cold inlet HTF temperature at design, converted to [K] in init()
    var m_f_rec_min: Float64                # [-] minimum receiver thermal output as fraction of design
    var m_q_rec_des: Float64                # [MW] design recever thermal output, converted to [W] in init()
    var m_rec_su_delay: Float64             # [hr] required startup time
    var m_rec_qf_delay: Float64             # [-] required startup energy as fraction of design thermal output
    var m_m_dot_htf_max_frac: Float64       # [-] maximum receiver HTF mass flow as fraction of design mass flow
    var m_q_dot_inc_min: Float64            # [Wt] minimum receiver thermal power
    var m_eta_pump: Float64                 # [-] HTF pump efficiency
    var m_night_recirc: Int32               # [-] 1=receiver is circulating HTF at night, otherwise not
    var m_clearsky_model: Int32
    var m_clearsky_data: List[Float64]

    struct S_inputs:
        var m_field_eff: Float64                                        # [-] = (irradiance on receiver) / (I_bn * area of all heliostats)
        var m_input_operation_mode: C_csp_collector_receiver.E_csp_cr_modes   # [-] operating mode of collector receiver
        var m_flux_map_input: Optional[Matrix[Float64]]                 # [-] flux values for each receiver surface node, as fraction of an evenly distributed irradiance

        def __init__(inout self):
            self.m_field_eff = Float64.NaN
            self.m_input_operation_mode = C_csp_collector_receiver.E_csp_cr_modes.OFF

    struct S_outputs:
        var m_m_dot_salt_tot: Float64       # [kg/hr] HTF mass flow through receiver
        var m_eta_therm: Float64            # [-] receiver thermal efficiency
        var m_W_dot_pump: Float64           # [MW] HTF pumping power
        var m_q_conv_sum: Float64           # [MW] total receiver convection losses
        var m_q_rad_sum: Float64            # [MW] total receiver radiation losses
        var m_Q_thermal: Float64            # [MW] thermal power delivered to TES/PC
        var m_T_salt_hot: Float64           # [C] HTF outlet temperature
        var m_field_eff_adj: Float64        # [-] heliostat field efficiency including component defocus
        var m_component_defocus: Float64    # [-] defocus applied by receiver
        var m_q_dot_rec_inc: Float64        # [MWt] receiver incident thermal power
        var m_q_startup: Float64            # [MWt-hr] thermal energy used to start receiver
        var m_dP_receiver: Float64          # [bar] receiver pressure drop
        var m_dP_total: Float64             # [bar] total pressure drop
        var m_vel_htf: Float64              # [m/s] HTF flow velocity through receiver tubes
        var m_T_salt_cold: Float64          # [C] HTF inlet temperature
        var m_m_dot_ss: Float64             # [kg/hr] HTF mass flow during steady-state
        var m_q_dot_ss: Float64             # [MW] thermal power during steady-state
        var m_f_timestep: Float64           # [-] fraction of nominal timestep not starting up
        var m_time_required_su: Float64     # [s] time it took receiver to startup
        var m_q_dot_piping_loss: Float64    # [MWt] thermal power lost from piping
        var m_q_heattrace: Float64          # [MWt-hr] Power required for heat tracing
        var m_inst_T_salt_hot: Float64      # [C] Instantaneous HTF outlet T at end of time step
        var m_max_T_salt_hot: Float64       # [C] Maximum HTF outlet T during time step
        var m_min_T_salt_hot: Float64       # [C] Minimum HTF outlet T during time step
        var m_max_rec_tout: Float64         # [C] Maximum HTF T at receiver outlet before downcomer loss
        var m_Twall_inlet: Float64          # [C] Average receiver wall temperature at inlet
        var m_Twall_outlet: Float64         # [C] Average receiver wall temperature at outlet
        var m_Triser: Float64               # [C] Average riser wall temperature at inlet
        var m_Tdownc: Float64               # [C] Average downcomer wall temperature at outlet
        var m_clearsky: Float64             # [W/m2] Clear-sky DNI used in receiver flow control
        var m_Q_thermal_csky_ss: Float64    # [MWt] Steady-state thermal power if DNI = clear-sky
        var m_Q_thermal_ss: Float64         # [MWt] Steady-state thermal power

        def __init__(inout self):
            self.clear()

        def clear(inout self):
            self.m_m_dot_salt_tot = Float64.NaN
            self.m_eta_therm = Float64.NaN
            self.m_W_dot_pump = Float64.NaN
            self.m_q_conv_sum = Float64.NaN
            self.m_q_rad_sum = Float64.NaN
            self.m_Q_thermal = Float64.NaN
            self.m_T_salt_hot = Float64.NaN
            self.m_field_eff_adj = Float64.NaN
            self.m_component_defocus = Float64.NaN
            self.m_q_dot_rec_inc = Float64.NaN
            self.m_q_startup = Float64.NaN
            self.m_dP_receiver = Float64.NaN
            self.m_dP_total = Float64.NaN
            self.m_vel_htf = Float64.NaN
            self.m_T_salt_cold = Float64.NaN
            self.m_m_dot_ss = Float64.NaN
            self.m_q_dot_ss = Float64.NaN
            self.m_f_timestep = Float64.NaN
            self.m_time_required_su = Float64.NaN
            self.m_q_dot_piping_loss = Float64.NaN
            self.m_q_heattrace = Float64.NaN
            self.m_inst_T_salt_hot = Float64.NaN
            self.m_max_T_salt_hot = Float64.NaN
            self.m_min_T_salt_hot = Float64.NaN
            self.m_max_rec_tout = Float64.NaN
            self.m_Twall_inlet = Float64.NaN
            self.m_Twall_outlet = Float64.NaN
            self.m_Triser = Float64.NaN
            self.m_Tdownc = Float64.NaN
            self.m_clearsky = Float64.NaN
            self.m_Q_thermal_csky_ss = Float64.NaN
            self.m_Q_thermal_ss = Float64.NaN

    var ms_outputs: S_outputs

    # Pure (abstract) methods in C++ -> provide dummy implementations
    def init(inout self):
        raise Error("Abstract method init() must be overridden")

    def get_operating_state(self) -> Int32:
        return self.m_mode_prev

    def call(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inputs: S_inputs, sim_info: C_csp_solver_sim_info):
        raise Error("Abstract method call() must be overridden")

    def off(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, sim_info: C_csp_solver_sim_info):
        raise Error("Abstract method off() must be overridden")

    def converged(inout self):
        raise Error("Abstract method converged() must be overridden")

    def get_pumping_parasitic_coef(self) -> Float64:
        raise Error("Abstract method get_pumping_parasitic_coef() must be overridden")

    def get_htf_property_object(self) -> ref[HTFProperties]:
        return self.field_htfProps

    def get_startup_time(self) -> Float64:  # [s]
        return self.m_rec_su_delay * 3600.0

    def get_startup_energy(self) -> Float64:  # [MWh]
        return self.m_rec_qf_delay * self.m_q_rec_des * 1.e-6

    def area_proj(self) -> Float64:  # [m^2]
        raise Error("Abstract method area_proj() must be overridden")

    # Protected members
    var field_htfProps: HTFProperties       # heat transfer fluid properties
    var tube_material: HTFProperties        # receiver tube material
    var ambient_air: HTFProperties          # ambient air properties
    var m_m_dot_htf_des: Float64            # [kg/s] receiver HTF mass flow at design
    var m_mode: C_csp_collector_receiver.E_csp_cr_modes
    var m_mode_prev: C_csp_collector_receiver.E_csp_cr_modes
    var error_msg: String                   # member string for exception messages

    def __init__(inout self):
        self.m_h_tower = Float64.NaN
        self.m_epsilon = Float64.NaN
        self.m_T_htf_hot_des = Float64.NaN
        self.m_T_htf_cold_des = Float64.NaN
        self.m_f_rec_min = Float64.NaN
        self.m_q_rec_des = Float64.NaN
        self.m_rec_su_delay = Float64.NaN
        self.m_rec_qf_delay = Float64.NaN
        self.m_m_dot_htf_max_frac = Float64.NaN
        self.m_eta_pump = Float64.NaN
        self.m_night_recirc = -1
        self.error_msg = ""
        self.m_m_dot_htf_des = Float64.NaN
        self.m_mode = C_csp_collector_receiver.E_csp_cr_modes.OFF
        self.m_mode_prev = C_csp_collector_receiver.E_csp_cr_modes.OFF
        self.m_clearsky_model = -1
        self.m_clearsky_data = List[Float64]()

    def get_clearsky(self, weather: C_csp_weatherreader.S_outputs, hour: Float64) -> Float64:
        if self.m_clearsky_model == -1 or weather.m_solzen >= 90.0:
            return 0.0
        var clearsky: Float64
        if self.m_clearsky_model == 0:  # Use user-defined array
            var nsteps: Int32 = len(self.m_clearsky_data)
            var baseline_step: Float64 = 8760.0 / Float64(nsteps)  # Weather file time step size (hr)
            var step: Int32 = Int32((hour - 1.e-6) / baseline_step)
            step = min(step, nsteps - 1)
            clearsky = self.m_clearsky_data[step]
        else:  # use methods in SolarPILOT
            var monthlen: List[Int32] = List[Int32](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
            var doy: Int32 = weather.m_day
            var m: Int32 = weather.m_month - 1
            for j in range(m):
                doy += monthlen[j]
            var pres: Float64 = weather.m_pres
            if pres < 20.0 and pres > 1.0:               # Some weather files seem to have inconsistent pressure units
                pres = weather.m_pres * 100.0             # convert to mbar
            var dpres: Float64 = pres * 1.e-3 * 0.986923  # Ambient pressure in atm
            var del_h2o: Float64 = exp(0.058 * weather.m_tdew + 2.413)  # Correlation for precipitable water in mm H20
            var S0: Float64 = 1.353 * (1.0 + 0.0335 * cos(2.0 * PI * (Float64(doy) + 10.0) / 365.0))
            var zenith: Float64 = weather.m_solzen * 3.14159 / 180.0
            var azimuth: Float64 = weather.m_solazi * 3.14159 / 180.0
            var szen: Float64 = sin(zenith)
            var czen: Float64 = cos(zenith)
            var save2: Float64 = 90.0 - atan2(szen, czen) * R2D
            var save: Float64 = 1.0 / czen
            if save2 <= 30.0:
                save = save - 41.972213 * pow(save2, (-2.0936381 - 0.04117341 * save2 + 0.000849854 * pow(save2, 2)))
            var alt: Float64 = weather.m_elev / 1000.0
            var csky: Float64 = 0.0
            if self.m_clearsky_model == 1:  # Meinel
                csky = (1.0 - 0.14 * alt) * exp(-0.357 / pow(czen, 0.678)) + 0.14 * alt
            elif self.m_clearsky_model == 2:  # Hottel
                csky = 0.4237 - 0.00821 * pow(6.0 - alt, 2) + (0.5055 + 0.00595 * pow(6.5 - alt, 2)) * exp(-(0.2711 + 0.01858 * pow(2.5 - alt, 2)) / (czen + 0.00001))
            elif self.m_clearsky_model == 3:  # Allen
                csky = 1.0 - 0.263 * ((del_h2o + 2.72) / (del_h2o + 5.0)) * pow((save * dpres), (0.367 * ((del_h2o + 11.53) / (del_h2o + 7.88))))
            elif self.m_clearsky_model == 4:  # Moon
                csky = 0.183 * exp(-save * dpres / 0.48) + 0.715 * exp(-save * dpres / 4.15) + 0.102
            clearsky = max(0.0, csky * S0 * 1000.0)
        return clearsky