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
from math import pow

enum:
    P_piping_loss = 0
    P_PIPE_LENGTH_ADD = 1
    P_PIPE_LENGTH_MULT = 2
    P_THT = 3
    P_design_power = 4
    P_design_eff = 5
    P_pb_fixed_par = 6
    P_aux_par = 7
    P_aux_par_f = 8
    P_aux_par_0 = 9
    P_aux_par_1 = 10
    P_aux_par_2 = 11
    P_bop_par = 12
    P_bop_par_f = 13
    P_bop_par_0 = 14
    P_bop_par_1 = 15
    P_bop_par_2 = 16
    I_P_cooling_tower = 17
    I_P_tower_pump = 18
    I_P_helio_track = 19
    I_P_plant_output = 20
    I_eta_cycle = 21
    I_P_cold_tank = 22
    I_P_hot_tank = 23
    I_aux_power = 24
    I_P_htf_pump = 25
    O_P_plant_balance_tot = 26
    O_P_cooling_tower_tot = 27
    O_P_piping_tot = 28
    O_P_parasitics = 29
    O_P_out_net = 30
    O_P_tank_heater = 31
    O_P_fixed = 32
    O_P_aux = 33
    N_MAX = 34

var sam_mw_pt_type228_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_piping_loss, "Piping_loss", "Thermal loss per meter of piping", "Wt/m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PIPE_LENGTH_ADD, "piping_length_add", "Value added to product of tower height*piping length multiple", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PIPE_LENGTH_MULT, "piping_length_mult", "Value multiplied to tower height", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_THT, "THT", "The height of the tower (hel. pivot to rec equator)", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_design_power, "Design_power", "Power production at design conditions", "MWe", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_design_eff, "design_eff", "Power cycle efficiency at design", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_pb_fixed_par, "pb_fixed_par", "Fixed parasitic load - runs at all times", "MWe/MWcap", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_aux_par, "aux_par", "Aux heater, boiler parasitic", "MWe/MWcap", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_aux_par_f, "aux_par_f", "Aux heater, boiler parasitic - multiplying fraction", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_aux_par_0, "aux_par_0", "Aux heater, boiler parasitic - constant coefficient", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_aux_par_1, "aux_par_1", "Aux heater, boiler parasitic - linear coefficient", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_aux_par_2, "aux_par_2", "Aux heater, boiler parasitic - quadratic coefficient", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_bop_par, "bop_par", "Balance of plant parasitic power fraction", "MWe/MWcap", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_bop_par_f, "bop_par_f", "Balance of plant parasitic power fraction - mult frac", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_bop_par_0, "bop_par_0", "Balance of plant parasitic power fraction - const coeff", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_bop_par_1, "bop_par_1", "Balance of plant parasitic power fraction - linear coeff", "none", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_bop_par_2, "bop_par_2", "Balance of plant parasitic power fraction - quadratic coeff", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_cooling_tower, "P_cooling_tower", "Cooling tower parasitic power fraction", "MWe", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_tower_pump, "P_tower_pump", "Reported tower pump power", "MWe", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_helio_track, "P_helio_track", "Reported heliostat tracking power", "MWe", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_plant_output, "P_plant_output", "Reported plant power output", "MWe", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_eta_cycle, "eta_cycle", "Power cycle efficiency", "none", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_cold_tank, "P_cold_tank", "Cold tank heater parasitic power", "MWe", "", "", "0.0"),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_hot_tank, "P_hot_tank", "Hot tank heater parasitic power", "MWe", "", "", "0.0"),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_aux_power, "aux_power", "Auxiliary heater thermal power output", "MWt", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_htf_pump, "P_htf_pump", "HTF pumping power", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_plant_balance_tot, "P_plant_balance_tot", "Total balance of plant parasitic power", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_cooling_tower_tot, "P_cooling_tower_tot", "Total cooling tower parasitic power", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_piping_tot, "P_piping_tot", "Total piping loss parasitic power", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_parasitics, "P_parasitics", "Overall parasitic losses", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_out_net, "P_out_net", "Power to the grid after parasitic losses", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_tank_heater, "P_tank_heater", "Total tank heater parasitic power", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_fixed, "P_fixed", "Total fixed parasitic loss", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_aux, "P_aux", "Total auxiliary heater parasitic loss", "MWe", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
)

@value
struct sam_mw_pt_type228(tcstypeinterface):
    var m_Q_dot_piping_loss: Float64
    var Design_power: Float64
    var design_eff: Float64
    var pb_fixed_par: Float64
    var aux_par: Float64
    var aux_par_f: Float64
    var aux_par_0: Float64
    var aux_par_1: Float64
    var aux_par_2: Float64
    var bop_par: Float64
    var bop_par_f: Float64
    var bop_par_0: Float64
    var bop_par_1: Float64
    var bop_par_2: Float64

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cst, ti)
        self.m_Q_dot_piping_loss = Float64.NAN
        self.Design_power = Float64.NAN
        self.design_eff = Float64.NAN
        self.pb_fixed_par = Float64.NAN
        self.aux_par = Float64.NAN
        self.aux_par_f = Float64.NAN
        self.aux_par_0 = Float64.NAN
        self.aux_par_1 = Float64.NAN
        self.aux_par_2 = Float64.NAN
        self.bop_par = Float64.NAN
        self.bop_par_f = Float64.NAN
        self.bop_par_0 = Float64.NAN
        self.bop_par_1 = Float64.NAN
        self.bop_par_2 = Float64.NAN

    def __del__(owned self):

    def init(inout self) -> Int:
        var pipe_loss_per_m = self.value(P_piping_loss) / 1.0E6  # [MWt/m] convert from Wt/m
        var h_tower = self.value(P_THT)  # [m] Tower height
        var pipe_length_mult = self.value(P_PIPE_LENGTH_MULT)  # [-]
        var pipe_length_add = self.value(P_PIPE_LENGTH_ADD)  # [m]
        self.m_Q_dot_piping_loss = pipe_loss_per_m * (h_tower * pipe_length_mult + pipe_length_add)  # [MWt]
        self.Design_power = self.value(P_design_power)  # [MWe]
        self.design_eff = self.value(P_design_eff)  # [-]
        self.pb_fixed_par = self.value(P_pb_fixed_par)  # [MWe/MWcap]
        self.aux_par = self.value(P_aux_par)  # [MWe/MWcap]
        self.aux_par_f = self.value(P_aux_par_f)  # [-]
        self.aux_par_0 = self.value(P_aux_par_0)  # [-]
        self.aux_par_1 = self.value(P_aux_par_1)  # [-]
        self.aux_par_2 = self.value(P_aux_par_2)  # [-]
        self.bop_par = self.value(P_bop_par)  # [MWe/MWcap]
        self.bop_par_f = self.value(P_bop_par_f)  # [-]
        self.bop_par_0 = self.value(P_bop_par_0)  # [-]
        self.bop_par_1 = self.value(P_bop_par_1)  # [-]
        self.bop_par_2 = self.value(P_bop_par_2)  # [-]
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        var P_cooling_tower = self.value(I_P_cooling_tower)  # [MWe] Cooling parasitics from power cycle model
        var P_tower_pump = self.value(I_P_tower_pump)  # [MWe] Power required to pump HTF through the tower
        var P_helio_track = self.value(I_P_helio_track)  # [MWe] Power required to startup/stow/track heliostats
        var P_plant_output = self.value(I_P_plant_output)  # [MWe] Electric output from power cycle model (not including cooling parasitics)
        var eta_cycle = self.value(I_eta_cycle)  # [-] Power cycle thermal efficiency considering cycle generation (defined above) and thermal input
        var P_cold_tank = self.value(I_P_cold_tank)  # [MWe] Power required to keep cold tank at its minimum temperature
        var P_hot_tank = self.value(I_P_hot_tank)  # [MWe] Power required to keep hot tank at its minimum temperature
        var aux_power = self.value(I_aux_power)  # [MWt] Aux power used during timestep
        var P_htf_pump = self.value(I_P_htf_pump)  # [MWe] Power required to pump HTF through PC AND TES (but no TES storage side pumping)
        var P_ratio = P_plant_output / self.Design_power
        var aux_ratio = aux_power / self.Design_power / self.design_eff
        var P_fixed = self.pb_fixed_par * self.Design_power  # [MWe]
        var P_plant_balance_tot: Float64
        if P_plant_output > 0.0:
            P_plant_balance_tot = self.Design_power * self.bop_par * self.bop_par_f * (self.bop_par_0 + self.bop_par_1 * P_ratio + self.bop_par_2 * pow(P_ratio, 2))
        else:
            P_plant_balance_tot = 0.0
        var P_aux: Float64
        if aux_ratio > 0.0:
            P_aux = self.Design_power * self.aux_par * self.aux_par_f * (self.aux_par_0 + self.aux_par_1 * aux_ratio + self.aux_par_2 * pow(aux_ratio, 2))
        else:
            P_aux = 0.0
        var P_cooling_tower_tot = P_cooling_tower  # [MWe]
        var P_piping_tot = self.m_Q_dot_piping_loss * eta_cycle * P_plant_output / self.Design_power  # MWe
        var P_tank_heater = P_cold_tank + P_hot_tank  # MWe
        var P_parasitics = P_plant_balance_tot + P_cooling_tower_tot + P_fixed + P_tower_pump + P_helio_track + P_piping_tot + P_tank_heater + P_aux + P_htf_pump
        self.value(O_P_plant_balance_tot, P_plant_balance_tot)
        self.value(O_P_cooling_tower_tot, P_cooling_tower_tot)
        self.value(O_P_piping_tot, P_piping_tot)
        self.value(O_P_parasitics, P_parasitics)
        self.value(O_P_out_net, P_plant_output - P_parasitics)
        self.value(O_P_tank_heater, P_tank_heater)
        self.value(O_P_fixed, P_fixed)
        self.value(O_P_aux, P_aux)
        return 0

    def converged(inout self, time: Float64) -> Int:
        return 0

TCS_IMPLEMENT_TYPE(sam_mw_pt_type228, "Power Tower Parasitics", "Ty Neises", 1, sam_mw_pt_type228_variables, None, 1)