"""
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
"""
from core import *
from tckernel import *
from common import *
from AutoPilot_API import *
from SolarField import *
from IOUtil import *
from csp_common import *

# static var_info _cm_vtab_tcsiscc[] = {
_cm_vtab_tcsiscc = [
    (SSC_INPUT, SSC_STRING, "solar_resource_file", "local weather file path", "", "", "Weather", "*", "LOCAL_FILE", ""),
    (SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "molten salt tower", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "run_type", "Run type", "-", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "helio_width", "Heliostat width", "m", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "helio_height", "Heliostat height", "m", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "helio_optical_error", "Heliostat optical error", "rad", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "helio_active_fraction", "Heliostat active frac.", "-", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "dens_mirror", "Ratio of Reflective Area to Profile", "-", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "helio_reflectance", "Heliostat reflectance", "-", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_absorptance", "Receiver absorptance", "-", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_height", "Receiver height", "m", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_aspect", "Receiver aspect ratio", "-", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_hl_perm2", "Receiver design heatloss", "kW/m2", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "land_bound_type", "Land boundary type", "-", "", "heliostat", "?=0", "", ""),
    (SSC_INPUT, SSC_NUMBER, "land_max", "Land max boundary", "-ORm", "", "heliostat", "?=7.5", "", ""),
    (SSC_INPUT, SSC_NUMBER, "land_min", "Land min boundary", "-ORm", "", "heliostat", "?=0.75", "", ""),
    (SSC_INPUT, SSC_MATRIX, "land_bound_table", "Land boundary table", "m", "", "heliostat", "?", "", ""),
    (SSC_INPUT, SSC_ARRAY, "land_bound_list", "Boundary table listing", "-", "", "heliostat", "?", "", ""),
    (SSC_INPUT, SSC_NUMBER, "dni_des", "Design-point DNI", "W/m2", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "p_start", "Heliostat startup energy", "kWe-hr", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "p_track", "Heliostat tracking energy", "kWe", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "hel_stow_deploy", "Stow/deploy elevation", "deg", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "v_wind_max", "Max. wind velocity", "m/s", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "interp_nug", "Interpolation nugget", "-", "", "heliostat", "?=0", "", ""),
    (SSC_INPUT, SSC_NUMBER, "interp_beta", "Interpolation beta coef.", "-", "", "heliostat", "?=1.99", "", ""),
    (SSC_INPUT, SSC_NUMBER, "n_flux_x", "Flux map X resolution", "-", "", "heliostat", "?=12", "", ""),
    (SSC_INPUT, SSC_NUMBER, "n_flux_y", "Flux map Y resolution", "-", "", "heliostat", "?=1", "", ""),
    (SSC_INPUT, SSC_MATRIX, "helio_positions", "Heliostat position table", "m", "", "heliostat", "run_type=1", "", ""),
    (SSC_INPUT, SSC_MATRIX, "helio_aim_points", "Heliostat aim point table", "m", "", "heliostat", "?", "", ""),
    (SSC_INPUT, SSC_NUMBER, "N_hel", "Number of heliostats", "-", "", "heliostat", "?", "", ""),
    (SSC_INPUT, SSC_MATRIX, "eta_map", "Field efficiency array", "-", "", "heliostat", "?", "", ""),
    (SSC_INPUT, SSC_MATRIX, "flux_positions", "Flux map sun positions", "deg", "", "heliostat", "?", "", ""),
    (SSC_INPUT, SSC_MATRIX, "flux_maps", "Flux map intensities", "-", "", "heliostat", "?", "", ""),
    (SSC_INPUT, SSC_NUMBER, "c_atm_0", "Attenuation coefficient 0", "", "", "heliostat", "?=0.006789", "", ""),
    (SSC_INPUT, SSC_NUMBER, "c_atm_1", "Attenuation coefficient 1", "", "", "heliostat", "?=0.1046", "", ""),
    (SSC_INPUT, SSC_NUMBER, "c_atm_2", "Attenuation coefficient 2", "", "", "heliostat", "?=-0.0107", "", ""),
    (SSC_INPUT, SSC_NUMBER, "c_atm_3", "Attenuation coefficient 3", "", "", "heliostat", "?=0.002845", "", ""),
    (SSC_INPUT, SSC_NUMBER, "n_facet_x", "Number of heliostat facets - X", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "n_facet_y", "Number of heliostat facets - Y", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "focus_type", "Heliostat focus method", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "cant_type", "Heliostat cant method", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "n_flux_days", "No. days in flux map lookup", "", "", "heliostat", "?=8", "", ""),
    (SSC_INPUT, SSC_NUMBER, "delta_flux_hrs", "Hourly frequency in flux map lookup", "", "", "heliostat", "?=1", "", ""),
    (SSC_INPUT, SSC_NUMBER, "h_tower", "Tower height", "m", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "q_design", "Receiver thermal design power", "MW", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "calc_fluxmaps", "Include fluxmap calculations", "", "", "heliostat", "?=0", "", ""),
    (SSC_INPUT, SSC_NUMBER, "tower_fixed_cost", "Tower fixed cost", "$", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "tower_exp", "Tower cost scaling exponent", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_ref_cost", "Receiver reference cost", "$", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_ref_area", "Receiver reference area for cost scale", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_cost_exp", "Receiver cost scaling exponent", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "site_spec_cost", "Site improvement cost", "$/m2", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "heliostat_spec_cost", "Heliostat field cost", "$/m2", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "plant_spec_cost", "Power cycle specific cost", "$/kWe", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "bop_spec_cost", "BOS specific cost", "$/kWe", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "tes_spec_cost", "Thermal energy storage cost", "$/kWht", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "land_spec_cost", "Total land area cost", "$/acre", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "contingency_rate", "Contingency for cost overrun", "%", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "sales_tax_rate", "Sales tax rate", "%", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "sales_tax_frac", "Percent of cost to which sales tax applies", "%", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "cost_sf_fixed", "Solar field fixed cost", "$", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "fossil_spec_cost", "Fossil system specific cost", "$/kWe", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "is_optimize", "Do SolarPILOT optimization", "", "", "heliostat", "?=0", "", ""),
    (SSC_INPUT, SSC_NUMBER, "flux_max", "Maximum allowable flux", "", "", "heliostat", "?=1000", "", ""),
    (SSC_INPUT, SSC_NUMBER, "opt_init_step", "Optimization initial step size", "", "", "heliostat", "?=0.05", "", ""),
    (SSC_INPUT, SSC_NUMBER, "opt_max_iter", "Max. number iteration steps", "", "", "heliostat", "?=200", "", ""),
    (SSC_INPUT, SSC_NUMBER, "opt_conv_tol", "Optimization convergence tol", "", "", "heliostat", "?=0.001", "", ""),
    (SSC_INPUT, SSC_NUMBER, "opt_flux_penalty", "Optimization flux overage penalty", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "opt_algorithm", "Optimization algorithm", "", "", "heliostat", "?=0", "", ""),
    (SSC_INPUT, SSC_NUMBER, "check_max_flux", "Check max flux at design point", "", "", "heliostat", "?=0", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.per_acre", "EPC cost per acre", "$/acre", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.percent", "EPC cost percent of direct", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.per_watt", "EPC cost per watt", "$/W", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.epc.fixed", "EPC fixed", "$", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.per_acre", "PLM cost per acre", "$/acre", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.percent", "PLM cost percent of direct", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.per_watt", "PLM cost per watt", "$/W", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.cost.plm.fixed", "PLM fixed", "$", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.sf.fixed_land_area", "Fixed land area", "acre", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "csp.pt.sf.land_overhead_factor", "Land overhead factor", "", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "total_installed_cost", "Total installed cost", "$", "", "heliostat", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "receiver_type", "External=0, Cavity=1", "", "", "receiver", "*", "INTEGER", ""),
    (SSC_INPUT, SSC_NUMBER, "N_panels", "Number of individual panels on the receiver", "", "", "receiver", "*", "INTEGER", ""),
    (SSC_INPUT, SSC_NUMBER, "D_rec", "The overall outer diameter of the receiver", "m", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "H_rec", "The height of the receiver", "m", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "THT", "The height of the tower (hel. pivot to rec equator)", "m", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "d_tube_out", "The outer diameter of an individual receiver tube", "mm", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "th_tube", "The wall thickness of a single receiver tube", "mm", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "mat_tube", "The material name of the receiver tubes", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_htf", "The name of the HTF used in the receiver", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_MATRIX, "field_fl_props", "User defined field fluid property data", "-", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "Flow_type", "A flag indicating which flow pattern is used", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "crossover_shift", "No. panels shift in receiver crossover position", "", "", "receiver", "?=0", "", ""),
    (SSC_INPUT, SSC_NUMBER, "epsilon", "The emissivity of the receiver surface coating", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "hl_ffact", "The heat loss factor (thermal loss fudge factor)", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "T_htf_hot_des", "Hot HTF outlet temperature at design conditions", "C", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "T_htf_cold_des", "Cold HTF inlet temperature at design conditions", "C", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "f_rec_min", "Minimum receiver mass flow rate turn down fraction", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "Q_rec_des", "Design-point receiver thermal power output", "MWt", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_su_delay", "Fixed startup delay time for the receiver", "hr", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "rec_qf_delay", "Energy-based rcvr startup delay (fraction of rated thermal power)", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "m_dot_htf_max", "Maximum receiver mass flow rate", "kg/hr", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "A_sf", "Solar Field Area", "m^2", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "eta_pump", "Receiver HTF pump efficiency", "", "", "receiver", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "q_pb_design", "Design point power block thermal power", "MWt", "", "powerblock", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "elev", "Plant elevation", "m", "", "powerblock", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "ngcc_model", "1: NREL, 2: GE", "", "", "powerblock", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "pinch_point_hotside", "Hot side temperature HX temperature difference", "C", "", "powerblock", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "pinch_point_coldside", "Cold side HX pinch point", "C", "", "powerblock", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "pb_pump_coef", "Required pumping power for HTF through power block", "kJ/kg", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "piping_loss", "Thermal loss per meter of piping", "Wt/m", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "piping_length", "Total length of exposed piping", "m", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "piping_length_mult", "Piping length multiplier", "", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "piping_length_const", "Piping constant length", "m", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "Q_rec_des", "Design point solar field thermal output", "MW", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "pb_fixed_par", "Fixed parasitic load - runs at all times", "MWe/MWcap", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "bop_par", "Balance of plant parasitic power fraction", "MWe/MWcap", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "bop_par_f", "Balance of plant parasitic power fraction - mult frac", "none", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "bop_par_0", "Balance of plant parasitic power fraction - const coeff", "none", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "bop_par_1", "Balance of plant parasitic power fraction - linear coeff", "none", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "bop_par_2", "Balance of plant parasitic power fraction - quadratic coeff", "none", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "fossil_output", "Fossil-only cycle output at design", "MWe", "", "parasitics", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "W_dot_solar_des", "Solar contribution to cycle output at design", "MWe", "", "parasitics", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "month", "Resource Month", "", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "hour", "Resource Hour of Day", "", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "solazi", "Resource Solar Azimuth", "deg", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "solzen", "Resource Solar Zenith", "deg", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "beam", "Resource Beam normal irradiance", "W/m2", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "tdry", "Resource Dry bulb temperature", "C", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "twet", "Resource Wet bulb temperature", "C", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "wspd", "Resource Wind Speed", "m/s", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "pres", "Resource Pressure", "mbar", "", "weather", "*", "LENGTH=8760", ""),
    (SSC_OUTPUT, SSC_ARRAY, "eta_field", "Field optical efficiency", "", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "field_eff_adj", "Solar field efficiency w/ defocusing", "", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "eta_therm", "Receiver thermal efficiency", "", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "Q_solar_total", "Receiver thermal power absorbed", "MWt", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "q_conv_sum", "Receiver thermal power loss to convection", "MWt", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "q_rad_sum", "Receiver thermal power loss to radiation", "MWt", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "Q_thermal", "Receiver thermal power to HTF", "MWt", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "m_dot_ss", "Receiver mass flow rate, steady state", "kg/s", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "m_dot_salt_tot", "Receiver mass flow rate, derated for startup", "kg/s", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "T_htf_cold", "Receiver HTF temperature in", "C", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "T_salt_hot", "Receiver HTF temperature out", "C", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "q_startup", "Receiver startup power", "MWt", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "f_timestep", "Receiver operating fraction after startup", "", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "m_dot_steam", "Cycle solar steam mass flow rate", "kg/hr", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "T_st_cold", "Cycle steam temp from NGCC to HX", "C", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "T_st_hot", "Cycle steam temp from HX back to NGCC", "C", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "Q_dot_max", "Cycle max allowable thermal power to NGCC", "MWt", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "fuel_use", "Cycle natural gas used during timestep", "MMBTU", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "W_dot_pc_hybrid", "Cycle net output including solar power", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "W_dot_pc_fossil", "Cycle net output only considering fossil power", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "W_dot_plant_hybrid", "Plant net output including solar power & parasitics", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "W_dot_plant_fossil", "Plant net output only considering fossil power & parasitics", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "W_dot_plant_solar", "Plant net output attributable to solar", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "eta_solar_use", "Plant solar use efficiency considering parasitics", "-", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "eta_fuel", "Plant efficiency of fossil only operation (LHV basis)", "%", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "solar_fraction", "Plant solar fraction", "-", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "W_dot_pump", "Parasitic power receiver HTF pump", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "pparasi", "Parasitic power heliostat drives", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "P_plant_balance_tot", "Parasitic power generation-dependent load", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_ARRAY, "P_fixed", "Parasitic power fixed load", "MWe", "", "Outputs", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual Energy", "kW", "", "Net_E_Calc", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "System heat rate", "MMBtu/MWh", "", "", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual fuel usage", "kWh", "", "", "*", "", ""),
    var_info_invalid,
]

class cm_tcsiscc(tcKernel):
    def __init__(self, prov: tcstypeprovider):
        super().__init__(prov)
        self.add_var_info(_cm_vtab_tcsiscc)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)
        self.add_var_info(vtab_sf_adjustment_factors)

    def exec(self):
        weather = self.add_unit("weatherreader", "TCS weather reader")
        type_hel_field = self.add_unit("sam_mw_pt_heliostatfield")
        type222_receiver = self.add_unit("sam_mw_pt_type222")
        iscc_pb = self.add_unit("sam_iscc_powerblock")
        iscc_parasitics = self.add_unit("sam_iscc_parasitics")
        bConnected = True

        self.set_unit_value(weather, "file_name", self.as_string("solar_resource_file"))
        self.set_unit_value(weather, "track_mode", 0.0)
        self.set_unit_value(weather, "tilt", 0.0)
        self.set_unit_value(weather, "azimuth", 0.0)

        self.set_unit_value_ssc_double(type_hel_field, "run_type")  # 0=auto, 1=user-type_hel_field, 2=user data
        self.set_unit_value_ssc_double(type_hel_field, "helio_width")  # [m]
        self.set_unit_value_ssc_double(type_hel_field, "helio_height")  # [m]
        self.set_unit_value_ssc_double(type_hel_field, "helio_optical_error")
        self.set_unit_value_ssc_double(type_hel_field, "helio_active_fraction")
        self.set_unit_value_ssc_double(type_hel_field, "dens_mirror")
        self.set_unit_value_ssc_double(type_hel_field, "helio_reflectance")
        self.set_unit_value_ssc_double(type_hel_field, "rec_absorptance")

        is_optimize = self.as_boolean("is_optimize")

        # /*
        # Any parameter that's dependent on the size of the solar field must be recalculated here
        # if the optimization is happening within the cmod
        # */
        H_rec = 0.0
        D_rec = 0.0
        rec_aspect = 0.0
        THT = 0.0
        A_sf = 0.0

        if is_optimize:
            spi = solarpilot_invoke(self)
            spi.run()
            steps = []  # vector<vector<double> >
            obj = []  # vector<double>
            flux = []  # vector<double>
            spi.getOptimizationSimulationHistory(steps, obj, flux)
            nr = len(steps)
            nc = len(steps[0]) + 2
            ssc_hist = self.allocate("opt_history", nr, nc)
            for i in range(nr):
                for j in range(len(steps[0])):
                    ssc_hist[i * nc + j] = ssc_number_t(steps[i][j])
                ssc_hist[i * nc + nc - 2] = ssc_number_t(obj[i])
                ssc_hist[i * nc + nc - 1] = ssc_number_t(flux[i])
            H_rec = spi.recs[0].rec_height.val
            rec_aspect = spi.recs[0].rec_aspect.Val()
            THT = spi.sf.tht.val
            nr = int(len(spi.layout.heliostat_positions))
            ssc_hl = self.allocate("helio_positions", nr, 2)
            for i in range(nr):
                ssc_hl[i * 2] = ssc_number_t(spi.layout.heliostat_positions[i].location.x)
                ssc_hl[i * 2 + 1] = ssc_number_t(spi.layout.heliostat_positions[i].location.y)
            A_sf = self.as_double("helio_height") * self.as_double("helio_width") * self.as_double("dens_mirror") * float(nr)
            piping_length = THT * self.as_double("piping_length_mult") + self.as_double("piping_length_const")
            self.assign("H_rec", var_data(ssc_number_t(H_rec)))
            self.assign("rec_height", var_data(ssc_number_t(H_rec)))
            self.assign("rec_aspect", var_data(ssc_number_t(rec_aspect)))
            self.assign("D_rec", var_data(ssc_number_t(H_rec / rec_aspect)))
            self.assign("THT", var_data(ssc_number_t(THT)))
            self.assign("h_tower", var_data(ssc_number_t(THT)))
            self.assign("A_sf", var_data(ssc_number_t(A_sf)))
            self.assign("piping_length", var_data(ssc_number_t(piping_length)))
            total_direct_cost = 0.0
            A_rec = float('nan')
            rec_type_value = spi.recs[0].rec_type.mapval()
            if rec_type_value == var_receiver.REC_TYPE.EXTERNAL_CYLINDRICAL:
                h = spi.recs[0].rec_height.val
                d = h / spi.recs[0].rec_aspect.Val()
                A_rec = h * d * 3.1415926
            elif rec_type_value == var_receiver.REC_TYPE.FLAT_PLATE:
                h = spi.recs[0].rec_height.val
                w = h / spi.recs[0].rec_aspect.Val()
                A_rec = h * w
            receiver = self.as_double("rec_ref_cost") * pow(A_rec / self.as_double("rec_ref_area"), self.as_double("rec_cost_exp"))  # receiver cost
            storage = 0.0
            P_ref = self.as_double("W_dot_solar_des") * 1000.0  # kWe
            power_block = P_ref * (self.as_double("plant_spec_cost") + self.as_double("bop_spec_cost"))  # $/kWe --> $
            site_improvements = A_sf * self.as_double("site_spec_cost")
            heliostats = A_sf * self.as_double("heliostat_spec_cost")
            cost_fixed = self.as_double("cost_sf_fixed")
            fossil = P_ref * self.as_double("fossil_spec_cost")
            tower = self.as_double("tower_fixed_cost") * exp(self.as_double("tower_exp") * (THT + 0.5 * (-H_rec + self.as_double("helio_height"))))
            total_direct_cost = (1.0 + self.as_double("contingency_rate") / 100.0) * (
                site_improvements + heliostats + power_block +
                cost_fixed + storage + fossil + tower + receiver)
            land_area = spi.land.land_area.Val() * self.as_double("csp.pt.sf.land_overhead_factor") + self.as_double("csp.pt.sf.fixed_land_area")
            cost_epc = (
                self.as_double("csp.pt.cost.epc.per_acre") * land_area
                + self.as_double("csp.pt.cost.epc.percent") * total_direct_cost / 100.0
                + P_ref * 1000.0 * self.as_double("csp.pt.cost.epc.per_watt")
                + self.as_double("csp.pt.cost.epc.fixed")
            )
            cost_plm = (
                self.as_double("csp.pt.cost.plm.per_acre") * land_area
                + self.as_double("csp.pt.cost.plm.percent") * total_direct_cost / 100.0
                + P_ref * 1000.0 * self.as_double("csp.pt.cost.plm.per_watt")
                + self.as_double("csp.pt.cost.plm.fixed")
            )
            cost_sales_tax = self.as_double("sales_tax_rate") / 100.0 * total_direct_cost * self.as_double("sales_tax_frac") / 100.0
            total_indirect_cost = cost_epc + cost_plm + cost_sales_tax
            total_installed_cost = total_direct_cost + total_indirect_cost
            self.assign("total_installed_cost", var_data(ssc_number_t(total_installed_cost)))
        else:
            H_rec = self.as_double("H_rec")
            rec_aspect = self.as_double("rec_aspect")
            THT = self.as_double("THT")
            A_sf = self.as_double("A_sf")

        D_rec = H_rec / rec_aspect
        self.set_unit_value_ssc_double(type_hel_field, "rec_height", H_rec)  # , 5.)
        self.set_unit_value_ssc_double(type_hel_field, "rec_aspect", rec_aspect)
        self.set_unit_value_ssc_double(type_hel_field, "h_tower", THT)  # , 50)
        self.set_unit_value_ssc_double(type_hel_field, "rec_hl_perm2")  # , 0.)
        self.set_unit_value_ssc_double(type_hel_field, "q_design", self.as_double("Q_rec_des"))  # , 25.)
        self.set_unit_value_ssc_double(type_hel_field, "dni_des")
        self.set_unit_value(type_hel_field, "weather_file", self.as_string("solar_resource_file"))
        self.set_unit_value_ssc_double(type_hel_field, "land_bound_type")  # , 0)
        self.set_unit_value_ssc_double(type_hel_field, "land_max")  # , 7.5)
        self.set_unit_value_ssc_double(type_hel_field, "land_min")  # , 0.75)
        self.set_unit_value_ssc_double(type_hel_field, "p_start")  # , 0.025)
        self.set_unit_value_ssc_double(type_hel_field, "p_track")  # , 0.055)
        self.set_unit_value_ssc_double(type_hel_field, "hel_stow_deploy")  # , 8)
        self.set_unit_value_ssc_double(type_hel_field, "v_wind_max")  # , 25.)
        self.set_unit_value_ssc_double(type_hel_field, "n_flux_x")  # , 10)
        self.set_unit_value_ssc_double(type_hel_field, "n_flux_y")  # , 1)
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_0")
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_1")
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_2")
        self.set_unit_value_ssc_double(type_hel_field, "c_atm_3")
        self.set_unit_value_ssc_double(type_hel_field, "n_facet_x")
        self.set_unit_value_ssc_double(type_hel_field, "n_facet_y")
        self.set_unit_value_ssc_double(type_hel_field, "focus_type")
        self.set_unit_value_ssc_double(type_hel_field, "cant_type")
        self.set_unit_value_ssc_double(type_hel_field, "n_flux_days")
        self.set_unit_value_ssc_double(type_hel_field, "delta_flux_hrs")

        run_type = int(self.get_unit_value_number(type_hel_field, "run_type"))
        # /*if(run_type == 0){
        # set_unit_value_ssc_matrix(type_hel_field, "helio_positions");
        # set_unit_value_ssc_matrix(type_hel_field, "eta_map");
        # set_unit_value_ssc_matrix(type_hel_field, "flux_positions");
        # set_unit_value_ssc_matrix(type_hel_field, "flux_maps");
        # }
        # else*/
        if run_type == 1:
            self.set_unit_value_ssc_matrix(type_hel_field, "helio_positions")
        elif run_type == 2:
            self.set_unit_value_ssc_matrix(type_hel_field, "eta_map")
            self.set_unit_value_ssc_matrix(type_hel_field, "flux_positions")
            self.set_unit_value_ssc_matrix(type_hel_field, "flux_maps")

        bConnected &= self.connect(weather, "wspd", type_hel_field, "vwind")
        self.set_unit_value_ssc_double(type_hel_field, "field_control", 1.0)
        self.set_unit_value_ssc_double(weather, "solzen", 90.0)  # initialize to be on the horizon
        bConnected &= self.connect(weather, "solzen", type_hel_field, "solzen")
        bConnected &= self.connect(weather, "solazi", type_hel_field, "solaz")

        if self.as_integer("receiver_type") == 0:
            self.set_unit_value_ssc_double(type222_receiver, "N_panels")
            self.set_unit_value_ssc_double(type222_receiver, "D_rec", D_rec)
            self.set_unit_value_ssc_double(type222_receiver, "H_rec", H_rec)
            self.set_unit_value_ssc_double(type222_receiver, "THT", THT)
            self.set_unit_value_ssc_double(type222_receiver, "d_tube_out")
            self.set_unit_value_ssc_double(type222_receiver, "th_tube")
            self.set_unit_value_ssc_double(type222_receiver, "mat_tube")
            self.set_unit_value_ssc_double(type222_receiver, "rec_htf")
            self.set_unit_value_ssc_matrix(type222_receiver, "field_fl_props")
            self.set_unit_value_ssc_double(type222_receiver, "Flow_type")
            self.set_unit_value_ssc_double(type222_receiver, "crossover_shift")
            self.set_unit_value_ssc_double(type222_receiver, "epsilon")
            self.set_unit_value_ssc_double(type222_receiver, "hl_ffact")
            self.set_unit_value_ssc_double(type222_receiver, "T_htf_hot_des")
            self.set_unit_value_ssc_double(type222_receiver, "T_htf_cold_des")
            self.set_unit_value_ssc_double(type222_receiver, "f_rec_min")
            self.set_unit_value_ssc_double(type222_receiver, "Q_rec_des")
            self.set_unit_value_ssc_double(type222_receiver, "rec_su_delay")
            self.set_unit_value_ssc_double(type222_receiver, "rec_qf_delay")
            self.set_unit_value_ssc_double(type222_receiver, "m_dot_htf_max")
            self.set_unit_value_ssc_double(type222_receiver, "A_sf", A_sf)
            self.set_unit_value_ssc_double(type222_receiver, "n_flux_x")
            self.set_unit_value_ssc_double(type222_receiver, "n_flux_y")
            self.set_unit_value_ssc_double(type222_receiver, "piping_loss")
            self.set_unit_value_ssc_double(type222_receiver, "piping_length_add", "piping_length_const")
            self.set_unit_value_ssc_double(type222_receiver, "piping_length_mult", "piping_length_mult")
            self.set_unit_value_ssc_double(type222_receiver, "T_salt_hot_target", self.as_double("T_htf_hot_des"))
            self.set_unit_value_ssc_double(type222_receiver, "eta_pump")
            self.set_unit_value_ssc_double(type222_receiver, "night_recirc", 0.0)
            self.set_unit_value_ssc_double(type222_receiver, "hel_stow_deploy")

            bConnected &= self.connect(weather, "solazi", type222_receiver, "azimuth")
            bConnected &= self.connect(weather, "solzen", type222_receiver, "zenith")
            bConnected &= self.connect(iscc_pb, "T_htf_cold", type222_receiver, "T_salt_cold")
            bConnected &= self.connect(weather, "wspd", type222_receiver, "V_wind_10")
            bConnected &= self.connect(weather, "pres", type222_receiver, "P_amb")
            bConnected &= self.connect(weather, "tdew", type222_receiver, "T_dp")
            bConnected &= self.connect(weather, "beam", type222_receiver, "I_bn")
            bConnected &= self.connect(type_hel_field, "eta_field", type222_receiver, "field_eff")
            bConnected &= self.connect(weather, "tdry", type222_receiver, "T_db")
            bConnected &= self.connect(type_hel_field, "flux_map", type222_receiver, "flux_map")
            self.set_unit_value(type222_receiver, "T_salt_cold", self.as_double("T_htf_cold_des"))
        # } // external receiver

        self.set_unit_value(iscc_pb, "HTF_code", self.as_double("rec_htf"))
        self.set_unit_value_ssc_matrix(iscc_pb, "field_fl_props")
        self.set_unit_value(iscc_pb, "Q_sf_des", self.as_double("q_pb_design"))
        self.set_unit_value_ssc_double(iscc_pb, "plant_elevation", self.as_double("elev"))
        self.set_unit_value(iscc_pb, "cycle_config", self.as_double("ngcc_model"))
        self.set_unit_value_ssc_double(iscc_pb, "hot_side_delta_t", self.as_double("pinch_point_hotside"))
        self.set_unit_value_ssc_double(iscc_pb, "pinch_point", self.as_double("pinch_point_coldside"))

        bConnected &= self.connect(weather, "tdry", iscc_pb, "T_amb")
        bConnected &= self.connect(weather, "pres", iscc_pb, "P_amb")
        bConnected &= self.connect(type222_receiver, "m_dot_salt_tot", iscc_pb, "m_dot_ms_ss")
        bConnected &= self.connect(type222_receiver, "q_dot_ss", iscc_pb, "q_dot_rec_ss")
        bConnected &= self.connect(type222_receiver, "T_salt_cold", iscc_pb, "T_rec_in")
        bConnected &= self.connect(type222_receiver, "T_salt_hot", iscc_pb, "T_rec_out")

        self.set_unit_value_ssc_double(iscc_parasitics, "W_htf_pc_pump", self.as_double("pb_pump_coef"))
        self.set_unit_value_ssc_double(iscc_parasitics, "Q_sf_des", self.as_double("Q_rec_des"))
        self.set_unit_value_ssc_double(iscc_parasitics, "pb_fixed_par")
        self.set_unit_value_ssc_double(iscc_parasitics, "bop_par")
        self.set_unit_value_ssc_double(iscc_parasitics, "bop_par_f")
        self.set_unit_value_ssc_double(iscc_parasitics, "bop_par_0")
        self.set_unit_value_ssc_double(iscc_parasitics, "bop_par_1")
        self.set_unit_value_ssc_double(iscc_parasitics, "bop_par_2")
        self.set_unit_value_ssc_double(iscc_parasitics, "W_dot_fossil_des", self.as_double("fossil_output"))
        self.set_unit_value_ssc_double(iscc_parasitics, "W_dot_solar_des")

        bConnected &= self.connect(type_hel_field, "pparasi", iscc_parasitics, "W_dot_tracking")
        bConnected &= self.connect(type222_receiver, "W_dot_pump", iscc_parasitics, "W_dot_rec_pump")
        bConnected &= self.connect(type222_receiver, "m_dot_ss", iscc_parasitics, "m_dot_htf_ss")
        bConnected &= self.connect(iscc_pb, "W_dot_pc_hybrid", iscc_parasitics, "W_dot_pc_hybrid")
        bConnected &= self.connect(iscc_pb, "W_dot_pc_fossil", iscc_parasitics, "W_dot_pc_fossil")
        bConnected &= self.connect(type222_receiver, "f_timestep", iscc_parasitics, "f_timestep")
        bConnected &= self.connect(type222_receiver, "q_dot_ss", iscc_parasitics, "q_solar_ss")
        bConnected &= self.connect(iscc_pb, "q_dot_fuel", iscc_parasitics, "q_dot_fuel")

        sf_haf = sf_adjustment_factors(self)
        if not sf_haf.setup():
            raise exec_error("tcsgeneric_solar", "failed to setup sf adjustment factors: " + sf_haf.error())
        sf_adjust = self.allocate("sf_adjust", 8760)
        for i in range(8760):
            sf_adjust[i] = sf_haf(i)
        self.set_unit_value_ssc_array(type_hel_field, "sf_adjust")

        if not bConnected:
            raise exec_error("tcs_iscc", util.format("there was a problem connecting outputs of one unit to inputs of another for the simulation."))

        hours = 8760
        if self.simulate(3600.0, hours * 3600.0, 3600.0) < 0:
            raise exec_error("tcs_iscc", util.format("there was a problem simulating in tcs_iscc."))
        if not self.set_all_output_arrays():
            raise exec_error("tcs_iscc", util.format("there was a problem returning the results from the simulation."))

        haf = adjustment_factors(self, "adjust")
        if not haf.setup():
            raise exec_error("tcsmolten_salt", "failed to setup adjustment factors: " + haf.error())
        p_hourly_energy = self.allocate("gen", 8760)
        count = 0
        hourly_energy = self.as_array("W_dot_plant_solar", &count)  # MWh
        if count != 8760:
            msg = "gen count incorrect (should be 8760): " + str(count)
            raise exec_error("tcsiscc", msg)
        for i in range(count):
            p_hourly_energy[i] = hourly_energy[i] * ssc_number_t(haf(i) * 1000.0)

        self.accumulate_annual("gen", "annual_energy")  # already in kWh
        kWhperkW = 0.0
        nameplate = self.as_double("system_capacity")
        annual_energy = 0.0
        for i in range(8760):
            annual_energy += p_hourly_energy[i]
        if nameplate > 0:
            kWhperkW = annual_energy / nameplate
        self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
        self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
        self.assign("system_heat_rate", 0.0)  # samsim tcstrough_physical
        self.assign("annual_fuel_usage", 0.0)

# DEFINE_TCS_MODULE_ENTRY( tcsiscc, "Triple pressure NGCC integrated with MS power tower", 4 )
# In Mojo we need to call a registration macro if available; assume it's defined elsewhere.
# For this translation, we omit the macro and rely on the Mojo equivalent.
# The macro is likely used in the framework; we'll keep it as a comment.
# DEFINE_TCS_MODULE_ENTRY( tcsiscc, "Triple pressure NGCC integrated with MS power tower", 4 )