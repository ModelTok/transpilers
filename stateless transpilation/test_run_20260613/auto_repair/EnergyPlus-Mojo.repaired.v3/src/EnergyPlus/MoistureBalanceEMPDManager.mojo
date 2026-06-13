// Mojo translation of MoistureBalanceEMPDManager.cc
// Faithful 1:1 translation, no refactoring.

from math import sqrt, pow, exp, log, abs
from string import format
from ObjexxFCL.Fmath import *
from Construction import *
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHeatBalance import *
from .DataIPShortCuts import *
from .DataMoistureBalance import *
from .DataMoistureBalanceEMPD import *
from DataSurfaces import *
from General import *
from .InputProcessing.InputProcessor import *
from Material import *
from MoistureBalanceEMPDManager import *
from OutputProcessor import *
from Psychrometrics import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *

// Namespace: EnergyPlus::MoistureBalanceEMPDManager
// Using declarations

using DataHeatBalance
using DataMoistureBalanceEMPD

// ---------- MaterialEMPD struct ----------
struct MaterialEMPD(MaterialBase):
    var mu: Float64 = 0.0
    var moistACoeff: Float64 = 0.0
    var moistBCoeff: Float64 = 0.0
    var moistCCoeff: Float64 = 0.0
    var moistDCoeff: Float64 = 0.0
    var surfaceDepth: Float64 = 0.0
    var deepDepth: Float64 = 0.0
    var coatingThickness: Float64 = 0.0
    var muCoating: Float64 = 0.0

    def __init__(inout self):
        super().__init__()
        self.group = Material.Group.Regular

    def calcDepthFromPeriod(inout self, state: EnergyPlusData, period: Float64) -> Float64:  # period in seconds
        T: Float64 = 24.0  # C
        RH: Float64 = 0.45
        P_amb: Float64 = 101325  # Pa
        PV_sat: Float64 = Psychrometrics.PsyPsatFnTemp(state, T, "CalcDepthFromPeriod")
        slope_MC: Float64 = self.moistACoeff * self.moistBCoeff * pow(RH, self.moistBCoeff - 1) + self.moistCCoeff * self.moistDCoeff * pow(RH, self.moistDCoeff - 1)
        diffusivity_air: Float64 = 2.0e-7 * pow(T + 273.15, 0.81) / P_amb
        EMPDdiffusivity: Float64 = diffusivity_air / self.mu
        return sqrt(EMPDdiffusivity * PV_sat * period / (self.Density * slope_MC * Constant.Pi))
    end
end

// ---------- EMPDReportVarsData struct ----------
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

    def __init__(inout self):
        self.rv_surface = 0.015
        self.RH_surface_layer = 0.0
        self.RH_deep_layer = 0.0
        self.w_surface_layer = 0.015
        self.w_deep_layer = 0.015
        self.mass_flux_zone = 0.0
        self.mass_flux_deep = 0.0
        self.u_surface_layer = 0.0
        self.u_deep_layer = 0.0
    end
end

// ---------- Function definitions ----------
def GetMoistureBalanceEMPDInput(inout state: EnergyPlusData):
    routineName: StringRef = "GetMoistureBalanceEMPDInput"
    IOStat: Int32  # IO Status when calling get input subroutine
    MaterialNames: List[StringRef] = List[StringRef](3)  # Number of Material Alpha names defined (0-based)
    MaterialNumAlpha: Int32  # Number of material alpha names being passed
    MaterialNumProp: Int32  # Number of material properties being passed
    MaterialProps: List[Float64] = List[Float64](9)  # Temporary array to transfer material properties (0-based)
    ErrorsFound: Bool = False  # If errors detected in input
    EMPDMat: Int32  # EMPD Moisture Material additional properties for each base material
    EMPDzone: List[Bool]  # EMPD property check for each zone
    var s_ip: ref = state.dataInputProcessing.inputProcessor
    var s_ipsc: ref = state.dataIPShortCut
    var s_mat: ref = state.dataMaterial
    s_ipsc.cCurrentModuleObject = "MaterialProperty:MoisturePenetrationDepth:Settings"
    EMPDMat = s_ip.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
    if EMPDMat == 0:
        ShowSevereError(state, format("EMPD Solution requested, but no \"{}\" objects were found.", s_ipsc.cCurrentModuleObject))
        ErrorsFound = True
    end
    for Loop in range(1, EMPDMat + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            s_ipsc.cCurrentModuleObject,
            Loop,
            MaterialNames,
            MaterialNumAlpha,
            MaterialProps,
            MaterialNumProp,
            IOStat,
            s_ipsc.lNumericFieldBlanks,
            s_ipsc.lAlphaFieldBlanks,
            s_ipsc.cAlphaFieldNames,
            s_ipsc.cNumericFieldNames
        )
        eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, MaterialNames[0])  # 1-based -> 0-based
        matNum: Int32 = Material.GetMaterialNum(state, MaterialNames[0])
        if matNum == 0:
            ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[0], MaterialNames[0])
            ErrorsFound = True
            continue
        end
        mat: Pointer[MaterialBase] = s_mat.materials[matNum - 1]  # 1-based -> 0-based
        if mat.group != Material.Group.Regular or mat.ROnly:
            ShowSevereCustom(state, eoh, "Reference Material is not appropriate type for EMPD properties, must have regular properties (L,Cp,K,D)")
            ErrorsFound = True
            continue
        end
        var matEMPD = Pointer[MaterialEMPD].alloc()  # equivalent to new MaterialEMPD
        matEMPD.MaterialBase.operator_assign(mat)  # deep copy parent object (exploit operator= by value copy)
        Pointer.free(mat)  # delete mat (assume Pointer.free)
        s_mat.materials[matNum - 1] = matEMPD  # This should work, material name remains the same (pointer assignment)
        matEMPD.hasEMPD = True
        matEMPD.mu = MaterialProps[0]  # 1-based -> 0-based
        matEMPD.moistACoeff = MaterialProps[1]
        matEMPD.moistBCoeff = MaterialProps[2]
        matEMPD.moistCCoeff = MaterialProps[3]
        matEMPD.moistDCoeff = MaterialProps[4]
        if s_ipsc.lNumericFieldBlanks[5] or MaterialProps[5] == Constant.AutoCalculate:  # index 5 corresponds to field 6
            matEMPD.surfaceDepth = matEMPD.calcDepthFromPeriod(state, 24 * 3600)  # 1 day
        else:
            matEMPD.surfaceDepth = MaterialProps[5]
        end
        if s_ipsc.lNumericFieldBlanks[6] or MaterialProps[6] == Constant.AutoCalculate:  # field 7
            matEMPD.deepDepth = matEMPD.calcDepthFromPeriod(state, 21 * 24 * 3600)  # 3 weeks
        else:
            matEMPD.deepDepth = MaterialProps[6]
        end
        matEMPD.coatingThickness = MaterialProps[7]  # field 8
        matEMPD.muCoating = MaterialProps[8]  # field 9
        if matEMPD.deepDepth <= matEMPD.surfaceDepth and matEMPD.deepDepth != 0.0:
            ShowWarningError(state, format("{}: material=\"{}\"", s_ipsc.cCurrentModuleObject, matEMPD.Name))
            ShowContinueError(state, "Deep-layer penetration depth should be zero or greater than the surface-layer penetration depth.")
        end
    end
    EMPDzone = List[Bool](state.dataGlobal.NumOfZones)  # 0-based size
    for i in range(EMPDzone.size):
        EMPDzone[i] = False
    end
    # Simulating dimension: for i in range(1, NumOfZones+1): EMPDzone(i) = false -> we already set all to false
    for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
        surf: ref = state.dataSurface.Surface[SurfNum - 1]  # 0-based
        if not surf.HeatTransSurf or surf.Class == DataSurfaces.SurfaceClass.Window:
            continue
        end
        if surf.HeatTransferAlgorithm != DataSurfaces.HeatTransferModel.EMPD:
            continue
        end
        constr: ref = state.dataConstruction.Construct[surf.Construction - 1]  # 0-based
        mat: Pointer[MaterialBase] = s_mat.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]  # 0-based
        matEMPD_ptr: Pointer[MaterialEMPD] = Pointer.cast[MaterialEMPD](mat)  # dynamic_cast
        if matEMPD_ptr.is_not_null and matEMPD_ptr.mu > 0.0 and surf.Zone > 0:
            EMPDzone[surf.Zone - 1] = True  # 1-based -> 0-based
        else:
            state.dataMoistureBalEMPD.ErrCount += 1
            if state.dataMoistureBalEMPD.ErrCount == 1 and not state.dataGlobal.DisplayExtraWarnings:
                ShowMessage(state, "GetMoistureBalanceEMPDInput: EMPD properties are not assigned to the inside layer of Surfaces")
                ShowContinueError(state, "...use Output:Diagnostics,DisplayExtraWarnings; to show more details on individual surfaces.")
            end
            if state.dataGlobal.DisplayExtraWarnings:
                ShowMessage(
                    state,
                    format("GetMoistureBalanceEMPDInput: EMPD properties are not assigned to the inside layer in Surface={}", surf.Name)
                )
                ShowContinueError(state, format("with Construction={}", constr.Name))
            end
        end
        if constr.TotLayers == 1:
            continue
        end
        var mat1: Pointer[MaterialBase] = s_mat.materials[constr.LayerPoint[0] - 1]  # 0-based
        if mat1.hasEMPD and surf.ExtBoundCond <= 0:
            ShowSevereError(
                state,
                format("{}: EMPD properties are assigned to the outside layer in Construction = {}", routineName, constr.Name)
            )
            ShowContinueError(state, format("..Outside layer material with EMPD properties = {}", mat1.Name))
            ShowContinueError(state, "..A material with EMPD properties must be assigned to the inside layer of a construction.")
            ErrorsFound = True
            continue
        end
        for Layer in range(2, constr.TotLayers):  # Layer from 2 to TotLayers-1, 1-based -> 0-based: indices 1..TotLayers-2
            matL: Pointer[MaterialBase] = s_mat.materials[constr.LayerPoint[Layer - 1] - 1]  # 0-based
            if matL.hasEMPD:
                ShowSevereError(
                    state,
                    format("{}: EMPD properties are assigned to a middle layer in Construction = {}", routineName, constr.Name)
                )
                ShowContinueError(state, format("..Middle layer material with EMPD properties = {}", matL.Name))
                ShowContinueError(state, "..A material with EMPD properties must be assigned to the inside layer of a construction.")
                ErrorsFound = True
            end
        end
    end
    for Loop in range(1, state.dataGlobal.NumOfZones + 1):
        if not EMPDzone[Loop - 1]:  # 0-based
            ShowSevereError(
                state,
                format("{}: None of the constructions for zone = {} has an inside layer with EMPD properties",
                       routineName,
                       state.dataHeatBal.Zone[Loop - 1].Name)
            )
            ShowContinueError(state, "..For each zone, the inside layer of at least one construction must have EMPD properties")
            ErrorsFound = True
        end
    end
    EMPDzone.free()  # deallocate
    ReportMoistureBalanceEMPD(state)
    if ErrorsFound:
        ShowFatalError(state, "GetMoistureBalanceEMPDInput: Errors found getting EMPD material properties, program terminated.")
    end
end

def InitMoistureBalanceEMPD(inout state: EnergyPlusData):
    // using Psychrometrics notations
    if state.dataMoistureBalEMPD.InitEnvrnFlag:
        state.dataMstBalEMPD.RVSurfaceOld = List[Float64](state.dataSurface.TotSurfaces)  # allocate
        state.dataMstBalEMPD.RVSurface = List[Float64](state.dataSurface.TotSurfaces)
        state.dataMstBalEMPD.HeatFluxLatent = List[Float64](state.dataSurface.TotSurfaces)
        state.dataMoistureBalEMPD.EMPDReportVars = List[EMPDReportVarsData](state.dataSurface.TotSurfaces)
        state.dataMstBalEMPD.RVSurfLayer = List[Float64](state.dataSurface.TotSurfaces)
        state.dataMstBalEMPD.RVSurfLayerOld = List[Float64](state.dataSurface.TotSurfaces)
        state.dataMstBalEMPD.RVDeepLayer = List[Float64](state.dataSurface.TotSurfaces)
        state.dataMstBalEMPD.RVdeepOld = List[Float64](state.dataSurface.TotSurfaces)
        state.dataMstBalEMPD.RVwall = List[Float64](state.dataSurface.TotSurfaces)
    end
    for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
        ZoneNum: Int32 = state.dataSurface.Surface[SurfNum - 1].Zone
        if not state.dataSurface.Surface[SurfNum - 1].HeatTransSurf:
            continue
        end
        rv_air_in_initval: Float64 = min(
            Psychrometrics.PsyRhovFnTdbWPb_fast(
                state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT,
                max(state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].airHumRat, 1.0e-5),
                state.dataEnvrn.OutBaroPress
            ),
            Psychrometrics.PsyRhovFnTdbRh(
                state,
                state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT,
                1.0,
                "InitMoistureBalanceEMPD"
            )
        )
        state.dataMstBalEMPD.RVSurfaceOld[SurfNum - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVSurface[SurfNum - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVSurfLayer[SurfNum - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVSurfLayerOld[SurfNum - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVDeepLayer[SurfNum - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVdeepOld[SurfNum - 1] = rv_air_in_initval
        state.dataMstBalEMPD.RVwall[SurfNum - 1] = rv_air_in_initval
    end
    if not state.dataMoistureBalEMPD.InitEnvrnFlag:
        return
    end
    GetMoistureBalanceEMPDInput(state)
    for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
        if not state.dataSurface.Surface[SurfNum - 1].HeatTransSurf:
            continue
        end
        if state.dataSurface.Surface[SurfNum - 1].Class == DataSurfaces.SurfaceClass.Window:
            continue
        end
        rvd: ref = state.dataMoistureBalEMPD.EMPDReportVars[SurfNum - 1]  # 0-based
        surf_name: String = state.dataSurface.Surface[SurfNum - 1].Name
        SetupOutputVariable(state,
                            "EMPD Surface Inside Face Water Vapor Density",
                            Constant.Units.kg_m3,
                            rvd.rv_surface,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Surface Layer Moisture Content",
                            Constant.Units.kg_m3,
                            rvd.u_surface_layer,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Deep Layer Moisture Content",
                            Constant.Units.kg_m3,
                            rvd.u_deep_layer,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Surface Layer Equivalent Relative Humidity",
                            Constant.Units.Perc,
                            rvd.RH_surface_layer,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Deep Layer Equivalent Relative Humidity",
                            Constant.Units.Perc,
                            rvd.RH_deep_layer,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Surface Layer Equivalent Humidity Ratio",
                            Constant.Units.kgWater_kgDryAir,
                            rvd.w_surface_layer,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Deep Layer Equivalent Humidity Ratio",
                            Constant.Units.kgWater_kgDryAir,
                            rvd.w_deep_layer,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Surface Moisture Flux to Zone",
                            Constant.Units.kg_m2s,
                            rvd.mass_flux_zone,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
        SetupOutputVariable(state,
                            "EMPD Deep Layer Moisture Flux",
                            Constant.Units.kg_m2s,
                            rvd.mass_flux_deep,
                            OutputProcessor.TimeStepType.Zone,
                            OutputProcessor.StoreType.Average,
                            surf_name)
    end
    if state.dataMoistureBalEMPD.InitEnvrnFlag:
        state.dataMoistureBalEMPD.InitEnvrnFlag = False
    end
end

def CalcMoistureBalanceEMPD(
    inout state: EnergyPlusData,
    SurfNum: Int32,
    SurfTempIn: Float64,
    TempZone: Float64,
    inout TempSat: Float64
):
    routineName: StringRef = "CalcMoistureEMPD"
    hm_deep_layer: Float64
    RSurfaceLayer: Float64
    Taver: Float64
    RHaver: Float64
    RVaver: Float64
    dU_dRH: Float64
    PVsurf: Float64
    PV_surf_layer: Float64
    PV_deep_layer: Float64
    PVsat: Float64
    RH_surf_layer_old: Float64
    RH_deep_layer_old: Float64
    EMPDdiffusivity: Float64
    Rcoating: Float64
    RH_surf_layer: Float64
    RH_surf_layer_tmp: Float64
    RH_deep_layer: Float64
    s_mat: ref = state.dataMaterial

    if state.dataGlobal.BeginEnvrnFlag and state.dataMoistureBalEMPD.OneTimeFlag:
        InitMoistureBalanceEMPD(state)
        state.dataMoistureBalEMPD.OneTimeFlag = False
    end
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataMoistureBalEMPD.OneTimeFlag = True
    end

    surface: ref = state.dataSurface.Surface[SurfNum - 1]
    rv_surface: ref = state.dataMstBalEMPD.RVSurface[SurfNum - 1]
    rv_surface_old: ref = state.dataMstBalEMPD.RVSurfaceOld[SurfNum - 1]
    h_mass_conv_in_fd: Float64 = state.dataMstBal.HMassConvInFD[SurfNum - 1]
    rho_vapor_air_in: Float64 = state.dataMstBal.RhoVaporAirIn[SurfNum - 1]

    RHZone: Float64
    mass_flux_surf_deep: Float64
    mass_flux_surf_deep_max: Float64
    mass_flux_zone_surf: Float64
    mass_flux_zone_surf_max: Float64
    mass_flux_surf_layer: Float64
    mass_flux_deep_layer: Float64
    mass_flux_zone: Float64
    rv_surf_layer: ref = state.dataMstBalEMPD.RVSurfLayer[SurfNum - 1]
    rv_surf_layer_old: Float64 = state.dataMstBalEMPD.RVSurfLayerOld[SurfNum - 1]
    hm_surf_layer: Float64
    rv_deep_layer: ref = state.dataMstBalEMPD.RVDeepLayer[SurfNum - 1]
    rv_deep_old: Float64 = state.dataMstBalEMPD.RVdeepOld[SurfNum - 1]
    heat_flux_latent: ref = state.dataMstBalEMPD.HeatFluxLatent[SurfNum - 1]
    heat_flux_latent = 0.0

    if not surface.HeatTransSurf:
        return
    end

    constr: ref = state.dataConstruction.Construct[surface.Construction - 1]
    mat: Pointer[MaterialBase] = s_mat.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]
    # dynamic_cast
    mat_empd_ptr: Pointer[MaterialEMPD] = Pointer.cast[MaterialEMPD](mat)
    # assert mat_empd_ptr is not null (simplified)
    if mat_empd_ptr.mu <= 0.0:
        rv_surface = Psychrometrics.PsyRhovFnTdbWPb(
            TempZone,
            state.dataZoneTempPredictorCorrector.zoneHeatBalance[surface.Zone - 1].airHumRat,
            state.dataEnvrn.OutBaroPress
        )
        return
    end

    Taver = SurfTempIn
    RVaver = rv_surface_old
    RHaver = RVaver * 461.52 * (Taver + Constant.Kelvin) * exp(-23.7093 + 4111.0 / (Taver + 237.7))
    PVsat = Psychrometrics.PsyPsatFnTemp(state, Taver, routineName)
    PVsurf = RHaver * exp(23.7093 - 4111.0 / (Taver + 237.7))
    TempSat = 4111.0 / (23.7093 - log(PVsurf)) + 35.45 - Constant.Kelvin
    EMPDdiffusivity = (2.0e-7 * pow(Taver + Constant.Kelvin, 0.81) / state.dataEnvrn.OutBaroPress) / mat_empd_ptr.mu * 461.52 * (Taver + Constant.Kelvin)
    dU_dRH = mat_empd_ptr.moistACoeff * mat_empd_ptr.moistBCoeff * pow(RHaver, mat_empd_ptr.moistBCoeff - 1) + mat_empd_ptr.moistCCoeff * mat_empd_ptr.moistDCoeff * pow(RHaver, mat_empd_ptr.moistDCoeff - 1)
    RHZone = rho_vapor_air_in * 461.52 * (TempZone + Constant.Kelvin) * exp(-23.7093 + 4111.0 / ((TempZone + Constant.Kelvin) - 35.45))
    RH_deep_layer_old = Psychrometrics.PsyRhFnTdbRhov(state, Taver, rv_deep_old)
    RH_surf_layer_old = Psychrometrics.PsyRhFnTdbRhov(state, Taver, rv_surf_layer_old)
    if mat_empd_ptr.muCoating <= 0.0:
        Rcoating = 0.0
    else:
        Rcoating = mat_empd_ptr.coatingThickness * mat_empd_ptr.muCoating * state.dataEnvrn.OutBaroPress / (2.0e-7 * pow(Taver + Constant.Kelvin, 0.81) * 461.52 * (Taver + Constant.Kelvin))
    end
    hm_surf_layer = 1.0 / (0.5 * mat_empd_ptr.surfaceDepth / EMPDdiffusivity + 1.0 / h_mass_conv_in_fd + Rcoating)
    if mat_empd_ptr.deepDepth <= 0.0:
        hm_deep_layer = 0.0
    else:
        hm_deep_layer = 2.0 * EMPDdiffusivity / (mat_empd_ptr.deepDepth + mat_empd_ptr.surfaceDepth)
    end
    RSurfaceLayer = 1.0 / hm_surf_layer - 1.0 / h_mass_conv_in_fd
    mass_flux_surf_deep_max = mat_empd_ptr.deepDepth * mat_empd_ptr.Density * dU_dRH * (RH_surf_layer_old - RH_deep_layer_old) / (state.dataGlobal.TimeStepZone * 3600.0)
    mass_flux_surf_deep = hm_deep_layer * (rv_surf_layer_old - rv_deep_old)
    if abs(mass_flux_surf_deep_max) < abs(mass_flux_surf_deep):
        mass_flux_surf_deep = mass_flux_surf_deep_max
    end
    mass_flux_zone_surf_max = mat_empd_ptr.surfaceDepth * mat_empd_ptr.Density * dU_dRH * (RHZone - RH_surf_layer_old) / (state.dataGlobal.TimeStepZone * 3600.0)
    mass_flux_zone_surf = hm_surf_layer * (rho_vapor_air_in - rv_surf_layer_old)
    if abs(mass_flux_zone_surf_max) < abs(mass_flux_zone_surf):
        mass_flux_zone_surf = mass_flux_zone_surf_max
    end
    mass_flux_surf_layer = hm_surf_layer * (rv_surf_layer_old - rho_vapor_air_in) + hm_deep_layer * (rv_surf_layer_old - rv_deep_old)
    mass_flux_deep_layer = hm_deep_layer * (rv_surf_layer_old - rv_deep_old)
    mass_flux_zone = hm_surf_layer * (rv_surf_layer_old - rho_vapor_air_in)
    RH_surf_layer_tmp = RH_surf_layer_old + state.dataGlobal.TimeStepZone * 3600.0 * (-mass_flux_surf_layer / (mat_empd_ptr.Density * mat_empd_ptr.surfaceDepth * dU_dRH))
    # Branching logic (verbatim)
    if RH_surf_layer_old < RH_deep_layer_old and RH_surf_layer_old < RHZone:
        if RHZone > RH_deep_layer_old:
            if RH_surf_layer_tmp > RHZone:
                RH_surf_layer = RHZone
            else:
                RH_surf_layer = RH_surf_layer_tmp
            end
        elif RH_surf_layer_tmp > RH_deep_layer_old:
            RH_surf_layer = RH_deep_layer_old
        else:
            RH_surf_layer = RH_surf_layer_tmp
        end
    elif RH_surf_layer_old < RH_deep_layer_old and RH_surf_layer_old > RHZone:
        if RH_surf_layer_tmp > RH_deep_layer_old:
            RH_surf_layer = RH_deep_layer_old
        elif RH_surf_layer_tmp < RHZone:
            RH_surf_layer = RHZone
        else:
            RH_surf_layer = RH_surf_layer_tmp
        end
    elif RH_surf_layer_old > RH_deep_layer_old and RH_surf_layer_old < RHZone:
        if RH_surf_layer_tmp > RHZone:
            RH_surf_layer = RHZone
        elif RH_surf_layer_tmp < RH_deep_layer_old:
            RH_surf_layer = RH_deep_layer_old
        else:
            RH_surf_layer = RH_surf_layer_tmp
        end
    elif RHZone < RH_deep_layer_old:
        if RH_surf_layer_tmp < RHZone:
            RH_surf_layer = RHZone
        else:
            RH_surf_layer = RH_surf_layer_tmp
        end
    elif RH_surf_layer_tmp < RH_deep_layer_old:
        RH_surf_layer = RH_deep_layer_old
    else:
        RH_surf_layer = RH_surf_layer_tmp
    end
    if mat_empd_ptr.deepDepth <= 0.0:
        RH_deep_layer = RH_deep_layer_old
    else:
        RH_deep_layer = RH_deep_layer_old + state.dataGlobal.TimeStepZone * 3600.0 * mass_flux_deep_layer / (mat_empd_ptr.Density * mat_empd_ptr.deepDepth * dU_dRH)
    end
    rv_surf_layer = Psychrometrics.PsyRhovFnTdbRh(state, Taver, RH_surf_layer)
    rv_deep_layer = Psychrometrics.PsyRhovFnTdbRh(state, Taver, RH_deep_layer)
    PV_surf_layer = RH_surf_layer * exp(23.7093 - 4111.0 / (Taver + 237.7))
    PV_deep_layer = RH_deep_layer * exp(23.7093 - 4111.0 / (Taver + 237.7))
    rv_surface = rv_surf_layer - mass_flux_zone * RSurfaceLayer
    heat_flux_latent = mass_flux_zone * DataMoistureBalanceEMPD.Lam
    rvd: ref = state.dataMoistureBalEMPD.EMPDReportVars[SurfNum - 1]
    rvd.rv_surface = rv_surface
    rvd.RH_surface_layer = RH_surf_layer * 100.0
    rvd.RH_deep_layer = RH_deep_layer * 100.0
    rvd.w_surface_layer = 0.622 * PV_surf_layer / (state.dataEnvrn.OutBaroPress - PV_surf_layer)
    rvd.w_deep_layer = 0.622 * PV_deep_layer / (state.dataEnvrn.OutBaroPress - PV_deep_layer)
    rvd.mass_flux_zone = mass_flux_zone
    rvd.mass_flux_deep = mass_flux_deep_layer
    rvd.u_surface_layer = mat_empd_ptr.moistACoeff * pow(RH_surf_layer, mat_empd_ptr.moistBCoeff) + mat_empd_ptr.moistCCoeff * pow(RH_surf_layer, mat_empd_ptr.moistDCoeff)
    rvd.u_deep_layer = mat_empd_ptr.moistACoeff * pow(RH_deep_layer, mat_empd_ptr.moistBCoeff) + mat_empd_ptr.moistCCoeff * pow(RH_deep_layer, mat_empd_ptr.moistDCoeff)
end

def UpdateMoistureBalanceEMPD(inout state: EnergyPlusData, SurfNum: Int32):
    state.dataMstBalEMPD.RVSurfaceOld[SurfNum - 1] = state.dataMstBalEMPD.RVSurface[SurfNum - 1]
    state.dataMstBalEMPD.RVdeepOld[SurfNum - 1] = state.dataMstBalEMPD.RVDeepLayer[SurfNum - 1]
    state.dataMstBalEMPD.RVSurfLayerOld[SurfNum - 1] = state.dataMstBalEMPD.RVSurfLayer[SurfNum - 1]
end

def ReportMoistureBalanceEMPD(inout state: EnergyPlusData):
    DoReport: Bool
    s_mat: ref = state.dataMaterial
    General.ScanForReports(state, "Constructions", DoReport, "Constructions")
    if not DoReport:
        return
    end
    print(state.files.eio,
          "{}".format("! <Construction EMPD>, Construction Name, Inside Layer Material Name, Vapor Resistance Factor, a, b, "
                      "c, d, Surface Penetration Depth {m}, Deep Penetration Depth {m}, Coating Vapor Resistance Factor, "
                      "Coating Thickness {m}\n"))
    for ConstrNum in range(1, state.dataHeatBal.TotConstructs + 1):
        constr: ref = state.dataConstruction.Construct[ConstrNum - 1]  # 0-based
        if constr.TypeIsWindow:
            continue
        end
        mat: Pointer[MaterialBase] = s_mat.materials[constr.LayerPoint[constr.TotLayers - 1] - 1]
        if not mat.hasEMPD:
            continue
        end
        matEMPD_ptr: Pointer[MaterialEMPD] = Pointer.cast[MaterialEMPD](mat)
        # assert matEMPD_ptr is not null
        Format_700: String = " Construction EMPD, {}, {}, {:8.4F}, {:8.4F}, {:8.4F}, {:8.4F}, {:8.4F}, {:8.4F}, {:8.4F}, {:8.4F}, {:8.4F}\n"
        print(state.files.eio,
              Format_700.format(
                  constr.Name,
                  matEMPD_ptr.Name,
                  matEMPD_ptr.mu,
                  matEMPD_ptr.moistACoeff,
                  matEMPD_ptr.moistBCoeff,
                  matEMPD_ptr.moistCCoeff,
                  matEMPD_ptr.moistDCoeff,
                  matEMPD_ptr.surfaceDepth,
                  matEMPD_ptr.deepDepth,
                  matEMPD_ptr.muCoating,
                  matEMPD_ptr.coatingThickness))
    end
end

// End of file