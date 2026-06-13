from math import sqrt, pow, exp, log, fabs, pi
from collections import Dict


# EXTERNAL DEPS (to wire in glue):
# - Material::MaterialBase struct from Material module
# - Psychrometrics functions: PsyPsatFnTemp, PsyRhovFnTdbRh, PsyRhovFnTdbWPb_fast,
#   PsyRhFnTdbRhov, PsyRhFnTdbWPb, PsyRhoAirFnPbTdbW, PsyRhovFnTdbWPb, PsyWFnTdbRhPb,
#   PsyCpAirFnW from Psychrometrics module
# - DataMoistureBalanceEMPD.Lam constant
# - Constant definitions: Kelvin, Units, AutoCalculate, Pi
# - Construction struct from Construction module
# - DataEnvironment, DataSurfaces, DataHeatBalance, DataMoistureBalance structs
# - OutputProcessor functions: SetupOutputVariable, TimeStepType, StoreType
# - InputProcessor functions
# - General functions: ScanForReports
# - Material functions: GetMaterialNum
# - Error reporting functions
# - EnergyPlusData main state struct


struct MaterialBase:
    var group: Int
    var Name: String
    var ROnly: Bool
    var Density: Float64
    var hasEMPD: Bool

    fn __init__(inout self):
        self.group = 0
        self.Name = ""
        self.ROnly = False
        self.Density = 0.0
        self.hasEMPD = False


struct MaterialEMPD(MaterialBase):
    var mu: Float64
    var moist_a_coeff: Float64
    var moist_b_coeff: Float64
    var moist_c_coeff: Float64
    var moist_d_coeff: Float64
    var surface_depth: Float64
    var deep_depth: Float64
    var coating_thickness: Float64
    var mu_coating: Float64

    fn __init__(inout self):
        MaterialBase.__init__(self)
        self.mu = 0.0
        self.moist_a_coeff = 0.0
        self.moist_b_coeff = 0.0
        self.moist_c_coeff = 0.0
        self.moist_d_coeff = 0.0
        self.surface_depth = 0.0
        self.deep_depth = 0.0
        self.coating_thickness = 0.0
        self.mu_coating = 0.0

    fn calc_depth_from_period(self, state: AnyType, period: Float64) -> Float64:
        let T = 24.0
        let RH = 0.45
        let P_amb = 101325.0

        let PV_sat = state.psychrometrics_PsyPsatFnTemp(state, T, "CalcDepthFromPeriod")

        let slope_MC = (self.moist_a_coeff * self.moist_b_coeff * pow(RH, self.moist_b_coeff - 1) +
                        self.moist_c_coeff * self.moist_d_coeff * pow(RH, self.moist_d_coeff - 1))

        let diffusivity_air = 2.0e-7 * pow(T + 273.15, 0.81) / P_amb

        let empd_diffusivity = diffusivity_air / self.mu

        return sqrt(empd_diffusivity * PV_sat * period / (self.Density * slope_MC * pi))


struct EMPDReportVarsData:
    var rv_surface: Float64
    var RH_surface_layer: Float64
    var RH_deep_layer: Float64
    var w_surface_layer: Float64
    var w_deep_layer: Float64
    var mass_flux_zone: Float64
    var mass_flux_deep: Float64
    var u_surface_layer: Float64
    var u_deep_layer: Float64

    fn __init__(inout self):
        self.rv_surface = 0.015
        self.RH_surface_layer = 0.0
        self.RH_deep_layer = 0.0
        self.w_surface_layer = 0.015
        self.w_deep_layer = 0.015
        self.mass_flux_zone = 0.0
        self.mass_flux_deep = 0.0
        self.u_surface_layer = 0.0
        self.u_deep_layer = 0.0


fn get_moisture_balance_empd_input(state: AnyType) -> None:
    let routine_name = "GetMoistureBalanceEMPDInput"

    var material_names = List[String]()
    material_names.append("")
    material_names.append("")
    material_names.append("")

    var material_num_alpha = 0
    var material_num_prop = 0

    var material_props = List[Float64]()
    for _ in range(9):
        material_props.append(0.0)

    var errors_found = False

    let s_ip = state.dataInputProcessing.inputProcessor
    let s_ipsc = state.dataIPShortCut
    let s_mat = state.dataMaterial

    s_ipsc.cCurrentModuleObject = "MaterialProperty:MoisturePenetrationDepth:Settings"
    let empd_mat = s_ip.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)

    if empd_mat == 0:
        state.show_severe_error(
            "EMPD Solution requested, but no \"" + s_ipsc.cCurrentModuleObject + "\" objects were found."
        )
        errors_found = True

    for loop in range(1, empd_mat + 1):
        s_ip.getObjectItem(
            state,
            s_ipsc.cCurrentModuleObject,
            loop,
            material_names,
            material_num_alpha,
            material_props,
            material_num_prop,
            s_ipsc.lNumericFieldBlanks,
            s_ipsc.lAlphaFieldBlanks,
            s_ipsc.cAlphaFieldNames,
            s_ipsc.cNumericFieldNames,
        )

        let eoh = state.ErrorObjectHeader(routine_name, s_ipsc.cCurrentModuleObject, material_names[0])

        let mat_num = state.material_GetMaterialNum(state, material_names[0])
        if mat_num == 0:
            state.show_severe_item_not_found(state, eoh, s_ipsc.cAlphaFieldNames[0], material_names[0])
            errors_found = True
            continue

        var mat = s_mat.materials[mat_num - 1]
        if mat.group != 0 or mat.ROnly:
            state.show_severe_custom(
                state,
                eoh,
                "Reference Material is not appropriate type for EMPD properties, must have regular properties (L,Cp,K,D)",
            )
            errors_found = True
            continue

        var mat_empd = MaterialEMPD()
        mat_empd.group = mat.group
        mat_empd.Name = mat.Name
        mat_empd.ROnly = mat.ROnly
        mat_empd.Density = mat.Density

        s_mat.materials[mat_num - 1] = mat_empd
        mat_empd.hasEMPD = True

        mat_empd.mu = material_props[0]
        mat_empd.moist_a_coeff = material_props[1]
        mat_empd.moist_b_coeff = material_props[2]
        mat_empd.moist_c_coeff = material_props[3]
        mat_empd.moist_d_coeff = material_props[4]

        if s_ipsc.lNumericFieldBlanks[5] or material_props[5] == state.Constant.AutoCalculate:
            mat_empd.surface_depth = mat_empd.calc_depth_from_period(state, 24 * 3600)
        else:
            mat_empd.surface_depth = material_props[5]

        if s_ipsc.lNumericFieldBlanks[6] or material_props[6] == state.Constant.AutoCalculate:
            mat_empd.deep_depth = mat_empd.calc_depth_from_period(state, 21 * 24 * 3600)
        else:
            mat_empd.deep_depth = material_props[6]

        mat_empd.coating_thickness = material_props[7]
        mat_empd.mu_coating = material_props[8]

        if mat_empd.deep_depth <= mat_empd.surface_depth and mat_empd.deep_depth != 0.0:
            state.show_warning_error(
                s_ipsc.cCurrentModuleObject + ": material=\"" + mat_empd.Name + "\""
            )
            state.show_continue_error(
                "Deep-layer penetration depth should be zero or greater than the surface-layer penetration depth."
            )

    var empd_zone = List[Bool]()
    for _ in range(state.dataGlobal.NumOfZones):
        empd_zone.append(False)

    for surf_num in range(1, state.dataSurface.TotSurfaces + 1):
        let surf = state.dataSurface.Surface[surf_num - 1]
        if not surf.HeatTransSurf or surf.Class == 5:
            continue
        if surf.HeatTransferAlgorithm != 2:
            continue

        let constr = state.dataConstruction.Construct[surf.Construction - 1]
        let mat = s_mat.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]

        if _is_material_empd(mat) and mat.mu > 0.0 and surf.Zone > 0:
            empd_zone[surf.Zone - 1] = True
        else:
            state.dataMoistureBalEMPD.ErrCount += 1
            if state.dataMoistureBalEMPD.ErrCount == 1 and not state.dataGlobal.DisplayExtraWarnings:
                state.show_message(
                    state,
                    "GetMoistureBalanceEMPDInput: EMPD properties are not assigned to the inside layer of Surfaces",
                )
                state.show_continue_error(
                    state,
                    "...use Output:Diagnostics,DisplayExtraWarnings; to show more details on individual surfaces.",
                )
            if state.dataGlobal.DisplayExtraWarnings:
                state.show_message(
                    state,
                    "GetMoistureBalanceEMPDInput: EMPD properties are not assigned to the inside layer in Surface=" + surf.Name,
                )
                state.show_continue_error(state, "with Construction=" + constr.Name)

        if constr.TotLayers == 1:
            continue

        let mat1 = s_mat.materials[constr.LayerPoint[0] - 1]
        if mat1.hasEMPD and surf.ExtBoundCond <= 0:
            state.show_severe_error(
                routine_name + ": EMPD properties are assigned to the outside layer in Construction = " + constr.Name
            )
            state.show_continue_error("..Outside layer material with EMPD properties = " + mat1.Name)
            state.show_continue_error(
                "..A material with EMPD properties must be assigned to the inside layer of a construction."
            )
            errors_found = True
            continue

        for layer in range(2, constr.TotLayers):
            let mat_l = s_mat.materials[constr.LayerPoint[layer - 1] - 1]
            if mat_l.hasEMPD:
                state.show_severe_error(
                    routine_name + ": EMPD properties are assigned to a middle layer in Construction = " + constr.Name
                )
                state.show_continue_error("..Middle layer material with EMPD properties = " + mat_l.Name)
                state.show_continue_error(
                    "..A material with EMPD properties must be assigned to the inside layer of a construction."
                )
                errors_found = True

    for loop in range(1, state.dataGlobal.NumOfZones + 1):
        if not empd_zone[loop - 1]:
            state.show_severe_error(
                routine_name + ": None of the constructions for zone = " + state.dataHeatBal.Zone[loop - 1].Name + " has an inside layer with EMPD properties"
            )
            state.show_continue_error(
                "..For each zone, the inside layer of at least one construction must have EMPD properties"
            )
            errors_found = True

    report_moisture_balance_empd(state)

    if errors_found:
        state.show_fatal_error(
            "GetMoistureBalanceEMPDInput: Errors found getting EMPD material properties, program terminated."
        )


@always_inline
fn _is_material_empd(mat: AnyType) -> Bool:
    return isinstance(mat, MaterialEMPD)


fn init_moisture_balance_empd(state: AnyType) -> None:
    if state.dataMoistureBalEMPD.InitEnvrnFlag:
        state.dataMstBalEMPD.RVSurfaceOld = List[Float64]()
        state.dataMstBalEMPD.RVSurface = List[Float64]()
        state.dataMstBalEMPD.HeatFluxLatent = List[Float64]()
        state.dataMstBalEMPD.RVSurfLayer = List[Float64]()
        state.dataMstBalEMPD.RVSurfLayerOld = List[Float64]()
        state.dataMstBalEMPD.RVDeepLayer = List[Float64]()
        state.dataMstBalEMPD.RVdeepOld = List[Float64]()
        state.dataMstBalEMPD.RVwall = List[Float64]()

        for _ in range(state.dataSurface.TotSurfaces):
            state.dataMstBalEMPD.RVSurfaceOld.append(0.0)
            state.dataMstBalEMPD.RVSurface.append(0.0)
            state.dataMstBalEMPD.HeatFluxLatent.append(0.0)
            state.dataMstBalEMPD.RVSurfLayer.append(0.0)
            state.dataMstBalEMPD.RVSurfLayerOld.append(0.0)
            state.dataMstBalEMPD.RVDeepLayer.append(0.0)
            state.dataMstBalEMPD.RVdeepOld.append(0.0)
            state.dataMstBalEMPD.RVwall.append(0.0)

        var empd_report_vars = List[EMPDReportVarsData]()
        for _ in range(state.dataSurface.TotSurfaces):
            empd_report_vars.append(EMPDReportVarsData())
        state.dataMoistureBalEMPD.EMPDReportVars = empd_report_vars

    for surf_num in range(1, state.dataSurface.TotSurfaces + 1):
        let zone_num = state.dataSurface.Surface[surf_num - 1].Zone
        if not state.dataSurface.Surface[surf_num - 1].HeatTransSurf:
            continue

        let rv_air_in_initval = _min(
            state.psychrometrics_PsyRhovFnTdbWPb_fast(
                state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].MAT,
                _max(state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].airHumRat, 1.0e-5),
                state.dataEnvrn.OutBaroPress,
            ),
            state.psychrometrics_PsyRhovFnTdbRh(
                state,
                state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].MAT,
                1.0,
                "InitMoistureBalanceEMPD",
            ),
        )
        state.dataMstBalEMPD.RVSurfaceOld[surf_num - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVSurface[surf_num - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVSurfLayer[surf_num - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVDeepLayer[surf_num - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVdeepOld[surf_num - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVwall[surf_num - 1] = rv_air_in_initval

    if not state.dataMoistureBalEMPD.InitEnvrnFlag:
        return

    get_moisture_balance_empd_input(state)

    for surf_num in range(1, state.dataSurface.TotSurfaces + 1):
        if not state.dataSurface.Surface[surf_num - 1].HeatTransSurf:
            continue
        if state.dataSurface.Surface[surf_num - 1].Class == 5:
            continue

        var rvd = state.dataMoistureBalEMPD.EMPDReportVars[surf_num - 1]
        let surf_name = state.dataSurface.Surface[surf_num - 1].Name

        state.setup_output_variable(
            state,
            "EMPD Surface Inside Face Water Vapor Density",
            "kg/m3",
            rvd.rv_surface,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Surface Layer Moisture Content",
            "kg/m3",
            rvd.u_surface_layer,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Deep Layer Moisture Content",
            "kg/m3",
            rvd.u_deep_layer,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Surface Layer Equivalent Relative Humidity",
            "%",
            rvd.RH_surface_layer,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Deep Layer Equivalent Relative Humidity",
            "%",
            rvd.RH_deep_layer,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Surface Layer Equivalent Humidity Ratio",
            "kgWater/kgDryAir",
            rvd.w_surface_layer,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Deep Layer Equivalent Humidity Ratio",
            "kgWater/kgDryAir",
            rvd.w_deep_layer,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Surface Moisture Flux to Zone",
            "kg/m2s",
            rvd.mass_flux_zone,
            "Zone",
            "Average",
            surf_name,
        )
        state.setup_output_variable(
            state,
            "EMPD Deep Layer Moisture Flux",
            "kg/m2s",
            rvd.mass_flux_deep,
            "Zone",
            "Average",
            surf_name,
        )

    if state.dataMoistureBalEMPD.InitEnvrnFlag:
        state.dataMoistureBalEMPD.InitEnvrnFlag = False


fn calc_moisture_balance_empd(
    state: AnyType,
    surf_num: Int,
    surf_temp_in: Float64,
    temp_zone: Float64,
) -> Float64:
    let routine_name = "CalcMoistureEMPD"

    let s_mat = state.dataMaterial

    if state.dataGlobal.BeginEnvrnFlag and state.dataMoistureBalEMPD.OneTimeFlag:
        init_moisture_balance_empd(state)
        state.dataMoistureBalEMPD.OneTimeFlag = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataMoistureBalEMPD.OneTimeFlag = True

    let surface = state.dataSurface.Surface[surf_num - 1]
    var rv_surface = state.dataMstBalEMPD.RVSurface[surf_num - 1]
    let rv_surface_old = state.dataMstBalEMPD.RVSurfaceOld[surf_num - 1]
    let h_mass_conv_in_fd = state.dataMstBal.HMassConvInFD[surf_num - 1]
    let rho_vapor_air_in = state.dataMstBal.RhoVaporAirIn[surf_num - 1]

    var heat_flux_latent = 0.0

    if not surface.HeatTransSurf:
        return 0.0

    let constr = state.dataConstruction.Construct[surface.Construction - 1]
    let mat = s_mat.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]

    if not _is_material_empd(mat) or mat.mu <= 0.0:
        return state.psychrometrics_PsyRhovFnTdbWPb(
            temp_zone,
            state.dataZoneTempPredictorCorrector.zoneHeatBalance[surface.Zone - 1].airHumRat,
            state.dataEnvrn.OutBaroPress,
        )

    let taver = surf_temp_in
    let rva_ver = rv_surface_old
    let rhaver = rva_ver * 461.52 * (taver + 273.15) * exp(-23.7093 + 4111.0 / (taver + 237.7))

    let pvsat = state.psychrometrics_PsyPsatFnTemp(state, taver, routine_name)
    let pvsurf = rhaver * exp(23.7093 - 4111.0 / (taver + 237.7))
    let temp_sat = 4111.0 / (23.7093 - log(pvsurf)) + 35.45 - 273.15

    let empd_diffusivity = (2.0e-7 * pow(taver + 273.15, 0.81) / state.dataEnvrn.OutBaroPress) / mat.mu * 461.52 * (taver + 273.15)

    let dU_dRH = (mat.moist_a_coeff * mat.moist_b_coeff * pow(rhaver, mat.moist_b_coeff - 1) +
                  mat.moist_c_coeff * mat.moist_d_coeff * pow(rhaver, mat.moist_d_coeff - 1))

    let rhzone = rho_vapor_air_in * 461.52 * (temp_zone + 273.15) * exp(-23.7093 + 4111.0 / ((temp_zone + 273.15) - 35.45))

    let rh_deep_layer_old = state.psychrometrics_PsyRhFnTdbRhov(state, taver, state.dataMstBalEMPD.RVdeepOld[surf_num - 1])
    let rh_surf_layer_old = state.psychrometrics_PsyRhFnTdbRhov(state, taver, state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1])

    var rcoating: Float64
    if mat.mu_coating <= 0.0:
        rcoating = 0.0
    else:
        rcoating = (mat.coating_thickness * mat.mu_coating * state.dataEnvrn.OutBaroPress /
                    (2.0e-7 * pow(taver + 273.15, 0.81) * 461.52 * (taver + 273.15)))

    let hm_surf_layer = 1.0 / (0.5 * mat.surface_depth / empd_diffusivity + 1.0 / h_mass_conv_in_fd + rcoating)

    var hm_deep_layer: Float64
    if mat.deep_depth <= 0.0:
        hm_deep_layer = 0.0
    else:
        hm_deep_layer = 2.0 * empd_diffusivity / (mat.deep_depth + mat.surface_depth)

    let rsurface_layer = 1.0 / hm_surf_layer - 1.0 / h_mass_conv_in_fd

    let mass_flux_surf_deep_max = (mat.deep_depth * mat.Density * dU_dRH * 
                                   (rh_surf_layer_old - rh_deep_layer_old) / (state.dataGlobal.TimeStepZone * 3600.0))
    var mass_flux_surf_deep = hm_deep_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - state.dataMstBalEMPD.RVdeepOld[surf_num - 1])
    if fabs(mass_flux_surf_deep_max) < fabs(mass_flux_surf_deep):
        mass_flux_surf_deep = mass_flux_surf_deep_max

    let mass_flux_zone_surf_max = (mat.surface_depth * mat.Density * dU_dRH * 
                                   (rhzone - rh_surf_layer_old) / (state.dataGlobal.TimeStepZone * 3600.0))
    var mass_flux_zone_surf = hm_surf_layer * (rho_vapor_air_in - state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1])
    if fabs(mass_flux_zone_surf_max) < fabs(mass_flux_zone_surf):
        mass_flux_zone_surf = mass_flux_zone_surf_max

    let mass_flux_surf_layer = (hm_surf_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - rho_vapor_air_in) + 
                                hm_deep_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - state.dataMstBalEMPD.RVdeepOld[surf_num - 1]))
    let mass_flux_deep_layer = hm_deep_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - state.dataMstBalEMPD.RVdeepOld[surf_num - 1])
    let mass_flux_zone = hm_surf_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - rho_vapor_air_in)

    let rh_surf_layer_tmp = (rh_surf_layer_old + 
                             state.dataGlobal.TimeStepZone * 3600.0 * 
                             (-mass_flux_surf_layer / (mat.Density * mat.surface_depth * dU_dRH)))

    var rh_surf_layer: Float64
    if rh_surf_layer_old < rh_deep_layer_old and rh_surf_layer_old < rhzone:
        if rhzone > rh_deep_layer_old:
            if rh_surf_layer_tmp > rhzone:
                rh_surf_layer = rhzone
            else:
                rh_surf_layer = rh_surf_layer_tmp
        elif rh_surf_layer_tmp > rh_deep_layer_old:
            rh_surf_layer = rh_deep_layer_old
        else:
            rh_surf_layer = rh_surf_layer_tmp
    elif rh_surf_layer_old < rh_deep_layer_old and rh_surf_layer_old > rhzone:
        if rh_surf_layer_tmp > rh_deep_layer_old:
            rh_surf_layer = rh_deep_layer_old
        elif rh_surf_layer_tmp < rhzone:
            rh_surf_layer = rhzone
        else:
            rh_surf_layer = rh_surf_layer_tmp
    elif rh_surf_layer_old > rh_deep_layer_old and rh_surf_layer_old < rhzone:
        if rh_surf_layer_tmp > rhzone:
            rh_surf_layer = rhzone
        elif rh_surf_layer_tmp < rh_deep_layer_old:
            rh_surf_layer = rh_deep_layer_old
        else:
            rh_surf_layer = rh_surf_layer_tmp
    elif rhzone < rh_deep_layer_old:
        if rh_surf_layer_tmp < rhzone:
            rh_surf_layer = rhzone
        else:
            rh_surf_layer = rh_surf_layer_tmp
    elif rh_surf_layer_tmp < rh_deep_layer_old:
        rh_surf_layer = rh_deep_layer_old
    else:
        rh_surf_layer = rh_surf_layer_tmp

    var rh_deep_layer: Float64
    if mat.deep_depth <= 0.0:
        rh_deep_layer = rh_deep_layer_old
    else:
        rh_deep_layer = (rh_deep_layer_old + 
                         state.dataGlobal.TimeStepZone * 3600.0 * 
                         mass_flux_deep_layer / (mat.Density * mat.deep_depth * dU_dRH))

    state.dataMstBalEMPD.RVSurfLayer[surf_num - 1] = state.psychrometrics_PsyRhovFnTdbRh(state, taver, rh_surf_layer)
    state.dataMstBalEMPD.RVDeepLayer[surf_num - 1] = state.psychrometrics_PsyRhovFnTdbRh(state, taver, rh_deep_layer)

    let pv_surf_layer = rh_surf_layer * exp(23.7093 - 4111.0 / (taver + 237.7))
    let pv_deep_layer = rh_deep_layer * exp(23.7093 - 4111.0 / (taver + 237.7))

    rv_surface = state.dataMstBalEMPD.RVSurfLayer[surf_num - 1] - mass_flux_zone * rsurface_layer
    state.dataMstBalEMPD.RVSurface[surf_num - 1] = rv_surface

    heat_flux_latent = mass_flux_zone * state.dataMoistureBalanceEMPD.Lam

    var rvd = state.dataMoistureBalEMPD.EMPDReportVars[surf_num - 1]
    rvd.rv_surface = rv_surface
    rvd.RH_surface_layer = rh_surf_layer * 100.0
    rvd.RH_deep_layer = rh_deep_layer * 100.0
    rvd.w_surface_layer = 0.622 * pv_surf_layer / (state.dataEnvrn.OutBaroPress - pv_surf_layer)
    rvd.w_deep_layer = 0.622 * pv_deep_layer / (state.dataEnvrn.OutBaroPress - pv_deep_layer)
    rvd.mass_flux_zone = mass_flux_zone
    rvd.mass_flux_deep = mass_flux_deep_layer
    rvd.u_surface_layer = (mat.moist_a_coeff * pow(rh_surf_layer, mat.moist_b_coeff) + 
                           mat.moist_c_coeff * pow(rh_surf_layer, mat.moist_d_coeff))
    rvd.u_deep_layer = (mat.moist_a_coeff * pow(rh_deep_layer, mat.moist_b_coeff) + 
                        mat.moist_c_coeff * pow(rh_deep_layer, mat.moist_d_coeff))

    state.dataMstBalEMPD.HeatFluxLatent[surf_num - 1] = heat_flux_latent

    return temp_sat


fn update_moisture_balance_empd(state: AnyType, surf_num: Int) -> None:
    state.dataMstBalEMPD.RVSurfaceOld[surf_num - 1] = state.dataMstBalEMPD.RVSurface[surf_num - 1]
    state.dataMstBalEMPD.RVdeepOld[surf_num - 1] = state.dataMstBalEMPD.RVDeepLayer[surf_num - 1]
    state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] = state.dataMstBalEMPD.RVSurfLayer[surf_num - 1]


fn report_moisture_balance_empd(state: AnyType) -> None:
    let do_report = state.general_ScanForReports(state, "Constructions", "Constructions")

    if not do_report:
        return

    state.print_eio(
        "! <Construction EMPD>, Construction Name, Inside Layer Material Name, Vapor Resistance Factor, a, b, "
        + "c, d, Surface Penetration Depth {m}, Deep Penetration Depth {m}, Coating Vapor Resistance Factor, "
        + "Coating Thickness {m}\n"
    )

    for constr_num in range(1, state.dataHeatBal.TotConstructs + 1):
        let constr = state.dataConstruction.Construct[constr_num - 1]
        if constr.TypeIsWindow:
            continue

        let mat = state.dataMaterial.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]
        if not mat.hasEMPD:
            continue

        if not _is_material_empd(mat):
            continue

        state.print_eio(
            " Construction EMPD, " + constr.Name + ", " + mat.Name + ", " + _fmt(mat.mu, 8, 4) + ", "
            + _fmt(mat.moist_a_coeff, 8, 4) + ", " + _fmt(mat.moist_b_coeff, 8, 4) + ", "
            + _fmt(mat.moist_c_coeff, 8, 4) + ", " + _fmt(mat.moist_d_coeff, 8, 4) + ", "
            + _fmt(mat.surface_depth, 8, 4) + ", " + _fmt(mat.deep_depth, 8, 4) + ", "
            + _fmt(mat.mu_coating, 8, 4) + ", " + _fmt(mat.coating_thickness, 8, 4) + "\n"
        )


@always_inline
fn _min(a: Float64, b: Float64) -> Float64:
    if a < b:
        return a
    return b


@always_inline
fn _max(a: Float64, b: Float64) -> Float64:
    if a > b:
        return a
    return b


@always_inline
fn _fmt(val: Float64, width: Int, precision: Int) -> String:
    return String(val)
