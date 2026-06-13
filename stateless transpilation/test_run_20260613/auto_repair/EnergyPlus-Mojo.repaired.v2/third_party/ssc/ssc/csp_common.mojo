from memory import pointer
from math import fabs, min, exp, pow
from utils import String

# Include header equivalents
from core import compute_module, var_map, var_info, var_info_invalid, SSC_INPUT, SSC_OUTPUT, SSC_NUMBER, SSC_MATRIX, SSC_ARRAY, SSC_ERROR, SSC_WARNING, exec_error, ssc_number_t, simulation_info, weather_data_provider, weather_header, weather_record
from AutoPilot_API import AutoPilot_S, sp_layout, sp_flux_table, sp_layout_table, AutoPilot, simulation_info
from lib_weatherfile import weatherfile, make_shared
from sco2_pc_csp_int import C_sco2_phx_air_cooler, C_sco2_cycle_core, C_comp__psi_eta_vs_phi, ssc_cmod_update, sco2_cycle_plot_data_TS, sco2_cycle_plot_data_PH, C_csp_exception, NS_HX_counterflow_eqs, calculate_turbomachinery_outlet_1
from lib_util import util, split
from common import spexception
from SolarField import var_heliostat, var_receiver, opt
from IOUtil import IOUtil

alias mysnprintf = snprintf

class solarpilot_invoke(var_map):
    var m_cmod: compute_module
    var m_sapi: AutoPilot_S
    var _optimization_sim_points: List[List[Float64]]
    var _optimization_objectives: List[Float64]
    var _optimization_fluxes: List[Float64]

    def __init__(inout self, cm: compute_module):
        self.m_cmod = cm
        self.m_sapi = AutoPilot_S()
        # Note: original set to 0, but AutoPilot_S is not nullable; will use default init
        # Instead, we track a flag if needed; for 1:1 translation, we set m_sapi but the C++ delete checks will not work
        # m_sapi will be initialized by default; we override later in run()
        # However, the original code sets m_sapi = 0; since Mojo doesn't have null pointers for objects,
        # we handle it by checking a flag; but to stay faithful, we'll use a nullable pointer approach via Optional
        # Actually, AutoPilot_S is a struct; we can use a pointer to AutoPilot_S.
        # Let's use Pointer[AutoPilot_S] to mimic null.
        self.m_sapi = AutoPilot_S()  # temporary, will be replaced in run()
        # For destructor equivalent, we need __del__. Since Mojo doesn't have destructors, we'll omit delete.

    def __del__(owned self):
        # Original deletes m_sapi; no-op in Mojo (GC handles)

    def GetSAPI(inout self) -> AutoPilot_S:
        return self.m_sapi

    def getOptimizationSimulationHistory(inout self, sim_points: List[List[Float64]], obj_values: List[Float64], flux_values: List[Float64]):
        sim_points = self._optimization_sim_points
        obj_values = self._optimization_objectives
        flux_values = self._optimization_fluxes

    def setOptimizationSimulationHistory(inout self, sim_points: List[List[Float64]], obj_values: List[Float64], flux_values: List[Float64]):
        self._optimization_sim_points = sim_points
        self._optimization_objectives = obj_values
        self._optimization_fluxes = flux_values

    def run(inout self, wdata: Optional[weather_data_provider] = None) -> Bool:
        # Original: if(m_sapi != 0) delete m_sapi; m_sapi = new AutoPilot_S();
        self.m_sapi = AutoPilot_S()
        var isopt: Bool = self.m_cmod.as_boolean("is_optimize")
        if isopt:
            opt.max_step.val = self.m_cmod.as_double("opt_init_step")
            opt.max_iter.val = self.m_cmod.as_integer("opt_max_iter")
            opt.converge_tol.val = self.m_cmod.as_double("opt_conv_tol")
            opt.algorithm.combo_select_by_mapval(self.m_cmod.as_integer("opt_algorithm"))
            opt.flux_penalty.val = self.m_cmod.as_double("opt_flux_penalty")
        recs.front().peak_flux.val = self.m_cmod.as_double("flux_max")
        var hf: var_heliostat = hels.front()
        sf.temp_which.combo_clear()
        var name: String = "Template 1"
        var val: String = "0"
        sf.temp_which.combo_add_choice(name, val)
        sf.temp_which.combo_select_by_choice_index(0)
        hf.width.val = self.m_cmod.as_double("helio_width")
        hf.height.val = self.m_cmod.as_double("helio_height")
        hf.err_azimuth.val = hf.err_elevation.val = hf.err_reflect_x.val = hf.err_reflect_y.val = 0.0
        hf.err_surface_x.val = hf.err_surface_y.val = self.m_cmod.as_double("helio_optical_error")
        hf.soiling.val = 1.0
        hf.reflect_ratio.val = self.m_cmod.as_double("helio_active_fraction") * self.m_cmod.as_double("dens_mirror")
        hf.reflectivity.val = self.m_cmod.as_double("helio_reflectance")
        hf.n_cant_x.val = self.m_cmod.as_integer("n_facet_x")
        hf.n_cant_y.val = self.m_cmod.as_integer("n_facet_y")
        var cant_choices: List[String] = ["No canting", "On-axis at slant", "On-axis, user-defined", "Off-axis, day and hour", "User-defined vector"]
        var cmap: List[Int] = [0, 0, 0, 0, 0]
        cmap[0] = var_heliostat.CANT_METHOD.NO_CANTING
        cmap[1] = var_heliostat.CANT_METHOD.ONAXIS_AT_SLANT
        cmap[2] = cmap[3] = cmap[4] = var_heliostat.CANT_METHOD.OFFAXIS_DAY_AND_HOUR
        var cant_type: Int = self.m_cmod.as_integer("cant_type")
        hf.cant_method.combo_select(cant_choices[cant_type])
        if cant_type == AutoPilot.API_CANT_TYPE.NONE:

        elif cant_type == AutoPilot.API_CANT_TYPE.ON_AXIS:

        elif cant_type == AutoPilot.API_CANT_TYPE.EQUINOX:
            hf.cant_day.val = 81
            hf.cant_hour.val = 12
        elif cant_type == AutoPilot.API_CANT_TYPE.SOLSTICE_SUMMER:
            hf.cant_day.val = 172
            hf.cant_hour.val = 12
        elif cant_type == AutoPilot.API_CANT_TYPE.SOLSTICE_WINTER:
            hf.cant_day.val = 355
            hf.cant_hour.val = 12
        else:
            var msg: String = String("Invalid Cant Type specified in AutoPILOT API. Method must be one of: \n") + \
                "NONE(0), ON_AXIS(1), EQUINOX(2), SOLSTICE_SUMMER(3), SOLSTICE_WINTER(4).\n" + \
                "Method specified is: " + String(cant_type) + "."
            raise spexception(msg)
        hf.focus_method.combo_select_by_choice_index(self.m_cmod.as_integer("focus_type"))
        var rf: var_receiver = recs.front()
        rf.absorptance.val = self.m_cmod.as_double("rec_absorptance")
        rf.rec_height.val = self.m_cmod.as_double("rec_height")
        rf.rec_width.val = rf.rec_diameter.val = rf.rec_height.val / self.m_cmod.as_double("rec_aspect")
        rf.therm_loss_base.val = self.m_cmod.as_double("rec_hl_perm2")
        sf.q_des.val = self.m_cmod.as_double("q_design")
        sf.dni_des.val = self.m_cmod.as_double("dni_des")
        land.is_bounds_scaled.val = True
        land.is_bounds_fixed.val = False
        land.is_bounds_array.val = False
        land.max_scaled_rad.val = self.m_cmod.as_double("land_max")
        land.min_scaled_rad.val = self.m_cmod.as_double("land_min")
        sf.tht.val = self.m_cmod.as_double("h_tower")
        fin.tower_fixed_cost.val = self.m_cmod.as_double("tower_fixed_cost")
        fin.tower_exp.val = self.m_cmod.as_double("tower_exp")
        fin.rec_ref_cost.val = self.m_cmod.as_double("rec_ref_cost")
        fin.rec_ref_area.val = self.m_cmod.as_double("rec_ref_area")
        fin.rec_cost_exp.val = self.m_cmod.as_double("rec_cost_exp")
        fin.site_spec_cost.val = self.m_cmod.as_double("site_spec_cost")
        fin.heliostat_spec_cost.val = self.m_cmod.as_double("heliostat_spec_cost")
        fin.land_spec_cost.val = self.m_cmod.as_double("land_spec_cost")
        fin.contingency_rate.val = self.m_cmod.as_double("contingency_rate")
        fin.sales_tax_rate.val = self.m_cmod.as_double("sales_tax_rate")
        fin.sales_tax_frac.val = self.m_cmod.as_double("sales_tax_frac")
        fin.fixed_cost.val = self.m_cmod.as_double("cost_sf_fixed")
        if wdata is None:
            var wffile: String = self.m_cmod.as_string("solar_resource_file")
            wdata = make_shared[weatherfile](wffile)
            if not wdata:
                raise exec_error("solarpilot", "no weather file specified")
            if not wdata.ok() or wdata.has_message():
                raise exec_error("solarpilot", wdata.message())
        var hdr: weather_header
        wdata.header(hdr)
        amb.latitude.val = hdr.lat
        amb.longitude.val = hdr.lon
        amb.time_zone.val = hdr.tz
        amb.atm_model.combo_select_by_choice_index(2)
        amb.atm_coefs.val.at[2, 0] = self.m_cmod.as_double("c_atm_0")
        amb.atm_coefs.val.at[2, 1] = self.m_cmod.as_double("c_atm_1")
        amb.atm_coefs.val.at[2, 2] = self.m_cmod.as_double("c_atm_2")
        amb.atm_coefs.val.at[2, 3] = self.m_cmod.as_double("c_atm_3")
        if not self.m_cmod.is_assigned("helio_positions_in"):
            var wf: weather_record
            var wfdata: List[String] = List[String]()
            wfdata.reserve(8760)
            var buf: String = String(" " * 1024)
            for i in range(8760):
                if not wdata.read(wf):
                    raise exec_error("solarpilot", "could not read data line " + util.to_string(i + 1) + " of 8760 in weather data")
                mysnprintf(buf, 1023, "%d,%d,%d,%.2lf,%.1lf,%.1lf,%.1lf", wf.day, wf.hour, wf.month, wf.dn, wf.tdry, wf.pres / 1000.0, wf.wspd)
                wfdata.push_back(String(buf))
            self.m_sapi.SetDetailCallback(ssc_cmod_solarpilot_callback, self.m_cmod)
            self.m_sapi.SetSummaryCallbackStatus(False)
            self.m_sapi.GenerateDesignPointSimulations(self, wfdata)
            if isopt:
                self.m_cmod.log("Optimizing...", SSC_WARNING, 0.0)
                self.m_sapi.SetSummaryCallback(optimize_callback, self.m_cmod)
                self.m_sapi.Setup(self, True)
                var nv: Int = 3
                var optvars: List[Pointer[Float64]] = List[Pointer[Float64]](nv)
                var upper: List[Float64] = List[Float64](nv, 1e308)  # HUGE_VAL approximate
                var lower: List[Float64] = List[Float64](nv, -1e308)
                var stepsize: List[Float64] = List[Float64](nv)
                var names: List[String] = List[String](nv)
                optvars[0] = address_of(sf.tht.val)
                optvars[1] = address_of(recs.front().rec_height.val)
                optvars[2] = address_of(recs.front().rec_diameter.val)
                names[0] = (split(sf.tht.name, ".")).back()
                names[1] = (split(recs.front().rec_height.name, ".")).back()
                names[2] = (split(recs.front().rec_diameter.name, ".")).back()
                stepsize[0] = sf.tht.val * opt.max_step.val
                stepsize[1] = recs.front().rec_height.val * opt.max_step.val
                stepsize[2] = recs.front().rec_diameter.val * opt.max_step.val
                if not self.m_sapi.Optimize(opt.algorithm.mapval(), optvars, upper, lower, stepsize, names):
                    return False
            self.m_sapi.Setup(self)
            self.m_sapi.SetSummaryCallbackStatus(False)
            self.m_sapi.PreSimCallbackUpdate()
            if not self.m_sapi.CreateLayout(self.layout):
                return False
        else:
            var format: String = "0,%f,%f,%f,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL;"
            sf.layout_data.val.clear()
            var hpos: util.matrix_t[Float64] = self.m_cmod.as_matrix("helio_positions_in")
            var row: String = String(" " * 200)
            for i in range(hpos.nrows()):
                sprintf(row, format.c_str(), hpos.at(i, 0), hpos.at(i, 1), 0.0)
                sf.layout_data.val.append(row)
            self.m_sapi.Setup(self)
        if self.m_cmod.as_boolean("calc_fluxmaps"):
            self.m_sapi.SetDetailCallbackStatus(False)
            self.m_sapi.SetSummaryCallbackStatus(True)
            self.m_sapi.SetSummaryCallback(ssc_cmod_solarpilot_callback, self.m_cmod)
            self.fluxtab.is_user_spacing = True
            self.fluxtab.n_flux_days = self.m_cmod.as_integer("n_flux_days")
            self.fluxtab.delta_flux_hrs = self.m_cmod.as_integer("delta_flux_hrs")
            var aim_method_save: String = flux.aim_method.val
            flux.aim_method.combo_select("Simple aim points")
            var nflux_x: Int = self.m_cmod.as_integer("n_flux_x")
            var nflux_y: Int = self.m_cmod.as_integer("n_flux_y")
            if not self.m_sapi.CalculateFluxMaps(self.fluxtab, nflux_x, nflux_y, True):
                flux.aim_method.combo_select(aim_method_save)
                return False
            flux.aim_method.combo_select(aim_method_save)
            if len(self.fluxtab.zeniths) == 0 or len(self.fluxtab.azimuths) == 0 or len(self.fluxtab.efficiency) == 0:
                raise exec_error("solarpilot", "failed to calculate a correct optical efficiency table")
            var flux_data: Pointer[block_t[Float64]] = address_of(self.fluxtab.flux_surfaces.front().flux_data)
            if flux_data[].ncols() == 0 or flux_data[].nlayers() == 0:
                raise exec_error("solarpilot", "failed to calculate a correct flux map table")
        if self.m_cmod.as_boolean("check_max_flux"):
            self.m_sapi.SetDetailCallbackStatus(False)
            self.m_sapi.SetSummaryCallbackStatus(True)
            self.m_sapi.SetSummaryCallback(ssc_cmod_solarpilot_callback, self.m_cmod)
            var flux_temp: sp_flux_table
            flux_temp.is_user_spacing = False
            flux_temp.azimuths.clear()
            flux_temp.zeniths.clear()
            flux_temp.azimuths.push_back(flux.flux_solar_az.Val() * D2R)
            flux_temp.zeniths.push_back((90.0 - flux.flux_solar_el.Val()) * D2R)
            if not self.m_sapi.CalculateFluxMaps(flux_temp, 20, 15, False):
                return False
            var flux_data: Pointer[block_t[Float64]] = address_of(flux_temp.flux_surfaces.front().flux_data)
            var flux_max_observed: Float64 = 0.0
            for i in range(flux_data[].nrows()):
                for j in range(flux_data[].ncols()):
                    if flux_data[].at(i, j, 0) > flux_max_observed:
                        flux_max_observed = flux_data[].at(i, j, 0)
            self.m_cmod.assign("flux_max_observed", ssc_number_t(flux_max_observed))
        return True

    def postsim_calcs(inout self, cm: compute_module) -> Bool:
        var H_rec: Float64 = recs.front().rec_height.val
        var rec_aspect: Float64 = recs.front().rec_aspect.Val()
        var THT: Float64 = sf.tht.val
        var nr: Int = Int(len(heliotab.positions))
        var ssc_hl: Pointer[ssc_number_t] = cm.allocate("helio_positions", nr, 2)
        for i in range(nr):
            ssc_hl[i * 2] = ssc_number_t(self.layout.heliostat_positions[i].location.x)
            ssc_hl[i * 2 + 1] = ssc_number_t(self.layout.heliostat_positions[i].location.y)
        var A_sf: Float64 = cm.as_double("helio_height") * cm.as_double("helio_width") * cm.as_double("dens_mirror") * Float64(nr)
        var piping_length: Float64 = THT * cm.as_double("csp.pt.par.piping_length_mult") + cm.as_double("csp.pt.par.piping_length_const")
        cm.assign("H_rec", var_data(ssc_number_t(H_rec)))
        cm.assign("rec_height", var_data(ssc_number_t(H_rec)))
        cm.assign("rec_aspect", var_data(ssc_number_t(rec_aspect)))
        cm.assign("D_rec", var_data(ssc_number_t(H_rec / rec_aspect)))
        cm.assign("THT", var_data(ssc_number_t(THT)))
        cm.assign("h_tower", var_data(ssc_number_t(THT)))
        cm.assign("A_sf", var_data(ssc_number_t(A_sf)))
        cm.assign("Piping_length", var_data(ssc_number_t(piping_length)))
        var total_direct_cost: Float64 = 0.0
        var A_rec: Float64 = Float64.NaN
        if recs.front().rec_type.mapval() == var_receiver.REC_TYPE.EXTERNAL_CYLINDRICAL:
            var h: Float64 = recs.front().rec_height.val
            var d: Float64 = h / recs.front().rec_aspect.Val()
            A_rec = h * d * 3.1415926
        elif recs.front().rec_type.mapval() == var_receiver.REC_TYPE.FLAT_PLATE:
            var h: Float64 = recs.front().rec_height.val
            var w: Float64 = h / recs.front().rec_aspect.Val()
            A_rec = h * w
        var receiver: Float64 = cm.as_double("rec_ref_cost") * pow(A_rec / cm.as_double("rec_ref_area"), cm.as_double("rec_cost_exp"))
        var storage: Float64 = cm.as_double("q_pb_design") * cm.as_double("tshours") * cm.as_double("tes_spec_cost") * 1000.0
        var P_ref: Float64 = cm.as_double("P_ref") * 1000.0
        var power_block: Float64 = P_ref * (cm.as_double("plant_spec_cost") + cm.as_double("bop_spec_cost"))
        var site_improvements: Float64 = A_sf * cm.as_double("site_spec_cost")
        var heliostats: Float64 = A_sf * cm.as_double("heliostat_spec_cost")
        var cost_fixed: Float64 = cm.as_double("cost_sf_fixed")
        var fossil: Float64 = P_ref * cm.as_double("fossil_spec_cost")
        var tower: Float64 = cm.as_double("tower_fixed_cost") * exp(cm.as_double("tower_exp") * (THT + 0.5 * (-H_rec + cm.as_double("helio_height"))))
        total_direct_cost = (1.0 + cm.as_double("contingency_rate") / 100.0) * (
            site_improvements + heliostats + power_block +
            cost_fixed + storage + fossil + tower + receiver)
        var land_area: Float64 = land.land_area.Val() * cm.as_double("csp.pt.sf.land_overhead_factor") + cm.as_double("csp.pt.sf.fixed_land_area")
        var cost_epc: Float64 = \
            cm.as_double("csp.pt.cost.epc.per_acre") * land_area \
            + cm.as_double("csp.pt.cost.epc.percent") * total_direct_cost / 100.0 \
            + P_ref * 1000.0 * cm.as_double("csp.pt.cost.epc.per_watt") \
            + cm.as_double("csp.pt.cost.epc.fixed")
        var cost_plm: Float64 = \
            cm.as_double("csp.pt.cost.plm.per_acre") * land_area \
            + cm.as_double("csp.pt.cost.plm.percent") * total_direct_cost / 100.0 \
            + P_ref * 1000.0 * cm.as_double("csp.pt.cost.plm.per_watt") \
            + cm.as_double("csp.pt.cost.plm.fixed")
        var cost_sales_tax: Float64 = cm.as_double("sales_tax_rate") / 100.0 * total_direct_cost * cm.as_double("sales_tax_frac") / 100.0
        var total_indirect_cost: Float64 = cost_epc + cost_plm + cost_sales_tax
        var total_installed_cost: Float64 = total_direct_cost + total_indirect_cost
        cm.assign("total_installed_cost", var_data(ssc_number_t(total_installed_cost)))
        return True

def ssc_cmod_solarpilot_callback(siminfo: Pointer[simulation_info], data: Pointer[Byte]) -> Bool:
    var cm: compute_module = compute_module(data)
    if not cm:
        return False
    var simprogress: Float32 = Float32(siminfo[].getCurrentSimulation()) / Float32(max(siminfo[].getTotalSimulationCount(), 1))
    return cm.update(siminfo[].getSimulationNotices(), simprogress * 100.0)

def optimize_callback(siminfo: Pointer[simulation_info], data: Pointer[Byte]) -> Bool:
    var cm: compute_module = compute_module(data)
    if not cm:
        return False
    var notices: String = siminfo[].getSimulationNotices()
    cm.log(notices, SSC_WARNING, 0.0)
    return True

def are_values_sig_different(v1: Float64, v2: Float64, tol: Float64) -> Bool:
    if fabs(v1) < tol or fabs(v2) < tol:
        if fabs(v1 - v2) > tol:
            return True
    else:
        if fabs(v1 - v2) / min(fabs(v1), fabs(v2)) > tol:
            return True
    return False

var vtab_sco2_design: List[var_info] = [
    var_info(SSC_INPUT, SSC_NUMBER, "htf", "Integer code for HTF used in PHX", "", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "htf_props", "User defined HTF property data", "", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "System Design", "?=[[0]]", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_htf_hot_des", "HTF design hot temperature (PHX inlet)", "C", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dT_PHX_hot_approach", "Temp diff btw hot HTF and turbine inlet", "C", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "T_amb_des", "Ambient temperature", "C", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dT_mc_approach", "Temp diff btw ambient air and main compressor inlet", "C", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "site_elevation", "Site elevation", "m", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "W_dot_net_des", "Design cycle power output (no cooling parasitics)", "MWe", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "design_method", "1 = Specify efficiency, 2 = Specify total recup UA, 3 = Specify each recup design", "", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_thermal_des", "Power cycle thermal efficiency", "", "", "System Design", "design_method=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "UA_recup_tot_des", "Total recuperator conductance", "kW/K", "Combined recuperator design", "Heat Exchanger Design", "design_method=2", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_design_code", "1 = UA, 2 = min dT, 3 = effectiveness", "-", "Low temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_UA_des_in", "Design LTR conductance", "kW/K", "Low temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_min_dT_des_in", "Design minimum allowable temperature difference in LTR", "C", "Low temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_eff_des_in", "Design effectiveness for LTR", "-", "Low temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LT_recup_eff_max", "Maximum allowable effectiveness in LTR", "-", "Low temperature recuperator", "Heat Exchanger Design", "?=1.0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_LP_deltaP_des_in", "LTR low pressure side pressure drop as fraction of inlet pressure", "-", "Low temperature recuperator", "Heat Exchanger Design", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_HP_deltaP_des_in", "LTR high pressure side pressure drop as fraction of inlet pressure", "-", "Low temperature recuperator", "Heat Exchanger Design", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_n_sub_hx", "LTR number of model subsections", "-", "Low temperature recuperator", "Heat Exchanger Design", "?=10", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "LTR_od_model", "0: mass flow scale, 1: conductance ratio model", "-", "Low temperature recuperator", "Heat Exchanger Design", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_design_code", "1 = UA, 2 = min dT, 3 = effectiveness", "-", "High temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_UA_des_in", "Design HTR conductance", "kW/K", "High temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_min_dT_des_in", "Design minimum allowable temperature difference in HTR", "C", "High temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_eff_des_in", "Design effectiveness for HTR", "-", "High temperature recuperator", "Heat Exchanger Design", "design_method=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HT_recup_eff_max", "Maximum allowable effectiveness in HTR", "-", "High temperature recuperator", "Heat Exchanger Design", "?=1.0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_LP_deltaP_des_in", "HTR low pressure side pressure drop as fraction of inlet pressure", "-", "High temperature recuperator", "Heat Exchanger Design", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_HP_deltaP_des_in", "HTR high pressure side pressure drop as fraction of inlet pressure", "-", "High temperature recuperator", "Heat Exchanger Design", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_n_sub_hx", "HTR number of model subsections", "-", "High temperature recuperator", "Heat Exchanger Design", "?=10", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "HTR_od_model", "0: mass flow scale, 1: conductance ratio model", "-", "High temperature recuperator", "Heat Exchanger Design", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "cycle_config", "1 = recompression, 2 = partial cooling", "", "High temperature recuperator", "Heat Exchanger Design", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_recomp_ok", "1 = Yes, 0 = simple cycle only, < 0 = fix f_recomp to abs(input)", "", "High temperature recuperator", "Heat Exchanger Design", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_P_high_fixed", "1 = Yes (=P_high_limit), 0 = No, optimized (default)", "", "High temperature recuperator", "Heat Exchanger Design", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_PR_fixed", "0 = No, >0 = fixed pressure ratio at input <0 = fixed LP at abs(input)", "", "High temperature recuperator", "Heat Exchanger Design", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_IP_fixed", "partial cooling config: 0 = No, >0 = fixed HP-IP pressure ratio at input, <0 = fixed IP at abs(input)", "", "High temperature recuperator", "Heat Exchanger Design", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "des_objective", "[2] = hit min phx deltat then max eta, [else] max eta", "", "High temperature recuperator", "Heat Exchanger Design", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "min_phx_deltaT", "Minimum design temperature difference across PHX", "C", "High temperature recuperator", "Heat Exchanger Design", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rel_tol", "Baseline solver and optimization relative tolerance exponent (10^-rel_tol)", "-", "High temperature recuperator", "Heat Exchanger Design", "?=3", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_isen_mc", "Design main compressor isentropic efficiency", "-", "", "", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "mc_comp_type", "Main compressor compressor type 1: SNL 2: CompA", "-", "", "", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_isen_rc", "Design re-compressor isentropic efficiency", "-", "", "", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_isen_pc", "Design precompressor isentropic efficiency", "-", "", "", "cycle_config=2", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_isen_t", "Design turbine isentropic efficiency", "-", "", "", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "PHX_co2_deltaP_des_in", "PHX co2 side pressure drop as fraction of inlet pressure", "-", "", "", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "deltaP_counterHX_frac", "Fraction of CO2 inlet pressure that is design point counterflow HX (recups & PHX) pressure drop", "-", "", "", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "P_high_limit", "High pressure limit in cycle", "MPa", "", "", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dT_PHX_cold_approach", "Temp diff btw cold HTF and cold CO2", "C", "", "PHX Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "PHX_n_sub_hx", "Number of subsections in PHX model", "-", "", "PHX Design", "?=10", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "PHX_od_model", "0: mass flow scale, 1: conductance ratio model", "-", "", "PHX Design", "?=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "is_design_air_cooler", "Defaults to True. False will skip air cooler calcs", "", "", "Air Cooler Design", "?=1.0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fan_power_frac", "Fraction of net cycle power consumed by air cooler fan", "", "", "Air Cooler Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "deltaP_cooler_frac", "Fraction of CO2 inlet pressure that is design point cooler CO2 pressure drop", "", "", "Air Cooler Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "eta_air_cooler_fan", "Air cooler fan isentropic efficiency", "", "", "Air Cooler Design", "?=0.5", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "N_nodes_air_cooler_pass", "Number of nodes in single air cooler pass", "", "", "Air Cooler Design", "?=10", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "T_htf_cold_des", "HTF design cold temperature (PHX outlet)", "C", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "m_dot_htf_des", "HTF mass flow rate", "kg/s", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "eta_thermal_calc", "Calculated cycle thermal efficiency", "-", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "m_dot_co2_full", "CO2 mass flow rate through HTR, PHX, turbine", "kg/s", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "recomp_frac", "Recompression fraction", "-", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "cycle_cost", "Cycle cost", "M$", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "cycle_spec_cost", "Cycle specific cost", "$/kWe", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "cycle_spec_cost_thermal", "Cycle specific cost - thermal", "$/kWt", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "W_dot_net_less_cooling", "System power output subtracting cooling parastics", "MWe,", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "eta_thermal_net_less_cooling_des", "Calculated cycle thermal efficiency using W_dot_net_less_cooling", "-", "System Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "T_comp_in", "Compressor inlet temperature", "C", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "P_comp_in", "Compressor inlet pressure", "MPa", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "P_comp_out", "Compressor outlet pressure", "MPa", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_T_out", "Compressor outlet temperature", "C", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_W_dot", "Compressor power", "MWe", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_m_dot_des", "Compressor mass flow rate", "kg/s", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_rho_in", "Compressor inlet density", "kg/m3", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_ideal_spec_work", "Compressor ideal spec work", "kJ/kg", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_phi_des", "Compressor design flow coefficient", "", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_psi_des", "Compressor design ideal head coefficient", "", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "mc_tip_ratio_des", "Compressor design stage tip speed ratio", "", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_n_stages", "Compressor stages", "", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_N_des", "Compressor design shaft speed", "rpm", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "mc_D", "Compressor stage diameters", "m", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_phi_surge", "Compressor flow coefficient where surge occurs", "", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_psi_max_at_N_des", "Compressor max ideal head coefficient at design shaft speed", "", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "mc_eta_stages_des", "Compressor design stage isentropic efficiencies", "", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cost", "Compressor cost", "M$", "Compressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_T_in_des", "Recompressor inlet temperature", "C", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_P_in_des", "Recompressor inlet pressure", "MPa", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_T_out_des", "Recompressor inlet temperature", "C", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_P_out_des", "Recompressor inlet pressure", "MPa", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_W_dot", "Recompressor power", "MWe", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_m_dot_des", "Recompressor mass flow rate", "kg/s", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_phi_des", "Recompressor design flow coefficient", "", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_psi_des", "Recompressor design ideal head coefficient", "", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "rc_tip_ratio_des", "Recompressor design stage tip speed ratio", "", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_n_stages", "Recompressor stages", "", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_N_des", "Recompressor design shaft speed", "rpm", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "rc_D", "Recompressor stage diameters", "m", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_phi_surge", "Recompressor flow coefficient where surge occurs", "", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_psi_max_at_N_des", "Recompressor max ideal head coefficient at design shaft speed", "", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "rc_eta_stages_des", "Recompressor design stage isenstropic efficiencies", "", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "rc_cost", "Recompressor cost", "M$", "Recompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_T_in_des", "Precompressor inlet temperature", "C", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_P_in_des", "Precompressor inlet pressure", "MPa", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_W_dot", "Precompressor power", "MWe", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_m_dot_des", "Precompressor mass flow rate", "kg/s", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_rho_in_des", "Precompressor inlet density", "kg/m3", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_ideal_spec_work_des", "Precompressor ideal spec work", "kJ/kg", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_phi_des", "Precompressor design flow coefficient", "", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pc_tip_ratio_des", "Precompressor design stage tip speed ratio", "", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_n_stages", "Precompressor stages", "", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_N_des", "Precompressor design shaft speed", "rpm", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pc_D", "Precompressor stage diameters", "m", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_phi_surge", "Precompressor flow coefficient where surge occurs", "", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pc_eta_stages_des", "Precompressor design stage isenstropic efficiencies", "", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cost", "Precompressor cost", "M$", "Precompressor", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "c_tot_cost", "Compressor total cost", "M$", "Compressor Totals", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "c_tot_W_dot", "Compressor total summed power", "MWe", "Compressor Totals", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_W_dot", "Turbine power", "MWe", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_m_dot_des", "Turbine mass flow rate", "kg/s", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "T_turb_in", "Turbine inlet temperature", "C", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_P_in_des", "Turbine design inlet pressure", "MPa", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_T_out_des", "Turbine outlet temperature", "C", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_P_out_des", "Turbine design outlet pressure", "MPa", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_delta_h_isen_des", "Turbine isentropic specific work", "kJ/kg", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_rho_in_des", "Turbine inlet density", "kg/m3", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_nu_des", "Turbine design velocity ratio", "", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_tip_ratio_des", "Turbine design tip speed ratio", "", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_N_des", "Turbine design shaft speed", "rpm", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_D", "Turbine diameter", "m", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "t_cost", "Tubine cost", "M$", "Turbine", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "recup_total_UA_assigned", "Total recuperator UA assigned to design routine", "MW/K", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "recup_total_UA_calculated", "Total recuperator UA calculated considering max eff and/or min temp diff parameter", "MW/K", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "recup_total_cost", "Total recuperator cost", "M$", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "recup_LTR_UA_frac", "Fraction of total conductance to LTR", "", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "LTR_HP_T_out_des", "Low temp recuperator HP outlet temperature", "C", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "LTR_UA_assigned", "Low temp recuperator UA assigned from total", "MW/K", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "LTR_UA_calculated", "Low temp recuperator UA calculated considering max eff and/or min temp diff parameter", "MW/K", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "eff_LTR", "Low temp recuperator effectiveness", "", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "NTU_LTR", "Low temp recuperator NTU", "", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "q_dot_LTR", "Low temp recuperator heat transfer", "MWt", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "LTR_LP_deltaP_des", "Low temp recuperator low pressure design pressure drop", "-", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "LTR_HP_deltaP_des", "Low temp recuperator high pressure design pressure drop", "-", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "LTR_min_dT", "Low temp recuperator min temperature difference", "C", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "LTR_cost", "Low temp recuperator cost", "M$", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_LP_T_out_des", "High temp recuperator LP outlet temperature", "C", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_HP_T_in_des", "High temp recuperator HP inlet temperature", "C", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_UA_assigned", "High temp recuperator UA assigned from total", "MW/K", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_UA_calculated", "High temp recuperator UA calculated considering max eff and/or min temp diff parameter", "MW/K", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "eff_HTR", "High temp recuperator effectiveness", "", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "NTU_HTR", "High temp recuperator NTRU", "", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "q_dot_HTR", "High temp recuperator heat transfer", "MWt", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_LP_deltaP_des", "High temp recuperator low pressure design pressure drop", "-", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_HP_deltaP_des", "High temp recuperator high pressure design pressure drop", "-", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_min_dT", "High temp recuperator min temperature difference", "C", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "HTR_cost", "High temp recuperator cost", "M$", "Recuperators", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "UA_PHX", "PHX Conductance", "MW/K", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "eff_PHX", "PHX effectiveness", "", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "NTU_PHX", "PHX NTU", "", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "T_co2_PHX_in", "CO2 temperature at PHX inlet", "C", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "P_co2_PHX_in", "CO2 pressure at PHX inlet", "MPa", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "deltaT_HTF_PHX", "HTF temp difference across PHX", "C", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "q_dot_PHX", "PHX heat transfer", "MWt", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "PHX_co2_deltaP_des", "PHX co2 side design pressure drop", "-", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "PHX_cost", "PHX cost", "M$", "PHX Design Solution", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_T_in", "Low pressure cross flow cooler inlet temperature", "C", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_P_in", "Low pressure cross flow cooler inlet pressure", "MPa", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_rho_in", "Low pressure cross flow cooler inlet density", "kg/m3", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_in_isen_deltah_to_P_mc_out", "Low pressure cross flow cooler inlet isen enthalpy rise to mc outlet pressure", "kJ/kg", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_m_dot_co2", "Low pressure cross flow cooler CO2 mass flow rate", "kg/s", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_UA", "Low pressure cross flow cooler conductance", "MW/K", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_q_dot", "Low pressure cooler heat transfer", "MWt", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_co2_deltaP_des", "Low pressure cooler co2 side design pressure drop", "-", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_W_dot_fan", "Low pressure cooler fan power", "MWe", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "mc_cooler_cost", "Low pressure cooler cost", "M$", "Low Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cooler_T_in", "Intermediate pressure cross flow cooler inlet temperature", "C", "Intermediate Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cooler_P_in", "Intermediate pressure cross flow cooler inlet pressure", "MPa", "Intermediate Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cooler_m_dot_co2", "Intermediate pressure cross flow cooler CO2 mass flow rate", "kg/s", "Intermediate Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cooler_UA", "Intermediate pressure cross flow cooler conductance", "MW/K", "Intermediate Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cooler_q_dot", "Intermediate pressure cooler heat transfer", "MWt", "Intermediate Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cooler_W_dot_fan", "Intermediate pressure cooler fan power", "MWe", "Intermediate Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "pc_cooler_cost", "Intermediate pressure cooler cost", "M$", "Intermediate Pressure Cooler", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "cooler_tot_cost", "Total cooler cost", "M$", "Cooler Totals", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "cooler_tot_UA", "Total cooler conductance", "MW/K", "Cooler Totals", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "cooler_tot_W_dot_fan", "Total cooler fan power", "MWe", "Cooler Totals", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_state_points", "Cycle temperature state points", "C", "State Points", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_state_points", "Cycle pressure state points", "MPa", "State Points", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_state_points", "Cycle entropy state points", "kJ/kg-K", "State Points", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "h_state_points", "Cycle enthalpy state points", "kJ/kg", "State Points", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_LTR_HP_data", "Temperature points along LTR HP stream", "C", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_LTR_HP_data", "Entropy points along LTR HP stream", "kJ/kg-K", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_HTR_HP_data", "Temperature points along HTR HP stream", "C", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_HTR_HP_data", "Entropy points along HTR HP stream", "kJ/kg-K", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_PHX_data", "Temperature points along PHX stream", "C", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_PHX_data", "Entropy points along PHX stream", "kJ/kg-K", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_HTR_LP_data", "Temperature points along HTR LP stream", "C", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_HTR_LP_data", "Entropy points along HTR LP stream", "kJ/kg-K", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_LTR_LP_data", "Temperature points along LTR LP stream", "C", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_LTR_LP_data", "Entropy points along LTR LP stream", "kJ/kg-K", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_main_cooler_data", "Temperature points along main cooler stream", "C", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_main_cooler_data", "Entropy points along main cooler stream", "kJ/kg-K", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "T_pre_cooler_data", "Temperature points along pre cooler stream", "C", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "s_pre_cooler_data", "Entropy points along pre cooler stream", "kJ/kg-K", "T-s plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_t_data", "Pressure points along turbine expansion", "MPa", "P-h plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "h_t_data", "Enthalpy points along turbine expansion", "kJ/kg", "P-h plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_mc_data", "Pressure points along main compression", "MPa", "P-h plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "h_mc_data", "Enthalpy points along main compression", "kJ/kg", "P-h plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_rc_data", "Pressure points along re compression", "MPa", "P-h plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "h_rc_data", "Enthalpy points along re compression", "kJ/kg", "P-h plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "P_pc_data", "Pressure points along pre compression", "MPa", "P-h plot data", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "h_pc_data", "Enthalpy points along pre compression", "kJ/kg", "P-h plot data", "", "*", "", ""),
    var_info_invalid
]

def sco2_design_cmod_common(cm: compute_module, c_sco2_cycle: C_sco2_phx_air_cooler) -> Int:
    var s_sco2_des_par: C_sco2_phx_air_cooler.S_des_par
    s_sco2_des_par.m_hot_fl_code = cm.as_integer("htf")
    s_sco2_des_par.mc_hot_fl_props = cm.as_matrix("htf_props")
    s_sco2_des_par.m_T_htf_hot_in = cm.as_double("T_htf_hot_des") + 273.15
    s_sco2_des_par.m_phx_dt_hot_approach = cm.as_double("dT_PHX_hot_approach")
    s_sco2_des_par.m_T_amb_des = cm.as_double("T_amb_des") + 273.15
    s_sco2_des_par.m_dt_mc_approach = cm.as_double("dT_mc_approach")
    s_sco2_des_par.m_elevation = cm.as_double("site_elevation")
    s_sco2_des_par.m_W_dot_net = cm.as_double("W_dot_net_des") * 1000.0
    s_sco2_des_par.m_cycle_config = cm.as_integer("cycle_config")
    s_sco2_des_par.m_LTR_od_UA_target_type = NS_HX_counterflow_eqs.E_UA_target_type(cm.as_integer("LTR_od_model"))
    s_sco2_des_par.m_HTR_od_UA_target_type = NS_HX_counterflow_eqs.E_UA_target_type(cm.as_integer("HTR_od_model"))
    s_sco2_des_par.m_design_method = cm.as_integer("design_method")
    if s_sco2_des_par.m_design_method == 1:
        s_sco2_des_par.m_LTR_target_code = 0
        s_sco2_des_par.m_HTR_target_code = 0
        s_sco2_des_par.m_eta_thermal = cm.as_double("eta_thermal_des")
        if s_sco2_des_par.m_eta_thermal < 0.0:
            cm.log("For cycle design method = 1, the input cycle thermal efficiency must be greater than 0", SSC_ERROR, -1.0)
            return -1
        s_sco2_des_par.m_UA_recup_tot_des = Float64.NaN
    elif s_sco2_des_par.m_design_method == 2:
        s_sco2_des_par.m_LTR_target_code = 0
        s_sco2_des_par.m_HTR_target_code = 0
        s_sco2_des_par.m_UA_recup_tot_des = cm.as_double("UA_recup_tot_des")
        if s_sco2_des_par.m_UA_recup_tot_des < 0.0:
            cm.log("For cycle design method = 2, the input total recuperator conductance must be greater than 0", SSC_ERROR, -1.0)
            return -1
        s_sco2_des_par.m_eta_thermal = Float64.NaN
    elif s_sco2_des_par.m_design_method == 3:
        s_sco2_des_par.m_LTR_target_code = cm.as_integer("LTR_design_code")
        s_sco2_des_par.m_LTR_UA = cm.as_double("LTR_UA_des_in")
        s_sco2_des_par.m_LTR_min_dT = cm.as_double("LTR_min_dT_des_in")
        s_sco2_des_par.m_LTR_eff_target = cm.as_double("LTR_eff_des_in")
        s_sco2_des_par.m_HTR_target_code = cm.as_integer("HTR_design_code")
        s_sco2_des_par.m_HTR_UA = cm.as_double("HTR_UA_des_in")
        s_sco2_des_par.m_HTR_min_dT = cm.as_double("HTR_min_dT_des_in")
        s_sco2_des_par.m_HTR_eff_target = cm.as_double("HTR_eff_des_in")
    else:
        var err_msg: String = util.format("The input cycle design method, %d, is invalid. It must be "
            " 1 = Specify efficiency, 2 = Specify total recup UA, 3 = Specify each recup design.", s_sco2_des_par.m_design_method)
        cm.log(err_msg, SSC_ERROR, -1.0)
    s_sco2_des_par.m_is_recomp_ok = cm.as_double("is_recomp_ok")
    s_sco2_des_par.m_P_high_limit = cm.as_double("P_high_limit") * 1000.0
    s_sco2_des_par.m_fixed_P_mc_out = cm.as_integer("is_P_high_fixed")
    var mc_PR_in: Float64 = cm.as_double("is_PR_fixed")
    if mc_PR_in != 0.0:
        if mc_PR_in < 0.0:
            s_sco2_des_par.m_PR_HP_to_LP_guess = s_sco2_des_par.m_P_high_limit / (-mc_PR_in * 1.0E3)
        else:
            s_sco2_des_par.m_PR_HP_to_LP_guess = mc_PR_in
        s_sco2_des_par.m_fixed_PR_HP_to_LP = True
    else:
        s_sco2_des_par.m_PR_HP_to_LP_guess = Float64.NaN
        s_sco2_des_par.m_fixed_PR_HP_to_LP = False
    var PR_HP_to_IP_in: Float64 = cm.as_double("is_IP_fixed")
    if PR_HP_to_IP_in != 0.0:
        if not s_sco2_des_par.m_fixed_PR_HP_to_LP:
            s_sco2_des_par.m_f_PR_HP_to_IP_guess = Float64.NaN
            s_sco2_des_par.m_fixed_f_PR_HP_to_IP = False
        else:
            s_sco2_des_par.m_fixed_f_PR_HP_to_IP = True
            var P_LP_in_local: Float64 = s_sco2_des_par.m_P_high_limit / s_sco2_des_par.m_PR_HP_to_LP_guess
            var P_IP_in_local: Float64 = fabs(PR_HP_to_IP_in) * 1.0E3
            if PR_HP_to_IP_in > 0.0:
                P_IP_in_local = s_sco2_des_par.m_P_high_limit / PR_HP_to_IP_in
            s_sco2_des_par.m_f_PR_HP_to_IP_guess = (s_sco2_des_par.m_P_high_limit - P_IP_in_local) / (s_sco2_des_par.m_P_high_limit - P_LP_in_local)
    else:
        s_sco2_des_par.m_f_PR_HP_to_IP_guess = Float64.NaN
        s_sco2_des_par.m_fixed_f_PR_HP_to_IP = False
    var DP_LT: List[Float64] = List[Float64](2)
    if cm.is_assigned("LTR_HP_deltaP_des_in"):
        DP_LT[0] = -cm.as_double("LTR_HP_deltaP_des_in")
    else:
        DP_LT[0] = -cm.as_double("deltaP_counterHX_frac")
    if cm.is_assigned("LTR_LP_deltaP_des_in"):
        DP_LT[1] = -cm.as_double("LTR_LP_deltaP_des_in")
    else:
        DP_LT[1] = -cm.as_double("deltaP_counterHX_frac")
    var DP_HT: List[Float64] = List[Float64](2)
    if cm.is_assigned("HTR_HP_deltaP_des_in"):
        DP_HT[0] = -cm.as_double("HTR_HP_deltaP_des_in")
    else:
        DP_HT[0] = -cm.as_double("deltaP_counterHX_frac")
    if cm.is_assigned("HTR_LP_deltaP_des_in"):
        DP_HT[1] = -cm.as_double("HTR_LP_deltaP_des_in")
    else:
        DP_HT[1] = -cm.as_double("deltaP_counterHX_frac")
    var DP_PHX: List[Float64] = List[Float64](2)
    DP_PHX[1] = 0
    if cm.is_assigned("PHX_co2_deltaP_des_in"):
        DP_PHX[0] = -cm.as_double("PHX_co2_deltaP_des_in")
    else:
        DP_PHX[0] = -cm.as_double("deltaP_counterHX_frac")
    var DP_PC: List[Float64] = List[Float64](2)
    DP_PC[0] = 0
    DP_PC[1] = -cm.as_double("deltaP_cooler_frac")
    s_sco2_des_par.m_DP_LT = DP_LT
    s_sco2_des_par.m_DP_HT = DP_HT
    s_sco2_des_par.m_DP_PC = DP_PC
    s_sco2_des_par.m_DP_PHX = DP_PHX
    s_sco2_des_par.m_N_turbine = 30000.0
    s_sco2_des_par.m_des_tol = pow(10, -cm.as_double("rel_tol"))
    s_sco2_des_par.m_des_opt_tol = pow(10, -cm.as_double("rel_tol"))
    s_sco2_des_par.m_LTR_N_sub_hxrs = cm.as_integer("LTR_n_sub_hx")
    s_sco2_des_par.m_LTR_eff_max = cm.as_double("LT_recup_eff_max")
    s_sco2_des_par.m_HTR_N_sub_hxrs = cm.as_integer("HTR_n_sub_hx")
    s_sco2_des_par.m_HTR_eff_max = cm.as_double("HT_recup_eff_max")
    s_sco2_des_par.m_eta_mc = cm.as_double("eta_isen_mc")
    var mc_comp_type: Int = cm.as_integer("mc_comp_type")
    if mc_comp_type == 2:
        raise exec_error("sco2_csp_system", "main compressor type 2 not available in this code base")
    else:
        s_sco2_des_par.m_mc_comp_type = C_comp__psi_eta_vs_phi.E_snl_radial_via_Dyreby
    s_sco2_des_par.m_eta_rc = cm.as_double("eta_isen_rc")
    if s_sco2_des_par.m_cycle_config == 2:
        s_sco2_des_par.m_eta_pc = cm.as_double("eta_isen_pc")
    else:
        s_sco2_des_par.m_eta_pc = s_sco2_des_par.m_eta_mc
    s_sco2_des_par.m_eta_t = cm.as_double("eta_isen_t")
    s_sco2_des_par.m_des_objective_type = cm.as_integer("des_objective")
    s_sco2_des_par.m_min_phx_deltaT = cm.as_double("min_phx_deltaT")
    s_sco2_des_par.m_phx_dt_cold_approach = cm.as_double("dT_PHX_cold_approach")
    s_sco2_des_par.m_phx_N_sub_hx = cm.as_integer("PHX_n_sub_hx")
    s_sco2_des_par.m_phx_od_UA_target_type = NS_HX_counterflow_eqs.E_UA_target_type(cm.as_integer("PHX_od_model"))
    s_sco2_des_par.m_is_des_air_cooler = cm.as_boolean("is_design_air_cooler")
    s_sco2_des_par.m_frac_fan_power = cm.as_double("fan_power_frac")
    s_sco2_des_par.m_deltaP_cooler_frac = cm.as_double("deltaP_cooler_frac")
    s_sco2_des_par.m_eta_fan = cm.as_double("eta_air_cooler_fan")
    s_sco2_des_par.m_N_nodes_pass = cm.as_integer("N_nodes_air_cooler_pass")
    var out_type: Int = -1
    var out_msg: String = ""
    c_sco2_cycle.mf_callback_update = ssc_cmod_update
    c_sco2_cycle.mp_mf_update = Pointer[Byte](address_of(cm))
    try:
        c_sco2_cycle.design(s_sco2_des_par)
    except C_csp_exception as csp_exception:
        while c_sco2_cycle.mc_messages.get_message(out_type, out_msg):
            cm.log(out_msg + "\n")
            cm.log("\n")
        raise exec_error("sco2_csp_system", csp_exception.m_error_message)
    while c_sco2_cycle.mc_messages.get_message(out_type, out_msg):
        cm.log(out_msg + "\n")
    var is_rc: Bool = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_is_rc
    var P_t: List[Float64] = List[Float64]()
    var h_t: List[Float64] = List[Float64]()
    var P_mc: List[Float64] = List[Float64]()
    var h_mc: List[Float64] = List[Float64]()
    var P_rc: List[Float64] = List[Float64]()
    var h_rc: List[Float64] = List[Float64]()
    var P_pc: List[Float64] = List[Float64]()
    var h_pc: List[Float64] = List[Float64]()
    var ph_err_code: Int = sco2_cycle_plot_data_PH(s_sco2_des_par.m_cycle_config,
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp,
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres,
        P_t,
        h_t,
        P_mc,
        h_mc,
        P_rc,
        h_rc,
        P_pc,
        h_pc)
    if ph_err_code != 0:
        raise exec_error("sco2_csp_system", "cycle plot data routine failed")
    var n_v: Int = len(P_t)
    var p_P_t_data: Pointer[ssc_number_t] = cm.allocate("P_t_data", n_v)
    var p_h_t_data: Pointer[ssc_number_t] = cm.allocate("h_t_data", n_v)
    for i in range(n_v):
        p_P_t_data[i] = ssc_number_t(P_t[i])
        p_h_t_data[i] = ssc_number_t(h_t[i])
    n_v = len(P_mc)
    var p_P_mc_data: Pointer[ssc_number_t] = cm.allocate("P_mc_data", n_v)
    var p_h_mc_data: Pointer[ssc_number_t] = cm.allocate("h_mc_data", n_v)
    for i in range(n_v):
        p_P_mc_data[i] = ssc_number_t(P_mc[i])
        p_h_mc_data[i] = ssc_number_t(h_mc[i])
    n_v = len(P_rc)
    var p_P_rc_data: Pointer[ssc_number_t] = cm.allocate("P_rc_data", n_v)
    var p_h_rc_data: Pointer[ssc_number_t] = cm.allocate("h_rc_data", n_v)
    for i in range(n_v):
        p_P_rc_data[i] = ssc_number_t(P_rc[i])
        p_h_rc_data[i] = ssc_number_t(h_rc[i])
    n_v = len(P_pc)
    var p_P_pc_data: Pointer[ssc_number_t] = cm.allocate("P_pc_data", n_v)
    var p_h_pc_data: Pointer[ssc_number_t] = cm.allocate("h_pc_data", n_v)
    for i in range(n_v):
        p_P_pc_data[i] = ssc_number_t(P_pc[i])
        p_h_pc_data[i] = ssc_number_t(h_pc[i])
    var T_LTR_HP: List[Float64] = List[Float64]()
    var s_LTR_HP: List[Float64] = List[Float64]()
    var T_HTR_HP: List[Float64] = List[Float64]()
    var s_HTR_HP: List[Float64] = List[Float64]()
    var T_PHX: List[Float64] = List[Float64]()
    var s_PHX: List[Float64] = List[Float64]()
    var T_HTR_LP: List[Float64] = List[Float64]()
    var s_HTR_LP: List[Float64] = List[Float64]()
    var T_LTR_LP: List[Float64] = List[Float64]()
    var s_LTR_LP: List[Float64] = List[Float64]()
    var T_main_cooler: List[Float64] = List[Float64]()
    var s_main_cooler: List[Float64] = List[Float64]()
    var T_pre_cooler: List[Float64] = List[Float64]()
    var s_pre_cooler: List[Float64] = List[Float64]()
    var plot_data_err_code: Int = sco2_cycle_plot_data_TS(s_sco2_des_par.m_cycle_config,
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres,
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_entr,
        T_LTR_HP,
        s_LTR_HP,
        T_HTR_HP,
        s_HTR_HP,
        T_PHX,
        s_PHX,
        T_HTR_LP,
        s_HTR_LP,
        T_LTR_LP,
        s_LTR_LP,
        T_main_cooler,
        s_main_cooler,
        T_pre_cooler,
        s_pre_cooler)
    if plot_data_err_code != 0:
        raise exec_error("sco2_csp_system", "cycle plot data routine failed")
    n_v = len(T_LTR_HP)
    var p_T_LTR_HP_data: Pointer[ssc_number_t] = cm.allocate("T_LTR_HP_data", n_v)
    var p_s_LTR_HP_data: Pointer[ssc_number_t] = cm.allocate("s_LTR_HP_data", n_v)
    for i in range(n_v):
        p_T_LTR_HP_data[i] = ssc_number_t(T_LTR_HP[i])
        p_s_LTR_HP_data[i] = ssc_number_t(s_LTR_HP[i])
    n_v = len(T_HTR_HP)
    var p_T_HTR_HP_data: Pointer[ssc_number_t] = cm.allocate("T_HTR_HP_data", n_v)
    var p_s_HTR_HP_data: Pointer[ssc_number_t] = cm.allocate("s_HTR_HP_data", n_v)
    for i in range(n_v):
        p_T_HTR_HP_data[i] = ssc_number_t(T_HTR_HP[i])
        p_s_HTR_HP_data[i] = ssc_number_t(s_HTR_HP[i])
    n_v = len(T_PHX)
    var p_T_PHX_data: Pointer[ssc_number_t] = cm.allocate("T_PHX_data", n_v)
    var p_s_PHX_data: Pointer[ssc_number_t] = cm.allocate("s_PHX_data", n_v)
    for i in range(n_v):
        p_T_PHX_data[i] = ssc_number_t(T_PHX[i])
        p_s_PHX_data[i] = ssc_number_t(s_PHX[i])
    n_v = len(T_HTR_LP)
    var p_T_HTR_LP_data: Pointer[ssc_number_t] = cm.allocate("T_HTR_LP_data", n_v)
    var p_s_HTR_LP_data: Pointer[ssc_number_t] = cm.allocate("s_HTR_LP_data", n_v)
    for i in range(n_v):
        p_T_HTR_LP_data[i] = ssc_number_t(T_HTR_LP[i])
        p_s_HTR_LP_data[i] = ssc_number_t(s_HTR_LP[i])
    n_v = len(T_LTR_LP)
    var p_T_LTR_LP_data: Pointer[ssc_number_t] = cm.allocate("T_LTR_LP_data", n_v)
    var p_s_LTR_LP_data: Pointer[ssc_number_t] = cm.allocate("s_LTR_LP_data", n_v)
    for i in range(n_v):
        p_T_LTR_LP_data[i] = ssc_number_t(T_LTR_LP[i])
        p_s_LTR_LP_data[i] = ssc_number_t(s_LTR_LP[i])
    n_v = len(T_main_cooler)
    var p_T_main_cooler: Pointer[ssc_number_t] = cm.allocate("T_main_cooler_data", n_v)
    var p_s_main_cooler: Pointer[ssc_number_t] = cm.allocate("s_main_cooler_data", n_v)
    for i in range(n_v):
        p_T_main_cooler[i] = ssc_number_t(T_main_cooler[i])
        p_s_main_cooler[i] = ssc_number_t(s_main_cooler[i])
    n_v = len(T_pre_cooler)
    var p_T_pre_cooler: Pointer[ssc_number_t] = cm.allocate("T_pre_cooler_data", n_v)
    var p_s_pre_cooler: Pointer[ssc_number_t] = cm.allocate("s_pre_cooler_data", n_v)
    for i in range(n_v):
        p_T_pre_cooler[i] = ssc_number_t(T_pre_cooler[i])
        p_s_pre_cooler[i] = ssc_number_t(s_pre_cooler[i])
    var cost_sum: Float64 = 0.0
    var comp_cost_sum: Float64 = 0.0
    var comp_power_sum: Float64 = 0.0
    var m_dot_htf_design: Float64 = c_sco2_cycle.get_phx_des_par().m_m_dot_hot_des
    var T_htf_cold_calc: Float64 = c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_T_h_out
    cm.assign("T_htf_cold_des", ssc_number_t(T_htf_cold_calc - 273.15))
    cm.assign("m_dot_htf_des", ssc_number_t(m_dot_htf_design))
    cm.assign("eta_thermal_calc", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_eta_thermal))
    cm.assign("m_dot_co2_full", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_m_dot_t))
    cm.assign("recomp_frac", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_recomp_frac))
    cm.assign("T_comp_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.MC_IN] - 273.15))
    cm.assign("P_comp_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.MC_IN] / 1000.0))
    cm.assign("P_comp_out", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.MC_OUT] / 1000.0))
    cm.assign("mc_T_out", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.MC_OUT] - 273.15))
    cm.assign("mc_W_dot", ssc_number_t(-c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_W_dot_mc * 1.0E-3))
    cm.assign("mc_rho_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_dens[C_sco2_cycle_core.MC_IN]))
    cm.assign("mc_ideal_spec_work", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_isen_spec_work))
    cm.assign("mc_m_dot_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_m_dot_t * (1.0 - c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_recomp_frac)))
    cm.assign("mc_phi_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_phi_des))
    cm.assign("mc_psi_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_psi_des))
    cm.assign("mc_tip_ratio_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_tip_ratio_max))
    var n_mc_stages: Int = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_n_stages
    cm.assign("mc_n_stages", ssc_number_t(n_mc_stages))
    cm.assign("mc_N_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_N_design))
    cm.assign("mc_psi_max_at_N_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_psi_max_at_N_des))
    var p_mc_D: Pointer[ssc_number_t] = cm.allocate("mc_D", n_mc_stages)
    var p_mc_tip_ratio_des: Pointer[ssc_number_t] = cm.allocate("mc_tip_ratio_des", n_mc_stages)
    var p_mc_eta_stages_des: Pointer[ssc_number_t] = cm.allocate("mc_eta_stages_des", n_mc_stages)
    var v_mc_D: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.mv_D
    var v_mc_tip_ratio_des: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.mv_tip_speed_ratio
    var v_mc_eta_stages_des: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.mv_eta_stages
    for i in range(n_mc_stages):
        p_mc_D[i] = ssc_number_t(v_mc_D[i])
        p_mc_tip_ratio_des[i] = ssc_number_t(v_mc_tip_ratio_des[i])
        p_mc_eta_stages_des[i] = ssc_number_t(v_mc_eta_stages_des[i])
    cm.assign("mc_phi_surge", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_phi_surge))
    cm.assign("mc_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_cost))
    cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_cost
    comp_cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_ms_des_solved.m_cost
    comp_power_sum += -c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_W_dot_mc * 1.0E-3
    cm.assign("rc_W_dot", ssc_number_t(-c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_W_dot_rc * 1.0E-3))
    cm.assign("rc_m_dot_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_m_dot_t * c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_recomp_frac))
    var n_rc_stages: Int = 0
    if is_rc:
        cm.assign("rc_T_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_T_in - 273.15))
        cm.assign("rc_P_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_P_in * 1.0E-3))
        cm.assign("rc_T_out_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_T_out - 273.15))
        cm.assign("rc_P_out_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_P_out * 1.0E-3))
        cm.assign("rc_phi_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_phi_des))
        cm.assign("rc_psi_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_psi_des))
        n_rc_stages = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_n_stages
        cm.assign("rc_n_stages", ssc_number_t(n_rc_stages))
        cm.assign("rc_N_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_N_design))
        cm.assign("rc_psi_max_at_N_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_psi_max_at_N_des))
        var p_rc_D: Pointer[ssc_number_t] = cm.allocate("rc_D", n_rc_stages)
        var p_rc_tip_ratio_des: Pointer[ssc_number_t] = cm.allocate("rc_tip_ratio_des", n_rc_stages)
        var p_rc_eta_stages_des: Pointer[ssc_number_t] = cm.allocate("rc_eta_stages_des", n_rc_stages)
        var v_rc_D: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.mv_D
        var v_rc_tip_ratio_des: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.mv_tip_speed_ratio
        var v_rc_eta_stages_des: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.mv_eta_stages
        for i in range(n_rc_stages):
            p_rc_D[i] = ssc_number_t(v_rc_D[i])
            p_rc_tip_ratio_des[i] = ssc_number_t(v_rc_tip_ratio_des[i])
            p_rc_eta_stages_des[i] = ssc_number_t(v_rc_eta_stages_des[i])
        cm.assign("rc_phi_surge", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_phi_surge))
        cm.assign("rc_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_cost))
        cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_cost
        comp_cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_rc_ms_des_solved.m_cost
        comp_power_sum += -c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_W_dot_rc * 1.0E-3
    else:
        var ssc_nan: ssc_number_t = Float64.NaN
        cm.assign("rc_T_in_des", ssc_nan)
        cm.assign("rc_P_in_des", ssc_nan)
        cm.assign("rc_T_out_des", ssc_nan)
        cm.assign("rc_P_out_des", ssc_nan)
        cm.assign("rc_phi_des", ssc_nan)
        cm.assign("rc_psi_des", ssc_nan)
        cm.assign("rc_n_stages", n_rc_stages)
        cm.assign("rc_N_des", ssc_nan)
        cm.assign("rc_psi_max_at_N_des", ssc_nan)
        var p_rc_D: Pointer[ssc_number_t] = cm.allocate("rc_D", 1)
        p_rc_D[0] = ssc_nan
        var p_rc_tip_ratio_des: Pointer[ssc_number_t] = cm.allocate("rc_tip_ratio_des", 1)
        p_rc_tip_ratio_des[0] = ssc_nan
        var p_rc_eta_stages_des: Pointer[ssc_number_t] = cm.allocate("rc_eta_stages_des", 1)
        p_rc_eta_stages_des[0] = ssc_nan
        cm.assign("rc_phi_surge", ssc_nan)
        cm.assign("rc_cost", ssc_nan)
    cm.assign("pc_W_dot", ssc_number_t(-c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_W_dot_pc * 1.0E-3))
    cm.assign("pc_m_dot_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_m_dot_pc))
    var n_pc_stages: Int = 0
    if s_sco2_des_par.m_cycle_config == 2:
        cm.assign("pc_T_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_T_in - 273.15))
        cm.assign("pc_P_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_P_in * 1.0E-3))
        cm.assign("pc_rho_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_dens[C_sco2_cycle_core.PC_IN]))
        cm.assign("pc_ideal_spec_work_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_isen_spec_work))
        cm.assign("pc_phi_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_phi_des))
        n_pc_stages = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_n_stages
        cm.assign("pc_n_stages", ssc_number_t(n_pc_stages))
        cm.assign("pc_N_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_N_design))
        var p_pc_D: Pointer[ssc_number_t] = cm.allocate("pc_D", n_pc_stages)
        var p_pc_tip_ratio_des: Pointer[ssc_number_t] = cm.allocate("pc_tip_ratio_des", n_pc_stages)
        var p_pc_eta_stages_des: Pointer[ssc_number_t] = cm.allocate("pc_eta_stages_des", n_pc_stages)
        var v_pc_D: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.mv_D
        var v_pc_tip_ratio_des: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.mv_tip_speed_ratio
        var v_pc_eta_stages_des: List[Float64] = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.mv_eta_stages
        for i in range(n_pc_stages):
            p_pc_D[i] = ssc_number_t(v_pc_D[i])
            p_pc_tip_ratio_des[i] = ssc_number_t(v_pc_tip_ratio_des[i])
            p_pc_eta_stages_des[i] = ssc_number_t(v_pc_eta_stages_des[i])
        cm.assign("pc_phi_surge", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_phi_surge))
        cm.assign("pc_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_cost))
        cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_cost
        comp_cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_ms_des_solved.m_cost
        comp_power_sum += -c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_W_dot_pc * 1.0E-3
    else:
        var ssc_nan2: ssc_number_t = Float64.NaN
        cm.assign("pc_T_in_des", ssc_nan2)
        cm.assign("pc_P_in_des", ssc_nan2)
        cm.assign("pc_rho_in_des", ssc_nan2)
        cm.assign("pc_ideal_spec_work_des", ssc_nan2)
        cm.assign("pc_phi_des", ssc_nan2)
        cm.assign("pc_n_stages", ssc_nan2)
        cm.assign("pc_N_des", ssc_nan2)
        var p_pc_D: Pointer[ssc_number_t] = cm.allocate("pc_D", 1)
        p_pc_D[0] = ssc_nan2
        var p_pc_tip_ratio_des: Pointer[ssc_number_t] = cm.allocate("pc_tip_ratio_des", 1)
        p_pc_tip_ratio_des[0] = ssc_nan2
        var p_pc_eta_stages_des: Pointer[ssc_number_t] = cm.allocate("pc_eta_stages_des", 1)
        p_pc_eta_stages_des[0] = ssc_nan2
        cm.assign("pc_phi_surge", ssc_nan2)
        cm.assign("pc_cost", ssc_nan2)
    cm.assign("c_tot_cost", comp_cost_sum)
    cm.assign("c_tot_W_dot", comp_power_sum)
    cm.assign("t_W_dot", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_W_dot_t * 1.0E-3))
    cm.assign("t_m_dot_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_m_dot_t))
    cm.assign("T_turb_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.TURB_IN] - 273.15))
    cm.assign("t_P_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.TURB_IN] * 1.0E-3))
    cm.assign("t_T_out_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.TURB_OUT] - 273.15))
    cm.assign("t_P_out_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.TURB_OUT] * 1.0E-3))
    cm.assign("t_delta_h_isen_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_delta_h_isen))
    cm.assign("t_rho_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_rho_in))
    cm.assign("t_nu_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_nu_design))
    cm.assign("t_tip_ratio_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_w_tip_ratio))
    cm.assign("t_N_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_N_design))
    cm.assign("t_D", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_D_rotor))
    cm.assign("t_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_cost))
    cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_t_des_solved.m_cost
    var recup_total_UA_assigned: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_UA_allocated * 1.0E-3
    var recup_total_UA_calculated: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_UA_calc_at_eff_max * 1.0E-3
    var recup_total_cost: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_cost
    cm.assign("LTR_HP_T_out_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.LTR_HP_OUT] - 273.15))
    cm.assign("LTR_UA_assigned", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_UA_allocated * 1.0E-3))
    cm.assign("LTR_UA_calculated", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_UA_calc_at_eff_max * 1.0E-3))
    cm.assign("eff_LTR", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_eff_design))
    cm.assign("NTU_LTR", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_NTU_design))
    cm.assign("q_dot_LTR", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_Q_dot_design * 1.0E-3))
    var LTR_LP_deltaP_frac: Float64 = 1.0 - c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.LTR_LP_OUT] / \
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.HTR_LP_OUT]
    cm.assign("LTR_LP_deltaP_des", ssc_number_t(LTR_LP_deltaP_frac))
    var LTR_HP_deltaP_frac: Float64 = 1.0 - c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.LTR_HP_OUT] / \
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.MC_OUT]
    cm.assign("LTR_HP_deltaP_des", ssc_number_t(LTR_HP_deltaP_frac))
    cm.assign("LTR_min_dT", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_min_DT_design))
    cm.assign("LTR_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_cost))
    cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_cost
    if is_rc:
        recup_total_UA_assigned += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_UA_allocated * 1.0E-3
        recup_total_UA_calculated += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_UA_calc_at_eff_max * 1.0E-3
        cm.assign("HTR_LP_T_out_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.HTR_LP_OUT] - 273.15))
        cm.assign("HTR_HP_T_in_des", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.MIXER_OUT] - 273.15))
        cm.assign("HTR_UA_assigned", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_UA_allocated * 1.0E-3))
        cm.assign("HTR_UA_calculated", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_UA_calc_at_eff_max * 1.0E-3))
        cm.assign("eff_HTR", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_eff_design))
        cm.assign("NTU_HTR", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_NTU_design))
        cm.assign("q_dot_HTR", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_Q_dot_design * 1.0E-3))
        cm.assign("HTR_min_dT", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_min_DT_design))
        cm.assign("HTR_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_cost))
        cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_cost
        recup_total_cost += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_HTR_des_solved.m_cost
        cm.assign("recup_LTR_UA_frac", ssc_number_t((c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_LTR_des_solved.m_UA_allocated * 1.0E-3) / recup_total_UA_assigned))
        var HTR_LP_deltaP_frac: Float64 = 1.0 - c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.HTR_LP_OUT] / \
            c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.TURB_OUT]
        cm.assign("HTR_LP_deltaP_des", ssc_number_t(HTR_LP_deltaP_frac))
        var HTR_HP_deltaP_frac: Float64 = 1.0 - c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.HTR_HP_OUT] / \
            c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.LTR_HP_OUT]
        cm.assign("HTR_HP_deltaP_des", ssc_number_t(HTR_HP_deltaP_frac))
    else:
        var ssc_nan3: ssc_number_t = Float64.NaN
        cm.assign("HTR_LP_T_out_des", ssc_nan3)
        cm.assign("HTR_HP_T_in_des", ssc_nan3)
        cm.assign("HTR_UA_assigned", ssc_nan3)
        cm.assign("HTR_UA_calculated", ssc_nan3)
        cm.assign("eff_HTR", ssc_nan3)
        cm.assign("NTU_HTR", ssc_nan3)
        cm.assign("q_dot_HTR", ssc_nan3)
        cm.assign("HTR_min_dT", ssc_nan3)
        cm.assign("HTR_cost", ssc_nan3)
        cm.assign("recup_LTR_UA_frac", ssc_nan3)
        cm.assign("HTR_LP_deltaP_des", ssc_nan3)
        cm.assign("HTR_HP_deltaP_des", ssc_nan3)
    cm.assign("recup_total_UA_assigned", ssc_number_t(recup_total_UA_assigned))
    cm.assign("recup_total_UA_calculated", ssc_number_t(recup_total_UA_calculated))
    cm.assign("recup_total_cost", ssc_number_t(recup_total_cost))
    cm.assign("UA_PHX", ssc_number_t(c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_UA_design * 1.0E-3))
    cm.assign("eff_PHX", ssc_number_t(c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_eff_design))
    cm.assign("NTU_PHX", ssc_number_t(c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_NTU_design))
    cm.assign("T_co2_PHX_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.HTR_HP_OUT] - 273.15))
    cm.assign("P_co2_PHX_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.HTR_HP_OUT] * 1.0E-3))
    cm.assign("deltaT_HTF_PHX", ssc_number_t(s_sco2_des_par.m_T_htf_hot_in - T_htf_cold_calc))
    cm.assign("q_dot_PHX", ssc_number_t(c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_Q_dot_design * 1.0E-3))
    var PHX_deltaP_frac: Float64 = 1.0 - c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.TURB_IN] / \
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.HTR_HP_OUT]
    cm.assign("PHX_co2_deltaP_des", ssc_number_t(PHX_deltaP_frac))
    cm.assign("PHX_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_cost))
    cost_sum += c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_cost
    cm.assign("mc_cooler_T_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_T_in_co2 - 273.15))
    cm.assign("mc_cooler_P_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_P_in_co2 / 1.0E3))
    cm.assign("mc_cooler_rho_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_dens[C_sco2_cycle_core.LTR_LP_OUT]))
    cm.assign("mc_cooler_m_dot_co2", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_m_dot_co2))
    cm.assign("mc_cooler_UA", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_UA_total * 1.0E-6))
    cm.assign("mc_cooler_q_dot", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_q_dot * 1.0E-6))
    var LP_cooler_deltaP_frac: Float64 = 1.0 - c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.MC_IN] / \
        c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.LTR_LP_OUT]
    cm.assign("mc_cooler_co2_deltaP_des", ssc_number_t(LP_cooler_deltaP_frac))
    cm.assign("mc_cooler_W_dot_fan", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_W_dot_fan))
    cm.assign("mc_cooler_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_cost))
    cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_cost
    var cooler_tot_cost: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_cost
    var cooler_tot_UA: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_UA_total * 1.0E-6
    var cooler_tot_W_dot_fan: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_mc_air_cooler.m_W_dot_fan
    if s_sco2_des_par.m_cycle_config == 2:
        cm.assign("pc_cooler_T_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_T_in_co2 - 273.15))
        cm.assign("pc_cooler_P_in", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_P_in_co2 / 1.0E3))
        cm.assign("pc_cooler_m_dot_co2", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_m_dot_co2))
        cm.assign("pc_cooler_UA", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_UA_total * 1.0E-6))
        cm.assign("pc_cooler_q_dot", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_q_dot * 1.0E-6))
        cm.assign("pc_cooler_W_dot_fan", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_W_dot_fan))
        cm.assign("pc_cooler_cost", ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_cost))
        cost_sum += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_cost
        cooler_tot_cost += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_cost
        cooler_tot_UA += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_UA_total * 1.0E-6
        cooler_tot_W_dot_fan += c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.ms_pc_air_cooler.m_W_dot_fan
    else:
        var ssc_nan4: ssc_number_t = Float64.NaN
        cm.assign("pc_cooler_T_in", ssc_nan4)
        cm.assign("pc_cooler_P_in", ssc_nan4)
        cm.assign("pc_cooler_m_dot_co2", ssc_nan4)
        cm.assign("pc_cooler_UA", ssc_nan4)
        cm.assign("pc_cooler_q_dot", ssc_nan4)
        cm.assign("pc_cooler_W_dot_fan", ssc_nan4)
        cm.assign("pc_cooler_cost", ssc_nan4)
    cm.assign("cooler_tot_cost", ssc_number_t(cooler_tot_cost))
    cm.assign("cooler_tot_UA", ssc_number_t(cooler_tot_UA))
    cm.assign("cooler_tot_W_dot_fan", ssc_number_t(cooler_tot_W_dot_fan))
    cm.assign("cycle_cost", ssc_number_t(cost_sum))
    cm.assign("cycle_spec_cost", ssc_number_t(cost_sum * 1.0E6 / s_sco2_des_par.m_W_dot_net))
    cm.assign("cycle_spec_cost_thermal", ssc_number_t(cost_sum * 1.0E6 / (s_sco2_des_par.m_W_dot_net / c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_eta_thermal)))
    var W_dot_net_less_cooling: Float64 = (1.0 - s_sco2_des_par.m_frac_fan_power) * s_sco2_des_par.m_W_dot_net * 1.0E-3
    cm.assign("W_dot_net_less_cooling", ssc_number_t(W_dot_net_less_cooling))
    cm.assign("eta_thermal_net_less_cooling_des", ssc_number_t(W_dot_net_less_cooling / (c_sco2_cycle.get_design_solved().ms_phx_des_solved.m_Q_dot_design * 1.0E-3)))
    var p_T_state_points: Pointer[ssc_number_t] = cm.allocate("T_state_points", C_sco2_cycle_core.END_SCO2_STATES)
    var p_P_state_points: Pointer[ssc_number_t] = cm.allocate("P_state_points", C_sco2_cycle_core.END_SCO2_STATES)
    var p_s_state_points: Pointer[ssc_number_t] = cm.allocate("s_state_points", C_sco2_cycle_core.END_SCO2_STATES)
    var p_h_state_points: Pointer[ssc_number_t] = cm.allocate("h_state_points", C_sco2_cycle_core.END_SCO2_STATES)
    for i in range(C_sco2_cycle_core.END_SCO2_STATES):
        p_T_state_points[i] = ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[i] - 273.15)
        p_P_state_points[i] = ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[i] / 1.0E3)
        p_s_state_points[i] = ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_entr[i])
        p_h_state_points[i] = ssc_number_t(c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_enth[i])
    var T_cooler_in: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_temp[C_sco2_cycle_core.LTR_LP_OUT]
    var P_cooler_in: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.LTR_LP_OUT]
    var P_cooler_out: Float64 = c_sco2_cycle.get_design_solved().ms_rc_cycle_solved.m_pres[C_sco2_cycle_core.MC_OUT]
    var isen_enth_check_err: Int = 0
    var h_cooler_in: Float64 = Float64.NaN
    var s_cooler_in: Float64 = Float64.NaN
    var rho_cooler_in: Float64 = Float64.NaN
    var T_isen_out: Float64 = Float64.NaN
    var h_isen_out: Float64 = Float64.NaN
    var s_isen_out: Float64 = Float64.NaN
    var rho_isen_out: Float64 = Float64.NaN
    var deltah_isen: Float64 = Float64.NaN
    calculate_turbomachinery_outlet_1(T_cooler_in, P_cooler_in, P_cooler_out, 1.0, True, isen_enth_check_err,
        h_cooler_in, s_cooler_in, rho_cooler_in, T_isen_out,
        h_isen_out, s_isen_out, rho_isen_out, deltah_isen)
    cm.assign("mc_cooler_in_isen_deltah_to_P_mc_out", ssc_number_t(-deltah_isen))
    return 0