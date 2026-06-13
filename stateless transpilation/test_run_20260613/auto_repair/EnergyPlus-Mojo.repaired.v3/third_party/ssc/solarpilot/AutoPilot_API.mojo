// Auto-generated 1:1 translation from C++.

from API_structures import sp_layout, sp_flux_table, sp_flux_map, sp_optical_table, sp_optimize, sim_result, simulation_info, var_map
from definitions import SolarField, Hvector, Receiver, Vect, Ambient, DateTime, sim_params, sim_results, block_t, matrix_t, FluxSurface, FluxGrid, FluxPoint, spexception, my_to_string, D2R
from IOUtil import interop
from LayoutSimulateThread import LayoutSimThread
from SolarField import SolarField
from mod_base import sp_optimize  # or defined?

import nlopt  # Assuming Mojo bindings for nlopt

@value
struct _aof_inst:
    var obj: Float64
    var flux: Float64
    def __init__(inout self, o: Float64, f: Float64):
        self.obj = o
        self.flux = f
    def __init__(inout self):

@value
struct AutoOptHelper:
    var m_iter: Int
    var m_autopilot: AutoPilot
    var m_all_points: List[List[Float64]]
    var m_objective: List[Float64]
    var m_flux: List[Float64]
    var m_opt_vars: List[Pointer[Float64]]
    var m_opt_names: List[String]
    var m_opt_obj: nlopt.opt
    var m_variables: var_map

    @value
    struct HistoryMap:
        var items: Dict[String, _aof_inst]
        def format(self, vars: List[Float64]) -> String:
            var buf = String()
            for i in range(len(vars)):
                buf += String.setw(8) + str(vars[i]) + ","
            return buf
        def add_call(inout self, vars: List[Float64], objective: Float64, flux: Float64):
            self.items[self.format(vars)] = _aof_inst(objective, flux)
        def check_call(self, vars: List[Float64], obj: Pointer[Float64], flux: Pointer[Float64]) -> Bool:
            let hash = self.format(vars)
            if self.items.find(hash) == None:
                return False
            let inst = self.items[hash]
            obj.store(inst.obj)
            flux.store(inst.flux)
            return True
        def size(self) -> Int:
            return len(self.items)

    var m_history_map = HistoryMap()

    def SetObjects(inout self, autopilot: AnyPointer, V: var_map, optobj: Pointer[nlopt.opt]):
        self.m_autopilot = autopilot[].as_ptr()
        self.m_variables = V
        self.m_opt_obj = optobj[].load()

    def Initialize(inout self):
        self.m_iter = 0
        self.m_autopilot = AutoPilot()
        self.m_opt_obj = nlopt.opt()
        self.m_all_points = List[List[Float64]]()
        self.m_objective = List[Float64]()
        self.m_flux = List[Float64]()
        self.m_opt_vars = List[Pointer[Float64]]()
        self.m_opt_names = List[String]()

    def Simulate(self, x: Pointer[Float64], n: Int, note: String = "") -> Float64:
        if self.m_autopilot.IsSimulationCancelled():
            self.m_opt_obj.force_stop()
            return 0.0
        self.m_iter += 1
        var current = List[Float64]()
        for i in range(len(self.m_opt_vars)):
            current.append(x.load(i))
            self.m_opt_vars[i].store(current[i])
        self.m_all_points.append(current)
        var obj: Float64
        var flux: Float64
        var cost: Float64
        if not self.m_autopilot.EvaluateDesign(obj, flux, cost):
            let errmsg = "Optimization failed at iteration " + my_to_string(self.m_iter) + ". Terminating simulation."
            throw spexception(errmsg)
        self.m_autopilot.PostEvaluationUpdate(self.m_iter, current, obj, flux, cost, note)
        self.m_objective.append(obj)
        self.m_flux.append(flux)
        self.m_history_map.add_call(current, obj, flux)
        return obj

def optimize_leastsq_eval(n: Int, x: Pointer[Float64], grad: Pointer[Float64], data: AnyPointer) -> Float64:
    let D = data[].as_ptr(response_surface_data)
    D.ncalls += 1
    if len(D.Beta) != n:
        D.Beta = List[Float64](n, 1.0)
    for i in range(n):
        D.Beta[i] = x.load(i)
    var ssres = 0.0
    for i in range(len(D.X)):
        let y = D.EvaluateBiLinearResponse(D.X[i])
        let ssrv = y - D.Y[i]
        ssres += ssrv * ssrv
    return ssres

def optimize_stdesc_eval(n: Int, x: Pointer[Float64], grad: Pointer[Float64], data: AnyPointer) -> Float64:
    let D = data[].as_ptr(response_surface_data)
    D.ncalls += 1
    var xpt = List[Float64]()
    for i in range(n):
        xpt.append(x.load(i))
    return D.EvaluateBiLinearResponse(xpt)

def optimize_maxstep_eval(n: Int, x: Pointer[Float64], grad: Pointer[Float64], data: AnyPointer) -> Float64:
    let D = data[].as_ptr(response_surface_data)
    var xpt = List[Float64]()
    var ssize = 0.0
    for i in range(n):
        xpt.append(x.load(i))
        let xistep = x.load(i) - D.cur_pos[i]
        ssize += xistep * xistep
    ssize = sqrt(ssize)
    return ssize - D.max_step_size

def optimize_auto_eval(n: Int, x: Pointer[Float64], grad: Pointer[Float64], data: AnyPointer) -> Float64:
    let D = data[].as_ptr(AutoOptHelper)
    return D.Simulate(x, n)

def constraint_auto_eval(n: Int, x: Pointer[Float64], grad: Pointer[Float64], data: AnyPointer) -> Float64:
    let D = data[].as_ptr(AutoOptHelper)
    var vars = List[Float64]()
    for i in range(n):
        vars.append(x.load(i))
    var obj: Float64
    var flux: Float64
    if D.m_history_map.check_call(vars, obj, flux):
        return flux - D.m_variables.recs.front().peak_flux.val
    else:
        let comment = " >> Checking flux constraint"
        D.Simulate(x, n, comment)
        return D.m_flux.back() - D.m_variables.recs.front().peak_flux.val

class AutoPilot:
    protected var _summary_callback: (simulation_info, AnyPointer) -> Bool
    protected var _summary_callback_data: AnyPointer
    protected var _detail_callback: (simulation_info, AnyPointer) -> Bool
    protected var _detail_callback_data: AnyPointer
    protected var _SF: SolarField
    protected var _sim_total: Int
    protected var _sim_complete: Int
    protected var _cancel_simulation: Bool
    protected var _has_summary_callback: Bool
    protected var _has_detail_callback: Bool
    protected var _is_solarfield_external: Bool
    protected var _setup_ok: Bool
    protected var _simflag: Bool
    protected var _opt: sp_optimize
    protected var _summary_siminfo: simulation_info
    protected var _detail_siminfo: simulation_info

    def interpolate_vectors(inout self, A: List[Float64], B: List[Float64], alpha: Float64) -> List[Float64]:
        if len(A) != len(B):
            throw spexception("Error (interpolate_vectors): vectors must have the same dimension.")
        var V = List[Float64]()
        for i in range(len(A)):
            V.append(A[i] + (B[i] - A[i]) * alpha)
        return V

    def PrepareFluxSimulation(inout self, fluxtab: sp_flux_table, flux_res_x: Int, flux_res_y: Int, is_normalized: Bool):
        var V = self._SF.getVarMap()
        V.amb.sim_time_step.Setval(0.0)
        let rec_to_sim = *self._SF.getReceivers()
        if flux_res_y > 1:
            V.flux.aim_method.combo_select_by_mapval(var_fluxsim.AIM_METHOD.IMAGE_SIZE_PRIORITY)
        for i in range(len(rec_to_sim)):
            rec_to_sim[i].DefineReceiverGeometry(flux_res_x, flux_res_y)
        var nflux_sim: Int
        if len(fluxtab.azimuths) == 0:
            var uday = List[Int]()
            var utime = List[List[Float64]]()
            if not fluxtab.is_user_spacing:
                fluxtab.n_flux_days = 8
                fluxtab.delta_flux_hrs = 1.0
            Ambient.calcSpacedDaysHours(V.amb.latitude.val, V.amb.longitude.val, V.amb.time_zone.val, fluxtab.n_flux_days, fluxtab.delta_flux_hrs, utime, uday)
            nflux_sim = 0
            for i in range(len(utime)):
                nflux_sim += len(utime[i])
            fluxtab.azimuths.clear()
            fluxtab.zeniths.clear()
            var DT = DateTime()
            let nday = len(uday)
            for i in range(nday):
                let nhour_day = len(utime[i])
                for j in range(nhour_day):
                    Ambient.setDateTime(DT, utime[i][j] + 12, uday[i])
                    var az: Float64
                    var zen: Float64
                    Ambient.calcSunPosition(*V, DT, az, zen)
                    fluxtab.azimuths.append(az * D2R)
                    fluxtab.zeniths.append(zen * D2R)
        else:
            nflux_sim = len(fluxtab.azimuths)
        fluxtab.flux_surfaces.clear()
        var nsurftot = 0
        for i in range(len(self._SF.getReceivers())):
            for j in range(len(self._SF.getReceivers()[i].getFluxSurfaces())):
                nsurftot += 1
        fluxtab.flux_surfaces.resize(nsurftot)
        for i in range(nsurftot):
            fluxtab.flux_surfaces[i].flux_data.resize(flux_res_y, flux_res_x, nflux_sim)

    def PostProcessLayout(inout self, layout: sp_layout):
        let hpos = self._SF.getHeliostats()
        layout.heliostat_positions.clear()
        for i in range(len(hpos)):
            var hp = sp_layout.h_position()
            hp.location.x = hpos[i].getLocation().x
            hp.location.y = hpos[i].getLocation().y
            hp.location.z = hpos[i].getLocation().z
            hp.cant_vector.i = hpos[i].getCantVector().i
            hp.cant_vector.j = hpos[i].getCantVector().j
            hp.cant_vector.k = hpos[i].getCantVector().k
            hp.aimpoint.x = hpos[i].getAimPoint().x
            hp.aimpoint.y = hpos[i].getAimPoint().y
            hp.aimpoint.z = hpos[i].getAimPoint().z
            hp.focal_length = hpos[i].getFocalX()
            hp.template_number = -1
            layout.heliostat_positions.append(hp)
        var V = self._SF.getVarMap()
        self._SF.updateAllCalculatedParameters(*V)

    def PostProcessFlux(inout self, result: sim_result, fluxmap: sp_flux_map, flux_layer: Int = 0):
        if not self._cancel_simulation:
            var itot = 0
            let Recs = self._SF.getReceivers()
            let nrec = len(Recs)
            for irec in range(nrec):
                let rec = Recs[irec]
                let nrecsurf = len(rec.getFluxSurfaces())
                for isurf in range(nrecsurf):
                    fluxmap.flux_surfaces[itot].map_name = rec.getVarMap().rec_name.val + " surface " + my_to_string(isurf + 1)
                    let fs = result.flux_surfaces[irec][isurf]
                    let nflux_x = fs.getFluxNX()
                    let nflux_y = fs.getFluxNY()
                    let fmap = result.flux_surfaces[irec][isurf].getFluxMap()
                    for fluxi in range(nflux_y):
                        for fluxj in range(nflux_x):
                            var fstack = fluxmap.flux_surfaces[itot]
                            let fpt = fmap[fluxj][nflux_y - fluxi - 1]
                            fstack.flux_data.at(fluxi, fluxj, flux_layer) = fpt.flux
                            fstack.xpos.append(fpt.location.x)
                            fstack.ypos.append(fpt.location.y)
                    itot += 1

    def CalculateFluxMapsOV1(inout self, sunpos: List[List[Float64]], fluxtab: List[List[Float64]], efficiency: List[Float64], flux_res_x: Int = 12, flux_res_y: Int = 10, is_normalized: Bool = True) -> Bool:
        var fluxtab_s = sp_flux_table()
        if not self.CalculateFluxMaps(fluxtab_s, flux_res_x, flux_res_y, is_normalized):
            return False
        let flux_data = fluxtab_s.flux_surfaces.front().flux_data
        fluxtab.clear()
        efficiency.clear()
        for i in range(flux_data.nlayers()):
            sunpos.append(List[Float64]([fluxtab_s.azimuths[i], fluxtab_s.zeniths[i]]))
            efficiency.append(fluxtab_s.efficiency[i])
            for j in range(flux_res_y):
                var newline = List[Float64]()
                for k in range(flux_res_x):
                    newline.append(flux_data.at(j, k, i))
                fluxtab.append(newline)
        return True

    def __init__(inout self):
        self._has_summary_callback = False
        self._has_detail_callback = False
        self._is_solarfield_external = False
        self._SF = SolarField()
        self._summary_callback = None
        self._detail_callback = None
        self._summary_callback_data = None
        self._detail_callback_data = None
        self._summary_siminfo = simulation_info()
        self._detail_siminfo = simulation_info()
        self._opt = sp_optimize()

    def __del__(inout self):
        if self._SF != None:
            try:
                delete self._SF
            except:

        if self._summary_siminfo != None:
            try:
                delete self._summary_siminfo
            except:

        if self._opt != None:
            delete self._opt

    def SetSummaryCallback(inout self, callback: (simulation_info, AnyPointer) -> Bool, cdata: AnyPointer):
        self._has_summary_callback = True
        self._summary_callback = callback
        self._summary_callback_data = cdata

    def SetDetailCallback(inout self, callback: (simulation_info, AnyPointer) -> Bool, cdata: AnyPointer):
        self._has_detail_callback = True
        self._detail_callback = callback
        self._detail_callback_data = cdata

    def SetSummaryCallbackStatus(inout self, is_enabled: Bool):
        self._has_summary_callback = is_enabled

    def SetDetailCallbackStatus(inout self, is_enabled: Bool):
        self._has_detail_callback = is_enabled
        if self._SF != None:
            self._SF.getSimInfoObject().isEnabled(is_enabled)

    def SetExternalSFObject(inout self, SF: SolarField):
        self._SF = SF
        self._is_solarfield_external = True

    def Setup(inout self, V: var_map, for_optimize: Bool = False) -> Bool:
        self._cancel_simulation = False
        if not self._is_solarfield_external:
            self._SF = SolarField()
        self._SF.Create(V)
        if not V.sf.layout_data.val.empty():
            self._SF.PrepareFieldLayout(*self._SF, 0, True)
            let sun = Ambient.calcSunVectorFromAzZen(self._SF.getVarMap().sf.sun_az_des.Val() * D2R, (90.0 - self._SF.getVarMap().sf.sun_el_des.Val()) * D2R)
            self._SF.calcHeliostatShadows(sun)
            let area = V.land.land_area.Val()
            V.land.bound_area.Setval(area)
            V.land.land_area.Setval(area)
        self.PreSimCallbackUpdate()
        self._setup_ok = True
        return True

    def GenerateDesignPointSimulations(inout self, V: var_map, wdata: List[String]):
        interop.GenerateSimulationWeatherData(V, -1, wdata)

    def PreSimCallbackUpdate(inout self):
        if self._has_detail_callback:
            self._detail_siminfo = self._SF.getSimInfoObject()
            self._SF.getSimInfoObject().setCallbackFunction(self._detail_callback, self._detail_callback_data)
            self._SF.getSimInfoObject().isEnabled(True)
        if self._has_summary_callback:
            if self._summary_siminfo == None:
                self._summary_siminfo = simulation_info()
            self._summary_siminfo.ResetValues()
            self._summary_siminfo.setCallbackFunction(self._summary_callback, self._summary_callback_data)

    def PostProcessLayout(inout self, layout: sp_layout):
        let hpos = self._SF.getHeliostats()
        layout.heliostat_positions.clear()
        for i in range(len(hpos)):
            var hp = sp_layout.h_position()
            hp.location.x = hpos[i].getLocation().x
            hp.location.y = hpos[i].getLocation().y
            hp.location.z = hpos[i].getLocation().z
            hp.cant_vector.i = hpos[i].getCantVector().i
            hp.cant_vector.j = hpos[i].getCantVector().j
            hp.cant_vector.k = hpos[i].getCantVector().k
            hp.aimpoint.x = hpos[i].getAimPoint().x
            hp.aimpoint.y = hpos[i].getAimPoint().y
            hp.aimpoint.z = hpos[i].getAimPoint().z
            hp.focal_length = hpos[i].getFocalX()
            hp.template_number = -1
            layout.heliostat_positions.append(hp)
        var V = self._SF.getVarMap()
        self._SF.updateAllCalculatedParameters(*V)

    def PrepareFluxSimulation(inout self, fluxtab: sp_flux_table, flux_res_x: Int, flux_res_y: Int, is_normalized: Bool):
        # Same as above; already defined

    def PostProcessFlux(inout self, result: sim_result, fluxmap: sp_flux_map, flux_layer: Int = 0):
        # Same as above; already defined

    def CancelSimulation(inout self):
        self._cancel_simulation = True
        self._SF.CancelSimulation()

    def EvaluateDesign(inout self, obj_metric: Pointer[Float64], flux_max: Pointer[Float64], tot_cost: Pointer[Float64]) -> Bool:
        var V = self._SF.getVarMap()
        if not self._cancel_simulation:
            self._SF.Create(*V)
            if self._SF.ErrCheck(): return False
        if not self._cancel_simulation:
            var layout = sp_layout()
            if not self.CreateLayout(layout, False):
                self.CancelSimulation()
                obj_metric.store(0.0)
                flux_max.store(0.0)
                return False
            if self._SF.ErrCheck(): return False
        if not self._cancel_simulation:
            self._SF.getVarMap().flux.flux_time_type.combo_select_by_mapval(var_fluxsim.FLUX_TIME_TYPE.SUN_POSITION)
            interop.PerformanceSimulationPrep(*self._SF, *self._SF.getHeliostats(), 0)
            self._SF.HermiteFluxSimulation(*self._SF.getHeliostats(), V.flux.aim_method.mapval() == var_fluxsim.AIM_METHOD.IMAGE_SIZE_PRIORITY)
            if self._SF.ErrCheck(): return False
        let optical_power = self._SF.getAnnualPowerApproximation()
        tot_cost.store(V.fin.total_installed_cost.Val())
        var flux_max_tmp = 0.0
        for i in range(len(self._SF.getReceivers())):
            for j in range(len(self._SF.getReceivers()[i].getFluxSurfaces())):
                let ff = self._SF.getReceivers()[i].getFluxSurfaces()[j].getMaxObservedFlux()
                if ff > flux_max_tmp:
                    flux_max_tmp = ff
        flux_max.store(flux_max_tmp)
        let qminimum = self._SF.getDesignThermalPowerWithLoss()
        let qactual = self._SF.getActualThermalPowerWithLoss()
        let power_shortage_ratio = min(qactual / qminimum, 1.0)
        obj_metric.store(tot_cost.load() / optical_power * 1.0e6 * (1.0 + (1.0 - power_shortage_ratio) * V.opt.power_penalty.val))
        return True

    def Optimize(inout self, method: Int, optvars: List[Pointer[Float64]], upper_range: List[Float64], lower_range: List[Float64], stepsize: List[Float64], names: List[String] = None) -> Bool:
        return self.OptimizeAuto(optvars, upper_range, lower_range, stepsize, names)

    def OptimizeRSGS(inout self, optvars: List[Pointer[Float64]], upper_range: List[Float64], lower_range: List[Float64], is_range_constr: List[Bool], names: List[String] = None) -> Bool:
        let nvars = len(optvars)
        var current = List[Float64](nvars, 1.0)
        var converged = False
        var opt_iter = 0
        var sim_count = 0
        var all_sim_points = List[List[Float64]]()
        var objective = List[Float64]()
        var max_flux = List[Float64]()
        var tot_costs = List[Float64]()
        var objective_old = 9.0e22
        var objective_new = 9.0e21
        var sim_count_begin = 0
        let converge_tol = self._SF.getVarMap().opt.converge_tol.val
        let max_step = self._SF.getVarMap().opt.max_step.val
        var os = String()
        os += "\n\nBeginning Simulation\nIter "
        for i in range(len(optvars)):
            os += String.setw(9) + (names == None ? "Var " + my_to_string(i + 1) : names[i]) + "|"
        os += "| Obj.    | Flux    | Plant cost"
        self._summary_siminfo.addSimulationNotice(os)
        while not converged:
            sim_count_begin = len(objective) - 1
            if opt_iter > 0:
                var zbest = 9.0e23
                var ibest = sim_count_begin
                for i in range(sim_count_begin, len(objective)):
                    if objective[i] < zbest:
                        zbest = objective[i]
                        ibest = i
                current = all_sim_points[ibest]
            self._summary_siminfo.addSimulationNotice("--- Iteration " + my_to_string(opt_iter + 1) + " ---\n...Simulating base point")
            for i in range(len(optvars)):
                optvars[i].store(current[i])
            all_sim_points.append(current)
            var base_obj: Float64
            var base_flux: Float64
            var cost: Float64
            self.EvaluateDesign(base_obj, base_flux, cost)
            self.PostEvaluationUpdate(sim_count, current, base_obj, base_flux, cost)
            if self._cancel_simulation: return False
            objective.append(base_obj)
            max_flux.append(base_flux)
            tot_costs.append(cost)
            var surface_objective = List[Float64]()
            var surface_eval_points = List[List[Float64]]()
            surface_objective.append(base_obj)
            surface_eval_points.append(current)
            objective_new = base_obj
            if (objective_old - objective_new) / objective_old < converge_tol:
                converged = True
                var zbest = 9.0e23
                var ibest = len(objective) - 1
                for i in range(len(objective)):
                    if objective[i] < zbest:
                        zbest = objective[i]
                        ibest = i
                for i in range(len(optvars)):
                    optvars[i].store(all_sim_points[ibest][i])
                break
            objective_old = objective_new
            var Reg = response_surface_data()
            var runs = List[List[Float64]]()
            Reg.GenerateSurfaceEvalPoints(current, runs, max_step)
            self._summary_siminfo.setTotalSimulationCount(len(runs))
            if not self._summary_siminfo.addSimulationNotice("...Creating local response surface"):
                self.CancelSimulation()
                return False
            for i in range(len(runs)):
                if not self._summary_siminfo.setCurrentSimulation(i):
                    self.CancelSimulation()
                    return False
                for j in range(len(optvars)):
                    optvars[j].store(runs[i][j])
                var obj: Float64
                var flux: Float64
                var cost: Float64
                all_sim_points.append(runs[i])
                self.EvaluateDesign(obj, flux, cost)
                self.PostEvaluationUpdate(sim_count, runs[i], obj, flux, cost)
                if self._cancel_simulation: return False
                surface_objective.append(obj)
                surface_eval_points.append(runs[i])
                objective.append(obj)
                max_flux.append(flux)
                tot_costs.append(cost)
            self._summary_siminfo.addSimulationNotice("...Generating regression fit")
            Reg.N_vars = nvars
            Reg.Y = surface_objective
            Reg.X = surface_eval_points
            let nbeta = Reg.CalcNumberBetas()
            Reg.Beta = List[Float64](nbeta, 1.0)
            var yave = 0.0
            for i in range(len(Reg.Y)):
                yave += Reg.Y[i]
            yave *= 1.0 / len(Reg.Y)
            Reg.Beta.front() = yave
            var surf = nlopt.opt(nlopt.LN_NELDERMEAD, nbeta)
            surf.set_min_objective(optimize_leastsq_eval, Reg)
            surf.set_xtol_rel(1.0e-7)
            surf.set_ftol_rel(1.0e-7)
            surf.set_maxtime(5.0)
            var min_ss: Float64
            try:
                surf.optimize(Reg.Beta, min_ss)
            except e as Exception:
                self._summary_siminfo.addSimulationNotice(str(e))
                return False
            var sstot = 0.0
            for i in range(len(Reg.Y)):
                let ssval = Reg.Y[i] - Reg.Beta.front()
                sstot += ssval * ssval
            self._summary_siminfo.addSimulationNotice("... r^2 = " + my_to_string(1.0 - min_ss / sstot))
            Reg.ncalls = 0
            Reg.max_step_size = max_step
            var steep = nlopt.opt(nlopt.GN_ESCH, nvars)
            steep.set_min_objective(optimize_stdesc_eval, Reg)
            steep.set_maxtime(2.0)
            var range_max = List[Float64]()
            var range_min = List[Float64]()
            for i in range(nvars):
                range_max.append(fmin(upper_range[i], current[i] + max_step))
                range_min.append(fmax(lower_range[i], current[i] - max_step))
            steep.set_upper_bounds(range_max)
            steep.set_lower_bounds(range_min)
            steep.set_xtol_rel(1.0e-4)
            steep.set_ftol_rel(1.0e-5)
            Reg.cur_pos = current
            var stepto = current.copy()
            var min_val: Float64
            try:
                steep.optimize(stepto, min_val)
            except e as Exception:
                self._summary_siminfo.addSimulationNotice(str(e))
                return False
            var step_vector = stepto.copy()
            for i in range(len(step_vector)):
                step_vector[i] += -current[i]
            var best_fact_obj = 9.0e9
            var i_best_fact = 0
            for i in range(len(surface_objective)):
                if surface_objective[i] < best_fact_obj:
                    best_fact_obj = surface_objective[i]
                    i_best_fact = i
            self._summary_siminfo.addSimulationNotice("...Best regression objective value = " + my_to_string(min_val))
            if best_fact_obj < min_val:
                self._summary_siminfo.addSimulationNotice("...Correcting step direction to use best response surface point.")
                step_vector = List[Float64](len(stepto))
                for i in range(len(current)):
                    step_vector[i] = surface_eval_points[i_best_fact][i] - current[i]
                var step_size = 0.0
                for i in range(len(step_vector)):
                    step_size += step_vector[i] * step_vector[i]
                step_size = sqrt(step_size)
                for i in range(len(step_vector)):
                    step_vector[i] *= Reg.max_step_size / step_size
                min_val = best_fact_obj
            let checktol = (base_obj - min_val) / base_obj
            if fabs(checktol) < converge_tol:
                self._summary_siminfo.addSimulationNotice("\nConvergence in the objective function value has been achieved. Final step variation: " + my_to_string(checktol))
                converged = True
                break
            self._summary_siminfo.ResetValues()
            var minmax_iter = 0
            var steep_converged = False
            var prev_obj = base_obj
            let max_desc_iter = self._SF.getVarMap().opt.max_desc_iter.val
            self._summary_siminfo.setTotalSimulationCount(max_desc_iter)
            self._summary_siminfo.addSimulationNotice("...Moving along steepest descent")
            var start_point = current.copy()
            var all_steep_objs = List[Float64]()
            var tried_steep_mod = False
            while True:
                if not self._summary_siminfo.setCurrentSimulation(minmax_iter):
                    self.CancelSimulation()
                    return False
                for i in range(len(optvars)):
                    current[i] += step_vector[i]
                    optvars[i].store(current[i])
                var obj: Float64
                var flux: Float64
                var cost: Float64
                all_sim_points.append(current)
                self.EvaluateDesign(obj, flux, cost)
                self.PostEvaluationUpdate(sim_count, current, obj, flux, cost)
                if self._cancel_simulation: return False
                if minmax_iter > 0:
                    prev_obj = objective.back()
                objective.append(obj)
                all_steep_objs.append(obj)
                max_flux.append(flux)
                tot_costs.append(cost)
                minmax_iter += 1
                if minmax_iter >= max_desc_iter:
                    break
                if obj > prev_obj:
                    if not tried_steep_mod:
                        var best_steep_obj = 9.0e9
                        for i in range(len(all_steep_objs)):
                            if all_steep_objs[i] < best_steep_obj:
                                best_steep_obj = all_steep_objs[i]
                        if best_fact_obj < best_steep_obj:
                            var new_step_vector = step_vector.copy()
                            var new_step_size = 0.0
                            for i in range(len(step_vector)):
                                let ds = surface_eval_points[i_best_fact][i] - start_point[i]
                                new_step_vector[i] = ds
                                new_step_size += ds * ds
                            new_step_size = sqrt(new_step_size)
                            var step_diff = 0.0
                            for i in range(len(step_vector)):
                                let ds = new_step_vector[i] - step_vector[i]
                                step_diff += ds * ds
                            if sqrt(step_diff) > max_step / 100.0 and new_step_size > 1.0e-8:
                                tried_steep_mod = True
                                self._summary_siminfo.addSimulationNotice("...Moving back to original point, trying alternate descent direction.")
                                step_vector = new_step_vector
                                var step_size = 0.0
                                for i in range(len(step_vector)):
                                    step_size += step_vector[i] * step_vector[i]
                                step_size = sqrt(step_size)
                                for i in range(len(step_vector)):
                                    step_vector[i] *= Reg.max_step_size / step_size
                                current = start_point
                                obj = base_obj
                                prev_obj = base_obj
                                continue
                    if fabs(obj / prev_obj - 1.0) < converge_tol:
                        steep_converged = True
                    current = all_sim_points[-2]
                    break
                var step_mag = 0.0
                for i in range(len(step_vector)):
                    step_mag += step_vector[i] * step_vector[i]
                step_mag = sqrt(step_mag)
                if step_mag < max_step / 10.0:
                    steep_converged = True
                    break
            if steep_converged:
                opt_iter += 1
                if opt_iter >= self._SF.getVarMap().opt.max_iter.val:
                    break
                continue
            let golden_ratio = 1.0 / 1.61803398875
            let nsimpts = len(all_sim_points)
            var lower_gs = all_sim_points[nsimpts - 1 - min(2, minmax_iter)]
            var upper_gs = all_sim_points.back()
            var site_a_gs: List[Float64]
            var site_b_gs: List[Float64]
            self._summary_siminfo.setTotalSimulationCount(self._SF.getVarMap().opt.max_gs_iter.val * 2)
            self._summary_siminfo.addSimulationNotice("...Refining with golden section")
            var site_a_sim_ok = False
            var site_b_sim_ok = False
            var za = 0.0
            var zb = 0.0
            for gsiter in range(self._SF.getVarMap().opt.max_gs_iter.val):
                if not self._summary_siminfo.setCurrentSimulation(gsiter * 2):
                    self.CancelSimulation()
                    return False
                site_a_gs = self.interpolate_vectors(lower_gs, upper_gs, 1.0 - golden_ratio)
                site_b_gs = self.interpolate_vectors(lower_gs, upper_gs, golden_ratio)
                var obj: Float64
                var flux: Float64
                var cost: Float64
                if not site_a_sim_ok:
                    current = site_a_gs
                    for i in range(len(optvars)):
                        optvars[i].store(current[i])
                    all_sim_points.append(current)
                    self.EvaluateDesign(obj, flux, cost)
                    self.PostEvaluationUpdate(sim_count, current, obj, flux, cost)
                    if self._cancel_simulation: return False
                    za = obj
                    objective.append(obj)
                    max_flux.append(flux)
                    tot_costs.append(cost)
                if not self._summary_siminfo.setCurrentSimulation(gsiter * 2 + 1):
                    self.CancelSimulation()
                    return False
                if not site_b_sim_ok:
                    current = site_b_gs
                    for i in range(len(optvars)):
                        optvars[i].store(current[i])
                    all_sim_points.append(current)
                    self.EvaluateDesign(obj, flux, cost)
                    self.PostEvaluationUpdate(sim_count, current, obj, flux, cost)
                    if self._cancel_simulation: return False
                    zb = obj
                    objective.append(obj)
                    max_flux.append(flux)
                    tot_costs.append(cost)
                if fabs((za - zb) / za) < self._SF.getVarMap().opt.converge_tol.val:
                    break
                if gsiter == self._SF.getVarMap().opt.max_gs_iter.val - 1:
                    break
                if za > zb:
                    lower_gs = site_a_gs
                    site_a_sim_ok = True
                    site_b_sim_ok = False
                    za = zb
                else:
                    upper_gs = site_b_gs
                    site_a_sim_ok = False
                    site_b_sim_ok = True
                    zb = za
            if self._cancel_simulation: return False
            current = site_a_gs if za < zb else site_b_gs
            opt_iter += 1
            if opt_iter >= self._SF.getVarMap().opt.max_iter.val:
                break
        if self._cancel_simulation: return False
        self._summary_siminfo.ResetValues()
        var zbest = 9.0e23
        var best_point = List[Float64]()
        var ibest = len(objective) - 1
        for i in range(len(objective)):
            if objective[i] < zbest:
                zbest = objective[i]
                ibest = i
        best_point = all_sim_points[ibest]
        self._summary_siminfo.addSimulationNotice("\nBest point found:")
        var ones = List[Float64](len(best_point), 1.0)
        self.PostEvaluationUpdate(sim_count, best_point, zbest, max_flux[ibest], tot_costs[ibest])
        self._summary_siminfo.addSimulationNotice("\n\nOptimization complete!")
        var dimsimpt = List[List[Float64]]()
        let nr = len(all_sim_points)
        let nc = len(all_sim_points.front())
        for i in range(nr):
            if nc == 0: break
            var tmp = List[Float64]()
            for j in range(nc):
                tmp.append(all_sim_points[i][j])
            dimsimpt.append(tmp)
        self._opt.setOptimizationSimulationHistory(dimsimpt, objective, max_flux)
        return True

    def OptimizeAuto(inout self, optvars: List[Pointer[Float64]], upper_range: List[Float64], lower_range: List[Float64], stepsize: List[Float64], names: List[String] = None) -> Bool:
        var V = self._SF.getVarMap()
        let nlm = nlopt.LN_COBYLA
        let flux_penalty_save = V.opt.flux_penalty.val
        V.opt.flux_penalty.val = 0.0
        var nlobj = nlopt.opt(nlm, unslen(optvars))
        var AO = AutoOptHelper()
        AO.Initialize()
        AO.SetObjects(Pointer[AutoPilot](self), *V, Pointer[nlopt.opt](nlobj))
        AO.m_opt_vars = optvars
        nlobj.set_min_objective(optimize_auto_eval, Pointer[AutoOptHelper](AO))
        nlobj.set_xtol_rel(1.0e-4)
        nlobj.set_ftol_rel(V.opt.converge_tol.val)
        nlobj.set_initial_step(stepsize)
        nlobj.set_maxeval(V.opt.max_iter.val)
        nlobj.set_lower_bounds(lower_range)
        nlobj.set_upper_bounds(upper_range)
        nlobj.add_inequality_constraint(constraint_auto_eval, Pointer[AutoOptHelper](AO), 0.0)
        let nvars = len(optvars)
        var start = List[Float64](nvars)
        for i in range(len(optvars)):
            start[i] = optvars[i].load()
        let iht = unsigned(names.find("receiver.0.rec_height") - names.begin())
        if iht < len(names):
            var xtemp = List[Float64](len(optvars))
            for i in range(len(optvars)):
                xtemp[i] = 1.0
            AO.Simulate(xtemp.data(), len(optvars))
            var feas_mult = 1.0
            if AO.m_flux.back() > V.recs.front().peak_flux.val:
                feas_mult += (AO.m_flux.back() / V.recs.front().peak_flux.val - 1.0) * 3.0
                start[iht] *= feas_mult
                self._summary_siminfo.addSimulationNotice("Modifying initial receiver height for feasibility")
        var os = String()
        os += "\n\nBeginning Simulation\nIter "
        for i in range(len(optvars)):
            os += String.setw(9) + (names == None ? "Var " + my_to_string(i + 1) : names[i]) + "|"
        os += "| Obj.    | Flux    | Plant cost"
        let hmsg = os
        var ol = String()
        for i in range(len(hmsg)):
            ol += "-"
        self._summary_siminfo.addSimulationNotice(os)
        self._summary_siminfo.addSimulationNotice(ol)
        var fmin: Float64
        try:
            nlobj.optimize(start, fmin)
            self._summary_siminfo.addSimulationNotice(ol)
            let iopt = len(AO.m_objective) - 1
            var oo = String()
            oo += "Algorithm converged:\n"
            for i in range(len(optvars)):
                oo += (names == None ? "" : names[i] + "=") + String.setw(8) + str(AO.m_all_points[iopt][i]) + "   "
            oo += "\nObjective: " + str(AO.m_objective.back())
            self._summary_siminfo.addSimulationNotice(oo)
        except:
            V.opt.flux_penalty.val = flux_penalty_save
            return False
        var dimsimpt = List[List[Float64]]()
        let nr = len(AO.m_all_points)
        let nc = len(AO.m_all_points.front())
        for i in range(nr):
            if nc == 0: break
            var tmp = List[Float64]()
            for j in range(nc):
                tmp.append(AO.m_all_points[i][j])
            dimsimpt.append(tmp)
        self._opt.setOptimizationSimulationHistory(dimsimpt, AO.m_objective, AO.m_flux)
        V.opt.flux_penalty.val = flux_penalty_save
        return True

    def OptimizeSemiAuto(inout self, optvars: List[Pointer[Float64]], upper_range: List[Float64], lower_range: List[Float64], is_range_constr: List[Bool], names: List[String] = None) -> Bool:
        var V = self._SF.getVarMap()
        var nlm: nlopt.algorithm
        match V.opt.algorithm.mapval():
            case var_optimize.ALGORITHM.BOBYQA:
                nlm = nlopt.LN_BOBYQA
            case var_optimize.ALGORITHM.COBYLA:
                nlm = nlopt.LN_COBYLA
            case var_optimize.ALGORITHM.NELDERMEAD:
                nlm = nlopt.LN_NELDERMEAD
            case var_optimize.ALGORITHM.NEWOUA:
                nlm = nlopt.LN_NEWUOA
            case var_optimize.ALGORITHM.SUBPLEX:
                nlm = nlopt.LN_SBPLX
            case _:
                nlm = -1
        let tot_max_iter = V.opt.max_iter.val
        let step_max_iter = tot_max_iter // 3
        V.opt.max_iter.val = step_max_iter
        let flux_penalty_save = V.opt.flux_penalty.val
        var iter_counter = 0
        # Tower height optimization block
        {
            var nlobj = nlopt.opt(nlm, 1)
            var towvar = List[Pointer[Float64]]()
            towvar.append(optvars.front())
            V.opt.flux_penalty.val = 0.0
            var AO = AutoOptHelper()
            AO.Initialize()
            AO.SetObjects(Pointer[AutoPilot](self), *V, Pointer[nlopt.opt](nlobj))
            AO.m_opt_vars = towvar
            nlobj.set_min_objective(optimize_auto_eval, Pointer[AutoOptHelper](AO))
            nlobj.set_xtol_rel(1.0e-4)
            nlobj.set_ftol_rel(V.opt.converge_tol.val)
            nlobj.set_initial_step(List[Float64]([V.opt.max_step.val]))
            nlobj.set_maxeval(V.opt.max_iter.val)
            var start = List[Float64]([1.0])
            var os = String()
            os += "\n\nOptimizing Tower Height\nIter "
            os += String.setw(9) + (names == None ? "Var 1" : names.front()) + "|"
            os += "| Obj.    | Flux    | Plant cost"
            let hmsg = os
            var ol = String()
            for i in range(len(hmsg)):
                ol += "-"
            self._summary_siminfo.addSimulationNotice(os)
            self._summary_siminfo.addSimulationNotice(ol)
            var fmin: Float64
            try:
                nlobj.optimize(start, fmin)
                self._summary_siminfo.addSimulationNotice(ol)
                var objbest = 9.0e9
                for i in range(len(AO.m_all_points)):
                    let obj = AO.m_objective[i]
                    if obj < objbest:
                        objbest = obj
                iter_counter += len(AO.m_all_points)
            except:
                V.opt.max_iter.val = tot_max_iter
                V.opt.flux_penalty.val = flux_penalty_save
                return False
            V.opt.flux_penalty.val = flux_penalty_save
        }
        # Receiver dimensions optimization block
        {
            var recvars = List[Pointer[Float64]]()
            recvars.append(optvars[1])
            recvars.append(optvars[2])
            var nlobj = nlopt.opt(nlm, unslen(recvars))
            var AO = AutoOptHelper()
            AO.Initialize()
            AO.m_iter = iter_counter
            AO.SetObjects(Pointer[AutoPilot](self), *V, Pointer[nlopt.opt](nlobj))
            AO.m_opt_vars = recvars
            nlobj.set_min_objective(optimize_auto_eval, Pointer[AutoOptHelper](AO))
            nlobj.set_xtol_rel(1.0e-4)
            nlobj.set_ftol_rel(V.opt.converge_tol.val)
            nlobj.set_initial_step(List[Float64](len(recvars), V.opt.max_step.val))
            nlobj.set_maxeval(V.opt.max_iter.val)
            let nvars = len(recvars)
            var start = List[Float64](nvars, 1.0)
            var os = String()
            os += "**Optimizing Receiver Dimensions at THT=" + str(optvars.front().load()) + "[m]\nIter "
            for i in range(len(recvars)):
                os += String.setw(9) + (names == None ? "Var " + my_to_string(i + 1) : names[i + 1]) + "|"
            os += "| Obj.    | Flux    | Plant cost"
            let hmsg = os
            var ol = String()
            for i in range(len(hmsg)):
                ol += "-"
            self._summary_siminfo.addSimulationNotice(os)
            self._summary_siminfo.addSimulationNotice(ol)
            var fmin: Float64
            try:
                nlobj.optimize(start, fmin)
                self._summary_siminfo.addSimulationNotice(ol)
                var objbest = 9.0e9
                for i in range(len(AO.m_all_points)):
                    let obj = AO.m_objective[i]
                    if obj < objbest:
                        objbest = obj
                iter_counter += len(AO.m_all_points)
            except:
                V.opt.max_iter.val = tot_max_iter
                return False
        }
        # Co-optimization block
        {
            V.opt.max_iter.val = step_max_iter + (tot_max_iter % 3)
            var nlobj = nlopt.opt(nlm, unslen(optvars))
            var AO = AutoOptHelper()
            AO.Initialize()
            AO.m_iter = iter_counter
            AO.SetObjects(Pointer[AutoPilot](self), *V, Pointer[nlopt.opt](nlobj))
            AO.m_opt_vars = optvars
            nlobj.set_min_objective(optimize_auto_eval, Pointer[AutoOptHelper](AO))
            nlobj.set_xtol_rel(1.0e-4)
            nlobj.set_ftol_rel(V.opt.converge_tol.val)
            nlobj.set_initial_step(List[Float64](len(optvars), V.opt.max_step.val))
            nlobj.set_maxeval(V.opt.max_iter.val)
            let nvars = len(optvars)
            var start = List[Float64](nvars, 1.0)
            var os = String()
            os += "**Co-optimizing geometry\nIter "
            for i in range(len(optvars)):
                os += String.setw(9) + (names == None ? "Var " + my_to_string(i + 1) : names[i]) + "|"
            os += "| Obj.    | Flux    | Plant cost"
            let hmsg = os
            var ol = String()
            for i in range(len(hmsg)):
                ol += "-"
            self._summary_siminfo.addSimulationNotice(os)
            self._summary_siminfo.addSimulationNotice(ol)
            var fmin: Float64
            try:
                nlobj.optimize(start, fmin)
                self._summary_siminfo.addSimulationNotice(ol)
                var iopt = 0
                var objbest = 9.0e9
                for i in range(len(AO.m_all_points)):
                    let obj = AO.m_objective[i]
                    if obj < objbest:
                        objbest = obj
                        iopt = i
                var oo = String()
                oo += "Best point found:\n"
                for i in range(len(optvars)):
                    oo += (names == None ? "" : names[i] + "=") + String.setw(8) + str(AO.m_all_points[iopt][i]) + "   "
                oo += "\nObjective: " + str(objbest)
                self._summary_siminfo.addSimulationNotice(oo)
            except:
                V.opt.max_iter.val = tot_max_iter
                return False
            var dimsimpt = List[List[Float64]]()
            let nr = len(AO.m_all_points)
            let nc = len(AO.m_all_points.front())
            for i in range(nr):
                if nc == 0: break
                var tmp = List[Float64]()
                for j in range(nc):
                    tmp.append(AO.m_all_points[i][j])
                dimsimpt.append(tmp)
            self._opt.setOptimizationSimulationHistory(dimsimpt, AO.m_objective, AO.m_flux)
        }
        V.opt.max_iter.val = tot_max_iter
        return True

    def IsSimulationCancelled(self) -> Bool:
        return self._cancel_simulation

    def GetOptimizationObject(self) -> sp_optimize:
        return self._opt

    def PostEvaluationUpdate(inout self, iter: Int, pos: List[Float64], obj: Float64, flux: Float64, cost: Float64, note: String = None):
        var os = String()
        os += "[" + String.setw(2) + str(iter) + "] "
        for i in range(len(pos)):
            os += String.setw(8) + str(pos[i]) + " |"
        os += "|" + String.setw(8) + str(obj) + " |" + String.setw(8) + str(flux) + " | $" + String.setw(8) + str(cost)
        if note != None:
            os += note
        self._summary_siminfo.addSimulationNotice(os)

    def CalculateFluxMapsOV1(inout self, sunpos: List[List[Float64]], fluxtab: List[List[Float64]], efficiency: List[Float64], flux_res_x: Int = 12, flux_res_y: Int = 10, is_normalized: Bool = True) -> Bool:
        var fluxtab_s = sp_flux_table()
        if not self.CalculateFluxMaps(fluxtab_s, flux_res_x, flux_res_y, is_normalized):
            return False
        let flux_data = fluxtab_s.flux_surfaces.front().flux_data
        fluxtab.clear()
        efficiency.clear()
        for i in range(flux_data.nlayers()):
            sunpos.append(List[Float64]([fluxtab_s.azimuths[i], fluxtab_s.zeniths[i]]))
            efficiency.append(fluxtab_s.efficiency[i])
            for j in range(flux_res_y):
                var newline = List[Float64]()
                for k in range(flux_res_x):
                    newline.append(flux_data.at(j, k, i))
                fluxtab.append(newline)
        return True

    enum API_CANT_TYPE:
        NONE = 0
        ON_AXIS = 1
        EQUINOX = 2
        SOLSTICE_SUMMER = 3
        SOLSTICE_WINTER = 4

class AutoPilot_S(AutoPilot):
    def CreateLayout(inout self, layout: sp_layout, do_post_process: Bool = True) -> Bool:
        self._cancel_simulation = False
        self.PreSimCallbackUpdate()
        if not self._cancel_simulation:
            let simok = self._SF.FieldLayout()
            if self._SF.ErrCheck() or not simok: return False
        if do_post_process:
            if not self._cancel_simulation:
                let sun = Ambient.calcSunVectorFromAzZen(self._SF.getVarMap().sf.sun_az_des.Val() * D2R, (90.0 - self._SF.getVarMap().sf.sun_el_des.Val()) * D2R)
                self._SF.calcHeliostatShadows(sun)
                if self._SF.ErrCheck(): return False
            if not self._cancel_simulation:
                self.PostProcessLayout(layout)
        return True

    def CalculateOpticalEfficiencyTable(inout self, opttab: sp_optical_table) -> Bool:
        self._cancel_simulation = False
        self.PreSimCallbackUpdate()
        var neff_az: Int
        var neff_zen: Int
        if not opttab.is_user_positions:
            neff_az = 12
            opttab.azimuths.clear()
            var eff_az = List[Float64]([0.0, 30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0, 330.0])
            for i in range(neff_az):
                opttab.azimuths.append(eff_az[i])
            neff_zen = 8
            opttab.zeniths.clear()
            var eff_zen = List[Float64]([0.50, 7.0, 15.0, 30.0, 45.0, 60.0, 75.0, 85.0])
            for i in range(neff_zen):
                opttab.zeniths.append(eff_zen[i])
        else:
            neff_az = len(opttab.azimuths)
            neff_zen = len(opttab.zeniths)
        let dni = self._SF.getVarMap().sf.dni_des.val
        var P = sim_params()
        P.dni = dni
        P.Tamb = 25.0
        let neff_tot = neff_az * neff_zen
        self._sim_total = neff_tot
        if self._has_summary_callback:
            self._summary_siminfo.ResetValues()
            self._summary_siminfo.setTotalSimulationCount(self._sim_total)
            self._summary_siminfo.addSimulationNotice("Simulating optical efficiency points")
        var results = sim_results()
        results.resize(neff_tot)
        let neff_tot_str = my_to_string(neff_tot)
        var k = 0
        for j in range(neff_zen):
            for i in range(neff_az):
                self._sim_complete = k
                if self._has_summary_callback:
                    if not self._summary_siminfo.setCurrentSimulation(self._sim_complete):
                        self.CancelSimulation()
                var azzen = List[Float64](2)
                azzen[0] = opttab.azimuths[i] - 180.0
                azzen[1] = opttab.zeniths[j]
                if not self._cancel_simulation:
                    self._SF.Simulate(azzen[0], azzen[1], P)
                if not self._cancel_simulation:
                    results[k].process_analytical_simulation(*self._SF, 0, azzen)
                    k += 1
                if self._cancel_simulation:
                    return False
        opttab.eff_data.clear()
        k = 0
        for j in range(neff_zen):
            var row = List[Float64]()
            for i in range(neff_az):
                row.append(results[k].eff_total_sf.ave)
                k += 1
            opttab.eff_data.append(row)
        return True

    def CalculateFluxMaps(inout self, fluxtab: sp_flux_table, flux_res_x: Int = 12, flux_res_y: Int = 10, is_normalized: Bool = True) -> Bool:
        self.PreSimCallbackUpdate()
        self._cancel_simulation = False
        self.PrepareFluxSimulation(fluxtab, flux_res_x, flux_res_y, is_normalized)
        let dni = self._SF.getVarMap().sf.dni_des.val
        var P = sim_params()
        P.dni = dni
        P.Tamb = 25.0
        self._sim_total = len(fluxtab.azimuths)
        self._sim_complete = 0
        if self._has_summary_callback:
            self._summary_siminfo.ResetValues()
            self._summary_siminfo.setTotalSimulationCount(self._sim_total)
            self._summary_siminfo.addSimulationNotice("Simulating flux maps")
        fluxtab.efficiency.clear()
        for i in range(self._sim_total):
            self._sim_complete += 1
            if self._has_summary_callback:
                if not self._summary_siminfo.setCurrentSimulation(self._sim_complete):
                    self.CancelSimulation()
            var azzen = List[Float64](2)
            azzen[0] = fluxtab.azimuths[i]
            azzen[1] = fluxtab.zeniths[i]
            if not self._cancel_simulation:
                self._SF.Simulate(azzen[0], azzen[1], P)
            if not self._cancel_simulation:
                self._SF.HermiteFluxSimulation(*self._SF.getHeliostats())
            var result = sim_result()
            if not self._cancel_simulation:
                result.process_analytical_simulation(*self._SF, 2, azzen)
                fluxtab.efficiency.append(result.eff_total_sf.ave)
            if not self._cancel_simulation:
                result.process_flux(self._SF, is_normalized)
            if not self._cancel_simulation:
                self.PostProcessFlux(result, fluxtab, i)
            if self._cancel_simulation:
                return False
        return True

    def CalculateFluxMaps(inout self, sunpos: List[List[Float64]], fluxtab: List[List[Float64]], efficiency: List[Float64], flux_res_x: Int = 12, flux_res_y: Int = 10, is_normalized: Bool = True) -> Bool:
        self.PreSimCallbackUpdate()
        return self.CalculateFluxMapsOV1(sunpos, fluxtab, efficiency, flux_res_x, flux_res_y, is_normalized)

@if SP_USE_THREADS:
class AutoPilot_MT(AutoPilot):
    var _n_threads: Int
    var _n_threads_active: Int
    var _simthread: LayoutSimThread
    var _in_mt_simulation: Bool

    def __init__(inout self):
        self._in_mt_simulation = False
        self._cancel_simulation = False
        self._has_summary_callback = False
        self._has_detail_callback = False
        self._summary_callback = None
        self._detail_callback = None
        self._summary_callback_data = None
        self._detail_callback_data = None
        self._summary_siminfo = simulation_info()
        self._SF = SolarField()
        self.SetMaxThreadCount(999999)

    def CreateLayout(inout self, layout: sp_layout, do_post_process: Bool = True) -> Bool:
        self._cancel_simulation = False
        self._in_mt_simulation = False
        self.PreSimCallbackUpdate()
        try:
            let nsim_req = self._SF.calcNumRequiredSimulations()
            if self._has_detail_callback:
                self._detail_siminfo.ResetValues()
                self._detail_siminfo.setTotalSimulationCount(nsim_req)
                self._detail_siminfo.addSimulationNotice("Creating field layout")
            if self._n_threads > 1 and nsim_req > 1:
                var wdata = WeatherData()
                let full_sim = self._SF.PrepareFieldLayout(*self._SF, wdata)
                if full_sim:
                    let nthreads = min(nsim_req, self._n_threads)
                    if self._has_detail_callback:
                        self._detail_siminfo.addSimulationNotice("Preparing " + my_to_string(self._n_threads) + " threads for simulation")
                    var SFarr = List[SolarField](nthreads)
                    for i in range(nthreads):
                        SFarr[i] = SolarField(*self._SF)
                    var results = sim_results()
                    results.resize(nsim_req)
                    let npert = int(ceil(float(nsim_req) / float(nthreads)))
                    self._simthread = LayoutSimThread(nthreads)
                    self._n_threads_active = nthreads
                    self._in_mt_simulation = True
                    var sim_first = 0
                    var sim_last = npert
                    for i in range(nthreads):
                        let istr = my_to_string(i + 1)
                        self._simthread[i].Setup(istr, SFarr[i], results, wdata, sim_first, sim_last, False, False)
                        sim_first = sim_last
                        sim_last = min(sim_last + npert, nsim_req)
                    if self._has_detail_callback:
                        self._detail_siminfo.setTotalSimulationCount(nsim_req)
                        self._detail_siminfo.setCurrentSimulation(0)
                        self._detail_siminfo.addSimulationNotice("Simulating layout design-point hours...")
                    for i in range(nthreads):
                        thread.start(self._simthread[i].StartThread)
                    while True:
                        var nsim_done = 0
                        var nsim_remain = 0
                        var nthread_done = 0
                        for i in range(nthreads):
                            if self._simthread[i].IsFinished():
                                nthread_done += 1
                            var ns: Int
                            var nr: Int
                            self._simthread[i].GetStatus(ns, nr)
                            nsim_done += ns
                            nsim_remain += nr
                        self._sim_total = nsim_req
                        self._sim_complete = nsim_done
                        if self._has_detail_callback:
                            if not self._detail_siminfo.setCurrentSimulation(nsim_done):
                                break
                        if nthread_done == nthreads: break
                        std.this_thread.sleep_for(std.chrono.milliseconds(75))
                    var cancelled = False
                    for i in range(nthreads):
                        cancelled = cancelled or self._simthread[i].IsSimulationCancelled()
                    var errored_out = False
                    for i in range(self._n_threads):
                        errored_out = errored_out or self._simthread[i].IsFinishedWithErrors()
                    if errored_out:
                        self.CancelSimulation()
                        var errmsgs = String()
                        for i in range(self._n_threads):
                            for j in range(len(self._simthread[i].GetSimMessages())):
                                errmsgs += self._simthread[i].GetSimMessages()[j] + "\n"
                        if not errmsgs.empty() and self._has_summary_callback:
                            self._summary_siminfo.addSimulationNotice(errmsgs)
                    for i in range(self._n_threads):
                        delete SFarr[i]
                    delete SFarr
                    delete self._simthread
                    self._simthread = LayoutSimThread()
                    if cancelled or errored_out:
                        return False
                    if self._SF.getVarMap().sf.des_sim_detail.mapval() == var_solarfield.DES_SIM_DETAIL.EFFICIENCY_MAP__ANNUAL:
                        if not self._cancel_simulation:
                            SolarField.AnnualEfficiencySimulation(self._SF.getVarMap().amb.weather_file.val, self._SF, results)
                    if not self._cancel_simulation:
                        self._SF.ProcessLayoutResults(results, nsim_req)
            else:
                self._n_threads_active = 1
                self._in_mt_simulation = False
                if not self._cancel_simulation:
                    let simok = self._SF.FieldLayout()
                    if self._SF.ErrCheck() or not simok: return False
            if do_post_process:
                let sun = Ambient.calcSunVectorFromAzZen(self._SF.getVarMap().sf.sun_az_des.Val() * D2R, (90.0 - self._SF.getVarMap().sf.sun_el_des.Val()) * D2R)
                if not self._cancel_simulation:
                    self._SF.calcHeliostatShadows(sun)
                    if self._SF.ErrCheck(): return False
                if not self._cancel_simulation:
                    self.PostProcessLayout(layout)
        except e as Exception:
            self._summary_siminfo.addSimulationNotice(str(e))
            return False
        except:
            self._summary_siminfo.addSimulationNotice("Caught unhandled exception in layout simulation. Simulation unsuccessful.")
            return False
        return True

    def SetMaxThreadCount(inout self, nt: Int) -> Bool:
        try:
            let nmax = std.thread.hardware_concurrency()
            self._n_threads = min(max(nt, 1), int(nmax))
        except:
            return False
        return True

    def CalculateOpticalEfficiencyTable(inout self, opttab: sp_optical_table) -> Bool:
        self._cancel_simulation = False
        self.PreSimCallbackUpdate()
        var neff_az: Int
        var neff_zen: Int
        if not opttab.is_user_positions:
            neff_az = 12
            opttab.azimuths.clear()
            var eff_az = List[Float64]([0.0, 30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0, 330.0])
            for i in range(neff_az):
                opttab.azimuths.append(eff_az[i])
            neff_zen = 8
            opttab.zeniths.clear()
            var eff_zen = List[Float64]([0.50, 7.0, 15.0, 30.0, 45.0, 60.0, 75.0, 85.0])
            for i in range(neff_zen):
                opttab.zeniths.append(eff_zen[i])
        else:
            neff_az = len(opttab.azimuths)
            neff_zen = len(opttab.zeniths)
        var V = self._SF.getVarMap()
        let dni = V.sf.dni_des.val
        var P = sim_params()
        P.dni = dni
        P.Tamb = 25.0
        let neff_tot = neff_az * neff_zen
        self._sim_total = neff_tot
        if self._has_summary_callback:
            self._summary_siminfo.ResetValues()
            self._summary_siminfo.setTotalSimulationCount(self._sim_total)
            self._summary_siminfo.addSimulationNotice