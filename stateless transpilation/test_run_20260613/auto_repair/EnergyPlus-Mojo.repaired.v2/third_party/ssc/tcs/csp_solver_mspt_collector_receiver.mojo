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
from csp_solver_core import C_csp_collector_receiver, C_csp_reported_outputs, csp_info_invalid
from csp_solver_pt_sf_perf_interp import C_pt_sf_perf_interp
from csp_solver_pt_receiver import C_pt_receiver
from csp_solver_htf_1state import C_csp_solver_htf_1state
from csp_solver_sim_info import C_csp_solver_sim_info
from csp_weatherreader import C_csp_weatherreader
from sam_csp_util import *
from algorithm import *
from math import *

struct S_output_info:
    var key: Int
    var timestep_type: Int

@value
struct csp_info_invalid_type:

var csp_info_invalid = csp_info_invalid_type()

class C_csp_mspt_collector_receiver(C_csp_collector_receiver):
    
    enum:
        E_FIELD_Q_DOT_INC = 0        #[MWt] Field incident thermal power
        E_FIELD_ETA_OPT = 1          #[-] Optical efficiency including receiver refl
        E_FIELD_ADJUST = 2           #[-] Field adjustment factor
        E_Q_DOT_INC = 3              #[MWt] Receiver incident thermal power
        E_ETA_THERMAL = 4            #[-] Receiver thermal efficiency
        E_Q_DOT_THERMAL = 5          #[MWt] Field incident thermal power
        E_M_DOT_HTF = 6              #[kg/hr] Receiver mass flow rate
        E_Q_DOT_STARTUP = 7          #[MWt] Receiver startup thermal power consumed
        E_T_HTF_IN = 8               #[C] Receiver HTF inlet temperature
        E_T_HTF_OUT = 9              #[C] Receiver HTF outlet temperature
        E_Q_DOT_PIPE_LOSS = 10       #[MWt] Tower piping losses
        E_Q_DOT_LOSS = 11            #[MWt] Receiver convection and radiation losses
        E_P_HEATTRACE = 12           #[MWe] Receiver heat trace parasitic
        E_T_HTF_OUT_END = 13         #[C] Instantaneous receiver HTF outlet temperature at the end of the time step
        E_T_HTF_OUT_MAX = 14         #[C] Receiver maximum HTF outlet temperature at any point during time step
        E_T_HTF_PANEL_OUT_MAX = 15   #[C] Receiver panel maximum HTF outlet temperature at any point during time step
        E_T_WALL_INLET = 16          #[C] Receiver inlet wall temperature at end of time step
        E_T_WALL_OUTLET = 17         #[C] Receiver inlet wall temperature at end of time step
        E_T_RISER = 18               #[C] Riser temperature at the end of the time step
        E_T_DOWNC = 19               #[C] Downcomer temperature at the end of the time step
        E_CLEARSKY = 20              #[W/m2] Clear-sky DNI 
        E_Q_DOT_THERMAL_CSKY_SS = 21 #[MWt] Thermal power from receiver under steady-state clear-sky conditions
        E_Q_DOT_THERMAL_SS = 22      #[MWt] Thermal power from receiver under steady-state conditions

    var mc_pt_heliostatfield: C_pt_sf_perf_interp
    var mc_pt_receiver: C_pt_receiver
    var mc_reported_outputs: C_csp_reported_outputs

    def __init__(inout self, pt_heliostatfield: C_pt_sf_perf_interp, pt_receiver: C_pt_receiver):
        self.mc_pt_heliostatfield = pt_heliostatfield
        self.mc_pt_receiver = pt_receiver
        self.mc_reported_outputs = C_csp_reported_outputs()
        var S_output_info: List[S_output_info] = List[S_output_info]()
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_FIELD_Q_DOT_INC, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_FIELD_ETA_OPT, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_FIELD_ADJUST, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_Q_DOT_INC, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_ETA_THERMAL, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_M_DOT_HTF, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_Q_DOT_STARTUP, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_HTF_IN, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_HTF_OUT, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_Q_DOT_PIPE_LOSS, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_Q_DOT_LOSS, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_P_HEATTRACE, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_HTF_OUT_END, C_csp_reported_outputs.TS_LAST))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_HTF_OUT_MAX, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_HTF_PANEL_OUT_MAX, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_WALL_INLET, C_csp_reported_outputs.TS_LAST))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_WALL_OUTLET, C_csp_reported_outputs.TS_LAST))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_RISER, C_csp_reported_outputs.TS_LAST))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_T_DOWNC, C_csp_reported_outputs.TS_LAST))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_CLEARSKY, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL_CSKY_SS, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        S_output_info.append(S_output_info(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL_SS, C_csp_reported_outputs.TS_WEIGHTED_AVE))
        self.mc_reported_outputs.construct(S_output_info)

    def __del__(owned self):

    def init(inout self, init_inputs: C_csp_collector_receiver.S_csp_cr_init_inputs, inout solved_params: C_csp_collector_receiver.S_csp_cr_solved_params):
        self.mc_pt_heliostatfield.init()
        self.mc_pt_receiver.init()
        solved_params.m_T_htf_cold_des = self.mc_pt_receiver.m_T_htf_cold_des       #[K]
        solved_params.m_q_dot_rec_des = self.mc_pt_receiver.m_q_rec_des / 1.E6      #[MW]
        solved_params.m_A_aper_total = self.mc_pt_heliostatfield.ms_params.m_A_sf   #[m^2]
        return

    def get_operating_state(inout self) -> Int:
        return self.mc_pt_receiver.get_operating_state()

    def get_startup_time(inout self) -> Float64:
        return self.mc_pt_receiver.get_startup_time()   #[s]

    def get_startup_energy(inout self) -> Float64:
        return self.mc_pt_receiver.get_startup_energy() #[MWh]

    def get_pumping_parasitic_coef(inout self) -> Float64:  #MWe/MWt
        return self.mc_pt_receiver.get_pumping_parasitic_coef()

    def get_min_power_delivery(inout self) -> Float64:    #MWt
        return self.mc_pt_receiver.m_f_rec_min * self.mc_pt_receiver.m_q_rec_des * 1.e-6

    def get_tracking_power(inout self) -> Float64:
        return self.mc_pt_heliostatfield.ms_params.m_p_track * self.mc_pt_heliostatfield.ms_params.m_N_hel * 1.e-3   #MWe

    def get_col_startup_power(inout self) -> Float64:
        return self.mc_pt_heliostatfield.ms_params.m_p_start * self.mc_pt_heliostatfield.ms_params.m_N_hel * 1.e-3   #MWe-hr

    def call(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inputs: C_csp_collector_receiver.S_csp_cr_inputs, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        var heliostat_field_control: Float64 = inputs.m_field_control
        self.mc_pt_heliostatfield.call(weather, heliostat_field_control, sim_info)
        var receiver_inputs: C_pt_receiver.S_inputs = C_pt_receiver.S_inputs()
        receiver_inputs.m_field_eff = self.mc_pt_heliostatfield.ms_outputs.m_eta_field
        receiver_inputs.m_input_operation_mode = inputs.m_input_operation_mode
        receiver_inputs.m_flux_map_input = self.mc_pt_heliostatfield.ms_outputs.m_flux_map_out
        self.mc_pt_receiver.call(weather, htf_state_in, receiver_inputs, sim_info)
        cr_out_solver.m_q_thermal = self.mc_pt_receiver.ms_outputs.m_Q_thermal                #[MW]
        cr_out_solver.m_q_startup = self.mc_pt_receiver.ms_outputs.m_q_startup                #[MWt-hr]
        cr_out_solver.m_m_dot_salt_tot = self.mc_pt_receiver.ms_outputs.m_m_dot_salt_tot      #[kg/hr]
        cr_out_solver.m_T_salt_hot = self.mc_pt_receiver.ms_outputs.m_T_salt_hot              #[C]
        cr_out_solver.m_component_defocus = self.mc_pt_receiver.ms_outputs.m_component_defocus  #[-]
        cr_out_solver.m_W_dot_htf_pump = self.mc_pt_receiver.ms_outputs.m_W_dot_pump          #[MWe]
        cr_out_solver.m_W_dot_col_tracking = self.mc_pt_heliostatfield.ms_outputs.m_pparasi   #[MWe]
        cr_out_solver.m_time_required_su = self.mc_pt_receiver.ms_outputs.m_time_required_su  #[s]
        cr_out_solver.m_q_rec_heattrace = self.mc_pt_receiver.ms_outputs.m_q_heattrace / (self.mc_pt_receiver.ms_outputs.m_time_required_su / 3600.0)  #[MWt])
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_FIELD_Q_DOT_INC, self.mc_pt_heliostatfield.ms_outputs.m_q_dot_field_inc)   #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_FIELD_ETA_OPT, self.mc_pt_heliostatfield.ms_outputs.m_eta_field)            #[-]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_FIELD_ADJUST, self.mc_pt_heliostatfield.ms_outputs.m_sf_adjust_out)         #[-]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_INC, self.mc_pt_receiver.ms_outputs.m_q_dot_rec_inc)   #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_ETA_THERMAL, self.mc_pt_receiver.ms_outputs.m_eta_therm)     #[-]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL, self.mc_pt_receiver.ms_outputs.m_Q_thermal)  #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_M_DOT_HTF, self.mc_pt_receiver.ms_outputs.m_m_dot_salt_tot) #[kg/hr]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_STARTUP, self.mc_pt_receiver.ms_outputs.m_q_startup / (self.mc_pt_receiver.ms_outputs.m_time_required_su / 3600.0))  #[MWt])
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_IN, htf_state_in.m_temp)                                    #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_OUT, self.mc_pt_receiver.ms_outputs.m_T_salt_hot)          #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_PIPE_LOSS, self.mc_pt_receiver.ms_outputs.m_q_dot_piping_loss)  #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_LOSS, self.mc_pt_receiver.ms_outputs.m_q_rad_sum + self.mc_pt_receiver.ms_outputs.m_q_conv_sum) #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_P_HEATTRACE, self.mc_pt_receiver.ms_outputs.m_q_heattrace / (self.mc_pt_receiver.ms_outputs.m_time_required_su / 3600.0))  #[MWt])
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_OUT_END, self.mc_pt_receiver.ms_outputs.m_inst_T_salt_hot)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_OUT_MAX, self.mc_pt_receiver.ms_outputs.m_max_T_salt_hot)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_PANEL_OUT_MAX, self.mc_pt_receiver.ms_outputs.m_max_rec_tout)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_WALL_INLET, self.mc_pt_receiver.ms_outputs.m_Twall_inlet)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_WALL_OUTLET, self.mc_pt_receiver.ms_outputs.m_Twall_outlet)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_RISER, self.mc_pt_receiver.ms_outputs.m_Triser)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_DOWNC, self.mc_pt_receiver.ms_outputs.m_Tdownc)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_CLEARSKY, self.mc_pt_receiver.ms_outputs.m_clearsky)
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL_CSKY_SS, self.mc_pt_receiver.ms_outputs.m_Q_thermal_csky_ss) #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL_SS, self.mc_pt_receiver.ms_outputs.m_Q_thermal_ss) #[MWt]

    def off(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        self.mc_pt_heliostatfield.off(sim_info)
        cr_out_solver.m_W_dot_col_tracking = self.mc_pt_heliostatfield.ms_outputs.m_pparasi            #[MWe]
        self.mc_pt_receiver.off(weather, htf_state_in, sim_info)
        cr_out_solver.m_q_thermal = self.mc_pt_receiver.ms_outputs.m_Q_thermal                  #[MW]
        cr_out_solver.m_q_startup = self.mc_pt_receiver.ms_outputs.m_q_startup                  #[MWt-hr]
        cr_out_solver.m_m_dot_salt_tot = self.mc_pt_receiver.ms_outputs.m_m_dot_salt_tot        #[kg/hr]
        cr_out_solver.m_T_salt_hot = self.mc_pt_receiver.ms_outputs.m_T_salt_hot                #[C]
        cr_out_solver.m_component_defocus = 1.0   #[-]
        cr_out_solver.m_W_dot_htf_pump = self.mc_pt_receiver.ms_outputs.m_W_dot_pump            #[MWe]
        cr_out_solver.m_time_required_su = self.mc_pt_receiver.ms_outputs.m_time_required_su    #[s]
        cr_out_solver.m_q_rec_heattrace = self.mc_pt_receiver.ms_outputs.m_q_heattrace / (self.mc_pt_receiver.ms_outputs.m_time_required_su / 3600.0)  #[MWt])
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_FIELD_Q_DOT_INC, self.mc_pt_heliostatfield.ms_outputs.m_q_dot_field_inc)   #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_FIELD_ETA_OPT, self.mc_pt_heliostatfield.ms_outputs.m_eta_field)            #[-]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_FIELD_ADJUST, self.mc_pt_heliostatfield.ms_outputs.m_sf_adjust_out)         #[-]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_INC, self.mc_pt_receiver.ms_outputs.m_q_dot_rec_inc)   #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_ETA_THERMAL, self.mc_pt_receiver.ms_outputs.m_eta_therm)     #[-]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL, self.mc_pt_receiver.ms_outputs.m_Q_thermal)  #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_M_DOT_HTF, self.mc_pt_receiver.ms_outputs.m_m_dot_salt_tot) #[kg/hr]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_STARTUP, self.mc_pt_receiver.ms_outputs.m_q_startup / (self.mc_pt_receiver.ms_outputs.m_time_required_su / 3600.0))  #[MWt])
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_IN, htf_state_in.m_temp)                                    #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_OUT, self.mc_pt_receiver.ms_outputs.m_T_salt_hot)          #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_PIPE_LOSS, self.mc_pt_receiver.ms_outputs.m_q_dot_piping_loss)  #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_LOSS, self.mc_pt_receiver.ms_outputs.m_q_rad_sum + self.mc_pt_receiver.ms_outputs.m_q_conv_sum) #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_P_HEATTRACE, self.mc_pt_receiver.ms_outputs.m_q_heattrace / (self.mc_pt_receiver.ms_outputs.m_time_required_su / 3600.0))  #[MWt])
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_OUT_END, self.mc_pt_receiver.ms_outputs.m_inst_T_salt_hot)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_OUT_MAX, self.mc_pt_receiver.ms_outputs.m_max_T_salt_hot)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_HTF_PANEL_OUT_MAX, self.mc_pt_receiver.ms_outputs.m_max_rec_tout)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_WALL_INLET, self.mc_pt_receiver.ms_outputs.m_Twall_inlet)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_WALL_OUTLET, self.mc_pt_receiver.ms_outputs.m_Twall_outlet)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_RISER, self.mc_pt_receiver.ms_outputs.m_Triser)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_T_DOWNC, self.mc_pt_receiver.ms_outputs.m_Tdownc)  #[C]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_CLEARSKY, self.mc_pt_receiver.ms_outputs.m_clearsky)
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL_CSKY_SS, self.mc_pt_receiver.ms_outputs.m_Q_thermal_csky_ss) #[MWt]
        self.mc_reported_outputs.value(C_csp_mspt_collector_receiver.E_Q_DOT_THERMAL_SS, self.mc_pt_receiver.ms_outputs.m_Q_thermal_ss) #[MWt]
        return

    def startup(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        var inputs: C_csp_collector_receiver.S_csp_cr_inputs = C_csp_collector_receiver.S_csp_cr_inputs()
        inputs.m_input_operation_mode = C_csp_collector_receiver.STARTUP
        inputs.m_field_control = 1.0
        self.call(weather, htf_state_in, inputs, cr_out_solver, sim_info)

    def on(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, field_control: Float64, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        var inputs: C_csp_collector_receiver.S_csp_cr_inputs = C_csp_collector_receiver.S_csp_cr_inputs()
        inputs.m_input_operation_mode = C_csp_collector_receiver.ON
        inputs.m_field_control = field_control
        self.call(weather, htf_state_in, inputs, cr_out_solver, sim_info)

    def estimates(inout self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inout est_out: C_csp_collector_receiver.S_csp_cr_est_out, sim_info: C_csp_solver_sim_info):
        var inputs: C_csp_collector_receiver.S_csp_cr_inputs = C_csp_collector_receiver.S_csp_cr_inputs()
        inputs.m_input_operation_mode = C_csp_collector_receiver.STEADY_STATE
        inputs.m_field_control = 1.0
        var cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver = C_csp_collector_receiver.S_csp_cr_out_solver()
        self.call(weather, htf_state_in, inputs, cr_out_solver, sim_info)
        var mode: Int = self.get_operating_state()
        if mode == C_csp_collector_receiver.ON:
            est_out.m_q_dot_avail = cr_out_solver.m_q_thermal            #[MWt]
            est_out.m_m_dot_avail = cr_out_solver.m_m_dot_salt_tot       #[kg/hr]
            est_out.m_T_htf_hot = cr_out_solver.m_T_salt_hot             #[C]
            est_out.m_q_startup_avail = 0.0
        else:
            est_out.m_q_startup_avail = cr_out_solver.m_q_thermal        #[MWt]
            est_out.m_q_dot_avail = 0.0
            est_out.m_m_dot_avail = 0.0
            est_out.m_T_htf_hot = 0.0

    def calculate_optical_efficiency(inout self, weather: C_csp_weatherreader.S_outputs, sim: C_csp_solver_sim_info) -> Float64:
        """
        Evaluate optical efficiency. This is a required function for the parent class, 
        but doesn't do much other than simply call the optical efficiency model in this case.
        """
        self.mc_pt_heliostatfield.call(weather, 1., sim)
        return self.mc_pt_heliostatfield.ms_outputs.m_eta_field

    def get_collector_area(inout self) -> Float64:
        return self.mc_pt_heliostatfield.ms_params.m_A_sf

    def calculate_thermal_efficiency_approx(inout self, weather: C_csp_weatherreader.S_outputs, q_inc: Float64) -> Float64:
        """ 
        A very approximate thermal efficiency used for quick optimization performance projections
        """
        var T_eff: Float64 = (self.mc_pt_receiver.m_T_htf_cold_des + self.mc_pt_receiver.m_T_htf_hot_des) * 0.55
        var T_amb: Float64 = weather.m_tdry + 273.15
        var T_eff4: Float64 = T_eff * T_eff
        T_eff4 *= T_eff4
        var T_amb4: Float64 = T_amb * T_amb
        T_amb4 *= T_amb4
        var Arec: Float64 = self.mc_pt_receiver.area_proj()
        var q_rad: Float64 = 5.67e-8 * self.mc_pt_receiver.m_epsilon * Arec * (T_eff4 - T_amb4) * 1.e-6   #MWt
        var v: Float64 = weather.m_wspd
        var v2: Float64 = v * v
        var v3: Float64 = v2 * v
        var q_conv: Float64 = q_rad / 2. * (-0.001129 * v3 + 0.031229 * v2 - 0.01822 * v + 0.962476)  #convection is about half radiation, scale by wind speed. surrogate regression from molten salt run.
        return max(1. - (q_rad + q_conv) / q_inc, 0.)

    def converged(inout self):
        self.mc_pt_heliostatfield.converged()
        self.mc_pt_receiver.converged()
        self.mc_reported_outputs.set_timestep_outputs()

    def write_output_intervals(inout self, report_time_start: Float64, v_temp_ts_time_end: List[Float64], report_time_end: Float64):
        self.mc_reported_outputs.send_to_reporting_ts_array(report_time_start, v_temp_ts_time_end, report_time_end)