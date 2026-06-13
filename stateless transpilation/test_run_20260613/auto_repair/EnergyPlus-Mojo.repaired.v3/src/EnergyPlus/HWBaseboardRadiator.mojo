from .Data.BaseData import BaseGlobalStruct
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import Environment
from DataGlobals import *
from DataHVACGlobals import *
from DataHeatBalFanSys import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataIPShortCuts import *

from DataSizing import *
from DataSurfaces import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from FluidProperties import *
from General import *
from GeneralRoutines import *
from GlobalNames import *
from HeatBalanceIntRadExchange import *
from HeatBalanceSurfaceManager import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from .Plant.DataPlant import *
from .Plant.PlantLocation import PlantLocation
from PlantUtilities import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from .Autosizing.HeatingCapacitySizing import *
from BranchNodeConnections import *

from math import log, exp, pow, abs
from sys import *

let cCMO_BBRadiator_Water: String = "ZoneHVAC:Baseboard:RadiantConvective:Water"
let cCMO_BBRadiator_Water_Design: String = "ZoneHVAC:Baseboard:RadiantConvective:Water:Design"

struct HWBaseboardParams:
    var Name: String
    var EquipType: PlantEquipmentType = PlantEquipmentType.Invalid
    var designObjectName: String
    var DesignObjectPtr: Int = 0
    var SurfacePtr: List[Int] = []
    var ZonePtr: Int = 0
    var availSched: Schedule? = None
    var WaterInletNode: Int = 0
    var WaterOutletNode: Int = 0
    var TotSurfToDistrib: Int = 0
    var ControlCompTypeNum: Int = 0
    var CompErrIndex: Int = 0
    var AirMassFlowRate: Float64 = 0.0
    var AirMassFlowRateStd: Float64 = 0.0
    var WaterTempAvg: Float64 = 0.0
    var RatedCapacity: Float64 = 0.0
    var UA: Float64 = 0.0
    var WaterMassFlowRate: Float64 = 0.0
    var WaterMassFlowRateMax: Float64 = 0.0
    var WaterMassFlowRateStd: Float64 = 0.0
    var WaterVolFlowRateMax: Float64 = 0.0
    var WaterInletTempStd: Float64 = 0.0
    var WaterInletTemp: Float64 = 0.0
    var WaterInletEnthalpy: Float64 = 0.0
    var WaterOutletTempStd: Float64 = 0.0
    var WaterOutletTemp: Float64 = 0.0
    var WaterOutletEnthalpy: Float64 = 0.0
    var AirInletTempStd: Float64 = 0.0
    var AirInletTemp: Float64 = 0.0
    var AirOutletTemp: Float64 = 0.0
    var AirInletHumRat: Float64 = 0.0
    var AirOutletTempStd: Float64 = 0.0
    var FracConvect: Float64 = 0.0
    var FracDistribToSurf: List[Float64] = []
    var TotPower: Float64 = 0.0
    var Power: Float64 = 0.0
    var ConvPower: Float64 = 0.0
    var RadPower: Float64 = 0.0
    var TotEnergy: Float64 = 0.0
    var Energy: Float64 = 0.0
    var ConvEnergy: Float64 = 0.0
    var RadEnergy: Float64 = 0.0
    var plantLoc: PlantLocation = PlantLocation()
    var BBLoadReSimIndex: Int = 0
    var BBMassFlowReSimIndex: Int = 0
    var BBInletTempFlowReSimIndex: Int = 0
    var HeatingCapMethod: Int = 0
    var ScaledHeatingCapacity: Float64 = 0.0
    var ZeroBBSourceSumHATsurf: Float64 = 0.0
    var QBBRadSource: Float64 = 0.0
    var QBBRadSrcAvg: Float64 = 0.0
    var LastSysTimeElapsed: Float64 = 0.0
    var LastTimeStepSys: Float64 = 0.0
    var LastQBBRadSrc: Float64 = 0.0

struct HWBaseboardDesignData:
    var designName: String
    var HeatingCapMethod: DesignSizingType = DesignSizingType.Invalid
    var ScaledHeatingCapacity: Float64 = 0.0
    var Offset: Float64 = 0.0
    var FracRadiant: Float64 = 0.0
    var FracDistribPerson: Float64 = 0.0

struct HWBaseboardNumericFieldData:
    var FieldNames: List[String] = []

struct HWBaseboardDesignNumericFieldData:
    var FieldNames: List[String] = []

struct HWBaseboardRadiatorData(BaseGlobalStruct):
    var MySizeFlag: List[Bool]
    var CheckEquipName: List[Bool]
    var SetLoopIndexFlag: List[Bool]
    var NumHWBaseboards: Int = 0
    var NumHWBaseboardDesignObjs: Int = 0
    var HWBaseboard: List[HWBaseboardParams] = []
    var HWBaseboardDesignObject: List[HWBaseboardDesignData] = []
    var HWBaseboardNumericFields: List[HWBaseboardNumericFieldData] = []
    var GetInputFlag: Bool = True
    var MyOneTimeFlag: Bool = True
    var Iter: Int = 0
    var MyEnvrnFlag2: Bool = True
    var MyEnvrnFlag: List[Bool]

    def init_constant_state[state: EnergyPlusData]() -> None:

    def init_state[state: EnergyPlusData]() -> None:

    def clear_state() -> None:
        self.MySizeFlag = []
        self.CheckEquipName = []
        self.SetLoopIndexFlag = []
        self.NumHWBaseboards = 0
        self.NumHWBaseboardDesignObjs = 0
        self.HWBaseboard = []
        self.HWBaseboardDesignObject = []
        self.HWBaseboardNumericFields = []
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.MyEnvrnFlag = []
        self.Iter = 0
        self.MyEnvrnFlag2 = True

def SimHWBaseboard(state: EnergyPlusData, EquipName: String, ControlledZoneNum: Int, FirstHVACIteration: Bool, PowerMet: Float64, CompIndex: Int) -> None:
    var BaseboardNum: Int
    var QZnReq: Float64
    var MaxWaterFlow: Float64
    var MinWaterFlow: Float64
    if state.dataHWBaseboardRad.GetInputFlag:
        GetHWBaseboardInput(state)
        state.dataHWBaseboardRad.GetInputFlag = False
    let NumHWBaseboards = state.dataHWBaseboardRad.NumHWBaseboards
    if CompIndex == 0:
        BaseboardNum = Util.FindItemInList(EquipName, state.dataHWBaseboardRad.HWBaseboard, HWBaseboardParams.Name)
        if BaseboardNum == 0:
            ShowFatalError(state, f"SimHWBaseboard: Unit not found={EquipName}")
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        if BaseboardNum > NumHWBaseboards or BaseboardNum < 1:
            ShowFatalError(state, f"SimHWBaseboard:  Invalid CompIndex passed={BaseboardNum}, Number of Units={NumHWBaseboards}, Entered Unit name={EquipName}")
        if state.dataHWBaseboardRad.CheckEquipName[BaseboardNum - 1]:
            if EquipName != state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1].Name:
                ShowFatalError(state, f"SimHWBaseboard: Invalid CompIndex passed={BaseboardNum}, Unit name={EquipName}, stored Unit Name for that index={state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1].Name}")
            state.dataHWBaseboardRad.CheckEquipName[BaseboardNum - 1] = False
    if CompIndex > 0:
        var hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1]
        let HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[hWBaseboard.DesignObjectPtr - 1]
        InitHWBaseboard(state, BaseboardNum, ControlledZoneNum, FirstHVACIteration)
        QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum - 1].RemainingOutputReqToHeatSP
        if FirstHVACIteration:
            MaxWaterFlow = hWBaseboard.WaterMassFlowRateMax
            MinWaterFlow = 0.0
        else:
            MaxWaterFlow = state.dataLoopNodes.Node[hWBaseboard.WaterInletNode - 1].MassFlowRateMaxAvail
            MinWaterFlow = state.dataLoopNodes.Node[hWBaseboard.WaterInletNode - 1].MassFlowRateMinAvail
        match hWBaseboard.EquipType:
            case PlantEquipmentType.Baseboard_Rad_Conv_Water:
                ControlCompOutput(state, hWBaseboard.Name, cCMO_BBRadiator_Water, BaseboardNum, FirstHVACIteration, QZnReq, hWBaseboard.WaterInletNode, MaxWaterFlow, MinWaterFlow, HWBaseboardDesignDataObject.Offset, hWBaseboard.ControlCompTypeNum, hWBaseboard.CompErrIndex, *, *, *, *, *, hWBaseboard.plantLoc)
            case _:
                ShowSevereError(state, f"SimBaseboard: Errors in Baseboard={hWBaseboard.Name}")
                ShowContinueError(state, f"Invalid or unimplemented equipment type={static_cast[Int](hWBaseboard.EquipType)}")
                ShowFatalError(state, "Preceding condition causes termination.")
        PowerMet = hWBaseboard.TotPower
        UpdateHWBaseboard(state, BaseboardNum)
        ReportHWBaseboard(state, BaseboardNum)
    else:
        ShowFatalError(state, f"SimHWBaseboard: Unit not found={EquipName}")

def GetHWBaseboardInput(state: EnergyPlusData) -> None:
    let RoutineName = "GetHWBaseboardInput:"
    let routineName = "GetHWBaseboardInput"
    let MaxFraction: Float64 = 1.0
    let MinFraction: Float64 = 0.0
    let MaxWaterTempAvg: Float64 = 150.0
    let MinWaterTempAvg: Float64 = 20.0
    let HighWaterMassFlowRate: Float64 = 10.0
    let LowWaterMassFlowRate: Float64 = 0.00001
    let MaxWaterFlowRate: Float64 = 10.0
    let MinWaterFlowRate: Float64 = 0.00001
    let WaterMassFlowDefault: Float64 = 0.063
    let MinDistribSurfaces: Int = 1
    let iHeatCAPMAlphaNum: Int = 2
    let iHeatDesignCapacityNumericNum: Int = 3
    let iHeatCapacityPerFloorAreaNumericNum: Int = 1
    let iHeatFracOfAutosizedCapacityNumericNum: Int = 2
    var BaseboardNum: Int
    var BaseboardDesignNum: Int
    var NumAlphas: Int
    var NumNumbers: Int
    var SurfNum: Int
    var IOStat: Int
    var ErrorsFound: Bool = False
    let NumHWBaseboards = state.dataHWBaseboardRad.NumHWBaseboards = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCMO_BBRadiator_Water)
    let NumHWBaseboardDesignObjs = state.dataHWBaseboardRad.NumHWBaseboardDesignObjs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCMO_BBRadiator_Water_Design)
    state.dataHWBaseboardRad.HWBaseboard = [HWBaseboardParams() for _ in range(NumHWBaseboards)]
    state.dataHWBaseboardRad.HWBaseboardDesignObject = [HWBaseboardDesignData() for _ in range(NumHWBaseboardDesignObjs)]
    state.dataHWBaseboardRad.CheckEquipName = [True for _ in range(NumHWBaseboards)]
    state.dataHWBaseboardRad.HWBaseboardNumericFields = [HWBaseboardNumericFieldData() for _ in range(NumHWBaseboards)]
    var HWBaseboardDesignNames: List[String] = ["" for _ in range(NumHWBaseboardDesignObjs)]
    for BaseboardDesignNum in range(1, NumHWBaseboardDesignObjs + 1):
        var thisHWBaseboardDesign = state.dataHWBaseboardRad.HWBaseboardDesignObject[BaseboardDesignNum - 1]
        state.dataInputProcessing.inputProcessor.getObjectItem(state, cCMO_BBRadiator_Water_Design, BaseboardDesignNum, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNumbers, IOStat, state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
        GlobalNames.VerifyUniqueBaseboardName(state, cCMO_BBRadiator_Water_Design, state.dataIPShortCut.cAlphaArgs[0], ErrorsFound, cCMO_BBRadiator_Water_Design + " Name")
        thisHWBaseboardDesign.designName = state.dataIPShortCut.cAlphaArgs[0]
        HWBaseboardDesignNames[BaseboardDesignNum - 1] = thisHWBaseboardDesign.designName
        thisHWBaseboardDesign.HeatingCapMethod = static_cast[DesignSizingType](getEnumValue(DesignSizingTypeNamesUC, state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]))
        if thisHWBaseboardDesign.HeatingCapMethod == DesignSizingType.CapacityPerFloorArea:
            if not state.dataIPShortCut.lNumericFieldBlanks[iHeatCapacityPerFloorAreaNumericNum - 1]:
                thisHWBaseboardDesign.ScaledHeatingCapacity = state.dataIPShortCut.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum - 1]
                if thisHWBaseboardDesign.ScaledHeatingCapacity <= 0.0:
                    ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboardDesign.designName}")
                    ShowContinueError(state, f"Input for {state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1]} = {state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]}")
                    ShowContinueError(state, f"Illegal {state.dataIPShortCut.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]} = {state.dataIPShortCut.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum - 1]}")
                    ErrorsFound = True
                elif thisHWBaseboardDesign.ScaledHeatingCapacity == DataSizing.AutoSize:
                    ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboardDesign.designName}")
                    ShowContinueError(state, f"Input for {state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1]} = {state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]}")
                    ShowContinueError(state, f"Illegal {state.dataIPShortCut.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]} = Autosize")
                    ErrorsFound = True
            else:
                ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboardDesign.designName}")
                ShowContinueError(state, f"Input for {state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1]} = {state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]}")
                ShowContinueError(state, f"Blank field not allowed for {state.dataIPShortCut.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]}")
                ErrorsFound = True
        elif thisHWBaseboardDesign.HeatingCapMethod == DesignSizingType.FractionOfAutosizedHeatingCapacity:
            if not state.dataIPShortCut.lNumericFieldBlanks[iHeatFracOfAutosizedCapacityNumericNum - 1]:
                thisHWBaseboardDesign.ScaledHeatingCapacity = state.dataIPShortCut.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum - 1]
                if thisHWBaseboardDesign.ScaledHeatingCapacity < 0.0:
                    ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboardDesign.designName}")
                    ShowContinueError(state, f"Illegal {state.dataIPShortCut.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1]} = {state.dataIPShortCut.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum - 1]}")
                    ErrorsFound = True
            else:
                ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboardDesign.designName}")
                ShowContinueError(state, f"Input for {state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1]} = {state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]}")
                ShowContinueError(state, f"Blank field not allowed for {state.dataIPShortCut.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1]}")
                ErrorsFound = True
        thisHWBaseboardDesign.Offset = state.dataIPShortCut.rNumericArgs[2]
        if thisHWBaseboardDesign.Offset <= 0.0:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water_Design}=\"{thisHWBaseboardDesign.designName}\", {state.dataIPShortCut.cNumericFieldNames[2]} was less than the allowable minimum.")
            ShowContinueError(state, f"...reset to a default value=[{MaxFraction:.2f}].")
            thisHWBaseboardDesign.Offset = 0.001
        thisHWBaseboardDesign.FracRadiant = state.dataIPShortCut.rNumericArgs[3]
        if thisHWBaseboardDesign.FracRadiant < MinFraction:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{thisHWBaseboardDesign.designName}\", {state.dataIPShortCut.cNumericFieldNames[3]} was lower than the allowable minimum.")
            ShowContinueError(state, f"...reset to minimum value=[{MinFraction:.2f}].")
            thisHWBaseboardDesign.FracRadiant = MinFraction
        if thisHWBaseboardDesign.FracRadiant > MaxFraction:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{thisHWBaseboardDesign.designName}\", {state.dataIPShortCut.cNumericFieldNames[3]} was higher than the allowable maximum.")
            ShowContinueError(state, f"...reset to maximum value=[{MaxFraction:.2f}].")
            thisHWBaseboardDesign.FracRadiant = MaxFraction
        thisHWBaseboardDesign.FracDistribPerson = state.dataIPShortCut.rNumericArgs[4]
        if thisHWBaseboardDesign.FracDistribPerson < MinFraction:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{thisHWBaseboardDesign.designName}\", {state.dataIPShortCut.cNumericFieldNames[4]} was lower than the allowable minimum.")
            ShowContinueError(state, f"...reset to minimum value=[{MinFraction:.3f}].")
            thisHWBaseboardDesign.FracDistribPerson = MinFraction
        if thisHWBaseboardDesign.FracDistribPerson > MaxFraction:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{thisHWBaseboardDesign.designName}\", {state.dataIPShortCut.cNumericFieldNames[4]} was higher than the allowable maximum.")
            ShowContinueError(state, f"...reset to maximum value=[{MaxFraction:.3f}].")
            thisHWBaseboardDesign.FracDistribPerson = MaxFraction
    for BaseboardNum in range(1, NumHWBaseboards + 1):
        var thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1]
        var HWBaseboardNumericFields = state.dataHWBaseboardRad.HWBaseboardNumericFields[BaseboardNum - 1]
        state.dataInputProcessing.inputProcessor.getObjectItem(state, cCMO_BBRadiator_Water, BaseboardNum, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNumbers, IOStat, state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
        let eoh = ErrorObjectHeader(routineName, cCMO_BBRadiator_Water, state.dataIPShortCut.cAlphaArgs[0])
        HWBaseboardNumericFields.FieldNames = [state.dataIPShortCut.cNumericFieldNames[i] for i in range(NumNumbers)]
        GlobalNames.VerifyUniqueBaseboardName(state, cCMO_BBRadiator_Water, state.dataIPShortCut.cAlphaArgs[0], ErrorsFound, cCMO_BBRadiator_Water + " Name")
        thisHWBaseboard.Name = state.dataIPShortCut.cAlphaArgs[0]
        thisHWBaseboard.EquipType = PlantEquipmentType.Baseboard_Rad_Conv_Water
        Util.setDesignObjectNameAndPointer(state, thisHWBaseboard.designObjectName, thisHWBaseboard.DesignObjectPtr, state.dataIPShortCut.cAlphaArgs[1], HWBaseboardDesignNames, cCMO_BBRadiator_Water, state.dataIPShortCut.cAlphaArgs[0], ErrorsFound)
        if ErrorsFound:
            break
        var HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[thisHWBaseboard.DesignObjectPtr - 1]
        if state.dataIPShortCut.lAlphaFieldBlanks[2]:
            thisHWBaseboard.availSched = Sched.GetScheduleAlwaysOn(state)
        elif (thisHWBaseboard.availSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[2])) is None:
            ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[2], state.dataIPShortCut.cAlphaArgs[2])
            ErrorsFound = True
        thisHWBaseboard.WaterInletNode = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[3], ErrorsFound, Node.ConnectionObjectType.ZoneHVACBaseboardRadiantConvectiveWater, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        thisHWBaseboard.WaterOutletNode = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[4], ErrorsFound, Node.ConnectionObjectType.ZoneHVACBaseboardRadiantConvectiveWater, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        Node.TestCompSet(state, cCMO_BBRadiator_Water, state.dataIPShortCut.cAlphaArgs[0], state.dataIPShortCut.cAlphaArgs[3], state.dataIPShortCut.cAlphaArgs[4], "Hot Water Nodes")
        thisHWBaseboard.WaterTempAvg = state.dataIPShortCut.rNumericArgs[0]
        if thisHWBaseboard.WaterTempAvg > MaxWaterTempAvg + 0.001:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", {state.dataIPShortCut.cNumericFieldNames[0]} was higher than the allowable maximum.")
            ShowContinueError(state, f"...reset to maximum value=[{MaxWaterTempAvg:.2f}].")
            thisHWBaseboard.WaterTempAvg = MaxWaterTempAvg
        elif thisHWBaseboard.WaterTempAvg < MinWaterTempAvg - 0.001:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", {state.dataIPShortCut.cNumericFieldNames[0]} was lower than the allowable minimum.")
            ShowContinueError(state, f"...reset to minimum value=[{MinWaterTempAvg:.2f}].")
            thisHWBaseboard.WaterTempAvg = MinWaterTempAvg
        thisHWBaseboard.WaterMassFlowRateStd = state.dataIPShortCut.rNumericArgs[1]
        if thisHWBaseboard.WaterMassFlowRateStd < LowWaterMassFlowRate - 0.0001 or thisHWBaseboard.WaterMassFlowRateStd > HighWaterMassFlowRate + 0.0001:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", {state.dataIPShortCut.cNumericFieldNames[1]} is an invalid Standard Water mass flow rate.")
            ShowContinueError(state, f"...reset to a default value=[{WaterMassFlowDefault:.1f}].")
            thisHWBaseboard.WaterMassFlowRateStd = WaterMassFlowDefault
        thisHWBaseboard.HeatingCapMethod = static_cast[Int](HWBaseboardDesignDataObject.HeatingCapMethod)
        if thisHWBaseboard.HeatingCapMethod == DataSizing.HeatingDesignCapacity:
            if not state.dataIPShortCut.lNumericFieldBlanks[iHeatDesignCapacityNumericNum - 1]:
                thisHWBaseboard.ScaledHeatingCapacity = state.dataIPShortCut.rNumericArgs[iHeatDesignCapacityNumericNum - 1]
                if thisHWBaseboard.ScaledHeatingCapacity < 0.0 and thisHWBaseboard.ScaledHeatingCapacity != DataSizing.AutoSize:
                    ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboard.Name}")
                    ShowContinueError(state, f"Illegal {state.dataIPShortCut.cNumericFieldNames[iHeatDesignCapacityNumericNum - 1]} = {state.dataIPShortCut.rNumericArgs[iHeatDesignCapacityNumericNum - 1]}")
                    ErrorsFound = True
            else:
                ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboard.Name}")
                ShowContinueError(state, f"Input for {state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1]} = {state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]}")
                ShowContinueError(state, f"Blank field not allowed for {state.dataIPShortCut.cNumericFieldNames[iHeatDesignCapacityNumericNum - 1]}")
                ErrorsFound = True
        elif thisHWBaseboard.HeatingCapMethod == DataSizing.CapacityPerFloorArea:
            thisHWBaseboard.ScaledHeatingCapacity = HWBaseboardDesignDataObject.ScaledHeatingCapacity
        elif thisHWBaseboard.HeatingCapMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
            thisHWBaseboard.ScaledHeatingCapacity = HWBaseboardDesignDataObject.ScaledHeatingCapacity
        else:
            ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject} = {thisHWBaseboard.Name}")
            ShowContinueError(state, f"Illegal {state.dataIPShortCut.cAlphaFieldNames[iHeatCAPMAlphaNum - 1]} = {state.dataIPShortCut.cAlphaArgs[iHeatCAPMAlphaNum - 1]}")
            ErrorsFound = True
        thisHWBaseboard.WaterVolFlowRateMax = state.dataIPShortCut.rNumericArgs[3]
        if abs(thisHWBaseboard.WaterVolFlowRateMax) <= MinWaterFlowRate:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", {state.dataIPShortCut.cNumericFieldNames[3]} was less than the allowable minimum.")
            ShowContinueError(state, f"...reset to minimum value=[{MinWaterFlowRate:.2f}].")
            thisHWBaseboard.WaterVolFlowRateMax = MinWaterFlowRate
        elif thisHWBaseboard.WaterVolFlowRateMax > MaxWaterFlowRate:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", {state.dataIPShortCut.cNumericFieldNames[3]} was higher than the allowable maximum.")
            ShowContinueError(state, f"...reset to maximum value=[{MaxWaterFlowRate:.2f}].")
            thisHWBaseboard.WaterVolFlowRateMax = MaxWaterFlowRate
        if HWBaseboardDesignDataObject.FracRadiant > MaxFraction:
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", Fraction Radiant was higher than the allowable maximum.")
            HWBaseboardDesignDataObject.FracRadiant = MaxFraction
            thisHWBaseboard.FracConvect = 0.0
        else:
            thisHWBaseboard.FracConvect = 1.0 - HWBaseboardDesignDataObject.FracRadiant
        thisHWBaseboard.TotSurfToDistrib = NumNumbers - 4
        if (thisHWBaseboard.TotSurfToDistrib < MinDistribSurfaces) and (HWBaseboardDesignDataObject.FracRadiant > MinFraction):
            ShowSevereError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", the number of surface/radiant fraction groups entered was less than the allowable minimum.")
            ShowContinueError(state, f"...the minimum that must be entered=[{MinDistribSurfaces}].")
            ErrorsFound = True
            thisHWBaseboard.TotSurfToDistrib = 0
        thisHWBaseboard.SurfacePtr = [0 for _ in range(thisHWBaseboard.TotSurfToDistrib)]
        thisHWBaseboard.FracDistribToSurf = [0.0 for _ in range(thisHWBaseboard.TotSurfToDistrib)]
        thisHWBaseboard.ZonePtr = DataZoneEquipment.GetZoneEquipControlledZoneNum(state, DataZoneEquipment.ZoneEquipType.BaseboardWater, thisHWBaseboard.Name)
        var AllFracsSummed: Float64 = HWBaseboardDesignDataObject.FracDistribPerson
        for SurfNum in range(1, thisHWBaseboard.TotSurfToDistrib + 1):
            thisHWBaseboard.SurfacePtr[SurfNum - 1] = HeatBalanceIntRadExchange.GetRadiantSystemSurface(state, cCMO_BBRadiator_Water, thisHWBaseboard.Name, thisHWBaseboard.ZonePtr, state.dataIPShortCut.cAlphaArgs[SurfNum + 4], ErrorsFound)
            thisHWBaseboard.FracDistribToSurf[SurfNum - 1] = state.dataIPShortCut.rNumericArgs[SurfNum + 3]
            if thisHWBaseboard.FracDistribToSurf[SurfNum - 1] > MaxFraction:
                ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", {state.dataIPShortCut.cNumericFieldNames[SurfNum + 3]}was greater than the allowable maximum.")
                ShowContinueError(state, f"...reset to maximum value=[{MaxFraction:.2f}].")
                thisHWBaseboard.TotSurfToDistrib = MaxFraction  # Note: original code sets TotSurfToDistrib to MaxFraction (likely bug, but faithful)
            if thisHWBaseboard.FracDistribToSurf[SurfNum - 1] < MinFraction:
                ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", {state.dataIPShortCut.cNumericFieldNames[SurfNum + 3]}was less than the allowable minimum.")
                ShowContinueError(state, f"...reset to maximum value=[{MinFraction:.2f}].")
                thisHWBaseboard.TotSurfToDistrib = MinFraction
            if thisHWBaseboard.SurfacePtr[SurfNum - 1] != 0:
                state.dataSurface.surfIntConv[thisHWBaseboard.SurfacePtr[SurfNum - 1] - 1].getsRadiantHeat = True
                state.dataSurface.allGetsRadiantHeatSurfaceList.append(thisHWBaseboard.SurfacePtr[SurfNum - 1])
            AllFracsSummed += thisHWBaseboard.FracDistribToSurf[SurfNum - 1]
        if AllFracsSummed > (MaxFraction + 0.01):
            ShowSevereError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", Summed radiant fractions for people + surface groups > 1.0")
            ErrorsFound = True
        if (AllFracsSummed < (MaxFraction - 0.01)) and (HWBaseboardDesignDataObject.FracRadiant > MinFraction):
            ShowWarningError(state, f"{RoutineName}{cCMO_BBRadiator_Water}=\"{state.dataIPShortCut.cAlphaArgs[0]}\", Summed radiant fractions for people + surface groups < 1.0")
            ShowContinueError(state, "The rest of the radiant energy delivered by the baseboard heater will be lost")
    if ErrorsFound:
        ShowFatalError(state, f"{RoutineName}{cCMO_BBRadiator_Water}Errors found getting input. Program terminates.")
    for BaseboardNum in range(1, NumHWBaseboards + 1):
        var thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1]
        SetupOutputVariable(state, "Baseboard Total Heating Rate", Units.W, thisHWBaseboard.TotPower, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Convective Heating Rate", Units.W, thisHWBaseboard.ConvPower, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Radiant Heating Rate", Units.W, thisHWBaseboard.RadPower, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Total Heating Energy", Units.J, thisHWBaseboard.TotEnergy, TimeStepType.System, StoreType.Sum, thisHWBaseboard.Name, Resource.EnergyTransfer, Group.HVAC, EndUseCat.Baseboard)
        SetupOutputVariable(state, "Baseboard Convective Heating Energy", Units.J, thisHWBaseboard.ConvEnergy, TimeStepType.System, StoreType.Sum, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Radiant Heating Energy", Units.J, thisHWBaseboard.RadEnergy, TimeStepType.System, StoreType.Sum, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Hot Water Energy", Units.J, thisHWBaseboard.Energy, TimeStepType.System, StoreType.Sum, thisHWBaseboard.Name, Resource.PlantLoopHeatingDemand, Group.HVAC, EndUseCat.Baseboard)
        SetupOutputVariable(state, "Baseboard Hot Water Mass Flow Rate", Units.kg_s, thisHWBaseboard.WaterMassFlowRate, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Air Mass Flow Rate", Units.kg_s, thisHWBaseboard.AirMassFlowRate, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Air Inlet Temperature", Units.C, thisHWBaseboard.AirInletTemp, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Air Outlet Temperature", Units.C, thisHWBaseboard.AirOutletTemp, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Water Inlet Temperature", Units.C, thisHWBaseboard.WaterInletTemp, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)
        SetupOutputVariable(state, "Baseboard Water Outlet Temperature", Units.C, thisHWBaseboard.WaterOutletTemp, TimeStepType.System, StoreType.Average, thisHWBaseboard.Name)

def InitHWBaseboard(state: EnergyPlusData, BaseboardNum: Int, ControlledZoneNum: Int, FirstHVACIteration: Bool) -> None:
    let Constant: Float64 = 0.0062
    let Coeff: Float64 = 0.0000275
    let RoutineName = "BaseboardRadiatorWater:InitHWBaseboard"
    var WaterInletNode: Int
    var rho: Float64
    var Cp: Float64
    let NumHWBaseboards = state.dataHWBaseboardRad.NumHWBaseboards
    var hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1]
    if state.dataHWBaseboardRad.MyOneTimeFlag:
        state.dataHWBaseboardRad.MyEnvrnFlag = [True for _ in range(NumHWBaseboards)]
        state.dataHWBaseboardRad.MySizeFlag = [True for _ in range(NumHWBaseboards)]
        state.dataHWBaseboardRad.SetLoopIndexFlag = [True for _ in range(NumHWBaseboards)]
        state.dataHWBaseboardRad.MyOneTimeFlag = False
        for i in range(len(state.dataHWBaseboardRad.HWBaseboard)):
            var hWBB = state.dataHWBaseboardRad.HWBaseboard[i]
            hWBB.ZeroBBSourceSumHATsurf = 0.0
            hWBB.QBBRadSource = 0.0
            hWBB.QBBRadSrcAvg = 0.0
            hWBB.LastQBBRadSrc = 0.0
            hWBB.LastSysTimeElapsed = 0.0
            hWBB.LastTimeStepSys = 0.0
            hWBB.AirMassFlowRateStd = Constant + Coeff * hWBB.RatedCapacity
    if state.dataHWBaseboardRad.SetLoopIndexFlag[BaseboardNum - 1]:
        if allocated(state.dataPlnt.PlantLoop):
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, hWBaseboard.Name, hWBaseboard.EquipType, hWBaseboard.plantLoc, errFlag, *, *, *, *, *)
            if errFlag:
                ShowFatalError(state, "InitHWBaseboard: Program terminated for previous conditions.")
            state.dataHWBaseboardRad.SetLoopIndexFlag[BaseboardNum - 1] = False
    if not state.dataGlobal.SysSizingCalc and state.dataHWBaseboardRad.MySizeFlag[BaseboardNum - 1] and not state.dataHWBaseboardRad.SetLoopIndexFlag[BaseboardNum - 1]:
        SizeHWBaseboard(state, BaseboardNum)
        state.dataHWBaseboardRad.MySizeFlag[BaseboardNum - 1] = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataHWBaseboardRad.MyEnvrnFlag[BaseboardNum - 1]:
        WaterInletNode = hWBaseboard.WaterInletNode
        rho = hWBaseboard.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
        hWBaseboard.WaterMassFlowRateMax = rho * hWBaseboard.WaterVolFlowRateMax
        PlantUtilities.InitComponentNodes(state, 0.0, hWBaseboard.WaterMassFlowRateMax, hWBaseboard.WaterInletNode, hWBaseboard.WaterOutletNode)
        state.dataLoopNodes.Node[WaterInletNode - 1].Temp = 60.0
        Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[WaterInletNode - 1].Temp, RoutineName)
        state.dataLoopNodes.Node[WaterInletNode - 1].Enthalpy = Cp * state.dataLoopNodes.Node[WaterInletNode - 1].Temp
        state.dataLoopNodes.Node[WaterInletNode - 1].Quality = 0.0
        state.dataLoopNodes.Node[WaterInletNode - 1].Press = 0.0
        state.dataLoopNodes.Node[WaterInletNode - 1].HumRat = 0.0
        hWBaseboard.ZeroBBSourceSumHATsurf = 0.0
        hWBaseboard.QBBRadSource = 0.0
        hWBaseboard.QBBRadSrcAvg = 0.0
        hWBaseboard.LastQBBRadSrc = 0.0
        hWBaseboard.LastSysTimeElapsed = 0.0
        hWBaseboard.LastTimeStepSys = 0.0
        state.dataHWBaseboardRad.MyEnvrnFlag[BaseboardNum - 1] = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHWBaseboardRad.MyEnvrnFlag[BaseboardNum - 1] = True
    if state.dataGlobal.BeginTimeStepFlag and FirstHVACIteration:
        let ZoneNum = hWBaseboard.ZonePtr
        hWBaseboard.ZeroBBSourceSumHATsurf = state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state)
        hWBaseboard.QBBRadSrcAvg = 0.0
        hWBaseboard.LastQBBRadSrc = 0.0
        hWBaseboard.LastSysTimeElapsed = 0.0
        hWBaseboard.LastTimeStepSys = 0.0
    WaterInletNode = hWBaseboard.WaterInletNode
    let ZoneNode = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1].ZoneNode
    hWBaseboard.WaterMassFlowRate = state.dataLoopNodes.Node[WaterInletNode - 1].MassFlowRate
    hWBaseboard.WaterInletTemp = state.dataLoopNodes.Node[WaterInletNode - 1].Temp
    hWBaseboard.WaterInletEnthalpy = state.dataLoopNodes.Node[WaterInletNode - 1].Enthalpy
    hWBaseboard.AirInletTemp = state.dataLoopNodes.Node[ZoneNode - 1].Temp
    hWBaseboard.AirInletHumRat = state.dataLoopNodes.Node[ZoneNode - 1].HumRat
    hWBaseboard.TotPower = 0.0
    hWBaseboard.Power = 0.0
    hWBaseboard.ConvPower = 0.0
    hWBaseboard.RadPower = 0.0
    hWBaseboard.TotEnergy = 0.0
    hWBaseboard.Energy = 0.0
    hWBaseboard.ConvEnergy = 0.0
    hWBaseboard.RadEnergy = 0.0

def SizeHWBaseboard(state: EnergyPlusData, BaseboardNum: Int) -> None:
    let AirInletTempStd: Float64 = 18.0
    let CPAirStd: Float64 = 1005.0
    let Constant: Float64 = 0.0062
    let Coeff: Float64 = 0.0000275
    let RoutineName = "SizeHWBaseboard"
    let RoutineNameFull = "BaseboardRadiatorWater:SizeHWBaseboard"
    var WaterInletTempStd: Float64
    var WaterOutletTempStd: Float64
    var AirOutletTempStd: Float64
    var DeltaT1: Float64
    var DeltaT2: Float64
    var LMTD: Float64
    var AirMassFlowRate: Float64
    var WaterMassFlowRateStd: Float64
    var rho: Float64
    var Cp: Float64
    var TempSize: Float64
    var PltSizHeatNum: Int = 0
    var DesCoilLoad: Float64 = 0.0
    var ErrorsFound: Bool = False
    var WaterVolFlowRateMaxDes: Float64 = 0.0
    var WaterVolFlowRateMaxUser: Float64 = 0.0
    var RatedCapacityDes: Float64 = 0.0
    state.dataSize.DataScalableCapSizingON = False
    var hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1]
    if state.dataSize.CurZoneEqNum > 0:
        var zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1]
        let CompName = hWBaseboard.Name
        state.dataSize.DataHeatSizeRatio = 1.0
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = hWBaseboard.ZonePtr
        let SizingMethod: Int = HVAC.HeatingCapacitySizing
        let FieldNum: Int = 3
        let SizingString = state.dataHWBaseboardRad.HWBaseboardNumericFields[BaseboardNum - 1].FieldNames[FieldNum - 1] + " [W]"
        let CapSizingMethod = hWBaseboard.HeatingCapMethod
        zoneEqSizing.SizingMethod[SizingMethod - 1] = CapSizingMethod
        if CapSizingMethod == DataSizing.HeatingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
            let CompType = cCMO_BBRadiator_Water
            if CapSizingMethod == DataSizing.HeatingDesignCapacity:
                if hWBaseboard.ScaledHeatingCapacity == DataSizing.AutoSize:
                    CheckZoneSizing(state, CompType, CompName)
                    zoneEqSizing.HeatingCapacity = True
                    zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad
                TempSize = hWBaseboard.ScaledHeatingCapacity
            elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                zoneEqSizing.HeatingCapacity = True
                zoneEqSizing.DesHeatingLoad = hWBaseboard.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber - 1].FloorArea
                TempSize = zoneEqSizing.DesHeatingLoad
                state.dataSize.DataScalableCapSizingON = True
            else:
                CheckZoneSizing(state, CompType, CompName)
                zoneEqSizing.HeatingCapacity = True
                state.dataSize.DataFracOfAutosizedHeatingCapacity = hWBaseboard.ScaledHeatingCapacity
                zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad
                TempSize = DataSizing.AutoSize
                state.dataSize.DataScalableCapSizingON = True
            let PrintFlag: Bool = False
            var errorsFound: Bool = False
            var sizerHeatingCapacity = HeatingCapacitySizer()
            sizerHeatingCapacity.overrideSizingString(SizingString)
            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            TempSize = sizerHeatingCapacity.size(state, TempSize, errorsFound)
            if hWBaseboard.ScaledHeatingCapacity == DataSizing.AutoSize:
                hWBaseboard.RatedCapacity = DataSizing.AutoSize
            else:
                hWBaseboard.RatedCapacity = TempSize
            if not state.dataSize.FinalZoneSizing.empty() and state.dataSize.CurZoneEqNum <= static_cast[Int](len(state.dataSize.FinalZoneSizing)):
                BaseSizer.reportSizerOutput(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "Design Size Heating Load [W]", state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad)
            RatedCapacityDes = TempSize
            state.dataSize.DataScalableCapSizingON = False
    PltSizHeatNum = hWBaseboard.plantLoc.loop.PlantSizNum
    if PltSizHeatNum > 0:
        if state.dataSize.CurZoneEqNum > 0:
            let FlowAutoSize: Bool = (hWBaseboard.WaterVolFlowRateMax == DataSizing.AutoSize)
            if not FlowAutoSize and not state.dataSize.ZoneSizingRunDone:
                if hWBaseboard.WaterVolFlowRateMax > 0.0:
                    BaseSizer.reportSizerOutput(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "User-Specified Maximum Water Flow Rate [m3/s]", hWBaseboard.WaterVolFlowRateMax)
            else:
                CheckZoneSizing(state, cCMO_BBRadiator_Water, hWBaseboard.Name)
                DesCoilLoad = RatedCapacityDes
                if DesCoilLoad >= HVAC.SmallLoad:
                    Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                    rho = hWBaseboard.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                    WaterVolFlowRateMaxDes = DesCoilLoad / (state.dataSize.PlantSizData[PltSizHeatNum - 1].DeltaT * Cp * rho)
                else:
                    WaterVolFlowRateMaxDes = 0.0
                if FlowAutoSize:
                    hWBaseboard.WaterVolFlowRateMax = WaterVolFlowRateMaxDes
                    BaseSizer.reportSizerOutput(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "Design Size Maximum Water Flow Rate [m3/s]", WaterVolFlowRateMaxDes)
                else:
                    if hWBaseboard.WaterVolFlowRateMax > 0.0 and WaterVolFlowRateMaxDes > 0.0:
                        WaterVolFlowRateMaxUser = hWBaseboard.WaterVolFlowRateMax
                        BaseSizer.reportSizerOutput(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "Design Size Maximum Water Flow Rate [m3/s]", WaterVolFlowRateMaxDes, "User-Specified Maximum Water Flow Rate [m3/s]", WaterVolFlowRateMaxUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(WaterVolFlowRateMaxDes - WaterVolFlowRateMaxUser) / WaterVolFlowRateMaxUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, f"SizeHWBaseboard: Potential issue with equipment sizing for ZoneHVAC:Baseboard:RadiantConvective:Water=\"{hWBaseboard.Name}\".")
                                ShowContinueError(state, f"User-Specified Maximum Water Flow Rate of {WaterVolFlowRateMaxUser:.5f} [m3/s]")
                                ShowContinueError(state, f"differs from Design Size Maximum Water Flow Rate of {WaterVolFlowRateMaxDes:.5f} [m3/s]")
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
            if hWBaseboard.WaterTempAvg > 0.0 and hWBaseboard.WaterMassFlowRateStd > 0.0 and hWBaseboard.RatedCapacity > 0.0:
                DesCoilLoad = hWBaseboard.RatedCapacity
                WaterMassFlowRateStd = hWBaseboard.WaterMassFlowRateStd
            elif hWBaseboard.RatedCapacity == DataSizing.AutoSize or hWBaseboard.RatedCapacity == 0.0:
                DesCoilLoad = RatedCapacityDes
                rho = hWBaseboard.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineNameFull)
                WaterMassFlowRateStd = hWBaseboard.WaterVolFlowRateMax * rho
            if DesCoilLoad >= HVAC.SmallLoad:
                AirMassFlowRate = Constant + Coeff * DesCoilLoad
                Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, hWBaseboard.WaterTempAvg, RoutineName)
                WaterInletTempStd = (DesCoilLoad / (2.0 * WaterMassFlowRateStd * Cp)) + hWBaseboard.WaterTempAvg
                WaterOutletTempStd = abs((2.0 * hWBaseboard.WaterTempAvg) - WaterInletTempStd)
                AirOutletTempStd = (DesCoilLoad / (AirMassFlowRate * CPAirStd)) + AirInletTempStd
                hWBaseboard.AirMassFlowRateStd = AirMassFlowRate
                if AirOutletTempStd >= WaterInletTempStd:
                    ShowSevereError(state, f"SizeHWBaseboard: ZoneHVAC:Baseboard:RadiantConvective:Water=\"{hWBaseboard.Name}\".")
                    ShowContinueError(state, "...Air Outlet temperature must be below the Water Inlet temperature")
                    ShowContinueError(state, f"...Air Outlet Temperature=[{AirOutletTempStd:.2f}], Water Inlet Temperature=[{WaterInletTempStd:.2f}].")
                    AirOutletTempStd = WaterInletTempStd - 0.01
                    ShowContinueError(state, f"...Air Outlet Temperature set to [{AirOutletTempStd:.2f}].")
                if AirInletTempStd >= WaterOutletTempStd:
                    ShowSevereError(state, f"SizeHWBaseboard: ZoneHVAC:Baseboard:RadiantConvective:Water=\"{hWBaseboard.Name}\".")
                    ShowContinueError(state, "...Water Outlet temperature must be below the Air Inlet temperature")
                    ShowContinueError(state, f"...Air Inlet Temperature=[{AirInletTempStd:.2f}], Water Outlet Temperature=[{WaterOutletTempStd:.2f}].")
                    WaterOutletTempStd = AirInletTempStd + 0.01
                    ShowContinueError(state, f"...Water Outlet Temperature set to [{WaterOutletTempStd:.2f}].")
                DeltaT1 = WaterInletTempStd - AirOutletTempStd
                DeltaT2 = WaterOutletTempStd - AirInletTempStd
                LMTD = (DeltaT1 - DeltaT2) / (log(DeltaT1 / DeltaT2))
                hWBaseboard.UA = DesCoilLoad / LMTD
            else:
                hWBaseboard.UA = 0.0
            BaseSizer.reportSizerOutput(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "U-Factor times Area [W/C]", hWBaseboard.UA)
    else:
        if hWBaseboard.WaterVolFlowRateMax == DataSizing.AutoSize or hWBaseboard.RatedCapacity == DataSizing.AutoSize or hWBaseboard.RatedCapacity == 0.0:
            ShowSevereError(state, "Autosizing of hot water baseboard requires a heating loop Sizing:Plant object")
            ShowContinueError(state, f"Occurs in Hot Water Baseboard Heater={hWBaseboard.Name}")
            ErrorsFound = True
        hWBaseboard.RatedCapacity = RatedCapacityDes
        DesCoilLoad = RatedCapacityDes
        if DesCoilLoad >= HVAC.SmallLoad:
            WaterMassFlowRateStd = hWBaseboard.WaterMassFlowRateStd
            AirMassFlowRate = Constant + Coeff * DesCoilLoad
            Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, hWBaseboard.WaterTempAvg, RoutineName)
            WaterInletTempStd = (DesCoilLoad / (2.0 * WaterMassFlowRateStd * Cp)) + hWBaseboard.WaterTempAvg
            WaterOutletTempStd = abs((2.0 * hWBaseboard.WaterTempAvg) - WaterInletTempStd)
            AirOutletTempStd = (DesCoilLoad / (AirMassFlowRate * CPAirStd)) + AirInletTempStd
            hWBaseboard.AirMassFlowRateStd = AirMassFlowRate
            if AirOutletTempStd >= WaterInletTempStd:
                ShowSevereError(state, f"SizeHWBaseboard: ZoneHVAC:Baseboard:RadiantConvective:Water=\"{hWBaseboard.Name}\".")
                ShowContinueError(state, "...Air Outlet temperature must be below the Water Inlet temperature")
                ShowContinueError(state, f"...Air Outlet Temperature=[{AirOutletTempStd:.2f}], Water Inlet Temperature=[{WaterInletTempStd:.2f}].")
                AirOutletTempStd = WaterInletTempStd - 0.01
                ShowContinueError(state, f"...Air Outlet Temperature set to [{AirOutletTempStd:.2f}].")
            if AirInletTempStd >= WaterOutletTempStd:
                ShowSevereError(state, f"SizeHWBaseboard: ZoneHVAC:Baseboard:RadiantConvective:Water=\"{hWBaseboard.Name}\".")
                ShowContinueError(state, "...Water Outlet temperature must be below the Air Inlet temperature")
                ShowContinueError(state, f"...Air Inlet Temperature=[{AirInletTempStd:.2f}], Water Outlet Temperature=[{WaterOutletTempStd:.2f}].")
                WaterOutletTempStd = AirInletTempStd + 0.01
                ShowContinueError(state, f"...Water Outlet Temperature set to [{WaterOutletTempStd:.2f}].")
            DeltaT1 = WaterInletTempStd - AirOutletTempStd
            DeltaT2 = WaterOutletTempStd - AirInletTempStd
            LMTD = (DeltaT1 - DeltaT2) / (log(DeltaT1 / DeltaT2))
            hWBaseboard.UA = DesCoilLoad / LMTD
        else:
            hWBaseboard.UA = 0.0
        BaseSizer.reportSizerOutput(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "U-Factor times Area [W/C]", hWBaseboard.UA)
    PlantUtilities.RegisterPlantCompDesignFlow(state, hWBaseboard.WaterInletNode, hWBaseboard.WaterVolFlowRateMax)
    if ErrorsFound:
        ShowFatalError(state, "Preceding sizing errors cause program termination")

def CalcHWBaseboard(state: EnergyPlusData, BaseboardNum: Int, LoadMet: Float64) -> None:
    let MinFrac: Float64 = 0.0005
    let RoutineName = "CalcHWBaseboard"
    var RadHeat: Float64
    var BBHeat: Float64
    var AirOutletTemp: Float64
    var WaterOutletTemp: Float64
    var AirMassFlowRate: Float64
    var CapacitanceAir: Float64
    var CapacitanceWater: Float64
    var CapacitanceMax: Float64
    var CapacitanceMin: Float64
    var CapacityRatio: Float64
    var NTU: Float64
    var Effectiveness: Float64
    var AA: Float64
    var BB: Float64
    var CC: Float64
    var Cp: Float64
    var hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1]
    let ZoneNum = hWBaseboard.ZonePtr
    let QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToHeatSP
    let AirInletTemp = hWBaseboard.AirInletTemp
    let WaterInletTemp = hWBaseboard.WaterInletTemp
    var WaterMassFlowRate = state.dataLoopNodes.Node[hWBaseboard.WaterInletNode - 1].MassFlowRate
    if QZnReq > HVAC.SmallLoad and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum - 1] and (hWBaseboard.availSched.getCurrentVal() > 0) and (WaterMassFlowRate > 0.0):
        let HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[hWBaseboard.DesignObjectPtr - 1]
        AirMassFlowRate = hWBaseboard.AirMassFlowRateStd * (WaterMassFlowRate / hWBaseboard.WaterMassFlowRateMax)
        CapacitanceAir = Psychrometrics.PsyCpAirFnW(hWBaseboard.AirInletHumRat) * AirMassFlowRate
        Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, WaterInletTemp, RoutineName)
        CapacitanceWater = Cp * WaterMassFlowRate
        CapacitanceMax = max(CapacitanceAir, CapacitanceWater)
        CapacitanceMin = min(CapacitanceAir, CapacitanceWater)
        CapacityRatio = CapacitanceMin / CapacitanceMax
        NTU = hWBaseboard.UA / CapacitanceMin
        AA = -CapacityRatio * pow(NTU, 0.78)
        if AA < -20.0:
            BB = 0.0
        else:
            BB = exp(AA)
        CC = (1.0 / CapacityRatio) * pow(NTU, 0.22) * (BB - 1.0)
        if CC < -20.0:
            Effectiveness = 1.0
        else:
            Effectiveness = 1.0 - exp(CC)
        AirOutletTemp = AirInletTemp + Effectiveness * CapacitanceMin * (WaterInletTemp - AirInletTemp) / CapacitanceAir
        WaterOutletTemp = WaterInletTemp - CapacitanceAir * (AirOutletTemp - AirInletTemp) / CapacitanceWater
        BBHeat = CapacitanceWater * (WaterInletTemp - WaterOutletTemp)
        RadHeat = BBHeat * HWBaseboardDesignDataObject.FracRadiant
        hWBaseboard.QBBRadSource = RadHeat
        if HWBaseboardDesignDataObject.FracRadiant <= MinFrac:
            LoadMet = BBHeat
        else:
            DistributeBBRadGains(state)
            HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
            HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
            LoadMet = (state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state) - hWBaseboard.ZeroBBSourceSumHATsurf) + (BBHeat * hWBaseboard.FracConvect) + (RadHeat * HWBaseboardDesignDataObject.FracDistribPerson)
        hWBaseboard.WaterOutletEnthalpy = hWBaseboard.WaterInletEnthalpy - BBHeat / WaterMassFlowRate
    else:
        CapacitanceWater = 0.0
        CapacitanceMax = 0.0
        CapacitanceMin = 0.0
        NTU = 0.0
        Effectiveness = 0.0
        AirOutletTemp = AirInletTemp
        WaterOutletTemp = WaterInletTemp
        BBHeat = 0.0
        LoadMet = 0.0
        RadHeat = 0.0
        WaterMassFlowRate = 0.0
        AirMassFlowRate = 0.0
        hWBaseboard.QBBRadSource = 0.0
        hWBaseboard.WaterOutletEnthalpy = hWBaseboard.WaterInletEnthalpy
        PlantUtilities.SetActuatedBranchFlowRate(state, WaterMassFlowRate, hWBaseboard.WaterInletNode, hWBaseboard.plantLoc, False)
    hWBaseboard.WaterOutletTemp = WaterOutletTemp
    hWBaseboard.AirOutletTemp = AirOutletTemp
    hWBaseboard.WaterMassFlowRate = WaterMassFlowRate
    hWBaseboard.AirMassFlowRate = AirMassFlowRate
    hWBaseboard.TotPower = LoadMet
    hWBaseboard.Power = BBHeat
    hWBaseboard.ConvPower = BBHeat - RadHeat
    hWBaseboard.RadPower = RadHeat

def UpdateHWBaseboard(state: EnergyPlusData, BaseboardNum: Int) -> None:
    var WaterInletNode: Int
    var WaterOutletNode: Int
    var thisHWBB = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum - 1]
    if state.dataGlobal.BeginEnvrnFlag and state.dataHWBaseboardRad.MyEnvrnFlag2:
        state.dataHWBaseboardRad.Iter = 0
        state.dataHWBaseboardRad.MyEnvrnFlag2 = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHWBaseboardRad.MyEnvrnFlag2 = True
    if thisHWBB.LastSysTimeElapsed == state.dataHVACGlobal.SysTimeElapsed:
        thisHWBB.QBBRadSrcAvg -= thisHWBB.LastQBBRadSrc * thisHWBB.LastTimeStepSys / state.dataGlobal.TimeStepZone
    thisHWBB.QBBRadSrcAvg += thisHWBB.QBBRadSource * state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone
    thisHWBB.LastQBBRadSrc = thisHWBB.QBBRadSource
    thisHWBB.LastSysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
    thisHWBB.LastTimeStepSys = state.dataHVACGlobal.TimeStepSys
    WaterInletNode = thisHWBB.WaterInletNode
    WaterOutletNode = thisHWBB.WaterOutletNode
    PlantUtilities.SafeCopyPlantNode(state, WaterInletNode, WaterOutletNode)
    state.dataLoopNodes.Node[WaterOutletNode - 1].Temp = thisHWBB.WaterOutletTemp
    state.dataLoopNodes.Node[WaterOutletNode - 1].Enthalpy = thisHWBB.WaterOutletEnthalpy

def UpdateBBRadSourceValAvg(state: EnergyPlusData, HWBaseboardSysOn: Bool) -> None:
    HWBaseboardSysOn = False
    if state.dataHWBaseboardRad.NumHWBaseboards == 0:
        return
    for i in range(state.dataHWBaseboardRad.NumHWBaseboards):
        var thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[i]
        thisHWBaseboard.QBBRadSource = thisHWBaseboard.QBBRadSrcAvg
        if thisHWBaseboard.QBBRadSrcAvg != 0.0:
            HWBaseboardSysOn = True
    DistributeBBRadGains(state)

def DistributeBBRadGains(state: EnergyPlusData) -> None:
    let SmallestArea: Float64 = 0.001
    var ThisSurfIntensity: Float64
    for i in range(len(state.dataHWBaseboardRad.HWBaseboard)):
        var thisHWBB = state.dataHWBaseboardRad.HWBaseboard[i]
        for radSurfNum in range(1, thisHWBB.TotSurfToDistrib + 1):
            let surfNum = thisHWBB.SurfacePtr[radSurfNum - 1]
            state.dataHeatBalFanSys.surfQRadFromHVAC[surfNum - 1].HWBaseboard = 0.0
    state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson = 0.0
    for i in range(len(state.dataHWBaseboardRad.HWBaseboard)):
        var thisHWBB = state.dataHWBaseboardRad.HWBaseboard[i]
        let HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[thisHWBB.DesignObjectPtr - 1]
        let ZoneNum = thisHWBB.ZonePtr
        if ZoneNum <= 0:
            continue
        state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson[ZoneNum - 1] += thisHWBB.QBBRadSource * HWBaseboardDesignDataObject.FracDistribPerson
        for RadSurfNum in range(1, thisHWBB.TotSurfToDistrib + 1):
            let SurfNum = thisHWBB.SurfacePtr[RadSurfNum - 1]
            if state.dataSurface.Surface[SurfNum - 1].Area > SmallestArea:
                ThisSurfIntensity = (thisHWBB.QBBRadSource * thisHWBB.FracDistribToSurf[RadSurfNum - 1] / state.dataSurface.Surface[SurfNum - 1].Area)
                state.dataHeatBalFanSys.surfQRadFromHVAC[SurfNum - 1].HWBaseboard += ThisSurfIntensity
                if ThisSurfIntensity > DataHeatBalFanSys.MaxRadHeatFlux:
                    ShowSevereError(state, "DistributeBBRadGains:  excessive thermal radiation heat flux intensity detected")
                    ShowContinueError(state, f"Surface = {state.dataSurface.Surface[SurfNum - 1].Name}")
                    ShowContinueError(state, f"Surface area = {state.dataSurface.Surface[SurfNum - 1].Area:.3f} [m2]")
                    ShowContinueError(state, f"Occurs in {cCMO_BBRadiator_Water} = {thisHW