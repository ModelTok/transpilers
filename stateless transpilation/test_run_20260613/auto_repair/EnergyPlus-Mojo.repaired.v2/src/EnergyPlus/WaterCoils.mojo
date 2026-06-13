# Mojo translation of WaterCoils.cc - Faithful 1:1, no refactoring

from ..Psychrometrics import (
    PsyCpAirFnW,
    PsyHFnTdbRhPb,
    PsyHFnTdbW,
    PsyRhoAirFnPbTdbW,
    PsyTdbFnHW,
    PsyTdpFnWPb,
    PsyTsatFnHPb,
    PsyWFnTdbH,
    PsyWFnTdbRhPb,
    PsyWFnTdbTwbPb,
    PsyWFnTdpPb,
    PsyTwbFnTdbWPb,
    RhoH2O,
)

from ..General import (
    Iterate,
    SolveRoot2,
    SafeDivide,
)

from ..Data.EnergyPlusData import EnergyPlusData
from ..DataPlant import PlantEquipmentType, PlantLocation
from ..FaultsManager import FaultPropertiesFoulingCoil, FouledCoil
from ..HVACControllers import CtrlVarType
from ..Plant.Utilities import (
    MyPlantSizingIndex,
    ScanPlantLoopsForObject,
    InitComponentNodes,
    RegisterPlantCompDesignFlow,
)
from ..ReportCoilSelection import getReportIndex, setCoilLvgAirTemp, setCoilLvgAirHumRat, setCoilFinalSizes
from ..Sched.Schedule import Schedule
from ..Node import Node as NodeManager
from ..Sizing import DataSizing
from ..Data.BranchNodeConnections import TestCompSet
from ..Data.OutputProcessor import SetupOutputVariable
from ..Data.Environment import StdRhoAir, StdBaroPress, OutBaroPress
from ..Data.Globals import (
    BeginEnvrnFlag,
    KickOffSimulation,
    SysSizingCalc,
    DoingSizing,
    WarmupFlag,
    DoingHVACSizingSimulations,
)
from ..Data.HVACGlobals import (
    MassFlowTolerance,
    TimeStepSysSec,
    SmallLoad,
    DesCoilHWInletTempMin,
    FanOp,
    CtrlVarType as HVACCtrlVarType,
)
from ..Data.ContaminantBalance import Contaminant
from ..Data.Water import WaterStorage
from ..Data.BranchInputManager import CompType
from ..InputProcessing.InputProcessor import getNumObjectsFound, getObjectDefMaxArgs, getObjectItem, VerifyUniqueCoilName
from ..NodeInputManager import GetOnlySingleNode
from ..WaterManager import SetupTankSupplyComponent
from ..FaultsManager import FaultPropertiesFoulingCoil, FouledCoil
from ..SetPointManager import NodeHasSPMCtrlVarType
from ..EMSManager import CheckIfNodeSetPointManagedByEMS
from ..OutputReportPredefined import (
    PreDefTableEntry,
    addFootNoteSubTable,
    pdchHeatCoilType,
    pdchHeatCoilDesCap,
    pdchHeatCoilNomCap,
    pdchHeatCoilNomEff,
    pdstHeatCoil,
    pdchCoolCoilType,
    pdchCoolCoilDesCap,
    pdchCoolCoilTotCap,
    pdchCoolCoilSensCap,
    pdchCoolCoilLatCap,
    pdchCoolCoilSHR,
    pdchCoolCoilNomEff,
    pdchCoolCoilUATotal,
    pdchCoolCoilArea,
    pdstCoolCoil,
)
from ..SimAirServingZones import CheckWaterCoilIsOnAirLoop
from ..Plant.DataPlant import PlantSizData
from ..Data.DesignSizing import DataFlowUsedForSizing, DataAirFlowUsedForSizing, DataWaterFlowUsedForSizing, DataCapacityUsedForSizing
from ..Data.AutomatedSizing import AutoSize

from ..Array1D import Array1D
from ..Array2D import Array2D
from ..Array2A import Array2A
from ..Optional import Optional

import Math
import Format

# Constants
alias MaxPolynomOrder: Int = 4
alias MaxOrderedPairs: Int = 60
alias PolyConvgTol: Float64 = 1.0e-5
alias MinWaterMassFlowFrac: Float64 = 0.000001
alias MinAirMassFlow: Float64 = 0.001

# Enums
enum CoilModel: Int32 {
    Invalid = -1
    HeatingSimple = 0
    CoolingSimple = 1
    CoolingDetailed = 2
    Num = 3
}

# Structs
struct WaterCoilEquipConditions:
    var Name: String
    var WaterCoilTypeA: String
    var WaterCoilModelA: String
    var WaterCoilType: PlantEquipmentType
    var coilType: HVAC.CoilType = HVAC.CoilType.Invalid
    var coilReportNum: Int = -1
    var WaterCoilModel: CoilModel
    var availSched: Schedule* = None
    var RequestingAutoSize: Bool
    var InletAirMassFlowRate: Float64
    var OutletAirMassFlowRate: Float64
    var InletAirTemp: Float64
    var OutletAirTemp: Float64
    var InletAirHumRat: Float64
    var OutletAirHumRat: Float64
    var InletAirEnthalpy: Float64
    var OutletAirEnthalpy: Float64
    var TotWaterCoilLoad: Float64
    var SenWaterCoilLoad: Float64
    var TotWaterHeatingCoilEnergy: Float64
    var TotWaterCoolingCoilEnergy: Float64
    var SenWaterCoolingCoilEnergy: Float64
    var DesWaterHeatingCoilRate: Float64
    var TotWaterHeatingCoilRate: Float64
    var DesWaterCoolingCoilRate: Float64
    var TotWaterCoolingCoilRate: Float64
    var SenWaterCoolingCoilRate: Float64
    var UACoil: Float64
    var LeavingRelHum: Float64
    var DesiredOutletTemp: Float64
    var DesiredOutletHumRat: Float64
    var InletWaterTemp: Float64
    var OutletWaterTemp: Float64
    var InletWaterMassFlowRate: Float64
    var OutletWaterMassFlowRate: Float64
    var MaxWaterVolFlowRate: Float64
    var MaxWaterMassFlowRate: Float64
    var InletWaterEnthalpy: Float64
    var OutletWaterEnthalpy: Float64
    var TubeOutsideSurfArea: Float64
    var TotTubeInsideArea: Float64
    var FinSurfArea: Float64
    var MinAirFlowArea: Float64
    var CoilDepth: Float64
    var FinDiam: Float64
    var FinThickness: Float64
    var TubeInsideDiam: Float64
    var TubeOutsideDiam: Float64
    var TubeThermConductivity: Float64
    var FinThermConductivity: Float64
    var FinSpacing: Float64
    var TubeDepthSpacing: Float64
    var NumOfTubeRows: Int
    var NumOfTubesPerRow: Int
    var EffectiveFinDiam: Float64
    var TotCoilOutsideSurfArea: Float64
    var CoilEffectiveInsideDiam: Float64
    var GeometryCoef1: Float64
    var GeometryCoef2: Float64
    var DryFinEfficncyCoef: Array1D[Float64]
    var SatEnthlCurveConstCoef: Float64
    var SatEnthlCurveSlope: Float64
    var EnthVsTempCurveAppxSlope: Float64
    var EnthVsTempCurveConst: Float64
    var MeanWaterTempSaved: Float64
    var InWaterTempSaved: Float64
    var OutWaterTempSaved: Float64
    var SurfAreaWetSaved: Float64
    var SurfAreaWetFraction: Float64
    var DesInletWaterTemp: Float64
    var DesAirVolFlowRate: Float64
    var DesInletAirTemp: Float64
    var DesInletAirHumRat: Float64
    var DesTotWaterCoilLoad: Float64
    var DesSenWaterCoilLoad: Float64
    var DesAirMassFlowRate: Float64
    var UACoilTotal: Float64
    var UACoilInternal: Float64
    var UACoilExternal: Float64
    var UACoilInternalDes: Float64
    var UACoilExternalDes: Float64
    var DesOutletAirTemp: Float64
    var DesOutletAirHumRat: Float64
    var DesOutletWaterTemp: Float64
    var HeatExchType: Int
    var CoolingCoilAnalysisMode: Int
    var UACoilInternalPerUnitArea: Float64
    var UAWetExtPerUnitArea: Float64
    var UADryExtPerUnitArea: Float64
    var SurfAreaWetFractionSaved: Float64
    var UACoilVariable: Float64
    var RatioAirSideToWaterSideConvect: Float64
    var AirSideNominalConvect: Float64
    var LiquidSideNominalConvect: Float64
    var Control: Int
    var AirInletNodeNum: Int
    var AirOutletNodeNum: Int
    var WaterInletNodeNum: Int
    var WaterOutletNodeNum: Int
    var WaterPlantLoc: PlantLocation
    var CondensateCollectMode: Int
    var CondensateCollectName: String
    var CondensateTankID: Int
    var CondensateTankSupplyARRID: Int
    var CondensateVdot: Float64
    var CondensateVol: Float64
    var CoilPerfInpMeth: Int
    var FaultyCoilFoulingFlag: Bool
    var FaultyCoilFoulingIndex: Int
    var FaultyCoilFoulingFactor: Float64
    var OriginalUACoilVariable: Float64
    var OriginalUACoilExternal: Float64
    var OriginalUACoilInternal: Float64
    var DesiccantRegenerationCoil: Bool
    var DesiccantDehumNum: Int
    var DesignWaterDeltaTemp: Float64
    var UseDesignWaterDeltaTemp: Bool
    var ControllerName: String
    var ControllerIndex: Int
    var reportCoilFinalSizes: Bool
    var AirLoopDOASFlag: Bool
    var heatRecoveryCoil: Bool
    var solveRootStats: General.SolveRootStats

    def __init__(inout self):
        self.Name = ""
        self.WaterCoilTypeA = ""
        self.WaterCoilModelA = ""
        self.WaterCoilType = PlantEquipmentType.Invalid
        self.coilType = HVAC.CoilType.Invalid
        self.coilReportNum = -1
        self.WaterCoilModel = CoilModel.Invalid
        self.availSched = None
        self.RequestingAutoSize = False
        self.InletAirMassFlowRate = 0.0
        self.OutletAirMassFlowRate = 0.0
        self.InletAirTemp = 0.0
        self.OutletAirTemp = 0.0
        self.InletAirHumRat = 0.0
        self.OutletAirHumRat = 0.0
        self.InletAirEnthalpy = 0.0
        self.OutletAirEnthalpy = 0.0
        self.TotWaterCoilLoad = 0.0
        self.SenWaterCoilLoad = 0.0
        self.TotWaterHeatingCoilEnergy = 0.0
        self.TotWaterCoolingCoilEnergy = 0.0
        self.SenWaterCoolingCoilEnergy = 0.0
        self.DesWaterHeatingCoilRate = 0.0
        self.TotWaterHeatingCoilRate = 0.0
        self.DesWaterCoolingCoilRate = 0.0
        self.TotWaterCoolingCoilRate = 0.0
        self.SenWaterCoolingCoilRate = 0.0
        self.UACoil = 0.0
        self.LeavingRelHum = 0.0
        self.DesiredOutletTemp = 0.0
        self.DesiredOutletHumRat = 0.0
        self.InletWaterTemp = 0.0
        self.OutletWaterTemp = 0.0
        self.InletWaterMassFlowRate = 0.0
        self.OutletWaterMassFlowRate = 0.0
        self.MaxWaterVolFlowRate = 0.0
        self.MaxWaterMassFlowRate = 0.0
        self.InletWaterEnthalpy = 0.0
        self.OutletWaterEnthalpy = 0.0
        self.TubeOutsideSurfArea = 0.0
        self.TotTubeInsideArea = 0.0
        self.FinSurfArea = 0.0
        self.MinAirFlowArea = 0.0
        self.CoilDepth = 0.0
        self.FinDiam = 0.0
        self.FinThickness = 0.0
        self.TubeInsideDiam = 0.0
        self.TubeOutsideDiam = 0.0
        self.TubeThermConductivity = 0.0
        self.FinThermConductivity = 0.0
        self.FinSpacing = 0.0
        self.TubeDepthSpacing = 0.0
        self.NumOfTubeRows = 0
        self.NumOfTubesPerRow = 0
        self.EffectiveFinDiam = 0.0
        self.TotCoilOutsideSurfArea = 0.0
        self.CoilEffectiveInsideDiam = 0.0
        self.GeometryCoef1 = 0.0
        self.GeometryCoef2 = 0.0
        self.DryFinEfficncyCoef = Array1D[Float64](5, 0.0)
        self.SatEnthlCurveConstCoef = 0.0
        self.SatEnthlCurveSlope = 0.0
        self.EnthVsTempCurveAppxSlope = 0.0
        self.EnthVsTempCurveConst = 0.0
        self.MeanWaterTempSaved = 0.0
        self.InWaterTempSaved = 0.0
        self.OutWaterTempSaved = 0.0
        self.SurfAreaWetSaved = 0.0
        self.SurfAreaWetFraction = 0.0
        self.DesInletWaterTemp = 0.0
        self.DesAirVolFlowRate = 0.0
        self.DesInletAirTemp = 0.0
        self.DesInletAirHumRat = 0.0
        self.DesTotWaterCoilLoad = 0.0
        self.DesSenWaterCoilLoad = 0.0
        self.DesAirMassFlowRate = 0.0
        self.UACoilTotal = 0.0
        self.UACoilInternal = 0.0
        self.UACoilExternal = 0.0
        self.UACoilInternalDes = 0.0
        self.UACoilExternalDes = 0.0
        self.DesOutletAirTemp = 0.0
        self.DesOutletAirHumRat = 0.0
        self.DesOutletWaterTemp = 0.0
        self.HeatExchType = 0
        self.CoolingCoilAnalysisMode = 0
        self.UACoilInternalPerUnitArea = 0.0
        self.UAWetExtPerUnitArea = 0.0
        self.UADryExtPerUnitArea = 0.0
        self.SurfAreaWetFractionSaved = 0.0
        self.UACoilVariable = 0.0
        self.RatioAirSideToWaterSideConvect = 1.0
        self.AirSideNominalConvect = 0.0
        self.LiquidSideNominalConvect = 0.0
        self.Control = 0
        self.AirInletNodeNum = 0
        self.AirOutletNodeNum = 0
        self.WaterInletNodeNum = 0
        self.WaterOutletNodeNum = 0
        self.WaterPlantLoc = PlantLocation()
        self.CondensateCollectMode = 1001
        self.CondensateTankID = 0
        self.CondensateTankSupplyARRID = 0
        self.CondensateVdot = 0.0
        self.CondensateVol = 0.0
        self.CoilPerfInpMeth = 0
        self.FaultyCoilFoulingFlag = False
        self.FaultyCoilFoulingIndex = 0
        self.FaultyCoilFoulingFactor = 0.0
        self.OriginalUACoilVariable = 0.0
        self.OriginalUACoilExternal = 0.0
        self.OriginalUACoilInternal = 0.0
        self.DesiccantRegenerationCoil = False
        self.DesiccantDehumNum = 0
        self.DesignWaterDeltaTemp = 0.0
        self.UseDesignWaterDeltaTemp = False
        self.ControllerName = ""
        self.ControllerIndex = 0
        self.reportCoilFinalSizes = True
        self.AirLoopDOASFlag = False
        self.heatRecoveryCoil = False
        self.solveRootStats = General.SolveRootStats()

struct WaterCoilNumericFieldData:
    var FieldNames: Array1D[String]
    def __init__(inout self):
        self.FieldNames = Array1D[String]()

# Functions
def SimulateWaterCoilComponents(
    inout state: EnergyPlusData,
    CompName: StringLiteral,
    FirstHVACIteration: Bool,
    inout CompIndex: Int,
    QActual: Optional[Float64] = None,
    fanOpMode: Optional[HVAC.FanOp] = None,
    PartLoadRatio: Optional[Float64] = None,
):
    var CoilNum: Int
    var fanOp: HVAC.FanOp
    var PartLoadFrac: Float64

    if state.dataWaterCoils.GetWaterCoilsInputFlag:
        GetWaterCoilInput(state)
        state.dataWaterCoils.GetWaterCoilsInputFlag = False

    if CompIndex == 0:
        CoilNum = Util.FindItemInList(CompName, state.dataWaterCoils.WaterCoil)
        if CoilNum == 0:
            ShowFatalError(state, Format.format("SimulateWaterCoilComponents: Coil not found={}", CompName))
        CompIndex = CoilNum
    else:
        CoilNum = CompIndex
        if CoilNum > state.dataWaterCoils.NumWaterCoils or CoilNum < 1:
            ShowFatalError(state,
                Format.format("SimulateWaterCoilComponents: Invalid CompIndex passed={}, Number of Water Coils={}, Coil name={}",
                    CoilNum, state.dataWaterCoils.NumWaterCoils, CompName))
        if state.dataWaterCoils.CheckEquipName[CoilNum]:
            var waterCoil = state.dataWaterCoils.WaterCoil[CoilNum]
            if CompName != waterCoil.Name:
                ShowFatalError(state,
                    Format.format("SimulateWaterCoilComponents: Invalid CompIndex passed={}, Coil name={}, stored Coil Name for that index={}",
                        CoilNum, CompName, waterCoil.Name))
            state.dataWaterCoils.CheckEquipName[CoilNum] = False

    InitWaterCoil(state, CoilNum, FirstHVACIteration)

    if fanOpMode.is_present():
        fanOp = fanOpMode.value()
    else:
        fanOp = HVAC.FanOp.Continuous

    if PartLoadRatio.is_present():
        PartLoadFrac = PartLoadRatio.value()
    else:
        PartLoadFrac = 1.0

    var waterCoil = state.dataWaterCoils.WaterCoil[CoilNum]
    if waterCoil.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling:
        CalcDetailFlatFinCoolingCoil(state, CoilNum, state.dataWaterCoils.SimCalc, fanOp, PartLoadFrac)
        if QActual.is_present():
            QActual.assign(waterCoil.SenWaterCoolingCoilRate)
    elif waterCoil.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterCooling:
        CoolingCoil(state, CoilNum, FirstHVACIteration, state.dataWaterCoils.SimCalc, fanOp, PartLoadFrac)
        if QActual.is_present():
            QActual.assign(waterCoil.SenWaterCoolingCoilRate)

    if waterCoil.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterSimpleHeating:
        CalcSimpleHeatingCoil(state, CoilNum, fanOp, PartLoadFrac, state.dataWaterCoils.SimCalc)
        if QActual.is_present():
            QActual.assign(waterCoil.TotWaterHeatingCoilRate)

    UpdateWaterCoil(state, CoilNum)
    ReportWaterCoil(state, CoilNum)

def GetWaterCoilInput(inout state: EnergyPlusData):
    alias RoutineName = "GetWaterCoilInput: "
    alias routineName = "GetWaterCoilInput"

    var CoilNum: Int
    var NumSimpHeat: Int = 0
    var NumFlatFin: Int = 0
    var NumCooling: Int = 0
    var SimpHeatNum: Int
    var FlatFinNum: Int
    var CoolingNum: Int
    var NumAlphas: Int
    var NumNums: Int
    var IOStat: Int
    var CurrentModuleObject: String
    var AlphArray: Array1D[String]
    var cAlphaFields: Array1D[String]
    var cNumericFields: Array1D[String]
    var NumArray: Array1D[Float64]
    var lAlphaBlanks: Array1D[Bool]
    var lNumericBlanks: Array1D[Bool]
    var MaxNums: Int = 0
    var MaxAlphas: Int = 0
    var TotalArgs: Int = 0
    var ErrorsFound: Bool = False

    NumSimpHeat = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Water")
    NumFlatFin = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Cooling:Water:DetailedGeometry")
    NumCooling = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Cooling:Water")
    state.dataWaterCoils.NumWaterCoils = NumSimpHeat + NumFlatFin + NumCooling

    if state.dataWaterCoils.NumWaterCoils > 0:
        state.dataWaterCoils.WaterCoil.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.WaterCoilNumericFields.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.WaterTempCoolCoilErrs.dimension(state.dataWaterCoils.NumWaterCoils, 0)
        state.dataWaterCoils.PartWetCoolCoilErrs.dimension(state.dataWaterCoils.NumWaterCoils, 0)
        state.dataWaterCoils.CheckEquipName.dimension(state.dataWaterCoils.NumWaterCoils, True)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Water", TotalArgs, NumAlphas, NumNums)
    MaxNums = max(MaxNums, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Cooling:Water:DetailedGeometry", TotalArgs, NumAlphas, NumNums)
    MaxNums = max(MaxNums, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Cooling:Water", TotalArgs, NumAlphas, NumNums)
    MaxNums = max(MaxNums, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)

    AlphArray.allocate(MaxAlphas)
    cAlphaFields.allocate(MaxAlphas)
    cNumericFields.allocate(MaxNums)
    NumArray.dimension(MaxNums, 0.0)
    lAlphaBlanks.dimension(MaxAlphas, True)
    lNumericBlanks.dimension(MaxNums, True)

    CurrentModuleObject = "Coil:Heating:Water"
    for SimpHeatNum in range(1, NumSimpHeat + 1):
        CoilNum = SimpHeatNum
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
            CurrentModuleObject, SimpHeatNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat,
            lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames.allocate(MaxNums)
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames = ""
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames = cNumericFields
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, AlphArray[1], ErrorsFound, CurrentModuleObject + " Name")
        var waterCoil = state.dataWaterCoils.WaterCoil[CoilNum]
        waterCoil.Name = AlphArray[1]
        waterCoil.coilType = HVAC.CoilType.HeatingWater
        waterCoil.coilReportNum = ReportCoilSelection.getReportIndex(state, waterCoil.Name, waterCoil.coilType)
        if lAlphaBlanks[2]:
            waterCoil.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            waterCoil.availSched = Sched.GetSchedule(state, AlphArray[2])
            if waterCoil.availSched == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[2], AlphArray[2])
                ErrorsFound = True
        waterCoil.WaterCoilModelA = "SIMPLE"
        waterCoil.WaterCoilModel = CoilModel.HeatingSimple
        waterCoil.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        waterCoil.UACoil = NumArray[1]
        waterCoil.UACoilVariable = waterCoil.UACoil
        waterCoil.MaxWaterVolFlowRate = NumArray[2]
        waterCoil.WaterInletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[3], ErrorsFound, Node.ConnectionObjectType.CoilHeatingWater, AlphArray[1],
            Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
        waterCoil.WaterOutletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[4], ErrorsFound, Node.ConnectionObjectType.CoilHeatingWater, AlphArray[1],
            Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
        waterCoil.AirInletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[5], ErrorsFound, Node.ConnectionObjectType.CoilHeatingWater, AlphArray[1],
            Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        waterCoil.AirOutletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[6], ErrorsFound, Node.ConnectionObjectType.CoilHeatingWater, AlphArray[1],
            Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        if AlphArray[7] == "NOMINALCAPACITY":
            waterCoil.CoilPerfInpMeth = state.dataWaterCoils.NomCap
        else:
            waterCoil.CoilPerfInpMeth = state.dataWaterCoils.UAandFlow
        waterCoil.DesTotWaterCoilLoad = NumArray[3]
        if waterCoil.UACoil == DataSizing.AutoSize and waterCoil.CoilPerfInpMeth == state.dataWaterCoils.UAandFlow:
            waterCoil.RequestingAutoSize = True
        if waterCoil.MaxWaterVolFlowRate == DataSizing.AutoSize:
            waterCoil.RequestingAutoSize = True
        if waterCoil.DesTotWaterCoilLoad == DataSizing.AutoSize and waterCoil.CoilPerfInpMeth == state.dataWaterCoils.NomCap:
            waterCoil.RequestingAutoSize = True
        waterCoil.DesInletWaterTemp = NumArray[4]
        waterCoil.DesInletAirTemp = NumArray[5]
        waterCoil.DesOutletWaterTemp = NumArray[6]
        waterCoil.DesOutletAirTemp = NumArray[7]
        waterCoil.RatioAirSideToWaterSideConvect = NumArray[8]
        if not lNumericBlanks[9]:
            waterCoil.DesignWaterDeltaTemp = NumArray[9]
            waterCoil.UseDesignWaterDeltaTemp = True
        else:
            waterCoil.UseDesignWaterDeltaTemp = False
        if waterCoil.DesInletWaterTemp <= waterCoil.DesOutletWaterTemp:
            ShowSevereError(state, Format.format("For {}, {}", CurrentModuleObject, AlphArray[1]))
            ShowContinueError(state, Format.format("  the {} must be greater than the {}.", cNumericFields[4], cNumericFields[6]))
            ErrorsFound = True
        if waterCoil.DesInletAirTemp >= waterCoil.DesOutletAirTemp:
            ShowSevereError(state, Format.format("For {}, {}", CurrentModuleObject, AlphArray[1]))
            ShowContinueError(state, Format.format("  the {} must be less than the {}.", cNumericFields[5], cNumericFields[7]))
            ErrorsFound = True
        if waterCoil.DesInletAirTemp >= waterCoil.DesInletWaterTemp:
            ShowSevereError(state, Format.format("For {}, {}", CurrentModuleObject, AlphArray[1]))
            ShowContinueError(state, Format.format("  the {} must be less than the {}.", cNumericFields[5], cNumericFields[4]))
            ErrorsFound = True
        NodeManager.TestCompSet(state, CurrentModuleObject, AlphArray[1], AlphArray[3], AlphArray[4], "Water Nodes")
        NodeManager.TestCompSet(state, CurrentModuleObject, AlphArray[1], AlphArray[5], AlphArray[6], "Air Nodes")
        SetupOutputVariable(state,
            "Heating Coil Heating Energy", Constant.Units.J, waterCoil.TotWaterHeatingCoilEnergy,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, waterCoil.Name,
            Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.HeatingCoils)
        SetupOutputVariable(state,
            "Heating Coil Source Side Heat Transfer Energy", Constant.Units.J, waterCoil.TotWaterHeatingCoilEnergy,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, waterCoil.Name,
            Constant.eResource.PlantLoopHeatingDemand, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.HeatingCoils)
        SetupOutputVariable(state,
            "Heating Coil Heating Rate", Constant.Units.W, waterCoil.TotWaterHeatingCoilRate,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil.Name)
        SetupOutputVariable(state,
            "Heating Coil U Factor Times Area Value", Constant.Units.W_K, waterCoil.UACoilVariable,
            OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil.Name)

    CurrentModuleObject = "Coil:Cooling:Water:DetailedGeometry"
    for FlatFinNum in range(1, NumFlatFin + 1):
        CoilNum = NumSimpHeat + FlatFinNum
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
            CurrentModuleObject, FlatFinNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat,
            lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh2 = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames.allocate(MaxNums)
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames = ""
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames = cNumericFields
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, AlphArray[1], ErrorsFound, CurrentModuleObject + " Name")
        var waterCoil2 = state.dataWaterCoils.WaterCoil[CoilNum]
        waterCoil2.Name = AlphArray[1]
        waterCoil2.coilType = HVAC.CoilType.CoolingWaterDetailed
        waterCoil2.coilReportNum = ReportCoilSelection.getReportIndex(state, waterCoil2.Name, waterCoil2.coilType)
        if lAlphaBlanks[2]:
            waterCoil2.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            waterCoil2.availSched = Sched.GetSchedule(state, AlphArray[2])
            if waterCoil2.availSched == None:
                ShowSevereItemNotFound(state, eoh2, cAlphaFields[2], AlphArray[2])
                ErrorsFound = True
        waterCoil2.WaterCoilModelA = "DETAILED FLAT FIN"
        waterCoil2.WaterCoilModel = CoilModel.CoolingDetailed
        waterCoil2.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling
        waterCoil2.MaxWaterVolFlowRate = NumArray[1]
        if waterCoil2.MaxWaterVolFlowRate == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        waterCoil2.TubeOutsideSurfArea = NumArray[2]
        if waterCoil2.TubeOutsideSurfArea == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        waterCoil2.TotTubeInsideArea = NumArray[3]
        if waterCoil2.TotTubeInsideArea == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        waterCoil2.FinSurfArea = NumArray[4]
        if waterCoil2.FinSurfArea == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        waterCoil2.MinAirFlowArea = NumArray[5]
        if waterCoil2.MinAirFlowArea == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        waterCoil2.CoilDepth = NumArray[6]
        if waterCoil2.CoilDepth == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        waterCoil2.FinDiam = NumArray[7]
        if waterCoil2.FinDiam == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        waterCoil2.FinThickness = NumArray[8]
        if waterCoil2.FinThickness <= 0.0:
            ShowSevereError(state, Format.format("{}: {} must be > 0.0, for {} = {}", CurrentModuleObject, cNumericFields[8], cAlphaFields[1], waterCoil2.Name))
            ErrorsFound = True
        waterCoil2.TubeInsideDiam = NumArray[9]
        waterCoil2.TubeOutsideDiam = NumArray[10]
        waterCoil2.TubeThermConductivity = NumArray[11]
        if waterCoil2.TubeThermConductivity <= 0.0:
            ShowSevereError(state, Format.format("{}: {} must be > 0.0, for {} = {}", CurrentModuleObject, cNumericFields[11], cAlphaFields[1], waterCoil2.Name))
            ErrorsFound = True
        waterCoil2.FinThermConductivity = NumArray[12]
        if waterCoil2.FinThermConductivity <= 0.0:
            ShowSevereError(state, Format.format("{}: {} must be > 0.0, for {} = {}", CurrentModuleObject, cNumericFields[12], cAlphaFields[1], waterCoil2.Name))
            ErrorsFound = True
        waterCoil2.FinSpacing = NumArray[13]
        waterCoil2.TubeDepthSpacing = NumArray[14]
        waterCoil2.NumOfTubeRows = NumArray[15]
        waterCoil2.NumOfTubesPerRow = NumArray[16]
        if waterCoil2.NumOfTubesPerRow == DataSizing.AutoSize:
            waterCoil2.RequestingAutoSize = True
        if not lNumericBlanks[17]:
            waterCoil2.DesignWaterDeltaTemp = NumArray[17]
            waterCoil2.UseDesignWaterDeltaTemp = True
        else:
            waterCoil2.UseDesignWaterDeltaTemp = False
        waterCoil2.WaterInletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[3], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterDetailedGeometry, AlphArray[1],
            Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
        waterCoil2.WaterOutletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[4], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterDetailedGeometry, AlphArray[1],
            Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
        waterCoil2.AirInletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[5], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterDetailedGeometry, AlphArray[1],
            Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        waterCoil2.AirOutletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[6], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterDetailedGeometry, AlphArray[1],
            Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        waterCoil2.CondensateCollectName = AlphArray[7]
        if lAlphaBlanks[7]:
            waterCoil2.CondensateCollectMode = state.dataWaterCoils.CondensateDiscarded
        else:
            waterCoil2.CondensateCollectMode = state.dataWaterCoils.CondensateToTank
            WaterManager.SetupTankSupplyComponent(state, waterCoil2.Name, CurrentModuleObject,
                waterCoil2.CondensateCollectName, ErrorsFound, waterCoil2.CondensateTankID, waterCoil2.CondensateTankSupplyARRID)
        NodeManager.TestCompSet(state, CurrentModuleObject, AlphArray[1], AlphArray[3], AlphArray[4], "Water Nodes")
        NodeManager.TestCompSet(state, CurrentModuleObject, AlphArray[1], AlphArray[5], AlphArray[6], "Air Nodes")
        SetupOutputVariable(state, "Cooling Coil Total Cooling Energy", Constant.Units.J,
            waterCoil2.TotWaterCoolingCoilEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum,
            waterCoil2.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingCoils)
        SetupOutputVariable(state, "Cooling Coil Source Side Heat Transfer Energy", Constant.Units.J,
            waterCoil2.TotWaterCoolingCoilEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum,
            waterCoil2.Name, Constant.eResource.PlantLoopCoolingDemand, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingCoils)
        SetupOutputVariable(state, "Cooling Coil Sensible Cooling Energy", Constant.Units.J,
            waterCoil2.SenWaterCoolingCoilEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, waterCoil2.Name)
        SetupOutputVariable(state, "Cooling Coil Total Cooling Rate", Constant.Units.W,
            waterCoil2.TotWaterCoolingCoilRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil2.Name)
        SetupOutputVariable(state, "Cooling Coil Sensible Cooling Rate", Constant.Units.W,
            waterCoil2.SenWaterCoolingCoilRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil2.Name)
        if waterCoil2.CondensateCollectMode == state.dataWaterCoils.CondensateToTank:
            SetupOutputVariable(state, "Cooling Coil Condensate Volume Flow Rate", Constant.Units.m3_s,
                waterCoil2.CondensateVdot, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil2.Name)
            SetupOutputVariable(state, "Cooling Coil Condensate Volume", Constant.Units.m3,
                waterCoil2.CondensateVol, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, waterCoil2.Name,
                Constant.eResource.OnSiteWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Condensate)

    CurrentModuleObject = "Coil:Cooling:Water"
    for CoolingNum in range(1, NumCooling + 1):
        CoilNum = NumSimpHeat + NumFlatFin + CoolingNum
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
            CurrentModuleObject, CoolingNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat,
            lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh3 = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames.allocate(MaxNums)
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames = ""
        state.dataWaterCoils.WaterCoilNumericFields[CoilNum].FieldNames = cNumericFields
        GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, AlphArray[1], ErrorsFound, CurrentModuleObject + " Name")
        var waterCoil3 = state.dataWaterCoils.WaterCoil[CoilNum]
        waterCoil3.Name = AlphArray[1]
        waterCoil3.coilType = HVAC.CoilType.CoolingWater
        waterCoil3.coilReportNum = ReportCoilSelection.getReportIndex(state, waterCoil3.Name, waterCoil3.coilType)
        if lAlphaBlanks[2]:
            waterCoil3.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            waterCoil3.availSched = Sched.GetSchedule(state, AlphArray[2])
            if waterCoil3.availSched == None:
                ShowSevereItemNotFound(state, eoh3, cAlphaFields[2], AlphArray[2])
                ErrorsFound = True
        waterCoil3.WaterCoilModelA = "Cooling"
        waterCoil3.WaterCoilModel = CoilModel.CoolingSimple
        waterCoil3.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterCooling
        waterCoil3.MaxWaterVolFlowRate = NumArray[1]
        if waterCoil3.MaxWaterVolFlowRate == DataSizing.AutoSize:
            waterCoil3.RequestingAutoSize = True
        waterCoil3.DesAirVolFlowRate = NumArray[2]
        if waterCoil3.DesAirVolFlowRate == DataSizing.AutoSize:
            waterCoil3.RequestingAutoSize = True
        waterCoil3.DesInletWaterTemp = NumArray[3]
        if waterCoil3.DesInletWaterTemp == DataSizing.AutoSize:
            waterCoil3.RequestingAutoSize = True
        waterCoil3.DesInletAirTemp = NumArray[4]
        if waterCoil3.DesInletAirTemp == DataSizing.AutoSize:
            waterCoil3.RequestingAutoSize = True
        waterCoil3.DesOutletAirTemp = NumArray[5]
        if waterCoil3.DesOutletAirTemp == DataSizing.AutoSize:
            waterCoil3.RequestingAutoSize = True
        waterCoil3.DesInletAirHumRat = NumArray[6]
        if waterCoil3.DesInletAirHumRat == DataSizing.AutoSize:
            waterCoil3.RequestingAutoSize = True
        waterCoil3.DesOutletAirHumRat = NumArray[7]
        if waterCoil3.DesOutletAirHumRat == DataSizing.AutoSize:
            waterCoil3.RequestingAutoSize = True
        if not lNumericBlanks[8]:
            waterCoil3.DesignWaterDeltaTemp = NumArray[8]
            waterCoil3.UseDesignWaterDeltaTemp = True
        else:
            waterCoil3.UseDesignWaterDeltaTemp = False
        waterCoil3.WaterInletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[3], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWater, AlphArray[1],
            Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
        waterCoil3.WaterOutletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[4], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWater, AlphArray[1],
            Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
        waterCoil3.AirInletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[5], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWater, AlphArray[1],
            Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        waterCoil3.AirOutletNodeNum = NodeManager.GetOnlySingleNode(state,
            AlphArray[6], ErrorsFound, Node.ConnectionObjectType.CoilCoolingWater, AlphArray[1],
            Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        if AlphArray[7] == "DETAILEDANALYSIS":
            waterCoil3.CoolingCoilAnalysisMode = state.dataWaterCoils.DetailedAnalysis
        else:
            waterCoil3.CoolingCoilAnalysisMode = state.dataWaterCoils.SimpleAnalysis
        if AlphArray[8] == "COUNTERFLOW":
            waterCoil3.HeatExchType = state.dataWaterCoils.CounterFlow
        else:
            waterCoil3.HeatExchType = state.dataWaterCoils.CrossFlow
        waterCoil3.CondensateCollectName = AlphArray[9]
        if lAlphaBlanks[9]:
            waterCoil3.CondensateCollectMode = state.dataWaterCoils.CondensateDiscarded
        else:
            waterCoil3.CondensateCollectMode = state.dataWaterCoils.CondensateToTank
            WaterManager.SetupTankSupplyComponent(state, waterCoil3.Name, CurrentModuleObject,
                waterCoil3.CondensateCollectName, ErrorsFound, waterCoil3.CondensateTankID, waterCoil3.CondensateTankSupplyARRID)
        NodeManager.TestCompSet(state, CurrentModuleObject, AlphArray[1], AlphArray[3], AlphArray[4], "Water Nodes")
        NodeManager.TestCompSet(state, CurrentModuleObject, AlphArray[1], AlphArray[5], AlphArray[6], "Air Nodes")
        SetupOutputVariable(state, "Cooling Coil Total Cooling Energy", Constant.Units.J,
            waterCoil3.TotWaterCoolingCoilEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum,
            waterCoil3.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingCoils)
        SetupOutputVariable(state, "Cooling Coil Source Side Heat Transfer Energy", Constant.Units.J,
            waterCoil3.TotWaterCoolingCoilEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum,
            waterCoil3.Name, Constant.eResource.PlantLoopCoolingDemand, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingCoils)
        SetupOutputVariable(state, "Cooling Coil Sensible Cooling Energy", Constant.Units.J,
            waterCoil3.SenWaterCoolingCoilEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, waterCoil3.Name)
        SetupOutputVariable(state, "Cooling Coil Total Cooling Rate", Constant.Units.W,
            waterCoil3.TotWaterCoolingCoilRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil3.Name)
        SetupOutputVariable(state, "Cooling Coil Sensible Cooling Rate", Constant.Units.W,
            waterCoil3.SenWaterCoolingCoilRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil3.Name)
        SetupOutputVariable(state, "Cooling Coil Wetted Area Fraction", Constant.Units.None,
            waterCoil3.SurfAreaWetFraction, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil3.Name)
        if waterCoil3.CondensateCollectMode == state.dataWaterCoils.CondensateToTank:
            SetupOutputVariable(state, "Cooling Coil Condensate Volume Flow Rate", Constant.Units.m3_s,
                waterCoil3.CondensateVdot, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, waterCoil3.Name)
            SetupOutputVariable(state, "Cooling Coil Condensate Volume", Constant.Units.m3,
                waterCoil3.CondensateVol, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, waterCoil3.Name,
                Constant.eResource.OnSiteWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Condensate)

    if ErrorsFound:
        ShowFatalError(state, Format.format("{}Errors found in getting input.", RoutineName))

    AlphArray.deallocate()
    cAlphaFields.deallocate()
    cNumericFields.deallocate()
    NumArray.deallocate()
    lAlphaBlanks.deallocate()
    lNumericBlanks.deallocate()

def InitWaterCoil(inout state: EnergyPlusData, CoilNum: Int, FirstHVACIteration: Bool):
    alias SmallNo: Float64 = 1.0e-9
    alias itmax: Int = 10
    alias RoutineName = "InitWaterCoil"

    var tempCoilNum: Int
    var DesInletAirEnth: Float64
    var DesOutletAirEnth: Float64
    var DesAirApparatusDewPtEnth: Float64
    var DesSatEnthAtWaterInTemp: Float64
    var DesHumRatAtWaterInTemp: Float64
    var CapacitanceAir: Float64
    var DesAirTempApparatusDewPt: Float64
    var DesAirHumRatApparatusDewPt: Float64
    var DesBypassFactor: Float64
    var SlopeTempVsHumRatio: Float64
    var TempApparatusDewPtEstimate: Float64
    var Y1: Float64
    var X1: Float64
    var error: Float64
    var iter: Int
    var icvg: Int
    var ResultX: Float64
    var Ipass: Int
    var AirInletNode: Int
    var WaterInletNode: Int
    var WaterOutletNode: Int
    var FinDiamVar: Float64
    var TubeToFinDiamRatio: Float64
    var CpAirStd: Float64
    var UA0: Float64
    var UA1: Float64
    var UA: Float64
    var DesUACoilExternalEnth: Float64
    var LogMeanEnthDiff: Float64
    var LogMeanTempDiff: Float64
    var DesOutletWaterTemp: Float64
    var DesSatEnthAtWaterOutTemp: Float64
    var DesEnthAtWaterOutTempAirInHumRat: Float64
    var DesEnthWaterOut: Float64
    var Cp: Float64
    var rho: Float64
    var errFlag: Bool
    var EnthCorrFrac: Float64 = 0.0
    var TempCorrFrac: Float64 = 0.0

    if state.dataWaterCoils.InitWaterCoilOneTimeFlag:
        state.dataWaterCoils.MyEnvrnFlag.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.MySizeFlag.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.CoilWarningOnceFlag.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.DesCpAir.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.MyCoilDesignFlag.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.MyCoilReportFlag.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.DesUARangeCheck.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.PlantLoopScanFlag.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.DesCpAir = 0.0
        state.dataWaterCoils.DesUARangeCheck = 0.0
        state.dataWaterCoils.MyEnvrnFlag = True
        state.dataWaterCoils.MySizeFlag = True
        state.dataWaterCoils.CoilWarningOnceFlag = True
        state.dataWaterCoils.MyUAAndFlowCalcFlag = True
        state.dataWaterCoils.MyCoilDesignFlag = True
        state.dataWaterCoils.MyCoilReportFlag = True
        state.dataWaterCoils.InitWaterCoilOneTimeFlag = False
        state.dataWaterCoils.PlantLoopScanFlag = True
        for tempCoilNum in range(1, state.dataWaterCoils.NumWaterCoils + 1):
            HVACControllers.GetControllerNameAndIndex(state,
                state.dataWaterCoils.WaterCoil[tempCoilNum].WaterInletNodeNum,
                state.dataWaterCoils.WaterCoil[tempCoilNum].ControllerName,
                state.dataWaterCoils.WaterCoil[tempCoilNum].ControllerIndex, errFlag)

    if state.dataWaterCoils.WaterCoilControllerCheckOneTimeFlag and state.dataHVACGlobal.GetAirPathDataDone:
        var ErrorsFound: Bool = False
        var WaterCoilOnAirLoop: Bool = True
        for tempCoilNum in range(1, state.dataWaterCoils.NumWaterCoils + 1):
            if state.dataWaterCoils.WaterCoil[tempCoilNum].ControllerIndex > 0:
                var CoilTypeNum = SimAirServingZones.CompType.Invalid
                var CompType: String
                var CompName = state.dataWaterCoils.WaterCoil[tempCoilNum].Name
                if state.dataWaterCoils.WaterCoil[tempCoilNum].WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterCooling:
                    CoilTypeNum = SimAirServingZones.CompType.WaterCoil_Cooling
                    CompType = HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWater)]
                elif state.dataWaterCoils.WaterCoil[tempCoilNum].WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling:
                    CoilTypeNum = SimAirServingZones.CompType.WaterCoil_DetailedCool
                    CompType = HVAC.coilTypeNames[int(HVAC.CoilType.CoolingWaterDetailed)]
                elif state.dataWaterCoils.WaterCoil[tempCoilNum].WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterSimpleHeating:
                    CoilTypeNum = SimAirServingZones.CompType.WaterCoil_SimpleHeat
                    CompType = HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)]
                WaterCoilOnAirLoop = True
                SimAirServingZones.CheckWaterCoilIsOnAirLoop(state, CoilTypeNum, CompType, CompName, WaterCoilOnAirLoop)
                if not WaterCoilOnAirLoop:
                    ShowContinueError(state,
                        Format.format("Controller:WaterCoil = {}. Invalid water controller entry.",
                            state.dataWaterCoils.WaterCoil[tempCoilNum].ControllerName))
                    ErrorsFound = True
        state.dataWaterCoils.WaterCoilControllerCheckOneTimeFlag = False
        if ErrorsFound:
            ShowFatalError(state, "Program terminated for previous condition.")

    var waterCoil = state.dataWaterCoils.WaterCoil[CoilNum]
    if state.dataWaterCoils.PlantLoopScanFlag[CoilNum] and allocated(state.dataPlnt.PlantLoop):
        errFlag = False
        PlantUtilities.ScanPlantLoopsForObject(state, waterCoil.Name, waterCoil.WaterCoilType, waterCoil.WaterPlantLoc, errFlag, _, _, _, _, _)
        if errFlag:
            ShowFatalError(state, "InitWaterCoil: Program terminated for previous conditions.")
        state.dataWaterCoils.PlantLoopScanFlag[CoilNum] = False

    if not state.dataGlobal.SysSizingCalc and state.dataWaterCoils.MySizeFlag[CoilNum]:
        SizeWaterCoil(state, CoilNum)
        state.dataWaterCoils.MySizeFlag[CoilNum] = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataWaterCoils.MyEnvrnFlag[CoilNum]:
        rho = waterCoil.WaterPlantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, RoutineName)
        waterCoil.TotWaterHeatingCoilEnergy = 0.0
        waterCoil.TotWaterCoolingCoilEnergy = 0.0
        waterCoil.SenWaterCoolingCoilEnergy = 0.0
        waterCoil.TotWaterHeatingCoilRate = 0.0
        waterCoil.TotWaterCoolingCoilRate = 0.0
        waterCoil.SenWaterCoolingCoilRate = 0.0
        AirInletNode = waterCoil.AirInletNodeNum
        WaterInletNode = waterCoil.WaterInletNodeNum
        WaterOutletNode = waterCoil.WaterOutletNodeNum
        state.dataWaterCoils.DesCpAir[CoilNum] = PsyCpAirFnW(0.0)
        state.dataWaterCoils.DesUARangeCheck[CoilNum] = (-1568.6 * waterCoil.DesInletAirHumRat + 20.157)

        if (waterCoil.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterCooling) or \
           (waterCoil.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling):
            var waterInletNode = state.dataLoopNodes.Node[WaterInletNode]
            waterInletNode.Temp = 5.0
            Cp = waterCoil.WaterPlantLoc.loop.glycol.getSpecificHeat(state, waterInletNode.Temp, RoutineName)
            waterInletNode.Enthalpy = Cp * waterInletNode.Temp
            waterInletNode.Quality = 0.0
            waterInletNode.Press = 0.0
            waterInletNode.HumRat = 0.0

        if waterCoil.WaterCoilType == DataPlant.PlantEquipmentType.CoilWaterSimpleHeating:
            var waterInletNode2 = state.dataLoopNodes.Node[WaterInletNode]
            waterInletNode2.Temp = 60.0
            Cp = waterCoil.WaterPlantLoc.loop.glycol.getSpecificHeat(state, waterInletNode2.Temp, RoutineName)
            waterInletNode2.Enthalpy = Cp * waterInletNode2.Temp
            waterInletNode2.Quality = 0.0
            waterInletNode2.Press = 0.0
            waterInletNode2.HumRat = 0.0
            state.dataWaterCoils.MyUAAndFlowCalcFlag[CoilNum] = False
            CpAirStd = PsyCpAirFnW(0.0)
            waterCoil.DesAirMassFlowRate = state.dataEnvrn.StdRhoAir * waterCoil.DesAirVolFlowRate
            waterCoil.LiquidSideNominalConvect = waterCoil.UACoil * (waterCoil.RatioAirSideToWaterSideConvect + 1) / waterCoil.RatioAirSideToWaterSideConvect
            waterCoil.AirSideNominalConvect = waterCoil.RatioAirSideToWaterSideConvect * waterCoil.LiquidSideNominalConvect
        else:
            state.dataWaterCoils.MyUAAndFlowCalcFlag[CoilNum] = False

        waterCoil.MaxWaterMassFlowRate = rho * waterCoil.MaxWaterVolFlowRate
        PlantUtilities.InitComponentNodes(state, 0.0, waterCoil.MaxWaterMassFlowRate, waterCoil.WaterInletNodeNum, waterCoil.WaterOutletNodeNum)

        if waterCoil.WaterCoilModel == CoilModel.CoolingDetailed:
            waterCoil.EffectiveFinDiam = Math.sqrt(4.0 * waterCoil.FinDiam * waterCoil.CoilDepth / (Constant.Pi * waterCoil.NumOfTubeRows * waterCoil.NumOfTubesPerRow))
            waterCoil.TotCoilOutsideSurfArea = waterCoil.TubeOutsideSurfArea + waterCoil.FinSurfArea
            waterCoil.CoilEffectiveInsideDiam = 4.0 * waterCoil.MinAirFlowArea * waterCoil.CoilDepth / waterCoil.TotCoilOutsideSurfArea
            TubeToFinDiamRatio = waterCoil.TubeOutsideDiam / waterCoil.EffectiveFinDiam
            if TubeToFinDiamRatio > 1.0:
                ShowWarningError(state, Format.format("InitWaterCoil: Detailed Flat Fin Coil, TubetoFinDiamRatio > 1.0, [{:.4R}]", TubeToFinDiamRatio))
                waterCoil.TubeDepthSpacing *= (pow_2(TubeToFinDiamRatio) + 0.1)
                waterCoil.CoilDepth = waterCoil.TubeDepthSpacing * waterCoil.NumOfTubeRows
                waterCoil.EffectiveFinDiam = Math.sqrt(4.0 * waterCoil.FinDiam * waterCoil.CoilDepth / (Constant.Pi * waterCoil.NumOfTubeRows * waterCoil.NumOfTubesPerRow))
                waterCoil.CoilEffectiveInsideDiam = 4.0 * waterCoil.MinAirFlowArea * waterCoil.CoilDepth / waterCoil.TotCoilOutsideSurfArea
                TubeToFinDiamRatio = waterCoil.TubeOutsideDiam / waterCoil.EffectiveFinDiam
                ShowContinueError(state, Format.format("  Resetting tube depth spacing to {:.4R} meters", waterCoil.TubeDepthSpacing))
                ShowContinueError(state, Format.format("  Resetting coil depth to {:.4R} meters", waterCoil.CoilDepth))
            CalcDryFinEffCoef(state, TubeToFinDiamRatio, state.dataWaterCoils.CoefSeries)
            waterCoil.DryFinEfficncyCoef = state.dataWaterCoils.CoefSeries
            FinDiamVar = 0.5 * (waterCoil.EffectiveFinDiam - waterCoil.TubeOutsideDiam)
            waterCoil.GeometryCoef1 = 0.159 * Math.pow(waterCoil.FinThickness / waterCoil.CoilEffectiveInsideDiam, -0.065) * \
                                      Math.pow(waterCoil.FinThickness / FinDiamVar, 0.141)
            waterCoil.GeometryCoef2 = -0.323 * Math.pow(waterCoil.FinSpacing / FinDiamVar, 0.049) * \
                                      Math.pow(waterCoil.EffectiveFinDiam / waterCoil.TubeDepthSpacing, 0.549) * \
                                      Math.pow(waterCoil.FinThickness / waterCoil.FinSpacing, -0.028)
            waterCoil.SatEnthlCurveConstCoef = -10.57
            waterCoil.SatEnthlCurveSlope = 3.3867
            waterCoil.EnthVsTempCurveAppxSlope = 3.3867
            waterCoil.EnthVsTempCurveConst = -10.57
            waterCoil.SurfAreaWetSaved = 0.0
            waterCoil.MeanWaterTempSaved = 0.0
            waterCoil.InWaterTempSaved = 0.0
            waterCoil.OutWaterTempSaved = 0.0

        if state.dataWaterCoils.MyCoilDesignFlag[CoilNum] and (waterCoil.WaterCoilModel == CoilModel.CoolingSimple) and \
           (waterCoil.DesAirVolFlowRate > 0.0) and (waterCoil.MaxWaterMassFlowRate > 0.0):
            DesInletAirEnth = PsyHFnTdbW(waterCoil.DesInletAirTemp, waterCoil.DesInletAirHumRat)
            DesOutletAirEnth = PsyHFnTdbW(waterCoil.DesOutletAirTemp, waterCoil.DesOutletAirHumRat)
            DesSatEnthAtWaterInTemp = PsyHFnTdbW(waterCoil.DesInletWaterTemp,
                PsyWFnTdpPb(state, waterCoil.DesInletWaterTemp, state.dataEnvrn.StdBaroPress))
            DesHumRatAtWaterInTemp = PsyWFnTdbH(state, waterCoil.DesInletWaterTemp, DesSatEnthAtWaterInTemp, RoutineName)
            if DesHumRatAtWaterInTemp > waterCoil.DesOutletAirHumRat and waterCoil.DesOutletAirTemp > waterCoil.DesInletWaterTemp:
                DesSatEnthAtWaterInTemp = PsyHFnTdbW(waterCoil.DesInletWaterTemp, waterCoil.DesOutletAirHumRat) - 0.0001
            if DesOutletAirEnth >= DesInletAirEnth or waterCoil.DesInletWaterTemp >= waterCoil.DesInletAirTemp:
                ShowWarningError(state, Format.format("The design cooling capacity is zero for Coil:Cooling:Water {}", waterCoil.Name))
                ShowContinueError(state, "  The maximum water flow rate for this coil will be set to zero and the coil will do no cooling.")
                ShowContinueError(state, Format.format("  Check the following coil design inputs for problems: Tair,in = {:.4R}", waterCoil.DesInletAirTemp))
                ShowContinueError(state, Format.format("                                                       Wair,in = {:.6R}", waterCoil.DesInletAirHumRat))
                ShowContinueError(state, Format.format("                                                       Twater,in = {:.4R}", waterCoil.DesInletWaterTemp))
                ShowContinueError(state, Format.format("                                                       Tair,out = {:.4R}",