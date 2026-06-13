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
from core import compute_module, var_info, var_info_invalid, SSC_INPUT, SSC_OUTPUT, SSC_NUMBER, SSC_MATRIX, exec_error, DEFINE_MODULE_ENTRY
from htf_props import HTFProperties
from sam_csp_util import util
from csp_solver_two_tank_tes import two_tank_tes_sizing

var _cm_vtab_ui_tes_calcs = [
	/*   VARTYPE   DATATYPE         NAME               LABEL                                            UNITS     META  GROUP REQUIRED_IF CONSTRAINTS         UI_HINTS*/
	{ SSC_INPUT,   SSC_NUMBER,   "P_ref",                    "Power cycle output at design",                 "MWe",   "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "design_eff",               "Power cycle thermal efficiency",               "",      "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "tshours",                  "Hours of TES relative to q_dot_pb_des",        "hr",    "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "T_htf_hot_des",            "Hot HTF temp (into TES HX, if applicable)",    "C",     "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "T_htf_cold_des",           "Cold HTF temp (out of TES HX, if applicable)", "C",     "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "rec_htf",                  "TES storage fluid code",                       "",      "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_MATRIX,   "field_fl_props",           "User defined tes storage fluid prop data",     "",      "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "h_tank_min",               "Min. allowable HTF height in storage tank",    "m",     "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "h_tank",                   "Total height of tank (HTF when tank is full",  "m",     "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "tank_pairs",               "Number of equivalent tank pairs",              "",      "", "",  "*",  "", "" },
	{ SSC_INPUT,   SSC_NUMBER,   "u_tank",                   "Loss coefficient from the tank",               "W/m2-K","", "",  "*",  "", "" },
	{ SSC_OUTPUT,  SSC_NUMBER,   "q_tes",                    "TES thermal capacity at design",               "MWt-hr","", "",  "*",  "", "" },
	{ SSC_OUTPUT,  SSC_NUMBER,   "tes_avail_vol",            "Available single temp storage volume",         "m^3",   "", "",  "*",  "", "" },
	{ SSC_OUTPUT,  SSC_NUMBER,   "vol_tank",                 "Total single temp storage volume",             "m^3",   "", "",  "*",  "", "" },
	{ SSC_OUTPUT,  SSC_NUMBER,   "csp_pt_tes_tank_diameter", "Single tank diameter",                         "m",     "", "",  "*",  "", "" },
	{ SSC_OUTPUT,  SSC_NUMBER,   "q_dot_tes_est",            "Estimated tank heat loss to env.",             "MWt",   "", "",  "*",  "", "" },
	{ SSC_OUTPUT,  SSC_NUMBER,   "csp_pt_tes_htf_density",   "HTF dens",                                     "kg/m^3","", "",  "*",  "", "" },
	var_info_invalid]

struct cm_ui_tes_calcs : compute_module:
    def __init__(inout self):
        self.add_var_info(_cm_vtab_ui_tes_calcs)

    def exec(inout self) raises:
        var P_ref: Float64 = self.as_double("P_ref")		# [MWe] Power cycle output at design
        var design_eff: Float64 = self.as_double("design_eff")		# [-] Power cycle efficiency at design 
        var q_dot_pb_des: Float64 = P_ref / design_eff		# [MWt] Power cycle thermal power at design
        var tshours: Float64 = self.as_double("tshours")		# [hrs] Hours of TES relative to q_dot_pb_des
        var Q_tes_des: Float64 = q_dot_pb_des * tshours		# [MWt-hr] TES thermal capacity at design
        self.assign("q_tes", Q_tes_des)
        var tes_htf_props: HTFProperties			# Instance of HTFProperties class for TES HTF
        var tes_fl: Int = self.as_double("rec_htf").to_int()
        var tes_fl_props: util.matrix_t[Float64] = self.as_matrix("field_fl_props")
        var T_htf_hot_des: Float64 = self.as_double("T_htf_hot_des")			# [C] Hot HTF temp
        var T_htf_cold_des: Float64 = self.as_double("T_htf_cold_des")		# [C] Cold HTF temp
        var T_HTF_ave: Float64 = 0.5 * (T_htf_hot_des + T_htf_cold_des)		# [C] Ave HTF temp at design
        if tes_fl != HTFProperties.User_defined and tes_fl < HTFProperties.End_Library_Fluids:
            if not tes_htf_props.SetFluid(tes_fl):
                raise exec_error("ui_tes_calcs", util.format("The user-defined HTF did not read correctly"))
        elif tes_fl == HTFProperties.User_defined:
            var n_rows: Int = tes_fl_props.nrows()
            var n_cols: Int = tes_fl_props.ncols()
            if n_rows > 2 and n_cols == 7:
                if not tes_htf_props.SetUserDefinedFluid(tes_fl_props):
                    var error_msg: String = util.format(tes_htf_props.UserFluidErrMessage(), n_rows, n_cols)
                    raise exec_error("ui_tes_calcs", error_msg)
            else:
                var error_msg: String = util.format("The user defined storage HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", n_rows, n_cols)
                raise exec_error("ui_tes_calcs", error_msg)
        else:
            raise exec_error("ui_tes_calcs", "Storage HTF code is not recognized")
        var h_min: Float64 = self.as_double("h_tank_min")			# [m]
        var h_tank: Float64 = self.as_double("h_tank")			# [m]
        var tank_pairs: Float64 = self.as_double("tank_pairs")		# [-]
        var u_tank: Float64 = self.as_double("u_tank")			# [W/m^2-K]
        var tes_avail_vol: Float64
        var vol_tank: Float64
        var csp_pt_tes_tank_diameter: Float64
        var q_dot_loss_des: Float64
        tes_avail_vol = vol_tank = csp_pt_tes_tank_diameter = q_dot_loss_des = Float64.NaN
        two_tank_tes_sizing(tes_htf_props, Q_tes_des, T_htf_hot_des + 273.15, T_htf_cold_des + 273.15, 
            h_min, h_tank, tank_pairs.to_int(), u_tank,
            tes_avail_vol, vol_tank, csp_pt_tes_tank_diameter, q_dot_loss_des)
        self.assign("tes_avail_vol", tes_avail_vol)
        self.assign("vol_tank", vol_tank)
        self.assign("q_dot_tes_est", q_dot_loss_des)
        self.assign("csp_pt_tes_tank_diameter", csp_pt_tes_tank_diameter)
        self.assign("csp.pt.tes.tank_diameter", csp_pt_tes_tank_diameter)
        self.assign("csp_pt_tes_htf_density", tes_htf_props.dens(T_HTF_ave + 273.15, 1.0))
        self.assign("csp.pt.tes.htf_density", tes_htf_props.dens(T_HTF_ave + 273.15, 1.0))
        return

DEFINE_MODULE_ENTRY(ui_tes_calcs, "Calculates values for all calculated values on UI TES page(s)", 0)