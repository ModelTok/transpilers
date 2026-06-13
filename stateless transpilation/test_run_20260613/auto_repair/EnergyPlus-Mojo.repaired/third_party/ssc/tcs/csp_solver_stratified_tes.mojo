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

from csp_solver_core import C_csp_tes, C_csp_exception, C_csp_messages
from csp_solver_util import util, HTFProperties, two_tank_tes_sizing
from sam_csp_util import CSP
from csp_solver_two_tank_tes import C_hx_cold_tes
from math import pow, exp, sqrt, fmax, pi  # note: fmax is built-in as max

# Note: pi constant from CSP is used, but we import math for pow/exp/sqrt

class C_storage_node:
    var mc_htf: HTFProperties
    var m_V_total: Float64  #[m^3] Total volume for *one temperature* tank
    var m_V_active: Float64 #[m^3] active volume of *one temperature* tank (either cold or hot)
    var m_V_inactive: Float64  #[m^3] INactive volume of *one temperature* tank (either cold or hot)
    var m_UA: Float64   #[W/K] Tank loss conductance
    var m_T_htr: Float64 #[K] Tank heater set point
    var m_max_q_htr: Float64   #[MWt] Max tank heater capacity
    var m_V_prev: Float64  #[m^3] Volume of storage fluid in tank
    var m_T_prev: Float64  #[K] Temperature of storage fluid in tank
    var m_m_prev: Float64  #[kg] Mass of storage fluid in tank
    var m_V_calc: Float64  #[m^3] Volume of storage fluid in tank
    var m_T_calc: Float64  #[K] Temperature of storage fluid in tank
    var m_m_calc: Float64  #[kg] Mass of storage fluid in tank

    def __init__(inout self):
        self.m_V_prev = Float64.NAN
        self.m_T_prev = Float64.NAN
        self.m_m_prev = Float64.NAN
        self.m_V_total = Float64.NAN
        self.m_V_active = Float64.NAN
        self.m_V_inactive = Float64.NAN
        self.m_UA = Float64.NAN
        self.m_T_htr = Float64.NAN
        self.m_max_q_htr = Float64.NAN

    def init(inout self, htf_class_in: HTFProperties, V_tank_one_temp: Float64, h_tank: Float64, lid: Bool, u_tank: Float64,
        tank_pairs: Float64, T_htr: Float64, max_q_htr: Float64, V_ini: Float64, T_ini: Float64):
        self.mc_htf = htf_class_in
        self.m_V_total = V_tank_one_temp  #[m^3]
        var A_cs: Float64 = self.m_V_total / (h_tank * tank_pairs)  #[m^2] Cross-sectional area of a single tank
        var diameter: Float64 = pow(A_cs / CSP.pi, 0.5) * 2.0  #[m] Diameter of a single tank
        if lid:
            # Calculate tank conductance if including top area in losses (top node of stratified tank.)
            self.m_UA = u_tank * (A_cs + CSP.pi * diameter * h_tank) * tank_pairs  #[W/K]
        if not lid:
            # Calculate tank conductance if only including sides of node
            self.m_UA = u_tank * (CSP.pi * diameter * h_tank) * tank_pairs  #[W/K]
        self.m_T_htr = T_htr
        self.m_max_q_htr = max_q_htr
        self.m_V_prev = V_ini
        self.m_T_prev = T_ini
        self.m_m_prev = self.calc_mass_at_prev()

    def calc_mass_at_prev(inout self) -> Float64:
        return self.m_V_prev * self.mc_htf.dens(self.m_T_prev, 1.0)  #[kg] 

    def get_m_T_prev(inout self) -> Float64:
        return self.m_T_prev  #[K]

    def get_m_T_calc(inout self) -> Float64:
        return self.m_T_calc

    def get_m_m_calc(inout self) -> Float64:
        return self.m_m_calc

    def m_dot_available(inout self, f_unavail: Float64, timestep: Float64) -> Float64:
        var rho: Float64 = self.mc_htf.dens(self.m_T_prev, 1.0)  #[kg/m^3]
        var V: Float64 = self.m_m_prev / rho  #[m^3] Volume available in tank (one temperature)
        var V_avail: Float64 = fmax(V - self.m_V_inactive, 0.0)  #[m^3] Volume that is active - need to maintain minimum height (corresponding m_V_inactive)
        var m_dot_avail: Float64 = fmax(V_avail - self.m_V_active * f_unavail, 0.0) * rho / timestep  #[kg/s] Max mass flow rate available
        return m_dot_avail  #[kg/s]

    def converged(inout self):
        self.m_V_prev = self.m_V_calc  #[m^3]
        self.m_T_prev = self.m_T_calc  #[K]
        self.m_m_prev = self.m_m_calc  #[kg]

    def energy_balance(inout self, timestep: Float64, m_dot_in: Float64, m_dot_out: Float64, T_in: Float64, T_amb: Float64,
        inout T_ave: Float64, inout q_heater: Float64, inout q_dot_loss: Float64):
        var rho: Float64 = self.mc_htf.dens(self.m_T_prev, 1.0)  #[kg/m^3]
        var cp: Float64 = self.mc_htf.Cp(self.m_T_prev) * 1000.0  #[J/kg-K] spec heat, convert from kJ/kg-K
        self.m_m_calc = fmax(0.001, self.m_m_prev + timestep * (m_dot_in - m_dot_out))  #[kg] Available mass at the end of this timestep, limit to nonzero positive number
        self.m_V_calc = self.m_m_calc / rho  #[m^3] Available volume at end of timestep (using initial temperature...)		
        if (m_dot_in - m_dot_out) != 0.0:
            var a_coef: Float64 = m_dot_in * T_in + self.m_UA / cp * T_amb
            var b_coef: Float64 = m_dot_in + self.m_UA / cp
            var c_coef: Float64 = (m_dot_in - m_dot_out)
            self.m_T_calc = a_coef / b_coef + (self.m_T_prev - a_coef / b_coef) * pow((timestep * c_coef / self.m_m_prev + 1), -b_coef / c_coef)
            T_ave = a_coef / b_coef + self.m_m_prev * (self.m_T_prev - a_coef / b_coef) / ((c_coef - b_coef) * timestep) * (pow((timestep * c_coef / self.m_m_prev + 1.0), 1.0 - b_coef / c_coef) - 1.0)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1.E6  #[MW]
            if self.m_T_calc < self.m_T_htr:
                q_heater = b_coef * ((self.m_T_htr - self.m_T_prev * pow((timestep * c_coef / self.m_m_prev + 1), -b_coef / c_coef)) /
                    (-pow((timestep * c_coef / self.m_m_prev + 1), -b_coef / c_coef) + 1)) - a_coef
                q_heater = q_heater * cp
                q_heater /= 1.E6
            else:
                q_heater = 0.0
                return
            if q_heater > self.m_max_q_htr:
                q_heater = self.m_max_q_htr
            a_coef += q_heater * 1.E6 / cp
            self.m_T_calc = a_coef / b_coef + (self.m_T_prev - a_coef / b_coef) * pow((timestep * c_coef / self.m_m_prev + 1), -b_coef / c_coef)
            T_ave = a_coef / b_coef + self.m_m_prev * (self.m_T_prev - a_coef / b_coef) / ((c_coef - b_coef) * timestep) * (pow((timestep * c_coef / self.m_m_prev + 1.0), 1.0 - b_coef / c_coef) - 1.0)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1.E6  #[MW]
        else:  # No mass flow rate, tank is idle
            var b_coef: Float64 = self.m_UA / (cp * self.m_m_prev)
            var c_coef: Float64 = self.m_UA / (cp * self.m_m_prev) * T_amb
            self.m_T_calc = c_coef / b_coef + (self.m_T_prev - c_coef / b_coef) * exp(-b_coef * timestep)
            T_ave = c_coef / b_coef - (self.m_T_prev - c_coef / b_coef) / (b_coef * timestep) * (exp(-b_coef * timestep) - 1.0)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1.E6
            if self.m_T_calc < self.m_T_htr:
                q_heater = (b_coef * (self.m_T_htr - self.m_T_prev * exp(-b_coef * timestep)) / (-exp(-b_coef * timestep) + 1.0) - c_coef) * cp * self.m_m_prev
                q_heater /= 1.E6  #[MW]
            else:
                q_heater = 0.0
                return
            if q_heater > self.m_max_q_htr:
                q_heater = self.m_max_q_htr
            c_coef += q_heater * 1.E6 / (cp * self.m_m_prev)
            self.m_T_calc = c_coef / b_coef + (self.m_T_prev - c_coef / b_coef) * exp(-b_coef * timestep)
            T_ave = c_coef / b_coef - (self.m_T_prev - c_coef / b_coef) / (b_coef * timestep) * (exp(-b_coef * timestep) - 1.0)
            q_dot_loss = self.m_UA * (T_ave - T_amb) / 1.E6  #[MW]

    def energy_balance_constant_mass(inout self, timestep: Float64, m_dot_in: Float64, T_in: Float64, T_amb: Float64,
        inout T_ave: Float64, inout q_heater: Float64, inout q_dot_loss: Float64):
        var rho: Float64 = self.mc_htf.dens(self.m_T_prev, 1.0)  #[kg/m^3]
        var cp: Float64 = self.mc_htf.Cp(self.m_T_prev) * 1000.0  #[J/kg-K] spec heat, convert from kJ/kg-K
        self.m_m_calc = self.m_m_prev  #[kg] Available mass at the end of this timestep, same as previous
        self.m_V_calc = self.m_m_calc / rho  #[m^3] Available volume at end of timestep (using initial temperature...)		
        var a_coef: Float64 = m_dot_in / self.m_m_calc + self.m_UA / (self.m_m_calc * cp)
        var b_coef: Float64 = m_dot_in / self.m_m_calc * T_in + self.m_UA / (self.m_m_calc * cp) * T_amb
        self.m_T_calc = b_coef / a_coef - (b_coef / a_coef - self.m_T_prev) * exp(-a_coef * timestep)
        T_ave = b_coef / a_coef - (b_coef / a_coef - self.m_T_prev) * exp(-a_coef * timestep / 2) #estimate of average
        q_dot_loss = self.m_UA * (T_ave - T_amb) / 1.E6  #[MW]
        q_heater = 0.0  #Assume no heater.
        return

class C_csp_stratified_tes: #Class for cold storage based on two tank tes ARD
    var mc_field_htfProps: HTFProperties  # Instance of HTFProperties class for field HTF
    var mc_store_htfProps: HTFProperties  # Instance of HTFProperties class for storage HTF
    var mc_hx: C_hx_cold_tes
    var mc_node_one: C_storage_node  # Instance of storage node class for the top node
    var mc_node_two: C_storage_node
    var mc_node_three: C_storage_node
    var mc_node_four: C_storage_node
    var mc_node_five: C_storage_node  # Upto six nodes allowed
    var mc_node_n: C_storage_node  # Instance of storage node class for the bottom node
    var error_msg: String
    var m_m_dot_tes_dc_max: Float64
    var m_m_dot_tes_ch_max: Float64
    var m_is_tes: Bool
    var m_vol_tank: Float64  #[m3] volume of *one temperature*, i.e. vol_tank = total cold storage = total hot storage
    var m_V_tank_active: Float64  #[m^3] available volume (considering h_min) of *one temperature*
    var m_q_pb_design: Float64  #[Wt] thermal power to power cycle at design
    var m_V_tank_hot_ini: Float64  #[m^3] Initial volume in hot storage tank

    var mc_csp_messages: C_csp_messages

    struct S_csp_strat_tes_outputs:
        var m_q_heater: Float64  #[MWe]  Heating power required to keep tanks at a minimum temperature
        var m_m_dot: Float64  #[kg/s] Hot tank mass flow rate, valid for direct and indirect systems
        var m_W_dot_rhtf_pump: Float64  #[MWe]  Pumping power, just for tank-to-tank in indirect storage
        var m_q_dot_loss: Float64  #[MWt]  Storage thermal losses
        var m_q_dot_dc_to_htf: Float64  #[MWt]  Thermal power to the HTF from storage
        var m_q_dot_ch_from_htf: Float64  #[MWt]  Thermal power from the HTF to storage
        var m_T_hot_ave: Float64  #[K]    Average hot tank temperature over timestep
        var m_T_cold_ave: Float64  #[K]    Average cold tank temperature over timestep
        var m_T_hot_final: Float64  #[K]    Hot tank temperature at end of timestep
        var m_T_cold_final: Float64  #[K]    Cold tank temperature at end of timestep

        def __init__(inout self):
            self.m_q_heater = Float64.NAN
            self.m_m_dot = Float64.NAN
            self.m_W_dot_rhtf_pump = Float64.NAN
            self.m_q_dot_loss = Float64.NAN
            self.m_q_dot_dc_to_htf = Float64.NAN
            self.m_q_dot_ch_from_htf = Float64.NAN
            self.m_T_hot_ave = Float64.NAN
            self.m_T_cold_ave = Float64.NAN
            self.m_T_hot_final = Float64.NAN
            self.m_T_cold_final = Float64.NAN

    struct S_params:
        var m_field_fl: Int
        var m_field_fl_props: util.matrix_t[Float64]
        var m_tes_fl: Int
        var m_tes_fl_props: util.matrix_t[Float64]
        var m_is_hx: Bool
        var m_W_dot_pc_design: Float64  #[MWe] Design point gross power cycle output
        var m_eta_pc_factor: Float64  #[-] Factor accounting for Design point power cycle thermal efficiency
        var m_solarm: Float64  #[-] solar multiple
        var m_ts_hours: Float64  #[hr] hours of storage at design power cycle operation		
        var m_h_tank: Float64  #[m] tank height
        var m_u_tank: Float64  #[W/m^2-K]
        var m_tank_pairs: Int  #[-]
        var m_hot_tank_Thtr: Float64  #[C] convert to K in init()
        var m_hot_tank_max_heat: Float64  #[MW]
        var m_cold_tank_Thtr: Float64  #[C] convert to K in init()
        var m_cold_tank_max_heat: Float64  #[MW]
        var m_dt_hot: Float64  #[C] Temperature difference across heat exchanger - assume hot and cold deltaTs are equal
        var m_T_field_in_des: Float64  #[C] convert to K in init()
        var m_T_field_out_des: Float64  #[C] convert to K in init()
        var m_T_tank_hot_ini: Float64  #[C] Initial temperature in hot storage tank
        var m_T_tank_cold_ini: Float64  #[C] Initial temperature in cold storage cold
        var m_h_tank_min: Float64  #[m] Minimum allowable HTF height in storage tank
        var m_f_V_hot_ini: Float64  #[%] Initial fraction of available volume that is hot
        var m_htf_pump_coef: Float64  #[kW/kg/s] Pumping power to move 1 kg/s of HTF through power cycle
        var dT_cw_rad: Float64  #[degrees] Temperature change in cooling water for cold storage cooling.
        var m_dot_cw_rad: Float64  #[kg/sec]	Mass flow of cooling water for cold storage cooling at design.
        var m_ctes_type: Int  #2= two tank (this model) 3=three node (other model)
        var m_dot_cw_cold: Float64  #[kg/sec]	Mass flow of storage water between cold storage and radiative field HX.
        var m_lat: Float64  #Latitude [degrees]

        def __init__(inout self):
            self.m_field_fl = -1
            self.m_tes_fl = -1
            self.m_tank_pairs = -1
            self.m_is_hx = True
            self.m_ts_hours = 0.0  #[hr] Default to 0 so that if storage isn't defined, simulation won't crash
            self.m_W_dot_pc_design = Float64.NAN
            self.m_eta_pc_factor = Float64.NAN
            self.m_solarm = Float64.NAN
            self.m_h_tank = Float64.NAN
            self.m_u_tank = Float64.NAN
            self.m_hot_tank_Thtr = Float64.NAN
            self.m_hot_tank_max_heat = Float64.NAN
            self.m_cold_tank_Thtr = Float64.NAN
            self.m_cold_tank_max_heat = Float64.NAN
            self.m_dt_hot = Float64.NAN
            self.m_T_field_in_des = Float64.NAN
            self.m_T_field_out_des = Float64.NAN
            self.m_T_tank_hot_ini = Float64.NAN
            self.m_T_tank_cold_ini = Float64.NAN
            self.m_h_tank_min = Float64.NAN
            self.m_f_V_hot_ini = Float64.NAN
            self.m_htf_pump_coef = Float64.NAN
            self.dT_cw_rad = Float64.NAN
            self.m_dot_cw_rad = Float64.NAN
            self.m_dot_cw_cold = Float64.NAN
            self.m_lat = Float64.NAN

    var ms_params: S_params

    def __init__(inout self):
        self.m_vol_tank = Float64.NAN
        self.m_V_tank_active = Float64.NAN
        self.m_q_pb_design = Float64.NAN
        self.m_V_tank_hot_ini = Float64.NAN
        self.m_m_dot_tes_dc_max = Float64.NAN
        self.m_m_dot_tes_ch_max = Float64.NAN
        # initialize members with default constructors
        self.mc_node_one = C_storage_node()
        self.mc_node_two = C_storage_node()
        self.mc_node_three = C_storage_node()
        self.mc_node_four = C_storage_node()
        self.mc_node_five = C_storage_node()
        self.mc_node_n = C_storage_node()
        self.mc_csp_messages = C_csp_messages()

    def init(inout self, init_inputs: C_csp_tes.S_csp_tes_init_inputs):
        if not (self.ms_params.m_ts_hours > 0.0):
            self.m_is_tes = False
            return  # No storage!
        self.m_is_tes = True

        if self.ms_params.m_field_fl != HTFProperties.User_defined and self.ms_params.m_field_fl < HTFProperties.End_Library_Fluids:
            if not self.mc_field_htfProps.SetFluid(self.ms_params.m_field_fl):
                raise C_csp_exception("Field HTF code is not recognized", "Two Tank TES Initialization")
        elif self.ms_params.m_field_fl == HTFProperties.User_defined:
            var n_rows: Int = self.ms_params.m_field_fl_props.nrows() as Int
            var n_cols: Int = self.ms_params.m_field_fl_props.ncols() as Int
            if n_rows > 2 and n_cols == 7:
                if not self.mc_field_htfProps.SetUserDefinedFluid(self.ms_params.m_field_fl_props):
                    self.error_msg = util.format(self.mc_field_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
            else:
                self.error_msg = util.format("The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
        else:
            raise C_csp_exception("Field HTF code is not recognized", "Two Tank TES Initialization")

        if self.ms_params.m_tes_fl != HTFProperties.User_defined and self.ms_params.m_tes_fl < HTFProperties.End_Library_Fluids:
            if not self.mc_store_htfProps.SetFluid(self.ms_params.m_tes_fl):
                raise C_csp_exception("Storage HTF code is not recognized", "Two Tank TES Initialization")
        elif self.ms_params.m_tes_fl == HTFProperties.User_defined:
            var n_rows: Int = self.ms_params.m_tes_fl_props.nrows() as Int
            var n_cols: Int = self.ms_params.m_tes_fl_props.ncols() as Int
            if n_rows > 2 and n_cols == 7:
                if not self.mc_store_htfProps.SetUserDefinedFluid(self.ms_params.m_tes_fl_props):
                    self.error_msg = util.format(self.mc_store_htfProps.UserFluidErrMessage(), n_rows, n_cols)
                    raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
            else:
                self.error_msg = util.format("The user defined storage HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise C_csp_exception(self.error_msg, "Two Tank TES Initialization")
        else:
            raise C_csp_exception("Storage HTF code is not recognized", "Two Tank TES Initialization")

        var is_hx_calc: Bool = True
        if self.ms_params.m_tes_fl != self.ms_params.m_field_fl:
            is_hx_calc = True
        elif self.ms_params.m_field_fl != HTFProperties.User_defined:
            is_hx_calc = False
        else:
            is_hx_calc = not self.mc_field_htfProps.equals(&self.mc_store_htfProps)

        if self.ms_params.m_is_hx != is_hx_calc:
            if is_hx_calc:
                self.mc_csp_messages.add_message(C_csp_messages.NOTICE, "Input field and storage fluids are different, but the inputs did not specify a field-to-storage heat exchanger. The system was modeled assuming a heat exchanger.")
            else:
                self.mc_csp_messages.add_message(C_csp_messages.NOTICE, "Input field and storage fluids are identical, but the inputs specified a field-to-storage heat exchanger. The system was modeled assuming no heat exchanger.")
            self.ms_params.m_is_hx = is_hx_calc

        self.m_q_pb_design = self.ms_params.m_W_dot_pc_design / self.ms_params.m_eta_pc_factor * 1.E6  #[Wt] - using pc efficiency factor for cold storage ARD
        self.ms_params.m_hot_tank_Thtr += 273.15  #[K] convert from C
        self.ms_params.m_cold_tank_Thtr += 273.15  #[K] convert from C
        self.ms_params.m_T_field_in_des += 273.15  #[K] convert from C
        self.ms_params.m_T_field_out_des += 273.15  #[K] convert from C
        self.ms_params.m_T_tank_hot_ini += 273.15  #[K] convert from C
        self.ms_params.m_T_tank_cold_ini += 273.15  #[K] convert from C

        var Q_tes_des: Float64 = self.m_q_pb_design / 1.E6 * self.ms_params.m_ts_hours  #[MWt-hr] TES thermal capacity at design
        var d_tank_temp: Float64 = Float64.NAN
        var q_dot_loss_temp: Float64 = Float64.NAN
        two_tank_tes_sizing(self.mc_store_htfProps, Q_tes_des, self.ms_params.m_T_field_out_des, self.ms_params.m_T_field_in_des,
            self.ms_params.m_h_tank_min, self.ms_params.m_h_tank, self.ms_params.m_tank_pairs, self.ms_params.m_u_tank,
            self.m_V_tank_active, self.m_vol_tank, d_tank_temp, q_dot_loss_temp)

        var duty: Float64 = self.m_q_pb_design * fmax(1.0, self.ms_params.m_solarm)  #[W] Allow all energy from the field to go into storage at any time
        if self.ms_params.m_ts_hours > 0.0:
            self.mc_hx.init(self.mc_field_htfProps, self.mc_store_htfProps, duty, self.ms_params.m_dt_hot, self.ms_params.m_T_field_out_des, self.ms_params.m_T_field_in_des)

        var n_nodes: Int = self.ms_params.m_ctes_type  #local variable for number of nodes
        var V_node_ini: Float64 = self.m_V_tank_active / n_nodes  #[m^3] Each node has equal volume
        var T_hot_ini: Float64 = self.ms_params.m_T_tank_hot_ini  #[K]
        var T_cold_ini: Float64 = self.ms_params.m_T_tank_cold_ini  #[K]
        var dT_node_ini: Float64 = (T_hot_ini - T_cold_ini)  #[K] spacing in temperature to initialize
        var h_node: Float64 = self.ms_params.m_h_tank / n_nodes  #Height of each section of tank equal divided equally

        self.mc_node_n.init(self.mc_store_htfProps, V_node_ini, h_node, False,
            self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_cold_tank_Thtr, self.ms_params.m_cold_tank_max_heat,
            V_node_ini, T_cold_ini)

        if n_nodes >= 6:
            self.mc_node_five.init(self.mc_store_htfProps, V_node_ini, h_node, False,
                self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_cold_tank_Thtr, self.ms_params.m_cold_tank_max_heat,
                V_node_ini, T_cold_ini + (n_nodes - 5.0) / (n_nodes - 1.0) * dT_node_ini) #Assume equal spacing between initial temperatures
        if n_nodes >= 5:
            self.mc_node_four.init(self.mc_store_htfProps, V_node_ini, h_node, False,
                self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_cold_tank_Thtr, self.ms_params.m_cold_tank_max_heat,
                V_node_ini, T_cold_ini + (n_nodes - 4.0) / (n_nodes - 1.0) * dT_node_ini)
        if n_nodes >= 4:
            self.mc_node_three.init(self.mc_store_htfProps, V_node_ini, h_node, False,
                self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_cold_tank_Thtr, self.ms_params.m_cold_tank_max_heat,
                V_node_ini, T_cold_ini + (n_nodes - 3.0) / (n_nodes - 1.0) * dT_node_ini)
        if n_nodes >= 3:
            self.mc_node_two.init(self.mc_store_htfProps, V_node_ini, h_node, False,
                self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_cold_tank_Thtr, self.ms_params.m_cold_tank_max_heat,
                V_node_ini, T_cold_ini + (n_nodes - 2.0) / (n_nodes - 1.0) * dT_node_ini)

        self.mc_node_one.init(self.mc_store_htfProps, V_node_ini, h_node, True,
            self.ms_params.m_u_tank, self.ms_params.m_tank_pairs, self.ms_params.m_hot_tank_Thtr, self.ms_params.m_hot_tank_max_heat,
            V_node_ini, T_hot_ini)

    def does_tes_exist(inout self) -> Bool:
        return self.m_is_tes

    def get_hot_temp(inout self) -> Float64:
        return self.mc_node_one.get_m_T_prev()  #[K]

    def get_cold_temp(inout self) -> Float64:
        return self.mc_node_n.get_m_T_prev()  #[K]

    def get_hot_mass(inout self) -> Float64:
        return self.mc_node_one.get_m_m_calc()  # [kg]

    def get_cold_mass(inout self) -> Float64:
        return self.mc_node_n.get_m_m_calc()  #[kg]

    def get_hot_mass_prev(inout self) -> Float64:
        return self.mc_node_one.calc_mass_at_prev()  # [kg]

    def get_cold_mass_prev(inout self) -> Float64:
        return self.mc_node_n.calc_mass_at_prev()  #[kg]

    def get_physical_volume(inout self) -> Float64:
        return self.m_vol_tank  #[m^3]

    def get_hot_massflow_avail(inout self, step_s: Float64) -> Float64: #[kg/sec]
        return self.mc_node_one.m_dot_available(0, step_s)

    def get_cold_massflow_avail(inout self, step_s: Float64) -> Float64: #[kg/sec]
        return self.mc_node_n.m_dot_available(0, step_s)

    def get_initial_charge_energy(inout self) -> Float64:
        return self.m_q_pb_design * self.ms_params.m_ts_hours * self.m_V_tank_hot_ini / self.m_vol_tank * 1.e-6

    def get_min_charge_energy(inout self) -> Float64:
        return 0. #ms_params.m_q_pb_design * ms_params.m_ts_hours * ms_params.m_h_tank_min / ms_params.m_h_tank*1.e-6;

    def get_max_charge_energy(inout self) -> Float64:
        return self.m_q_pb_design * self.ms_params.m_ts_hours / 1.e6

    def get_degradation_rate(inout self) -> Float64:
        var d_tank: Float64 = sqrt(self.m_vol_tank / (self.ms_params.m_tank_pairs as Float64 * self.ms_params.m_h_tank * 3.14159))
        var e_loss: Float64 = self.ms_params.m_u_tank * 3.14159 * self.ms_params.m_tank_pairs as Float64 * d_tank * (self.ms_params.m_T_field_in_des + self.ms_params.m_T_field_out_des - 576.3) * 1.e-6  #MJ/s  -- assumes full area for loss, Tamb = 15C
        return e_loss / (self.m_q_pb_design * self.ms_params.m_ts_hours * 3600.) #s^-1  -- fraction of heat loss per second based on full charge

    def discharge_avail_est(inout self, T_cold_K: Float64, step_s: Float64, inout q_dot_dc_est: Float64, inout m_dot_field_est: Float64, inout T_hot_field_est: Float64):
        var f_storage: Float64 = 0.0  # for now, hardcode such that storage always completely discharges
        var m_dot_tank_disch_avail: Float64 = self.mc_node_one.m_dot_available(f_storage, step_s)  #[kg/s]
        var T_hot_ini: Float64 = self.mc_node_one.get_m_T_prev()  #[K]
        if self.ms_params.m_is_hx:
            var eff: Float64 = Float64.NAN
            var T_cold_tes: Float64 = Float64.NAN
            self.mc_hx.hx_discharge_mdot_tes(T_hot_ini, m_dot_tank_disch_avail, T_cold_K, eff, T_cold_tes, T_hot_field_est, q_dot_dc_est, m_dot_field_est)
        else:
            var cp_T_avg: Float64 = self.mc_store_htfProps.Cp(0.5 * (T_cold_K + T_hot_ini))  #[kJ/kg-K] spec heat at average temperature during discharge from hot to cold
            q_dot_dc_est = m_dot_tank_disch_avail * cp_T_avg * (T_hot_ini - T_cold_K) * 1.E-3  #[MW]
            m_dot_field_est = m_dot_tank_disch_avail
            T_hot_field_est = T_hot_ini
        self.m_m_dot_tes_dc_max = m_dot_tank_disch_avail * step_s  #[kg/s]

    def charge_avail_est(inout self, T_hot_K: Float64, step_s: Float64, inout q_dot_ch_est: Float64, inout m_dot_field_est: Float64, inout T_cold_field_est: Float64):
        var f_ch_storage: Float64 = 0.0  # for now, hardcode such that storage always completely charges
        var m_dot_tank_charge_avail: Float64 = self.mc_node_three.m_dot_available(f_ch_storage, step_s)  #[kg/s]
        var T_cold_ini: Float64 = self.mc_node_three.get_m_T_prev()  #[K]
        if self.ms_params.m_is_hx:
            var eff: Float64 = Float64.NAN
            var T_hot_tes: Float64 = Float64.NAN
            self.mc_hx.hx_charge_mdot_tes(T_cold_ini, m_dot_tank_charge_avail, T_hot_K, eff, T_hot_tes, T_cold_field_est, q_dot_ch_est, m_dot_field_est)
        else:
            var cp_T_avg: Float64 = self.mc_store_htfProps.Cp(0.5 * (T_cold_ini + T_hot_K))  #[kJ/kg-K] spec heat at average temperature during charging from cold to hot
            q_dot_ch_est = m_dot_tank_charge_avail * cp_T_avg * (T_hot_K - T_cold_ini) * 1.E-3  #[MW]
            m_dot_field_est = m_dot_tank_charge_avail
            T_cold_field_est = T_cold_ini
        self.m_m_dot_tes_ch_max = m_dot_tank_charge_avail * step_s  #[kg/s]

    def discharge_full(inout self, timestep: Float64, T_amb: Float64, 
        T_htf_cold_in: Float64, inout T_htf_hot_out: Float64, inout m_dot_htf_out: Float64, inout outputs: S_csp_strat_tes_outputs):
        var q_heater_cold: Float64 = Float64.NAN
        var q_heater_hot: Float64 = Float64.NAN
        var q_dot_loss_cold: Float64 = Float64.NAN
        var q_dot_loss_hot: Float64 = Float64.NAN
        var T_cold_ave: Float64 = Float64.NAN
        if not self.ms_params.m_is_hx:
            m_dot_htf_out = self.m_m_dot_tes_dc_max / timestep  #[kg/s]
            self.mc_node_one.energy_balance(timestep, 0.0, m_dot_htf_out, 0.0, T_amb, T_htf_hot_out, q_heater_hot, q_dot_loss_hot)
            self.mc_node_three.energy_balance(timestep, m_dot_htf_out, 0.0, T_htf_cold_in, T_amb, T_cold_ave, q_heater_cold, q_dot_loss_cold)
        else:
            # Iterate between field htf - hx - and storage	

        outputs.m_q_heater = q_heater_cold + q_heater_hot
        outputs.m_m_dot = m_dot_htf_out
        outputs.m_W_dot_rhtf_pump = m_dot_htf_out * self.ms_params.m_htf_pump_coef / 1.E3  #[MWe] Pumping power for Receiver HTF, convert from kW/kg/s*kg/s
        outputs.m_q_dot_loss = q_dot_loss_cold + q_dot_loss_hot
        outputs.m_T_hot_ave = T_htf_hot_out
        outputs.m_T_cold_ave = T_cold_ave
        outputs.m_T_hot_final = self.mc_node_one.get_m_T_calc()  #[K]
        outputs.m_T_cold_final = self.mc_node_three.get_m_T_calc()  #[K]
        var T_htf_ave: Float64 = 0.5 * (T_htf_cold_in + T_htf_hot_out)  #[K]
        var cp_htf_ave: Float64 = self.mc_field_htfProps.Cp(T_htf_ave)  #[kJ/kg-K]
        outputs.m_q_dot_dc_to_htf = m_dot_htf_out * cp_htf_ave * (T_htf_hot_out - T_htf_cold_in) / 1000.0  #[MWt]
        outputs.m_q_dot_ch_from_htf = 0.0  #[MWt]

    def discharge(inout self, timestep: Float64, T_amb: Float64, m_dot_htf_in: Float64, 
        T_htf_cold_in: Float64, inout T_htf_hot_out: Float64, inout outputs: S_csp_strat_tes_outputs) -> Bool:
        var q_heater_cold: Float64 = Float64.NAN
        var q_heater_hot: Float64 = Float64.NAN
        var q_dot_loss_cold: Float64 = Float64.NAN
        var q_dot_loss_hot: Float64 = Float64.NAN
        var T_cold_ave: Float64 = Float64.NAN
        if not self.ms_params.m_is_hx:
            if m_dot_htf_in > self.m_m_dot_tes_dc_max / timestep:
                outputs.m_q_heater = Float64.NAN
                outputs.m_m_dot = Float64.NAN
                outputs.m_W_dot_rhtf_pump = Float64.NAN
                outputs.m_q_dot_loss = Float64.NAN
                outputs.m_q_dot_dc_to_htf = Float64.NAN
                outputs.m_q_dot_ch_from_htf = Float64.NAN
                outputs.m_T_hot_ave = Float64.NAN
                outputs.m_T_cold_ave = Float64.NAN
                outputs.m_T_hot_final = Float64.NAN
                outputs.m_T_cold_final = Float64.NAN
                return False
            self.mc_node_one.energy_balance(timestep, 0.0, m_dot_htf_in, 0.0, T_amb, T_htf_hot_out, q_heater_hot, q_dot_loss_hot)
            self.mc_node_three.energy_balance(timestep, m_dot_htf_in, 0.0, T_htf_cold_in, T_amb, T_cold_ave, q_heater_cold, q_dot_loss_cold)
        else:
            # Iterate between field htf - hx - and storage	

        outputs.m_q_heater = q_heater_cold + q_heater_hot  #[MWt]
        outputs.m_m_dot = m_dot_htf_in
        outputs.m_W_dot_rhtf_pump = m_dot_htf_in * self.ms_params.m_htf_pump_coef / 1.E3  #[MWe] Pumping power for Receiver HTF, convert from kW/kg/s*kg/s
        outputs.m_q_dot_loss = q_dot_loss_cold + q_dot_loss_hot  #[MWt]
        outputs.m_T_hot_ave = T_htf_hot_out  #[K]
        outputs.m_T_cold_ave = T_cold_ave  #[K]
        outputs.m_T_hot_final = self.mc_node_one.get_m_T_calc()  #[K]
        outputs.m_T_cold_final = self.mc_node_three.get_m_T_calc()  #[K]
        var T_htf_ave: Float64 = 0.5 * (T_htf_cold_in + T_htf_hot_out)  #[K]
        var cp_htf_ave: Float64 = self.mc_field_htfProps.Cp(T_htf_ave)  #[kJ/kg-K]
        outputs.m_q_dot_dc_to_htf = m_dot_htf_in * cp_htf_ave * (T_htf_hot_out - T_htf_cold_in) / 1000.0  #[MWt]
        outputs.m_q_dot_ch_from_htf = 0.0  #[MWt]
        return True

    def charge(inout self, timestep: Float64, T_amb: Float64, m_dot_htf_in: Float64, 
        T_htf_hot_in: Float64, inout T_htf_cold_out: Float64, inout outputs: S_csp_strat_tes_outputs) -> Bool:
        var q_heater_cold: Float64 = Float64.NAN
        var q_heater_hot: Float64 = Float64.NAN
        var q_dot_loss_cold: Float64 = Float64.NAN
        var q_dot_loss_hot: Float64 = Float64.NAN
        var T_hot_ave: Float64 = Float64.NAN
        if not self.ms_params.m_is_hx:
            if m_dot_htf_in > self.m_m_dot_tes_ch_max / timestep:
                outputs.m_q_dot_loss = Float64.NAN
                outputs.m_q_heater = Float64.NAN
                outputs.m_m_dot = Float64.NAN
                outputs.m_T_hot_ave = Float64.NAN
                outputs.m_T_cold_ave = Float64.NAN
                outputs.m_T_hot_final = Float64.NAN
                outputs.m_T_cold_final = Float64.NAN
                return False
            self.mc_node_three.energy_balance(timestep, 0.0, m_dot_htf_in, 0.0, T_amb, T_htf_cold_out, q_heater_cold, q_dot_loss_cold)
            self.mc_node_one.energy_balance(timestep, m_dot_htf_in, 0.0, T_htf_hot_in, T_amb, T_hot_ave, q_heater_hot, q_dot_loss_hot)
        else:
            # Iterate between field htf - hx - and storage	

        outputs.m_q_heater = q_heater_cold + q_heater_hot  #[MW] Storage thermal losses
        outputs.m_m_dot = m_dot_htf_in
        outputs.m_W_dot_rhtf_pump = m_dot_htf_in * self.ms_params.m_htf_pump_coef / 1.E3  #[MWe] Pumping power for Receiver HTF, convert from kW/kg/s*kg/s
        outputs.m_q_dot_loss = q_dot_loss_cold + q_dot_loss_hot  #[MW] Heating power required to keep tanks at a minimum temperature
        outputs.m_T_hot_ave = T_hot_ave  #[K] Average hot tank temperature over timestep
        outputs.m_T_cold_ave = T_htf_cold_out  #[K] Average cold tank temperature over timestep
        outputs.m_T_hot_final = self.mc_node_one.get_m_T_calc()  #[K] Hot temperature at end of timestep
        outputs.m_T_cold_final = self.mc_node_three.get_m_T_calc()  #[K] Cold temperature at end of timestep
        var T_htf_ave: Float64 = 0.5 * (T_htf_hot_in + T_htf_cold_out)  #[K]
        var cp_htf_ave: Float64 = self.mc_field_htfProps.Cp(T_htf_ave)  #[kJ/kg-K]
        outputs.m_q_dot_ch_from_htf = m_dot_htf_in * cp_htf_ave * (T_htf_hot_in - T_htf_cold_out) / 1000.0  #[MWt]
        outputs.m_q_dot_dc_to_htf = 0.0  #[MWt]
        return True

    def charge_discharge(inout self, timestep: Float64, T_amb: Float64, m_dot_hot_in: Float64, 
        T_hot_in: Float64, m_dot_cold_in: Float64, T_cold_in: Float64, inout outputs: S_csp_strat_tes_outputs) -> Bool:
        var q_heater_cold: Float64 = Float64.NAN
        var q_heater_hot: Float64 = Float64.NAN
        var q_dot_loss_cold: Float64 = Float64.NAN
        var q_dot_loss_hot: Float64 = Float64.NAN
        var T_hot_ave: Float64 = Float64.NAN
        var T_cold_ave: Float64 = Float64.NAN
        if not self.ms_params.m_is_hx:
            if m_dot_hot_in > self.m_m_dot_tes_ch_max / timestep:
                outputs.m_q_dot_loss = Float64.NAN
                outputs.m_q_heater = Float64.NAN
                outputs.m_m_dot = Float64.NAN
                outputs.m_T_hot_ave = Float64.NAN
                outputs.m_T_cold_ave = Float64.NAN
                outputs.m_T_hot_final = Float64.NAN
                outputs.m_T_cold_final = Float64.NAN
                return False
            self.mc_node_three.energy_balance(timestep, m_dot_cold_in, m_dot_hot_in, T_cold_in, T_amb, T_cold_ave, q_heater_cold, q_dot_loss_cold)
            self.mc_node_one.energy_balance(timestep, m_dot_hot_in, m_dot_cold_in, T_hot_in, T_amb, T_hot_ave, q_heater_hot, q_dot_loss_hot)
        else:
            # Iterate between field htf - hx - and storage	

        outputs.m_q_heater = q_heater_cold + q_heater_hot  #[MW] Storage thermal losses
        outputs.m_m_dot = m_dot_hot_in
        outputs.m_W_dot_rhtf_pump = m_dot_hot_in * self.ms_params.m_htf_pump_coef / 1.E3  #[MWe] Pumping power for Receiver HTF, convert from kW/kg/s*kg/s
        outputs.m_q_dot_loss = q_dot_loss_cold + q_dot_loss_hot  #[MW] Heating power required to keep tanks at a minimum temperature
        outputs.m_T_hot_ave = T_hot_ave  #[K] Average hot tank temperature over timestep
        outputs.m_T_cold_ave = T_cold_ave  #[K] Average cold tank temperature over timestep
        outputs.m_T_hot_final = self.mc_node_one.get_m_T_calc()  #[K] Hot temperature at end of timestep
        outputs.m_T_cold_final = self.mc_node_three.get_m_T_calc()  #[K] Cold temperature at end of timestep
        var T_htf_ave: Float64 = 0.5 * (T_hot_in + T_cold_ave)  #[K]
        var cp_htf_ave: Float64 = self.mc_field_htfProps.Cp(T_htf_ave)  #[kJ/kg-K]
        outputs.m_q_dot_ch_from_htf = m_dot_hot_in * cp_htf_ave * (T_hot_in - T_cold_ave) / 1000.0  #[MWt]
        outputs.m_q_dot_dc_to_htf = 0.0  #[MWt]
        return True

    def recirculation(inout self, timestep: Float64, T_amb: Float64, m_dot_cold_in: Float64, 
        T_cold_in: Float64, inout outputs: S_csp_strat_tes_outputs) -> Bool:
        var q_heater_cold: Float64 = Float64.NAN
        var q_heater_hot: Float64 = Float64.NAN
        var q_dot_loss_cold: Float64 = Float64.NAN
        var q_dot_loss_hot: Float64 = Float64.NAN
        var T_hot_ave: Float64 = Float64.NAN
        var T_cold_ave: Float64 = Float64.NAN
        if not self.ms_params.m_is_hx:
            if m_dot_cold_in > self.m_m_dot_tes_ch_max / timestep:  #Is this necessary for recirculation mode? ARD
                outputs.m_q_dot_loss = Float64.NAN
                outputs.m_q_heater = Float64.NAN
                outputs.m_m_dot = Float64.NAN
                outputs.m_T_hot_ave = Float64.NAN
                outputs.m_T_c