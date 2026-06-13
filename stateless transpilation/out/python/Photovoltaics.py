from dataclasses import dataclass, field
from typing import Callable, Optional, List
from enum import IntEnum
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with .dataPhotovoltaic, .dataPhotovoltaicState, .dataSurface,
#   .dataHeatBal, .dataHeatBalFanSys, .dataHeatBalSurf, .dataSurfaces, .dataEnvironment,
#   .dataHVACGlobal, .dataConstruction, .dataGlobal, .dataInputProcessing, .dataIPShortCut
# - ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowSevereEmptyField,
#   ShowSevereInvalidKey, ShowSevereItemNotFound, ErrorObjectHeader: error reporting
# - Util.FindItemInList: search utility
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
# - InputProcessor: getNumObjectsFound, getObjectItem, getEnumValue
# - Sched.GetSchedule: schedule lookup
# - Constant: Kelvin, DegToRad, Units, eResource, etc.
# - DataPhotovoltaics: enum and const definitions (MinIrradiance)
# - PhotovoltaicThermalCollectors: GetPVTThermalPowerProduction, GetPVTmodelIndex, GetPVTTsColl, SetPVTQdotSource
# - TranspiredCollector: GetTranspiredCollectorIndex, GetUTSCTsColl, SetUTSCQdotSource

class PVModel(IntEnum):
    Simple = 0
    TRNSYS = 1
    Sandia = 2
    Num = 3
    Invalid = -1

class CellIntegration(IntEnum):
    Decoupled = 0
    DecoupledUllebergDynamic = 1
    SurfaceOutsideFace = 2
    TranspiredCollector = 3
    ExteriorVentedCavity = 4
    PVTSolarCollector = 5
    Num = 6
    Invalid = -1

class Efficiency(IntEnum):
    Fixed = 0
    Scheduled = 1
    Num = 2
    Invalid = -1

class SiPVCells(IntEnum):
    CrystallineSilicon = 0
    AmorphousSilicon = 1
    Num = 2
    Invalid = -1

@dataclass
class PhotovoltaicStateData:
    CheckEquipName: List[bool] = field(default_factory=list)
    GetInputFlag: bool = True
    MyOneTimeFlag: bool = True
    firstTime: bool = True
    PVTimeStep: float = 0.0
    MyEnvrnFlag: List[bool] = field(default_factory=list)

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        self.CheckEquipName.clear()
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.firstTime = True
        self.MyEnvrnFlag.clear()

cPVGeneratorObjectName = "Generator:Photovoltaic"

pvModelNames = [
    "PhotovoltaicPerformance:Simple",
    "PhotovoltaicPerformance:EquivalentOne-Diode",
    "PhotovoltaicPerformance:Sandia"
]

pvModelNamesUC = [
    "PHOTOVOLTAICPERFORMANCE:SIMPLE",
    "PHOTOVOLTAICPERFORMANCE:EQUIVALENTONE-DIODE",
    "PHOTOVOLTAICPERFORMANCE:SANDIA"
]

cellIntegrationNames = [
    "Decoupled",
    "DecoupledUllebergDynamic",
    "IntegratedSurfaceOutsideFace",
    "IntegratedTranspiredCollector",
    "IntegratedExteriorVentedCavity",
    "PhotovoltaicThermalSolarCollector"
]

cellIntegrationNamesUC = [
    "DECOUPLED",
    "DECOUPLEDULLEBERGDYNAMIC",
    "INTEGRATEDSURFACEOUTSIDEFACE",
    "INTEGRATEDTRANSPIREDCOLLECTOR",
    "INTEGRATEDEXTERIORVENTEDCAVITY",
    "PHOTOVOLTAICTHERMALSOLARCOLLECTOR"
]

efficiencyNames = ["Fixed", "Scheduled"]
efficiencyNamesUC = ["FIXED", "SCHEDULED"]

siPVCellsNames = ["CrystallineSilicon", "AmorphousSilicon"]
siPVCellsNamesUC = ["CRYSTALLINESILICON", "AMORPHOUSSILICON"]

def SimPVGenerator(state, GeneratorType, GeneratorName, GeneratorIndex_ref, RunFlag, PVLoad):
    PVnum = 0

    if state.dataPhotovoltaicState.GetInputFlag:
        GetPVInput(state)
        state.dataPhotovoltaicState.GetInputFlag = False

    if GeneratorIndex_ref[0] == 0:
        PVnum = Util.FindItemInList(GeneratorName, state.dataPhotovoltaic.PVarray)
        if PVnum == 0:
            ShowFatalError(state, f"SimPhotovoltaicGenerator: Specified PV not one of valid Photovoltaic Generators {GeneratorName}")
        GeneratorIndex_ref[0] = PVnum
    else:
        PVnum = GeneratorIndex_ref[0]
        if PVnum > state.dataPhotovoltaic.NumPVs or PVnum < 1:
            ShowFatalError(state, f"SimPhotovoltaicGenerator: Invalid GeneratorIndex passed={PVnum}, Number of PVs={state.dataPhotovoltaic.NumPVs}, Generator name={GeneratorName}")
        if state.dataPhotovoltaicState.CheckEquipName[PVnum - 1]:
            if GeneratorName != state.dataPhotovoltaic.PVarray[PVnum - 1].Name:
                ShowFatalError(state, f"SimPhotovoltaicGenerator: Invalid GeneratorIndex passed={PVnum}, Generator name={GeneratorName}, stored PV Name for that index={state.dataPhotovoltaic.PVarray[PVnum - 1].Name}")
            state.dataPhotovoltaicState.CheckEquipName[PVnum - 1] = False

    pv_model_type = state.dataPhotovoltaic.PVarray[PVnum - 1].PVModelType
    if pv_model_type == PVModel.Simple:
        CalcSimplePV(state, PVnum)
    elif pv_model_type == PVModel.TRNSYS:
        InitTRNSYSPV(state, PVnum)
        CalcTRNSYSPV(state, PVnum, RunFlag)
    elif pv_model_type == PVModel.Sandia:
        CalcSandiaPV(state, PVnum, RunFlag)
    else:
        ShowFatalError(state, f"Specified generator model type not found for PV generator = {GeneratorName}")

    ReportPV(state, PVnum)

def GetPVGeneratorResults(state, GeneratorType, GeneratorIndex, GeneratorPower_ref, GeneratorEnergy_ref, ThermalPower_ref, ThermalEnergy_ref):
    pv = state.dataPhotovoltaic.PVarray[GeneratorIndex - 1]
    GeneratorPower_ref[0] = pv.Report.DCPower
    GeneratorEnergy_ref[0] = pv.Report.DCEnergy

    if pv.CellIntegrationMode == CellIntegration.PVTSolarCollector:
        from PhotovoltaicThermalCollectors import GetPVTThermalPowerProduction
        GetPVTThermalPowerProduction(state, GeneratorIndex, ThermalPower_ref, ThermalEnergy_ref)
    else:
        ThermalPower_ref[0] = 0.0
        ThermalEnergy_ref[0] = 0.0

def GetPVInput(state):
    routineName = "GetPVInput"

    state.dataPhotovoltaic.NumPVs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cPVGeneratorObjectName)
    state.dataPhotovoltaic.NumSimplePVModuleTypes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pvModelNames[PVModel.Simple])
    state.dataPhotovoltaic.Num1DiodePVModuleTypes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pvModelNames[PVModel.TRNSYS])
    state.dataPhotovoltaic.NumSNLPVModuleTypes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pvModelNames[PVModel.Sandia])

    if state.dataPhotovoltaic.NumPVs <= 0:
        ShowSevereError(state, f"Did not find any {cPVGeneratorObjectName}")
        return

    if not hasattr(state.dataPhotovoltaic, 'PVarray') or state.dataPhotovoltaic.PVarray is None:
        state.dataPhotovoltaic.PVarray = [None] * state.dataPhotovoltaic.NumPVs

    state.dataPhotovoltaicState.CheckEquipName = [True] * state.dataPhotovoltaic.NumPVs

    s_ipsc = state.dataIPShortCut
    s_ipsc.cCurrentModuleObject = cPVGeneratorObjectName

    for PVnum in range(1, state.dataPhotovoltaic.NumPVs + 1):
        NumAlphas = [0]
        NumNums = [0]
        IOStat = [0]

        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, s_ipsc.cCurrentModuleObject, PVnum,
            s_ipsc.cAlphaArgs, NumAlphas,
            s_ipsc.rNumericArgs, NumNums,
            IOStat, None,
            s_ipsc.lAlphaFieldBlanks,
            s_ipsc.cAlphaFieldNames,
            s_ipsc.cNumericFieldNames
        )

        eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
        pv = state.dataPhotovoltaic.PVarray[PVnum - 1]
        if pv is None:
            pv = PVArrayStruct()
            state.dataPhotovoltaic.PVarray[PVnum - 1] = pv

        pv.Name = s_ipsc.cAlphaArgs[0]
        pv.SurfaceName = s_ipsc.cAlphaArgs[1]
        pv.SurfacePtr = Util.FindItemInList(s_ipsc.cAlphaArgs[1], state.dataSurface.Surface)

        if s_ipsc.lAlphaFieldBlanks[1]:
            ShowSevereError(state, f"Invalid {s_ipsc.cAlphaFieldNames[1]} = {s_ipsc.cAlphaArgs[1]}")
            ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject} = {s_ipsc.cAlphaArgs[0]}")
            ShowContinueError(state, "Surface name cannot be blank")

        if pv.SurfacePtr == 0:
            ShowSevereError(state, f"Invalid {s_ipsc.cAlphaFieldNames[1]} = {s_ipsc.cAlphaArgs[1]}")
            ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject} = {s_ipsc.cAlphaArgs[0]}")
        else:
            SurfNum = pv.SurfacePtr
            state.dataSurface.SurfIsPV[SurfNum - 1] = True

            if not state.dataSurface.Surface[SurfNum - 1].ExtSolar:
                ShowWarningError(state, f"Invalid {s_ipsc.cAlphaFieldNames[1]} = {s_ipsc.cAlphaArgs[1]}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject} = {s_ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, "Surface is not exposed to solar, check surface boundary condition")

            pv.Zone = GetPVZone(state, pv.SurfacePtr)

            if (state.dataSurface.Surface[SurfNum - 1].Tilt < -95.0) or (state.dataSurface.Surface[SurfNum - 1].Tilt > 95.0):
                ShowWarningError(state, f"Suspected input problem with {s_ipsc.cAlphaFieldNames[1]} = {s_ipsc.cAlphaArgs[1]}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject} = {s_ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, "Surface used for solar collector faces down")
                ShowContinueError(state, f"Surface tilt angle (degrees from ground outward normal) = {state.dataSurface.Surface[SurfNum - 1].Tilt:.2f}")

        if s_ipsc.lAlphaFieldBlanks[2]:
            ShowSevereEmptyField(state, eoh, s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2])
        else:
            pv.PVModelType = getEnumValue(pvModelNamesUC, s_ipsc.cAlphaArgs[2])
            if pv.PVModelType == PVModel.Invalid:
                ShowSevereInvalidKey(state, eoh, s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2])

        pv.PerfObjName = s_ipsc.cAlphaArgs[3]

        if s_ipsc.lAlphaFieldBlanks[4]:
            ShowSevereEmptyField(state, eoh, s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4])
        else:
            pv.CellIntegrationMode = getEnumValue(cellIntegrationNamesUC, s_ipsc.cAlphaArgs[4])
            if pv.CellIntegrationMode == CellIntegration.Invalid:
                ShowSevereInvalidKey(state, eoh, s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4])

        pv.NumSeriesNParall = s_ipsc.rNumericArgs[0]
        pv.NumModNSeries = s_ipsc.rNumericArgs[1]

def GetPVZone(state, SurfNum):
    GetPVZone_val = 0

    if SurfNum > 0:
        GetPVZone_val = state.dataSurface.Surface[SurfNum - 1].Zone
        if GetPVZone_val == 0:
            GetPVZone_val = Util.FindItemInList(state.dataSurface.Surface[SurfNum - 1].ZoneName, state.dataHeatBal.Zone)

    return GetPVZone_val

def CalcSimplePV(state, thisPV):
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    ThisSurf = state.dataPhotovoltaic.PVarray[thisPV - 1].SurfacePtr
    pv = state.dataPhotovoltaic.PVarray[thisPV - 1]

    if state.dataHeatBal.SurfQRadSWOutIncident[ThisSurf - 1] > DataPhotovoltaics.MinIrradiance:
        eff_mode = pv.SimplePVModule.EfficencyInputMode
        if eff_mode == Efficiency.Fixed:
            Eff = pv.SimplePVModule.PVEfficiency
        elif eff_mode == Efficiency.Scheduled:
            Eff = pv.SimplePVModule.effSched.getCurrentVal()
            pv.SimplePVModule.PVEfficiency = Eff
        else:
            Eff = 0.0
            ShowSevereError(state, "caught bad Mode in Generator:Photovoltaic:Simple use FIXED or SCHEDULED efficiency mode")

        pv.Report.DCPower = pv.SimplePVModule.AreaCol * Eff * state.dataHeatBal.SurfQRadSWOutIncident[ThisSurf - 1]
        pv.SurfaceSink = pv.Report.DCPower
        pv.Report.DCEnergy = pv.Report.DCPower * TimeStepSysSec
        pv.Report.ArrayEfficiency = Eff
    else:
        pv.SurfaceSink = 0.0
        pv.Report.DCEnergy = 0.0
        pv.Report.DCPower = 0.0
        pv.Report.ArrayEfficiency = 0.0

def ReportPV(state, PVnum):
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    pv = state.dataPhotovoltaic.PVarray[PVnum - 1]

    pv.Report.DCEnergy = pv.Report.DCPower * TimeStepSysSec

    thisZone = pv.Zone
    if thisZone != 0:
        multiplier = state.dataHeatBal.Zone[thisZone - 1].Multiplier * state.dataHeatBal.Zone[thisZone - 1].ListMultiplier
        pv.Report.DCEnergy *= multiplier
        pv.Report.DCPower *= multiplier

    cell_mode = pv.CellIntegrationMode
    if cell_mode == CellIntegration.SurfaceOutsideFace:
        state.dataHeatBalFanSys.QPVSysSource[pv.SurfacePtr - 1] = -1.0 * pv.SurfaceSink
    elif cell_mode == CellIntegration.TranspiredCollector:
        from TranspiredCollector import SetUTSCQdotSource
        SetUTSCQdotSource(state, pv.UTSCPtr, -1.0 * pv.SurfaceSink)
    elif cell_mode == CellIntegration.ExteriorVentedCavity:
        SetVentedModuleQdotSource(state, pv.ExtVentCavPtr, -1.0 * pv.SurfaceSink)
    elif cell_mode == CellIntegration.PVTSolarCollector:
        from PhotovoltaicThermalCollectors import SetPVTQdotSource
        SetPVTQdotSource(state, pv.PVTPtr, -1.0 * pv.SurfaceSink)

def CalcSandiaPV(state, PVnum, RunFlag):
    ThisSurf = state.dataPhotovoltaic.PVarray[PVnum - 1].SurfacePtr
    pv = state.dataPhotovoltaic.PVarray[PVnum - 1]

    pv.SNLPVinto.IcBeam = state.dataHeatBal.SurfQRadSWOutIncidentBeam[ThisSurf - 1]
    pv.SNLPVinto.IcDiffuse = state.dataHeatBal.SurfQRadSWOutIncident[ThisSurf - 1] - state.dataHeatBal.SurfQRadSWOutIncidentBeam[ThisSurf - 1]
    pv.SNLPVinto.IncidenceAngle = math.acos(state.dataHeatBal.SurfCosIncidenceAngle[ThisSurf - 1]) / Constant.DegToRad
    pv.SNLPVinto.ZenithAngle = math.acos(state.dataEnvrn.SOLCOS[2]) / Constant.DegToRad
    pv.SNLPVinto.Tamb = state.dataSurface.SurfOutDryBulbTemp[ThisSurf - 1]
    pv.SNLPVinto.WindSpeed = state.dataSurface.SurfOutWindSpeed[ThisSurf - 1]
    pv.SNLPVinto.Altitude = state.dataEnvrn.Elevation

    if ((pv.SNLPVinto.IcBeam + pv.SNLPVinto.IcDiffuse) > DataPhotovoltaics.MinIrradiance) and RunFlag:

        cell_mode = pv.CellIntegrationMode
        if cell_mode == CellIntegration.Decoupled:
            pv.SNLPVCalc.Tback = SandiaModuleTemperature(
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVinto.WindSpeed,
                pv.SNLPVinto.Tamb,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.a,
                pv.SNLPVModule.b
            )
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegration.SurfaceOutsideFace:
            pv.SNLPVCalc.Tback = state.dataHeatBalSurf.SurfTempOut[pv.SurfacePtr - 1]
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegration.TranspiredCollector:
            from TranspiredCollector import GetUTSCTsColl
            GetUTSCTsColl(state, pv.UTSCPtr, pv.SNLPVCalc.Tback)
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegration.ExteriorVentedCavity:
            GetExtVentedCavityTsColl(state, pv.ExtVentCavPtr, pv.SNLPVCalc.Tback)
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegration.PVTSolarCollector:
            from PhotovoltaicThermalCollectors import GetPVTTsColl
            GetPVTTsColl(state, pv.PVTPtr, pv.SNLPVCalc.Tback)
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        else:
            ShowSevereError(state, f"Sandia PV Simulation Temperature Modeling Mode Error in {pv.Name}")

        pv.SNLPVCalc.AMa = AbsoluteAirMass(pv.SNLPVinto.ZenithAngle, pv.SNLPVinto.Altitude)

        pv.SNLPVCalc.F1 = SandiaF1(
            pv.SNLPVCalc.AMa,
            pv.SNLPVModule.a_0,
            pv.SNLPVModule.a_1,
            pv.SNLPVModule.a_2,
            pv.SNLPVModule.a_3,
            pv.SNLPVModule.a_4
        )

        pv.SNLPVCalc.F2 = SandiaF2(
            pv.SNLPVinto.IncidenceAngle,
            pv.SNLPVModule.b_0,
            pv.SNLPVModule.b_1,
            pv.SNLPVModule.b_2,
            pv.SNLPVModule.b_3,
            pv.SNLPVModule.b_4,
            pv.SNLPVModule.b_5
        )

        pv.SNLPVCalc.Isc = SandiaIsc(
            pv.SNLPVCalc.Tcell,
            pv.SNLPVModule.Isc0,
            pv.SNLPVinto.IcBeam,
            pv.SNLPVinto.IcDiffuse,
            pv.SNLPVCalc.F1,
            pv.SNLPVCalc.F2,
            pv.SNLPVModule.fd,
            pv.SNLPVModule.aIsc
        )

        Ee = SandiaEffectiveIrradiance(
            pv.SNLPVCalc.Tcell,
            pv.SNLPVCalc.Isc,
            pv.SNLPVModule.Isc0,
            pv.SNLPVModule.aIsc
        )

        pv.SNLPVCalc.Imp = SandiaImp(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Imp0,
            pv.SNLPVModule.aImp,
            pv.SNLPVModule.c_0,
            pv.SNLPVModule.c_1
        )

        pv.SNLPVCalc.Voc = SandiaVoc(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Voc0,
            pv.SNLPVModule.NcellSer,
            pv.SNLPVModule.DiodeFactor,
            pv.SNLPVModule.BVoc0,
            pv.SNLPVModule.mBVoc
        )

        pv.SNLPVCalc.Vmp = SandiaVmp(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Vmp0,
            pv.SNLPVModule.NcellSer,
            pv.SNLPVModule.DiodeFactor,
            pv.SNLPVModule.BVmp0,
            pv.SNLPVModule.mBVmp,
            pv.SNLPVModule.c_2,
            pv.SNLPVModule.c_3
        )

        pv.SNLPVCalc.Ix = SandiaIx(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Ix0,
            pv.SNLPVModule.aIsc,
            pv.SNLPVModule.aImp,
            pv.SNLPVModule.c_4,
            pv.SNLPVModule.c_5
        )

        pv.SNLPVCalc.Vx = pv.SNLPVCalc.Voc / 2.0

        pv.SNLPVCalc.Ixx = SandiaIxx(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Ixx0,
            pv.SNLPVModule.aImp,
            pv.SNLPVModule.c_6,
            pv.SNLPVModule.c_7
        )

        pv.SNLPVCalc.Vxx = 0.5 * (pv.SNLPVCalc.Voc + pv.SNLPVCalc.Vmp)

        pv.SNLPVCalc.Pmp = pv.SNLPVCalc.Imp * pv.SNLPVCalc.Vmp

        pv.SNLPVCalc.EffMax = pv.SNLPVCalc.Pmp / (pv.SNLPVinto.IcBeam + pv.SNLPVinto.IcDiffuse) / pv.SNLPVModule.Acoll

        pv.SNLPVCalc.Pmp *= pv.NumSeriesNParall * pv.NumModNSeries
        pv.SNLPVCalc.Imp *= pv.NumModNSeries
        pv.SNLPVCalc.Vmp *= pv.NumModNSeries
        pv.SNLPVCalc.Isc *= pv.NumSeriesNParall
        pv.SNLPVCalc.Voc *= pv.NumModNSeries
        pv.SNLPVCalc.Ix *= pv.NumSeriesNParall
        pv.SNLPVCalc.Ixx *= pv.NumSeriesNParall
        pv.SNLPVCalc.Vx *= pv.NumModNSeries
        pv.SNLPVCalc.Vxx *= pv.NumModNSeries
        pv.SNLPVCalc.SurfaceSink = pv.SNLPVCalc.Pmp
    else:
        pv.SNLPVCalc.Vmp = 0.0
        pv.SNLPVCalc.Imp = 0.0
        pv.SNLPVCalc.Pmp = 0.0
        pv.SNLPVCalc.EffMax = 0.0
        pv.SNLPVCalc.Isc = 0.0
        pv.SNLPVCalc.Voc = 0.0
        pv.SNLPVCalc.Tcell = pv.SNLPVinto.Tamb
        pv.SNLPVCalc.Tback = pv.SNLPVinto.Tamb
        pv.SNLPVCalc.AMa = 999.0
        pv.SNLPVCalc.F1 = 0.0
        pv.SNLPVCalc.F2 = 0.0
        pv.SNLPVCalc.Ix = 0.0
        pv.SNLPVCalc.Vx = 0.0
        pv.SNLPVCalc.Ixx = 0.0
        pv.SNLPVCalc.Vxx = 0.0
        pv.SNLPVCalc.SurfaceSink = 0.0

    pv.Report.DCPower = pv.SNLPVCalc.Pmp
    pv.Report.ArrayIsc = pv.SNLPVCalc.Isc
    pv.Report.ArrayVoc = pv.SNLPVCalc.Voc
    pv.Report.CellTemp = pv.SNLPVCalc.Tcell
    pv.Report.ArrayEfficiency = pv.SNLPVCalc.EffMax
    pv.SurfaceSink = pv.SNLPVCalc.SurfaceSink

def InitTRNSYSPV(state, PVnum):
    pv = state.dataPhotovoltaic.PVarray[PVnum - 1]

    if state.dataPhotovoltaicState.MyOneTimeFlag:
        state.dataPhotovoltaicState.MyEnvrnFlag = [True] * state.dataPhotovoltaic.NumPVs
        state.dataPhotovoltaicState.MyOneTimeFlag = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataPhotovoltaicState.MyEnvrnFlag[PVnum - 1]:
        pv.TRNSYSPVcalc.CellTempK = state.dataSurface.SurfOutDryBulbTemp[pv.SurfacePtr - 1] + Constant.Kelvin
        pv.TRNSYSPVcalc.LastCellTempK = state.dataSurface.SurfOutDryBulbTemp[pv.SurfacePtr - 1] + Constant.Kelvin
        state.dataPhotovoltaicState.MyEnvrnFlag[PVnum - 1] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataPhotovoltaicState.MyEnvrnFlag[PVnum - 1] = True

    TimeElapsed = state.dataGlobal.HourOfDay + state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed

    if pv.TRNSYSPVcalc.TimeElapsed != TimeElapsed:
        pv.TRNSYSPVcalc.LastCellTempK = pv.TRNSYSPVcalc.CellTempK
        pv.TRNSYSPVcalc.TimeElapsed = TimeElapsed

    if any(x > 0.0 for x in state.dataHeatBal.SurfQRadSWOutIncident):
        pv.TRNSYSPVcalc.Insolation = state.dataHeatBal.SurfQRadSWOutIncident[pv.SurfacePtr - 1]
    else:
        pv.TRNSYSPVcalc.Insolation = 0.0

def CalcTRNSYSPV(state, PVnum, RunFlag):
    EPS = 0.001
    ERR = 0.001
    MinInsolation = 30.0
    KMAX = 100
    EtaIni = 0.10

    if state.dataPhotovoltaicState.firstTime and state.dataPhotovoltaic.PVarray[PVnum - 1].CellIntegrationMode == CellIntegration.DecoupledUllebergDynamic:
        state.dataPhotovoltaicState.PVTimeStep = float(state.dataGlobal.MinutesInTimeStep) * 60.0

    state.dataPhotovoltaicState.firstTime = False

    pv = state.dataPhotovoltaic.PVarray[PVnum - 1]
    state.dataPhotovoltaic.ShuntResistance = pv.TRNSYSPVModule.ShuntResistance

    Tambient = state.dataSurface.SurfOutDryBulbTemp[pv.SurfacePtr - 1] + Constant.Kelvin

    if (pv.TRNSYSPVcalc.Insolation > MinInsolation) and RunFlag:
        DummyErr = 2.0 * ERR
        EtaOld = EtaIni
        ETA = 0.0

        while DummyErr > ERR:
            cell_mode = pv.CellIntegrationMode
            if cell_mode == CellIntegration.Decoupled:
                pv.TRNSYSPVModule.HeatLossCoef = (pv.TRNSYSPVModule.TauAlpha * pv.TRNSYSPVModule.NOCTInsolation /
                    (pv.TRNSYSPVModule.NOCTCellTemp - pv.TRNSYSPVModule.NOCTAmbTemp))
                CellTemp = (Tambient + (pv.TRNSYSPVcalc.Insolation * pv.TRNSYSPVModule.TauAlpha /
                    pv.TRNSYSPVModule.HeatLossCoef) * (1.0 - ETA / pv.TRNSYSPVModule.TauAlpha))
            elif cell_mode == CellIntegration.DecoupledUllebergDynamic:
                CellTemp = (Tambient + (pv.TRNSYSPVcalc.LastCellTempK - Tambient) *
                    math.exp(-pv.TRNSYSPVModule.HeatLossCoef / pv.TRNSYSPVModule.HeatCapacity *
                    state.dataPhotovoltaicState.PVTimeStep) + (pv.TRNSYSPVModule.TauAlpha - ETA) *
                    pv.TRNSYSPVcalc.Insolation / pv.TRNSYSPVModule.HeatLossCoef *
                    (1.0 - math.exp(-pv.TRNSYSPVModule.HeatLossCoef / pv.TRNSYSPVModule.HeatCapacity *
                    state.dataPhotovoltaicState.PVTimeStep)))
            elif cell_mode == CellIntegration.SurfaceOutsideFace:
                CellTemp = state.dataHeatBalSurf.SurfTempOut[pv.SurfacePtr - 1] + Constant.Kelvin
            elif cell_mode == CellIntegration.TranspiredCollector:
                from TranspiredCollector import GetUTSCTsColl
                GetUTSCTsColl(state, pv.UTSCPtr, CellTemp)
                CellTemp += Constant.Kelvin
            elif cell_mode == CellIntegration.ExteriorVentedCavity:
                GetExtVentedCavityTsColl(state, pv.ExtVentCavPtr, CellTemp)
                CellTemp += Constant.Kelvin
            elif cell_mode == CellIntegration.PVTSolarCollector:
                from PhotovoltaicThermalCollectors import GetPVTTsColl
                GetPVTTsColl(state, pv.PVTPtr, CellTemp)
                CellTemp += Constant.Kelvin

            ILRef = pv.TRNSYSPVModule.RefIsc
            AARef = ((pv.TRNSYSPVModule.TempCoefVoc * pv.TRNSYSPVModule.RefTemperature -
                pv.TRNSYSPVModule.RefVoc + pv.TRNSYSPVModule.SemiConductorBandgap *
                pv.TRNSYSPVModule.CellsInSeries) /
                (pv.TRNSYSPVModule.TempCoefIsc * pv.TRNSYSPVModule.RefTemperature / ILRef - 3.0))

            IORef = ILRef * math.exp(-pv.TRNSYSPVModule.RefVoc / AARef)

            SeriesResistance = ((AARef * math.log(1.0 - pv.TRNSYSPVModule.Imp / ILRef) -
                pv.TRNSYSPVModule.Vmp + pv.TRNSYSPVModule.RefVoc) /
                pv.TRNSYSPVModule.Imp)

            IL = (pv.TRNSYSPVcalc.Insolation / pv.TRNSYSPVModule.RefInsolation *
                (ILRef + pv.TRNSYSPVModule.TempCoefIsc *
                (CellTemp - pv.TRNSYSPVModule.RefTemperature)))

            cell_temp_ratio = CellTemp / pv.TRNSYSPVModule.RefTemperature
            AA = AARef * cell_temp_ratio
            IO = IORef * (cell_temp_ratio ** 3) * math.exp(
                pv.TRNSYSPVModule.SemiConductorBandgap * pv.TRNSYSPVModule.CellsInSeries / AARef *
                (1.0 - pv.TRNSYSPVModule.RefTemperature / CellTemp))

            ISCG1 = IL
            ISC = [ISCG1]
            NEWTON(state, ISC, lambda st, II, VV, IL_, IO_, RS, AA_: FUN(st, II, VV, IL_, IO_, RS, AA_),
                   lambda st, II, VV, IO_, RS, AA_: FI(st, II, VV, IO_, RS, AA_),
                   ISC[0], 0.0, IO, IL, SeriesResistance, AA, ISCG1, EPS)

            VOCG1 = (math.log(IL / IO) + 1.0) * AA
            VOC = [VOCG1]
            NEWTON(state, VOC, lambda st, II, VV, IL_, IO_, RS, AA_: FUN(st, II, VV, IL_, IO_, RS, AA_),
                   lambda st, II, VV, IO_, RS, AA_: FV(st, II, VV, IO_, RS, AA_),
                   0.0, VOC[0], IO, IL, SeriesResistance, AA, VOCG1, EPS)

            VLEFT = 0.0
            VRIGHT = VOC[0]
            VM_result = [0.0]
            K_result = [0]
            SEARCH(state, VLEFT, VRIGHT, VM_result, K_result, IO, IL, SeriesResistance, AA, EPS, KMAX)
            VM = VM_result[0]

            IM = [0.0]
            PM = [0.0]
            POWER(state, IO, IL, SeriesResistance, AA, EPS, IM, VM, PM)

            ETA = PM[0] / pv.TRNSYSPVcalc.Insolation / pv.TRNSYSPVModule.Area
            DummyErr = abs((ETA - EtaOld) / EtaOld) if EtaOld != 0 else 0
            EtaOld = ETA

    else:
        cell_mode = pv.CellIntegrationMode
        if cell_mode == CellIntegration.Decoupled:
            CellTemp = Tambient
        elif cell_mode == CellIntegration.DecoupledUllebergDynamic:
            CellTemp = (Tambient + (pv.TRNSYSPVcalc.LastCellTempK - Tambient) *
                math.exp(-pv.TRNSYSPVModule.HeatLossCoef / pv.TRNSYSPVModule.HeatCapacity *
                state.dataPhotovoltaicState.PVTimeStep))
        elif cell_mode == CellIntegration.SurfaceOutsideFace:
            CellTemp = state.dataHeatBalSurf.SurfTempOut[pv.SurfacePtr - 1] + Constant.Kelvin
        elif cell_mode == CellIntegration.TranspiredCollector:
            from TranspiredCollector import GetUTSCTsColl
            GetUTSCTsColl(state, pv.UTSCPtr, CellTemp)
            CellTemp += Constant.Kelvin
        elif cell_mode == CellIntegration.ExteriorVentedCavity:
            GetExtVentedCavityTsColl(state, pv.ExtVentCavPtr, CellTemp)
            CellTemp += Constant.Kelvin
        elif cell_mode == CellIntegration.PVTSolarCollector:
            from PhotovoltaicThermalCollectors import GetPVTTsColl
            GetPVTTsColl(state, pv.PVTPtr, CellTemp)
            CellTemp += Constant.Kelvin

        pv.TRNSYSPVcalc.Insolation = 0.0
        IM = 0.0
        VM = 0.0
        PM = 0.0
        ETA = 0.0
        ISC = 0.0
        VOC = 0.0

    CellTempC = CellTemp - Constant.Kelvin

    IA = pv.NumSeriesNParall * IM
    ISCA = pv.NumSeriesNParall * ISC
    VA = pv.NumModNSeries * VM
    VOCA = pv.NumModNSeries * VOC
    PA = IA * VA

    pv.TRNSYSPVcalc.ArrayCurrent = IA
    pv.TRNSYSPVcalc.ArrayVoltage = VA
    pv.TRNSYSPVcalc.ArrayPower = PA
    pv.Report.DCPower = PA
    pv.TRNSYSPVcalc.ArrayEfficiency = ETA
    pv.Report.ArrayEfficiency = ETA
    pv.TRNSYSPVcalc.CellTemp = CellTempC
    pv.Report.CellTemp = CellTempC
    pv.TRNSYSPVcalc.CellTempK = CellTemp
    pv.TRNSYSPVcalc.ArrayIsc = ISCA
    pv.Report.ArrayIsc = ISCA
    pv.TRNSYSPVcalc.ArrayVoc = VOCA
    pv.Report.ArrayVoc = VOCA
    pv.SurfaceSink = PA

def POWER(state, IO, IL, RSER, AA, EPS, II_ref, VV, PP_ref):
    IG1 = IL - IO * math.exp(VV / AA - 1.0)
    II_ref[0] = IG1
    NEWTON(state, II_ref, lambda st, II, VV_, IL_, IO_, RS, AA_: FUN(st, II, VV_, IL_, IO_, RS, AA_),
           lambda st, II, VV_, IO_, RS, AA_: FI(st, II, VV_, IO_, RS, AA_),
           II_ref[0], VV, IO, IL, RSER, AA, IG1, EPS)
    PP_ref[0] = II_ref[0] * VV

def NEWTON(state, XX_ref, FXX, DER, II, VV, IO, IL, RSER, AA, XS, EPS):
    COUNT = 0
    XX_ref[0] = XS
    ERR = 1.0

    while (ERR > EPS) and (COUNT <= 10):
        X0 = XX_ref[0]
        XX_ref[0] -= FXX(state, II, VV, IL, IO, RSER, AA) / DER(state, II, VV, IO, RSER, AA)
        COUNT += 1
        ERR = abs((XX_ref[0] - X0) / X0) if X0 != 0 else 0

def SEARCH(state, A_ref, B_ref, P_ref, K_ref, IO, IL, RSER, AA, EPS, KMAX):
    DELTA = 1.0e-3
    EPSILON = 1.0e-3
    RONE = (math.sqrt(5.0) - 1.0) / 2.0
    RTWO = RONE * RONE

    H = B_ref[0] - A_ref[0]
    IM = [0.0]
    PM = [0.0]
    POWER(state, IO, IL, RSER, AA, EPS, IM, A_ref[0], PM)
    YA = -1.0 * PM[0]

    POWER(state, IO, IL, RSER, AA, EPS, IM, B_ref[0], PM)
    YB = -1.0 * PM[0]

    C = A_ref[0] + RTWO * H
    D = A_ref[0] + RONE * H

    POWER(state, IO, IL, RSER, AA, EPS, IM, C, PM)
    YC = -1.0 * PM[0]

    POWER(state, IO, IL, RSER, AA, EPS, IM, D, PM)
    YD = -1.0 * PM[0]

    K_ref[0] = 1

    while (abs(YB - YA) > EPSILON or H > DELTA):
        if YC < YD:
            B_ref[0] = D
            YB = YD
            D = C
            YD = YC
            H = B_ref[0] - A_ref[0]
            C = A_ref[0] + RTWO * H
            POWER(state, IO, IL, RSER, AA, EPS, IM, C, PM)
            YC = -1.0 * PM[0]
        else:
            A_ref[0] = C
            YA = YC
            C = D
            YC = YD
            H = B_ref[0] - A_ref[0]
            D = A_ref[0] + RONE * H
            POWER(state, IO, IL, RSER, AA, EPS, IM, D, PM)
            YD = -1.0 * PM[0]
        K_ref[0] += 1

    if K_ref[0] < KMAX:
        P_ref[0] = A_ref[0]
        YP = YA
        if YB < YA:
            P_ref[0] = B_ref[0]
            YP = YB

def FUN(state, II, VV, IL, IO, RSER, AA):
    FUN_val = 0.0

    if (((VV + II * RSER) / AA) < 700.0):
        FUN_val = II - IL + IO * (math.exp((VV + II * RSER) / AA) - 1.0) - ((VV + II * RSER) / state.dataPhotovoltaic.ShuntResistance)
    else:
        ShowSevereError(state, "EquivalentOneDiode Photovoltaic model failed to find maximum power point")
        ShowContinueError(state, "Numerical solver failed trying to take exponential of too large a number")
        ShowContinueError(state, f"Check input data in {pvModelNames[PVModel.TRNSYS]}")
        ShowContinueError(state, f"VV (voltage) = {VV:.5e}")
        ShowContinueError(state, f"II (current) = {II:.5e}")
        ShowFatalError(state, "FUN: EnergyPlus terminates because of numerical problem in EquivalentOne-Diode PV model")

    return FUN_val

def FI(state, II, VV, IO, RSER, AA):
    FI_val = 0.0

    if (((VV + II * RSER) / AA) < 700.0):
        FI_val = 1.0 + IO * math.exp((VV + II * RSER) / AA) * RSER / AA + (RSER / state.dataPhotovoltaic.ShuntResistance)
    else:
        ShowSevereError(state, "EquivalentOneDiode Photovoltaic model failed to find maximum power point")
        ShowContinueError(state, "Numerical solver failed trying to take exponential of too large a number")
        ShowContinueError(state, f"Check input data in {pvModelNames[PVModel.TRNSYS]}")
        ShowContinueError(state, f"VV (voltage) = {VV:.5e}")
        ShowContinueError(state, f"II (current) = {II:.5e}")
        ShowFatalError(state, "FI: EnergyPlus terminates because of numerical problem in EquivalentOne-Diode PV model")

    return FI_val

def FV(state, II, VV, IO, RSER, AA):
    FV_val = 0.0

    if (((VV + II * RSER) / AA) < 700.0):
        FV_val = IO * math.exp((VV + II * RSER) / AA) / AA + (1.0 / state.dataPhotovoltaic.ShuntResistance)
    else:
        ShowSevereError(state, "EquivalentOneDiode Photovoltaic model failed to find maximum power point")
        ShowContinueError(state, "Numerical solver failed trying to take exponential of too large a number")
        ShowContinueError(state, f"Check input data in {pvModelNames[PVModel.TRNSYS]}")
        ShowContinueError(state, f"VV (voltage) = {VV:.5e}")
        ShowContinueError(state, f"II (current) = {II:.5e}")
        ShowFatalError(state, "FI: EnergyPlus terminates because of numerical problem in EquivalentOne-Diode PV model")

    return FV_val

def SandiaModuleTemperature(Ibc, Idc, Ws, Ta, fd, a, b):
    E = Ibc + fd * Idc
    return E * math.exp(a + b * Ws) + Ta

def SandiaTcellFromTmodule(Tm, Ibc, Idc, fd, DT0):
    E = Ibc + fd * Idc
    return Tm + (E / 1000.0) * DT0

def SandiaCellTemperature(Ibc, Idc, Ws, Ta, fd, a, b, DT0):
    E = Ibc + fd * Idc
    Tm = E * math.exp(a + b * Ws) + Ta
    return Tm + (E / 1000.0) * DT0

def SandiaEffectiveIrradiance(Tc, Isc, Isc0, aIsc):
    return Isc / (1.0 + aIsc * (Tc - 25.0)) / Isc0

def AbsoluteAirMass(SolZen, Altitude):
    if SolZen < 89.9:
        AM = 1.0 / (math.cos(SolZen * Constant.DegToRad) + 0.5057 * pow(96.08 - SolZen, -1.634))
        return math.exp(-0.0001184 * Altitude) * AM
    else:
        AM = 36.32
        return math.exp(-0.0001184 * Altitude) * AM

def SandiaF1(AMa, a0, a1, a2, a3, a4):
    F1 = a0 + a1 * AMa + a2 * (AMa ** 2) + a3 * (AMa ** 3) + a4 * (AMa ** 4)
    return F1 if F1 > 0.0 else 0.0

def SandiaF2(IncAng, b0, b1, b2, b3, b4, b5):
    F2 = b0 + b1 * IncAng + b2 * (IncAng ** 2) + b3 * (IncAng ** 3) + b4 * (IncAng ** 4) + b5 * (IncAng ** 5)
    return F2 if F2 > 0.0 else 0.0

def SandiaImp(Tc, Ee, Imp0, aImp, C0, C1):
    return Imp0 * (C0 * Ee + C1 * (Ee ** 2)) * (1.0 + aImp * (Tc - 25.0))

def SandiaIsc(Tc, Isc0, Ibc, Idc, F1, F2, fd, aIsc):
    return Isc0 * F1 * ((Ibc * F2 + fd * Idc) / 1000.0) * (1.0 + aIsc * (Tc - 25.0))

def SandiaIx(Tc, Ee, Ix0, aIsc, aImp, C4, C5):
    return Ix0 * (C4 * Ee + C5 * (Ee ** 2)) * (1.0 + ((aIsc + aImp) / 2.0) * (Tc - 25.0))

def SandiaIxx(Tc, Ee, Ixx0, aImp, C6, C7):
    return Ixx0 * (C6 * Ee + C7 * (Ee ** 2)) * (1.0 + aImp * (Tc - 25.0))

def SandiaVmp(Tc, Ee, Vmp0, NcellSer, DiodeFactor, BVmp0, mBVmp, C2, C3):
    if Ee > 0.0:
        dTc = DiodeFactor * ((1.38066e-23 * (Tc + Constant.Kelvin)) / 1.60218e-19)
        BVmpEe = BVmp0 + mBVmp * (1.0 - Ee)
        return Vmp0 + C2 * NcellSer * dTc * math.log(Ee) + C3 * NcellSer * (dTc * math.log(Ee)) ** 2 + BVmpEe * (Tc - 25.0)
    else:
        return 0.0

def SandiaVoc(Tc, Ee, Voc0, NcellSer, DiodeFactor, BVoc0, mBVoc):
    if Ee > 0.0:
        dTc = DiodeFactor * ((1.38066e-23 * (Tc + Constant.Kelvin)) / 1.60218e-19)
        BVocEe = BVoc0 + mBVoc * (1.0 - Ee)
        return Voc0 + NcellSer * dTc * math.log(Ee) + BVocEe * (Tc - 25.0)
    else:
        return 0.0

def SetVentedModuleQdotSource(state, VentModNum, QSource):
    state.dataHeatBal.ExtVentedCavity[VentModNum - 1].QdotSource = QSource / state.dataHeatBal.ExtVentedCavity[VentModNum - 1].ProjArea

def GetExtVentedCavityIndex(state, SurfacePtr, VentCavIndex_ref):
    if SurfacePtr == 0:
        ShowFatalError(state, "Invalid surface passed to GetExtVentedCavityIndex")

    CavNum = 0
    Found = False

    for thisCav in range(state.dataSurface.TotExtVentCav):
        for ThisSurf in range(state.dataHeatBal.ExtVentedCavity[thisCav].NumSurfs):
            if SurfacePtr == state.dataHeatBal.ExtVentedCavity[thisCav].SurfPtrs[ThisSurf]:
                Found = True
                CavNum = thisCav + 1

    if not Found:
        ShowFatalError(state, f"Did not find surface in Exterior Vented Cavity description in GetExtVentedCavityIndex, Surface name = {state.dataSurface.Surface[SurfacePtr - 1].Name}")
    else:
        VentCavIndex_ref[0] = CavNum

def GetExtVentedCavityTsColl(state, VentModNum, TsColl_ref):
    TsColl_ref[0] = state.dataHeatBal.ExtVentedCavity[VentModNum - 1].Tbaffle

class PVArrayStruct:
    pass

class SimplePVModuleStruct:
    pass

class SNLPVInputs:
    pass

class SNLPVCalcs:
    pass

class SNLModuleParams:
    pass

class TRNSYSPVCalcs:
    pass

class TRNSYSPVModule:
    pass

class PVReport:
    pass
