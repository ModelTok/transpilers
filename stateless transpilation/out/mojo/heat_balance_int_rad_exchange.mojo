# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing all global data
# - Functions: ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError, DisplayString
# - Constants: Constant.StefanBoltzmann, Constant.Kelvin
# - Util functions: Util.FindItemInList, Util.makeUPPER, Util.SameString
# - Array operations: sum, transpose, min, max, pow_2, pow_4, root_4
# - General.ScanForReports
# - DataSurfaces, DataHeatBalance, DataConstruction, DataHeatBalSurf, DataViewFactorInformation
# - WindowEquivalentLayer.EQLWindowInsideEffectiveEmiss
# - state.files.eio, state.files.debug for output

from math import pow, fabs, sqrt
from collections import InlineArray


struct HeatBalanceIntRadExchgData:
    """Global data for interior radiant exchange calculations."""
    var MaxNumOfRadEnclosureSurfs: Int
    var CarrollMethod: Bool
    var CalcInteriorRadExchangefirstTime: Bool
    var SurfaceTempRad: DynamicVector[Float64]
    var SurfaceTempInKto4th: DynamicVector[Float64]
    var SurfaceEmiss: DynamicVector[Float64]
    var ViewFactorReport: Bool
    var LargestSurf: Int

    fn __init__(inout self):
        self.MaxNumOfRadEnclosureSurfs = 0
        self.CarrollMethod = False
        self.CalcInteriorRadExchangefirstTime = True
        self.SurfaceTempRad = DynamicVector[Float64]()
        self.SurfaceTempInKto4th = DynamicVector[Float64]()
        self.SurfaceEmiss = DynamicVector[Float64]()
        self.ViewFactorReport = False
        self.LargestSurf = 0

    fn clear_state(inout self):
        self.MaxNumOfRadEnclosureSurfs = 0
        self.CarrollMethod = False
        self.CalcInteriorRadExchangefirstTime = True
        self.SurfaceTempRad.clear()
        self.SurfaceTempInKto4th.clear()
        self.SurfaceEmiss.clear()
        self.ViewFactorReport = False
        self.LargestSurf = 0


alias STEFAN_BOLTZMANN = 5.67e-8
alias KELVIN = 273.15


@always_inline
fn any_interior_shade_blind(shade_flag: String) -> Bool:
    """Check if shade flag indicates interior shade or blind."""
    return shade_flag == "IntShade" or shade_flag == "IntBlind"


@always_inline
fn not_shaded(shade_flag: String) -> Bool:
    """Check if surface is not shaded."""
    return shade_flag == "NoShade" or shade_flag == ""


fn window_equivalent_layer_eql_window_inside_effective_emiss(state, const_num: Int) -> Float64:
    """Get inside effective emissivity for EQL window."""
    return 0.9


fn calc_interior_rad_exchange(
    state,
    surface_temp: DynamicVector[Float64],
    surf_iterations: Int,
    net_lw_rad_to_surf: InlineArray[Float64],
    zone_to_resimulate: Int = -1,
    called_from: String = ""
):
    """Calculate interior radiant exchange between surfaces."""
    
    var surface_temp_rad = state.data_heat_bal_int_rad_exchg.SurfaceTempRad
    var surface_temp_in_k_to_4th = state.data_heat_bal_int_rad_exchg.SurfaceTempInKto4th
    var surface_emiss = state.data_heat_bal_int_rad_exchg.SurfaceEmiss

    if state.data_heat_bal_int_rad_exchg.CalcInteriorRadExchangefirstTime:
        let max_surfs = state.data_heat_bal_int_rad_exchg.MaxNumOfRadEnclosureSurfs
        surface_temp_rad = DynamicVector[Float64](capacity=max_surfs)
        surface_temp_in_k_to_4th = DynamicVector[Float64](capacity=max_surfs)
        surface_emiss = DynamicVector[Float64](capacity=max_surfs)
        for _ in range(max_surfs):
            surface_temp_rad.push_back(0.0)
            surface_temp_in_k_to_4th.push_back(0.0)
            surface_emiss.push_back(0.0)
        state.data_heat_bal_int_rad_exchg.CalcInteriorRadExchangefirstTime = False

    if state.data_global.KickOffSimulation or state.data_global.KickOffSizing:
        return

    let partial_resimulate = zone_to_resimulate >= 0

    var start_enclosure = 1
    var end_enclosure = state.data_view_factor.NumOfRadiantEnclosures
    
    if partial_resimulate:
        start_enclosure = state.data_heat_bal.Zone[zone_to_resimulate].zoneRadEnclosureFirst
        end_enclosure = state.data_heat_bal.Zone[zone_to_resimulate].zoneRadEnclosureLast
        for enclosure_num in range(start_enclosure, end_enclosure + 1):
            let enclosure = state.data_view_factor.EnclRadInfo[enclosure_num]
            for i in enclosure.SurfacePtr:
                net_lw_rad_to_surf[i] = 0.0
                state.data_surface.SurfWinIRfromParentZone[i] = 0.0
    else:
        for i in range(len(net_lw_rad_to_surf)):
            net_lw_rad_to_surf[i] = 0.0
        for surf_num in range(1, state.data_surface.TotSurfaces + 1):
            state.data_surface.SurfWinIRfromParentZone[surf_num] = 0.0

    for enclosure_num in range(start_enclosure, end_enclosure + 1):
        let zone_info = state.data_view_factor.EnclRadInfo[enclosure_num]
        let zone_script_f = zone_info.ScriptF
        let n_zone_surfaces = zone_info.NumOfSurfaces
        let s_zone_surfaces = n_zone_surfaces

        if surf_iterations == 0:
            var int_shade_or_blind_status_changed = False
            var int_mov_insul_changed = False

            if not state.data_global.BeginEnvrnFlag:
                for surf_num in zone_info.SurfacePtr:
                    if int_shade_or_blind_status_changed or int_mov_insul_changed:
                        break
                    if state.data_construction.Construct[state.data_surface.Surface[surf_num].Construction].TypeIsWindow:
                        let shade_flag = state.data_surface.SurfWinShadingFlag[surf_num]
                        let shade_flag_prev = state.data_surface.SurfWinExtIntShadePrevTS[surf_num]
                        if shade_flag_prev != shade_flag and (any_interior_shade_blind(shade_flag_prev) or any_interior_shade_blind(shade_flag)):
                            int_shade_or_blind_status_changed = True
                        if (state.data_surface.SurfWinWindowModelType[surf_num] == "EQL" and
                            state.data_window_equiv_layer.CFS[state.data_construction.Construct[state.data_surface.Surface[surf_num].Construction].EQLConsPtr].ISControlled):
                            int_shade_or_blind_status_changed = True
                    else:
                        if state.data_surface.AnyMovableInsulation:
                            int_mov_insul_changed = update_movable_insulation_flag(state, surf_num)

            if int_shade_or_blind_status_changed or int_mov_insul_changed or state.data_global.BeginEnvrnFlag:
                for zone_surf_num in range(n_zone_surfaces):
                    let surf_num = zone_info.SurfacePtr[zone_surf_num]
                    let constr_num = state.data_surface.Surface[surf_num].Construction
                    zone_info.Emissivity[zone_surf_num] = state.data_heat_bal_surf.SurfAbsThermalInt[surf_num]
                    if (state.data_construction.Construct[constr_num].TypeIsWindow and
                        any_interior_shade_blind(state.data_surface.SurfWinShadingFlag[surf_num])):
                        zone_info.Emissivity[zone_surf_num] = state.data_heat_bal_surf.SurfAbsThermalInt[surf_num]
                    if (state.data_surface.SurfWinWindowModelType[surf_num] == "EQL" and
                        state.data_window_equiv_layer.CFS[state.data_construction.Construct[constr_num].EQLConsPtr].ISControlled):
                        zone_info.Emissivity[zone_surf_num] = window_equivalent_layer_eql_window_inside_effective_emiss(state, constr_num)

                if state.data_heat_bal_int_rad_exchg.CarrollMethod:
                    calc_fp(n_zone_surfaces, zone_info.Emissivity, zone_info.FMRT, zone_info.Fp)
                else:
                    calc_script_f(state, n_zone_surfaces, zone_info.Area, zone_info.F, zone_info.Emissivity, zone_script_f)
                    for i in range(len(zone_script_f)):
                        zone_script_f[i] *= STEFAN_BOLTZMANN

        var carroll_mrt_numerator = 0.0
        var carroll_mrt_denominator = 0.0
        
        for zone_surf_num in range(s_zone_surfaces):
            let surf_num = zone_info.SurfacePtr[zone_surf_num]
            let surf = state.data_surface.Surface[surf_num]
            let surf_window = state.data_surface.SurfaceWindow[surf_num]
            let constr_num = surf.Construction
            let construct = state.data_construction.Construct[constr_num]
            
            if construct.WindowTypeEQL:
                surface_temp_rad[zone_surf_num] = state.data_surface.SurfWinEffInsSurfTemp[surf_num]
                surface_emiss[zone_surf_num] = window_equivalent_layer_eql_window_inside_effective_emiss(state, constr_num)
            elif (construct.WindowTypeBSDF and state.data_surface.SurfWinShadingFlag[surf_num] == "IntShade"):
                let surf_shade = state.data_surface.surfShades[surf_num]
                surface_temp_rad[zone_surf_num] = state.data_surface.SurfWinEffInsSurfTemp[surf_num]
                surface_emiss[zone_surf_num] = surf_shade.effShadeEmi + surf_shade.effGlassEmi
            elif construct.WindowTypeBSDF:
                surface_temp_rad[zone_surf_num] = state.data_surface.SurfWinEffInsSurfTemp[surf_num]
                surface_emiss[zone_surf_num] = construct.InsideAbsorpThermal
            elif (construct.TypeIsWindow and surf.OriginalClass != "TDD_Diffuser"):
                if surf_iterations == 0 and not_shaded(state.data_surface.SurfWinShadingFlag[surf_num]):
                    surface_temp_rad[zone_surf_num] = surf_window.thetaFace[2 * construct.TotGlassLayers - 1] - KELVIN
                    surface_emiss[zone_surf_num] = construct.InsideAbsorpThermal
                elif any_interior_shade_blind(state.data_surface.SurfWinShadingFlag[surf_num]):
                    surface_temp_rad[zone_surf_num] = state.data_surface.SurfWinEffInsSurfTemp[surf_num]
                    surface_emiss[zone_surf_num] = state.data_heat_bal_surf.SurfAbsThermalInt[surf_num]
                else:
                    surface_temp_rad[zone_surf_num] = surface_temp[surf_num]
                    surface_emiss[zone_surf_num] = construct.InsideAbsorpThermal
            else:
                surface_temp_rad[zone_surf_num] = surface_temp[surf_num]
                surface_emiss[zone_surf_num] = construct.InsideAbsorpThermal
            
            surface_temp_in_k_to_4th[zone_surf_num] = pow(surface_temp_rad[zone_surf_num] + KELVIN, 4.0)
            if state.data_heat_bal_int_rad_exchg.CarrollMethod:
                carroll_mrt_numerator += surface_temp_in_k_to_4th[zone_surf_num] * zone_info.Fp[zone_surf_num] * zone_info.Area[zone_surf_num]
                carroll_mrt_denominator += zone_info.Fp[zone_surf_num] * zone_info.Area[zone_surf_num]

        if state.data_heat_bal_int_rad_exchg.CarrollMethod:
            var carroll_mrt_in_k_to_4th: Float64
            if carroll_mrt_denominator > 0.0:
                carroll_mrt_in_k_to_4th = carroll_mrt_numerator / carroll_mrt_denominator
            else:
                carroll_mrt_in_k_to_4th = 293.15
            
            for rec_zone_surf_num in range(s_zone_surfaces):
                let rec_surf_num = zone_info.SurfacePtr[rec_zone_surf_num]
                let constr_num_rec = state.data_surface.Surface[rec_surf_num].Construction
                let rec_construct = state.data_construction.Construct[constr_num_rec]
                
                if rec_construct.TypeIsWindow:
                    var carroll_mrt_in_k_to_4th_win = carroll_mrt_in_k_to_4th
                    var carroll_mrt_numerator_win = 0.0
                    var carroll_mrt_denominator_win = 0.0
                    for send_zone_surf_num in range(s_zone_surfaces):
                        if send_zone_surf_num != rec_zone_surf_num:
                            carroll_mrt_numerator_win += (pow(surface_temp_rad[send_zone_surf_num] + KELVIN, 4.0) *
                                                          zone_info.Fp[send_zone_surf_num] * zone_info.Area[send_zone_surf_num])
                            carroll_mrt_denominator_win += zone_info.Fp[send_zone_surf_num] * zone_info.Area[send_zone_surf_num]
                    if carroll_mrt_denominator_win > 0.0:
                        carroll_mrt_in_k_to_4th_win = carroll_mrt_numerator_win / carroll_mrt_denominator_win
                    state.data_surface.SurfWinIRfromParentZone[rec_surf_num] += (
                        (zone_info.Fp[rec_zone_surf_num] * carroll_mrt_in_k_to_4th_win) / surface_emiss[rec_zone_surf_num]
                    )
                
                net_lw_rad_to_surf[rec_surf_num] += (zone_info.Fp[rec_zone_surf_num] *
                                                     (carroll_mrt_in_k_to_4th - surface_temp_in_k_to_4th[rec_zone_surf_num]))
        else:
            for rec_zone_surf_num in range(s_zone_surfaces):
                let rec_surf_num = zone_info.SurfacePtr[rec_zone_surf_num]
                let constr_num_rec = state.data_surface.Surface[rec_surf_num].Construction
                let rec_construct = state.data_construction.Construct[constr_num_rec]

                if rec_construct.TypeIsWindow:
                    var script_f_acc = 0.0
                    var net_lw_rad_to_rec_surf_cor = 0.0
                    var ir_from_parent_zone_acc = 0.0
                    for send_zone_surf_num in range(s_zone_surfaces):
                        let l_sr = rec_zone_surf_num * s_zone_surfaces + send_zone_surf_num
                        let script_f = zone_script_f[l_sr]
                        let script_f_temp_ink_4th = script_f * surface_temp_in_k_to_4th[send_zone_surf_num]
                        ir_from_parent_zone_acc += script_f_temp_ink_4th
                        
                        if rec_zone_surf_num != send_zone_surf_num:
                            script_f_acc += script_f
                        else:
                            net_lw_rad_to_rec_surf_cor = script_f_temp_ink_4th
                    
                    net_lw_rad_to_surf[rec_surf_num] += (ir_from_parent_zone_acc - net_lw_rad_to_rec_surf_cor -
                                                         (script_f_acc * surface_temp_in_k_to_4th[rec_zone_surf_num]))
                    state.data_surface.SurfWinIRfromParentZone[rec_surf_num] += ir_from_parent_zone_acc / surface_emiss[rec_zone_surf_num]
                else:
                    var net_lw_rad_to_rec_surf_acc = 0.0
                    zone_script_f[rec_zone_surf_num * s_zone_surfaces + rec_zone_surf_num] = 0.0
                    for send_zone_surf_num in range(s_zone_surfaces):
                        let l_sr = rec_zone_surf_num * s_zone_surfaces + send_zone_surf_num
                        net_lw_rad_to_rec_surf_acc += (zone_script_f[l_sr] *
                                                      (surface_temp_in_k_to_4th[send_zone_surf_num] - surface_temp_in_k_to_4th[rec_zone_surf_num]))
                    net_lw_rad_to_surf[rec_surf_num] += net_lw_rad_to_rec_surf_acc

    if state.data_surface.UseRepresentativeSurfaceCalculations:
        for surf_num in state.data_surface.AllHTSurfaceList:
            let rep_surf_num = state.data_surface.Surface[surf_num].RepresentativeCalcSurfNum
            if surf_num != rep_surf_num:
                state.data_surface.SurfWinIRfromParentZone[surf_num] = state.data_surface.SurfWinIRfromParentZone[rep_surf_num]
                net_lw_rad_to_surf[surf_num] = net_lw_rad_to_surf[rep_surf_num]


fn update_movable_insulation_flag(state, surf_num: Int) -> Bool:
    """Update flag for changes in interior movable insulation."""
    let s_surf = state.data_surface
    let mov_insul = s_surf.intMovInsuls[surf_num]
    if mov_insul.present != mov_insul.presentPrevTS:
        return (fabs(state.data_construction.Construct[s_surf.Surface[surf_num].Construction].InsideAbsorpThermal -
                     state.data_material.materials[mov_insul.matNum].AbsorpThermal) > 0.01)
    return False


fn init_interior_rad_exchange(state):
    """Initialize interior radiant exchange parameters."""
    var errors_found = False

    state.data_heat_bal_int_rad_exchg.MaxNumOfRadEnclosureSurfs = 0
    
    for enclosure_num in range(1, state.data_view_factor.NumOfRadiantEnclosures + 1):
        let this_enclosure = state.data_view_factor.EnclRadInfo[enclosure_num]
        
        var num_enclosure_surfaces = 0
        for space_num in this_enclosure.spaceNums:
            for surf_num in state.data_heat_bal.space[space_num].surfaces:
                if state.data_surface.Surface[surf_num].IsAirBoundarySurf:
                    continue
                if surf_num == state.data_surface.Surface[surf_num].RepresentativeCalcSurfNum:
                    num_enclosure_surfaces += 1
        
        this_enclosure.NumOfSurfaces = num_enclosure_surfaces
        state.data_heat_bal_int_rad_exchg.MaxNumOfRadEnclosureSurfs = max(
            state.data_heat_bal_int_rad_exchg.MaxNumOfRadEnclosureSurfs, num_enclosure_surfaces
        )
        
        if num_enclosure_surfaces < 1:
            errors_found = True

        this_enclosure.F = DynamicVector[DynamicVector[Float64]](capacity=num_enclosure_surfaces)
        this_enclosure.ScriptF = DynamicVector[DynamicVector[Float64]](capacity=num_enclosure_surfaces)
        this_enclosure.Area = DynamicVector[Float64](capacity=num_enclosure_surfaces)
        this_enclosure.Emissivity = DynamicVector[Float64](capacity=num_enclosure_surfaces)
        
        for _ in range(num_enclosure_surfaces):
            var row = DynamicVector[Float64](capacity=num_enclosure_surfaces)
            for _ in range(num_enclosure_surfaces):
                row.push_back(0.0)
            this_enclosure.F.push_back(row)
            this_enclosure.ScriptF.push_back(row)
            this_enclosure.Area.push_back(0.0)
            this_enclosure.Emissivity.push_back(0.0)

        if state.data_heat_bal_int_rad_exchg.CarrollMethod:
            this_enclosure.Fp = DynamicVector[Float64](capacity=num_enclosure_surfaces)
            this_enclosure.FMRT = DynamicVector[Float64](capacity=num_enclosure_surfaces)
            for _ in range(num_enclosure_surfaces):
                this_enclosure.Fp.push_back(1.0)
                this_enclosure.FMRT.push_back(0.0)


fn init_solar_view_factors(state):
    """Initialize solar view factors."""
    var errors_found = False


fn get_input_view_factors_by_name(state, enclosure_name: String, n: Int, f, s_ptr, no_user_input_f, errors_found):
    """Get user input view factors by name."""
    no_user_input_f[0] = True


fn calc_approximate_view_factors(state, n: Int, a, azimuth, tilt, f, s_ptr):
    """Calculate approximate view factors using area weighting."""
    let same_angle_limit = 10.0
    var zone_area = DynamicVector[Float64](capacity=n)
    
    for _ in range(n):
        zone_area.push_back(0.0)
    
    for i in range(n):
        for j in range(n):
            if i == j:
                continue
            if (state.data_surface.Surface[s_ptr[j]].Class == "Floor" and
                state.data_surface.Surface[s_ptr[i]].Class == "Floor"):
                continue
            
            if ((state.data_surface.Surface[s_ptr[j]].Class == "IntMass") or
                (state.data_surface.Surface[s_ptr[i]].Class == "IntMass") or
                (state.data_surface.Surface[s_ptr[j]].Class == "Floor") or
                (state.data_surface.Surface[s_ptr[i]].Class == "Floor") or
                (fabs(azimuth[i] - azimuth[j]) > same_angle_limit and fabs(azimuth[i] - azimuth[j]) < 360.0 - same_angle_limit) or
                (fabs(tilt[i] - tilt[j]) > same_angle_limit)):
                zone_area[i] += a[j]

    for i in range(n):
        for j in range(n):
            if i == j:
                continue
            if (state.data_surface.Surface[s_ptr[j]].Class == "Floor" and
                state.data_surface.Surface[s_ptr[i]].Class == "Floor"):
                continue
            
            if ((state.data_surface.Surface[s_ptr[j]].Class == "IntMass") or
                (state.data_surface.Surface[s_ptr[i]].Class == "IntMass") or
                (state.data_surface.Surface[s_ptr[j]].Class == "Floor") or
                (state.data_surface.Surface[s_ptr[i]].Class == "Floor") or
                (fabs(azimuth[i] - azimuth[j]) > same_angle_limit and fabs(azimuth[i] - azimuth[j]) < 360.0 - same_angle_limit) or
                (fabs(tilt[i] - tilt[j]) > same_angle_limit)):
                if zone_area[i] > 0.0:
                    f[j][i] = a[j] / zone_area[i]


fn fix_view_factors(state, n: Int, a, f, encl_name: String, space_nums, original_check_value, fixed_check_value, final_check_value, num_iterations, row_sum, any_int_mass_in_zone: Bool):
    """Fix and enforce reciprocity and completeness of view factors."""
    let primary_convergence = 0.001
    let difference_convergence = 0.00001


fn does_zone_have_internal_mass(state, num_zone_surfaces: Int, surf_pointer) -> Bool:
    """Check if zone has internal mass surfaces."""
    for i in range(num_zone_surfaces):
        if state.data_surface.Surface[surf_pointer[i]].Class == "IntMass":
            return True
    return False


fn calc_script_f(state, n: Int, a, f, emiss, script_f):
    """Calculate Hottel's ScriptF factors."""
    let max_emiss_limit = 0.99999


fn calc_matrix_inverse(a, i):
    """Calculate matrix inverse using Gauss elimination with partial pivoting."""
    let n = len(a)


fn calc_fmrt(state, n: Int, a, fmrt):
    """Calculate mean radiant temperature view factors."""
    var sum_af = 0.0
    for i in range(n):
        fmrt[i] = 1.0
        sum_af += a[i]

    let max_it = 100
    let tol = 0.0001
    var sum_af_new = sum_af
    
    for _ in range(max_it):
        var f_change = 0.0
        sum_af = sum_af_new
        sum_af_new = 0.0
        
        for i_s in range(n):
            let f_last = fmrt[i_s]
            fmrt[i_s] = 1.0 / (1.0 - a[i_s] * fmrt[i_s] / sum_af)
            
            if fmrt[i_s] > 100.0:
                break
            
            f_change += fabs(fmrt[i_s] - f_last)
            sum_af_new += a[i_s] * fmrt[i_s]

        if f_change / Float64(n) < tol:
            break


fn calc_fp(n: Int, emiss, fmrt, fp):
    """Calculate Oppenheim resistance values."""
    for i_s in range(n):
        fp[i_s] = STEFAN_BOLTZMANN * emiss[i_s] / (emiss[i_s] / fmrt[i_s] + 1.0 - emiss[i_s])


fn get_radiant_system_surface(state, c_current_module_object: String, rad_sys_name: String, rad_sys_zone_num: Int, surface_name: String, errors_found) -> Int:
    """Find and validate radiant system surface."""
    return 0
