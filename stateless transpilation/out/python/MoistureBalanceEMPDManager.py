from typing import Protocol, List, Any, Optional
from dataclasses import dataclass, field
import math

# EXTERNAL DEPS (to wire in glue):
# - Material::MaterialBase, Material::Group, GetMaterialNum from Material.py
# - Psychrometrics: PsyPsatFnTemp, PsyRhovFnTdbRh, PsyRhovFnTdbWPb_fast, PsyRhFnTdbRhov,
#   PsyRhFnTdbWPb, PsyRhoAirFnPbTdbW, PsyRhovFnTdbWPb, PsyWFnTdbRhPb, PsyCpAirFnW
#   from Psychrometrics.py
# - DataMoistureBalanceEMPD.Lam constant from DataMoistureBalanceEMPD.py
# - Constant: Kelvin, Units, AutoCalculate, Pi from Constant.py
# - Construction.Construct class from Construction.py
# - DataEnvironment, DataSurfaces, DataHeatBalance, DataMoistureBalance structs
# - OutputProcessor.SetupOutputVariable, OutputProcessor.TimeStepType, OutputProcessor.StoreType
# - InputProcessor functions from InputProcessor.py
# - General.ScanForReports from General.py
# - Error functions: ShowSevereError, ShowContinueError, ShowMessage, ShowWarningError,
#   ShowFatalError, ShowSevereItemNotFound, ShowSevereCustom, ErrorObjectHeader
# - EnergyPlusData main state object


@dataclass
class MaterialBase:
    group: Optional[int] = None
    Name: str = ""
    ROnly: bool = False
    Density: float = 0.0
    hasEMPD: bool = False


@dataclass
class MaterialEMPD(MaterialBase):
    mu: float = 0.0
    moist_a_coeff: float = 0.0
    moist_b_coeff: float = 0.0
    moist_c_coeff: float = 0.0
    moist_d_coeff: float = 0.0
    surface_depth: float = 0.0
    deep_depth: float = 0.0
    coating_thickness: float = 0.0
    mu_coating: float = 0.0

    def __post_init__(self):
        if self.group is None:
            self.group = 0  # Material::Group::Regular

    def calc_depth_from_period(self, state: Any, period: float) -> float:
        T = 24.0
        RH = 0.45
        P_amb = 101325.0

        PV_sat = state.psychrometrics_PsyPsatFnTemp(state, T, "CalcDepthFromPeriod")

        slope_MC = (self.moist_a_coeff * self.moist_b_coeff * (RH ** (self.moist_b_coeff - 1)) +
                    self.moist_c_coeff * self.moist_d_coeff * (RH ** (self.moist_d_coeff - 1)))

        diffusivity_air = 2.0e-7 * ((T + 273.15) ** 0.81) / P_amb

        empd_diffusivity = diffusivity_air / self.mu

        return math.sqrt(empd_diffusivity * PV_sat * period / (self.Density * slope_MC * math.pi))


@dataclass
class EMPDReportVarsData:
    rv_surface: float = 0.015
    RH_surface_layer: float = 0.0
    RH_deep_layer: float = 0.0
    w_surface_layer: float = 0.015
    w_deep_layer: float = 0.015
    mass_flux_zone: float = 0.0
    mass_flux_deep: float = 0.0
    u_surface_layer: float = 0.0
    u_deep_layer: float = 0.0


def get_moisture_balance_empd_input(state: Any) -> None:
    routine_name = "GetMoistureBalanceEMPDInput"

    material_names = [""] * 3
    material_num_alpha = 0
    material_num_prop = 0
    material_props = [0.0] * 9
    errors_found = False

    s_ip = state.dataInputProcessing.inputProcessor
    s_ipsc = state.dataIPShortCut
    s_mat = state.dataMaterial

    s_ipsc.cCurrentModuleObject = "MaterialProperty:MoisturePenetrationDepth:Settings"
    empd_mat = s_ip.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)

    if empd_mat == 0:
        state.show_severe_error(
            f"EMPD Solution requested, but no \"{s_ipsc.cCurrentModuleObject}\" objects were found."
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

        eoh = state.ErrorObjectHeader(routine_name, s_ipsc.cCurrentModuleObject, material_names[0])

        mat_num = state.material_GetMaterialNum(state, material_names[0])
        if mat_num == 0:
            state.show_severe_item_not_found(state, eoh, s_ipsc.cAlphaFieldNames[0], material_names[0])
            errors_found = True
            continue

        mat = s_mat.materials[mat_num - 1]
        if mat.group != 0 or mat.ROnly:
            state.show_severe_custom(
                state,
                eoh,
                "Reference Material is not appropriate type for EMPD properties, must have regular properties (L,Cp,K,D)",
            )
            errors_found = True
            continue

        mat_empd = MaterialEMPD()
        for attr in ["group", "Name", "ROnly", "Density"]:
            if hasattr(mat, attr):
                setattr(mat_empd, attr, getattr(mat, attr))

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
                f"{s_ipsc.cCurrentModuleObject}: material=\"{mat_empd.Name}\""
            )
            state.show_continue_error(
                "Deep-layer penetration depth should be zero or greater than the surface-layer penetration depth."
            )

    empd_zone = [False] * state.dataGlobal.NumOfZones

    for surf_num in range(1, state.dataSurface.TotSurfaces + 1):
        surf = state.dataSurface.Surface[surf_num - 1]
        if not surf.HeatTransSurf or surf.Class == 5:
            continue
        if surf.HeatTransferAlgorithm != 2:
            continue

        constr = state.dataConstruction.Construct[surf.Construction - 1]
        mat = s_mat.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]

        if isinstance(mat, MaterialEMPD) and mat.mu > 0.0 and surf.Zone > 0:
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
                    f"GetMoistureBalanceEMPDInput: EMPD properties are not assigned to the inside layer in Surface={surf.Name}",
                )
                state.show_continue_error(state, f"with Construction={constr.Name}")

        if constr.TotLayers == 1:
            continue

        mat1 = s_mat.materials[constr.LayerPoint[0] - 1]
        if mat1.hasEMPD and surf.ExtBoundCond <= 0:
            state.show_severe_error(
                f"{routine_name}: EMPD properties are assigned to the outside layer in Construction = {constr.Name}"
            )
            state.show_continue_error(f"..Outside layer material with EMPD properties = {mat1.Name}")
            state.show_continue_error(
                "..A material with EMPD properties must be assigned to the inside layer of a construction."
            )
            errors_found = True
            continue

        for layer in range(2, constr.TotLayers):
            mat_l = s_mat.materials[constr.LayerPoint[layer - 1] - 1]
            if mat_l.hasEMPD:
                state.show_severe_error(
                    f"{routine_name}: EMPD properties are assigned to a middle layer in Construction = {constr.Name}"
                )
                state.show_continue_error(f"..Middle layer material with EMPD properties = {mat_l.Name}")
                state.show_continue_error(
                    "..A material with EMPD properties must be assigned to the inside layer of a construction."
                )
                errors_found = True

    for loop in range(1, state.dataGlobal.NumOfZones + 1):
        if not empd_zone[loop - 1]:
            state.show_severe_error(
                f"{routine_name}: None of the constructions for zone = {state.dataHeatBal.Zone[loop - 1].Name} has an inside layer with EMPD properties"
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


def init_moisture_balance_empd(state: Any) -> None:
    if state.dataMoistureBalEMPD.InitEnvrnFlag:
        state.dataMstBalEMPD.RVSurfaceOld = [0.0] * state.dataSurface.TotSurfaces
        state.dataMstBalEMPD.RVSurface = [0.0] * state.dataSurface.TotSurfaces
        state.dataMstBalEMPD.HeatFluxLatent = [0.0] * state.dataSurface.TotSurfaces
        state.dataMoistureBalEMPD.EMPDReportVars = [EMPDReportVarsData() for _ in range(state.dataSurface.TotSurfaces)]
        state.dataMstBalEMPD.RVSurfLayer = [0.0] * state.dataSurface.TotSurfaces
        state.dataMstBalEMPD.RVSurfLayerOld = [0.0] * state.dataSurface.TotSurfaces
        state.dataMstBalEMPD.RVDeepLayer = [0.0] * state.dataSurface.TotSurfaces
        state.dataMstBalEMPD.RVdeepOld = [0.0] * state.dataSurface.TotSurfaces
        state.dataMstBalEMPD.RVwall = [0.0] * state.dataSurface.TotSurfaces

    for surf_num in range(1, state.dataSurface.TotSurfaces + 1):
        zone_num = state.dataSurface.Surface[surf_num - 1].Zone
        if not state.dataSurface.Surface[surf_num - 1].HeatTransSurf:
            continue

        rv_air_in_initval = min(
            state.psychrometrics_PsyRhovFnTdbWPb_fast(
                state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].MAT,
                max(state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].airHumRat, 1.0e-5),
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

        rvd = state.dataMoistureBalEMPD.EMPDReportVars[surf_num - 1]
        surf_name = state.dataSurface.Surface[surf_num - 1].Name

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


def calc_moisture_balance_empd(
    state: Any,
    surf_num: int,
    surf_temp_in: float,
    temp_zone: float,
) -> float:
    routine_name = "CalcMoistureEMPD"

    s_mat = state.dataMaterial

    if state.dataGlobal.BeginEnvrnFlag and state.dataMoistureBalEMPD.OneTimeFlag:
        init_moisture_balance_empd(state)
        state.dataMoistureBalEMPD.OneTimeFlag = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataMoistureBalEMPD.OneTimeFlag = True

    surface = state.dataSurface.Surface[surf_num - 1]
    rv_surface = state.dataMstBalEMPD.RVSurface[surf_num - 1]
    rv_surface_old = state.dataMstBalEMPD.RVSurfaceOld[surf_num - 1]
    h_mass_conv_in_fd = state.dataMstBal.HMassConvInFD[surf_num - 1]
    rho_vapor_air_in = state.dataMstBal.RhoVaporAirIn[surf_num - 1]

    heat_flux_latent = 0.0

    if not surface.HeatTransSurf:
        return 0.0

    constr = state.dataConstruction.Construct[surface.Construction - 1]
    mat = s_mat.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]
    assert isinstance(mat, MaterialEMPD)

    if mat.mu <= 0.0:
        return state.psychrometrics_PsyRhovFnTdbWPb(
            temp_zone,
            state.dataZoneTempPredictorCorrector.zoneHeatBalance[surface.Zone - 1].airHumRat,
            state.dataEnvrn.OutBaroPress,
        )

    taver = surf_temp_in
    rva_ver = rv_surface_old
    rhaver = rva_ver * 461.52 * (taver + 273.15) * math.exp(-23.7093 + 4111.0 / (taver + 237.7))

    pvsat = state.psychrometrics_PsyPsatFnTemp(state, taver, routine_name)
    pvsurf = rhaver * math.exp(23.7093 - 4111.0 / (taver + 237.7))
    temp_sat = 4111.0 / (23.7093 - math.log(pvsurf)) + 35.45 - 273.15

    empd_diffusivity = (2.0e-7 * pow(taver + 273.15, 0.81) / state.dataEnvrn.OutBaroPress) / mat.mu * 461.52 * (taver + 273.15)

    dU_dRH = (mat.moist_a_coeff * mat.moist_b_coeff * pow(rhaver, mat.moist_b_coeff - 1) +
              mat.moist_c_coeff * mat.moist_d_coeff * pow(rhaver, mat.moist_d_coeff - 1))

    rhzone = rho_vapor_air_in * 461.52 * (temp_zone + 273.15) * math.exp(-23.7093 + 4111.0 / ((temp_zone + 273.15) - 35.45))

    rh_deep_layer_old = state.psychrometrics_PsyRhFnTdbRhov(state, taver, state.dataMstBalEMPD.RVdeepOld[surf_num - 1])
    rh_surf_layer_old = state.psychrometrics_PsyRhFnTdbRhov(state, taver, state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1])

    if mat.mu_coating <= 0.0:
        rcoating = 0.0
    else:
        rcoating = (mat.coating_thickness * mat.mu_coating * state.dataEnvrn.OutBaroPress /
                    (2.0e-7 * pow(taver + 273.15, 0.81) * 461.52 * (taver + 273.15)))

    hm_surf_layer = 1.0 / (0.5 * mat.surface_depth / empd_diffusivity + 1.0 / h_mass_conv_in_fd + rcoating)

    if mat.deep_depth <= 0.0:
        hm_deep_layer = 0.0
    else:
        hm_deep_layer = 2.0 * empd_diffusivity / (mat.deep_depth + mat.surface_depth)

    rsurface_layer = 1.0 / hm_surf_layer - 1.0 / h_mass_conv_in_fd

    mass_flux_surf_deep_max = (mat.deep_depth * mat.Density * dU_dRH * 
                               (rh_surf_layer_old - rh_deep_layer_old) / (state.dataGlobal.TimeStepZone * 3600.0))
    mass_flux_surf_deep = hm_deep_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - state.dataMstBalEMPD.RVdeepOld[surf_num - 1])
    if abs(mass_flux_surf_deep_max) < abs(mass_flux_surf_deep):
        mass_flux_surf_deep = mass_flux_surf_deep_max

    mass_flux_zone_surf_max = (mat.surface_depth * mat.Density * dU_dRH * 
                               (rhzone - rh_surf_layer_old) / (state.dataGlobal.TimeStepZone * 3600.0))
    mass_flux_zone_surf = hm_surf_layer * (rho_vapor_air_in - state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1])
    if abs(mass_flux_zone_surf_max) < abs(mass_flux_zone_surf):
        mass_flux_zone_surf = mass_flux_zone_surf_max

    mass_flux_surf_layer = (hm_surf_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - rho_vapor_air_in) + 
                            hm_deep_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - state.dataMstBalEMPD.RVdeepOld[surf_num - 1]))
    mass_flux_deep_layer = hm_deep_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - state.dataMstBalEMPD.RVdeepOld[surf_num - 1])
    mass_flux_zone = hm_surf_layer * (state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] - rho_vapor_air_in)

    rh_surf_layer_tmp = (rh_surf_layer_old + 
                         state.dataGlobal.TimeStepZone * 3600.0 * 
                         (-mass_flux_surf_layer / (mat.Density * mat.surface_depth * dU_dRH)))

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

    if mat.deep_depth <= 0.0:
        rh_deep_layer = rh_deep_layer_old
    else:
        rh_deep_layer = (rh_deep_layer_old + 
                         state.dataGlobal.TimeStepZone * 3600.0 * 
                         mass_flux_deep_layer / (mat.Density * mat.deep_depth * dU_dRH))

    state.dataMstBalEMPD.RVSurfLayer[surf_num - 1] = state.psychrometrics_PsyRhovFnTdbRh(state, taver, rh_surf_layer)
    state.dataMstBalEMPD.RVDeepLayer[surf_num - 1] = state.psychrometrics_PsyRhovFnTdbRh(state, taver, rh_deep_layer)

    pv_surf_layer = rh_surf_layer * math.exp(23.7093 - 4111.0 / (taver + 237.7))
    pv_deep_layer = rh_deep_layer * math.exp(23.7093 - 4111.0 / (taver + 237.7))

    rv_surface = state.dataMstBalEMPD.RVSurfLayer[surf_num - 1] - mass_flux_zone * rsurface_layer
    state.dataMstBalEMPD.RVSurface[surf_num - 1] = rv_surface

    heat_flux_latent = mass_flux_zone * state.dataMoistureBalanceEMPD.Lam

    rvd = state.dataMoistureBalEMPD.EMPDReportVars[surf_num - 1]
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


def update_moisture_balance_empd(state: Any, surf_num: int) -> None:
    state.dataMstBalEMPD.RVSurfaceOld[surf_num - 1] = state.dataMstBalEMPD.RVSurface[surf_num - 1]
    state.dataMstBalEMPD.RVdeepOld[surf_num - 1] = state.dataMstBalEMPD.RVDeepLayer[surf_num - 1]
    state.dataMstBalEMPD.RVSurfLayerOld[surf_num - 1] = state.dataMstBalEMPD.RVSurfLayer[surf_num - 1]


def report_moisture_balance_empd(state: Any) -> None:
    do_report = state.general_ScanForReports(state, "Constructions", "Constructions")

    if not do_report:
        return

    state.print_eio(
        "! <Construction EMPD>, Construction Name, Inside Layer Material Name, Vapor Resistance Factor, a, b, "
        "c, d, Surface Penetration Depth {m}, Deep Penetration Depth {m}, Coating Vapor Resistance Factor, "
        "Coating Thickness {m}\n"
    )

    for constr_num in range(1, state.dataHeatBal.TotConstructs + 1):
        constr = state.dataConstruction.Construct[constr_num - 1]
        if constr.TypeIsWindow:
            continue

        mat = state.dataMaterial.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]
        if not mat.hasEMPD:
            continue

        assert isinstance(mat, MaterialEMPD)

        state.print_eio(
            f" Construction EMPD, {constr.Name}, {mat.Name}, {mat.mu:8.4f}, {mat.moist_a_coeff:8.4f}, "
            f"{mat.moist_b_coeff:8.4f}, {mat.moist_c_coeff:8.4f}, {mat.moist_d_coeff:8.4f}, {mat.surface_depth:8.4f}, "
            f"{mat.deep_depth:8.4f}, {mat.mu_coating:8.4f}, {mat.coating_thickness:8.4f}\n"
        )
