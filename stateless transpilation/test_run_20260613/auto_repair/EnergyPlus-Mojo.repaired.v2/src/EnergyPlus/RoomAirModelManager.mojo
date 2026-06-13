// RoomAirModelManager.mojo - Faithful 1:1 translation from C++ (RoomAirModelManager.cc)

from BaseboardElectric import BaseboardElectric
from CrossVentMgr import CrossVentMgr
from DataEnvironment import DataEnvironment
from EnergyPlus.DataErrorTracking import DataErrorTracking
from EnergyPlus.DataHeatBalFanSys import DataHeatBalFanSys
from DataHeatBalance import DataHeatBalance, IntGainType, IntGainTypeNamesUC
from EnergyPlus.DataIPShortCuts import DataIPShortCuts
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataRoomAirModel import RoomAirModel, AirNodeType, Comfort, Diffuser, UserDefinedPatternType, UserDefinedPatternMode, userDefinedPatternModeNamesUC, roomAirModelNamesUC, airNodeTypeNamesUC, comfortNamesUC, diffuserNamesUC, AFNAirNodeNested, BegEnd, ErrorObjectHeader
from DataSurfaces import DataSurfaces, SurfaceClass
from DataZoneEquipment import DataZoneEquipment, ZoneEquipType, zoneEquipTypeNamesUC, EquipConfiguration
from DisplacementVentMgr import DisplacementVentMgr
from FanCoilUnits import FanCoilUnits
from General import General
from HVACStandAloneERV import HVACStandAloneERV
from HVACVariableRefrigerantFlow import HVACVariableRefrigerantFlow
from HybridUnitaryAirConditioners import HybridUnitaryAirConditioners
from .InputProcessing.InputProcessor import InputProcessor
from InternalHeatGains import InternalHeatGains
from MundtSimMgr import MundtSimMgr
from OutdoorAirUnit import OutdoorAirUnit
from OutputProcessor import OutputProcessor, SetupOutputVariable, TimeStepType, StoreType
from Psychrometrics import Psychrometrics, PsyRhoAirFnPbTdbW
from PurchasedAirManager import PurchasedAirManager
from RoomAirModelAirflowNetwork import RoomAirModelAirflowNetwork, SimRoomAirModelAFN
from RoomAirModelUserTempPattern import RoomAirModelUserTempPattern, ManageUserDefinedPatterns, FigureNDheightInZone
from ScheduleManager import ScheduleManager, Sched
from UFADManager import UFADManager, ManageUFAD
from UnitHeater import UnitHeater
from UnitVentilator import UnitVentilator
from UtilityRoutines import UtilityRoutines, Util
from VentilatedSlab import VentilatedSlab
from WaterThermalTanks import WaterThermalTanks
from WindowAC import WindowAC
from ZoneDehumidifier import ZoneDehumidifier
from ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from .AirflowNetwork.src.Solver import AirflowNetwork
from ObjexxFCL import Array1D, Array2D, Array, Array_functions
from .Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.Data.BaseData import BaseData
from EnergyPlus.EnergyPlus import EnergyPlus

import builtins

alias = alias  # for static constants

@private
alias routineName = "GetUserDefinedPatternData: "

@private
var cUserDefinedControlObject = "RoomAir:TemperaturePattern:UserDefined"
@private
var cTempPatternConstGradientObject = "RoomAir:TemperaturePattern:ConstantGradient"
@private
var cTempPatternTwoGradientObject = "RoomAir:TemperaturePattern:TwoGradientInterpolation"
@private
var cTempPatternNDHeightObject = "RoomAir:TemperaturePattern:NonDimensionalHeight"
@private
var cTempPatternSurfMapObject = "RoomAir:TemperaturePattern:SurfaceMapping"

def ManageAirModel(inout state: EnergyPlusData, ZoneNum: Int):
    if state.dataRoomAir.GetAirModelData:
        GetAirModelDatas(state)
        state.dataRoomAir.GetAirModelData = False
    if not state.dataRoomAir.anyNonMixingRoomAirModel:
        return
    if state.dataRoomAir.UCSDModelUsed:
        SharedDVCVUFDataInit(state, ZoneNum)
    switch state.dataRoomAir.AirModel[ZoneNum-1].AirModel:
        case RoomAirModel.UserDefined:
            ManageUserDefinedPatterns(state, ZoneNum)
        case RoomAirModel.Mixing:  # Mixing air model
            pass  # do nothing
        case RoomAirModel.DispVent1Node:  # Mundt air model
            ManageDispVent1Node(state, ZoneNum)
        case RoomAirModel.DispVent3Node:  # UCDV Displacement Ventilation model
            ManageDispVent3Node(state, ZoneNum)
        case RoomAirModel.CrossVent:  # UCSD Cross Ventilation model
            ManageCrossVent(state, ZoneNum)
        case RoomAirModel.UFADInt:  # UCSD UFAD interior zone model
            ManageUFAD(state, ZoneNum, RoomAirModel.UFADInt)
        case RoomAirModel.UFADExt:  # UCSD UFAD exterior zone model
            ManageUFAD(state, ZoneNum, RoomAirModel.UFADExt)
        case RoomAirModel.AirflowNetwork:  # RoomAirflowNetwork zone model
            SimRoomAirModelAFN(state, ZoneNum)
        default:  # mixing air model

def GetAirModelDatas(inout state: EnergyPlusData):
    var ErrorsFound: Bool = False
    GetAirNodeData(state, ErrorsFound)
    GetMundtData(state, ErrorsFound)
    GetRoomAirflowNetworkData(state, ErrorsFound)
    GetDisplacementVentData(state, ErrorsFound)
    GetCrossVentData(state, ErrorsFound)
    GetUserDefinedPatternData(state, ErrorsFound)
    GetUFADZoneData(state, ErrorsFound)
    if ErrorsFound:
        ShowFatalError(state, "GetAirModelData: Errors found getting air model input.  Program terminates.")

def GetUserDefinedPatternData(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    var NumAlphas: Int
    var NumNumbers: Int
    var Status: Int
    var ipsc = state.dataIPShortCut
    state.dataRoomAir.numTempDistContrldZones = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cUserDefinedControlObject)
    state.dataRoomAir.NumConstantGradient = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cTempPatternConstGradientObject)
    state.dataRoomAir.NumTwoGradientInterp = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cTempPatternTwoGradientObject)
    state.dataRoomAir.NumNonDimensionalHeight = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cTempPatternNDHeightObject)
    state.dataRoomAir.NumSurfaceMapping = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cTempPatternSurfMapObject)
    state.dataRoomAir.NumAirTempPatterns = state.dataRoomAir.NumConstantGradient + state.dataRoomAir.NumTwoGradientInterp + state.dataRoomAir.NumNonDimensionalHeight + state.dataRoomAir.NumSurfaceMapping
    ipsc.cCurrentModuleObject = cUserDefinedControlObject
    if state.dataRoomAir.numTempDistContrldZones == 0:
        if state.dataRoomAir.NumAirTempPatterns != 0:
            ShowWarningError(state, f"Missing {ipsc.cCurrentModuleObject} object needed to use roomair temperature patterns")
        return
    if not allocated(state.dataRoomAir.AirPatternZoneInfo):
        state.dataRoomAir.AirPatternZoneInfo.allocate(state.dataGlobal.NumOfZones)
    for ObjNum in range(1, state.dataRoomAir.numTempDistContrldZones+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, ObjNum, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, Status, _, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        var ZoneNum = Util.FindItemInList(ipsc.cAlphaArgs[1], state.dataHeatBal.Zone)
        if ZoneNum == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
            return
        var airPatternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum-1]  # 0-based
        airPatternZoneInfo.IsUsed = True
        airPatternZoneInfo.Name = ipsc.cAlphaArgs[0]
        airPatternZoneInfo.ZoneName = ipsc.cAlphaArgs[1]
        if ipsc.lAlphaFieldBlanks[2]:
            airPatternZoneInfo.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            airPatternZoneInfo.availSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[2])
            if airPatternZoneInfo.availSched == None:
                ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
                ErrorsFound = True
        if ipsc.lAlphaFieldBlanks[3]:

        else:
            airPatternZoneInfo.patternSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[3])
            if airPatternZoneInfo.patternSched == None:
                ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[3], ipsc.cAlphaArgs[3])
                ErrorsFound = True
        airPatternZoneInfo.ZoneID = ZoneNum
        airPatternZoneInfo.totNumSurfs = 0
        for spaceNum in state.dataHeatBal.Zone[ZoneNum-1].spaceIndexes:
            var thisSpace = state.dataHeatBal.space[spaceNum-1]
            airPatternZoneInfo.totNumSurfs += thisSpace.HTSurfaceLast - thisSpace.HTSurfaceFirst + 1
        airPatternZoneInfo.Surf.allocate(airPatternZoneInfo.totNumSurfs)
        var thisSurfinZone = 0
        for spaceNum in state.dataHeatBal.Zone[ZoneNum-1].spaceIndexes:
            var thisSpace = state.dataHeatBal.space[spaceNum-1]
            for thisHBsurfID in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast+1):
                thisSurfinZone += 1
                if state.dataSurface.Surface[thisHBsurfID-1].Class == DataSurfaces.SurfaceClass.IntMass:
                    airPatternZoneInfo.Surf[thisSurfinZone-1].SurfID = thisHBsurfID
                    airPatternZoneInfo.Surf[thisSurfinZone-1].Zeta = 0.5
                    continue
                airPatternZoneInfo.Surf[thisSurfinZone-1].SurfID = thisHBsurfID
                airPatternZoneInfo.Surf[thisSurfinZone-1].Zeta = FigureNDheightInZone(state, thisHBsurfID)
        # end for spaceNum
    # end for ObjNum

    for iZone in range(1, state.dataGlobal.NumOfZones+1):
        if state.dataRoomAir.AirModel[iZone-1].AirModel != RoomAirModel.UserDefined:
            continue
        if state.dataRoomAir.AirPatternZoneInfo[iZone-1].IsUsed:
            continue
        ShowSevereError(state, f"{routineName}AirModel for Zone=[{state.dataHeatBal.Zone[iZone-1].Name}] is indicated as \"User Defined\".")
        ShowContinueError(state, f"...but missing a {ipsc.cCurrentModuleObject} object for control.")
        ErrorsFound = True

    if not allocated(state.dataRoomAir.AirPattern):
        state.dataRoomAir.AirPattern.allocate(state.dataRoomAir.NumAirTempPatterns)

    ipsc.cCurrentModuleObject = cTempPatternConstGradientObject
    for ObjNum in range(1, state.dataRoomAir.NumConstantGradient+1):
        var thisPattern = ObjNum
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, ObjNum, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, Status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var roomAirPattern = state.dataRoomAir.AirPattern[thisPattern-1]
        roomAirPattern.Name = ipsc.cAlphaArgs[0]
        roomAirPattern.PatrnID = ipsc.rNumericArgs[0]
        roomAirPattern.PatternMode = UserDefinedPatternType.ConstGradTemp
        roomAirPattern.DeltaTstat = ipsc.rNumericArgs[1]
        roomAirPattern.DeltaTleaving = ipsc.rNumericArgs[2]
        roomAirPattern.DeltaTexhaust = ipsc.rNumericArgs[3]
        roomAirPattern.GradPatrn.Gradient = ipsc.rNumericArgs[4]

    ipsc.cCurrentModuleObject = cTempPatternTwoGradientObject
    for ObjNum in range(1, state.dataRoomAir.NumTwoGradientInterp+1):
        var thisPattern = state.dataRoomAir.NumConstantGradient + ObjNum
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, ObjNum, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, Status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var roomAirPattern = state.dataRoomAir.AirPattern[thisPattern-1]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        roomAirPattern.PatternMode = UserDefinedPatternType.TwoGradInterp
        roomAirPattern.Name = ipsc.cAlphaArgs[0]
        roomAirPattern.PatrnID = ipsc.rNumericArgs[0]
        roomAirPattern.TwoGradPatrn.TstatHeight = ipsc.rNumericArgs[1]
        roomAirPattern.TwoGradPatrn.TleavingHeight = ipsc.rNumericArgs[2]
        roomAirPattern.TwoGradPatrn.TexhaustHeight = ipsc.rNumericArgs[3]
        roomAirPattern.TwoGradPatrn.LowGradient = ipsc.rNumericArgs[4]
        roomAirPattern.TwoGradPatrn.HiGradient = ipsc.rNumericArgs[5]
        roomAirPattern.TwoGradPatrn.InterpolationMode = static_cast[UserDefinedPatternMode](getEnumValue(userDefinedPatternModeNamesUC, Util.makeUPPER(ipsc.cAlphaArgs[1])))
        if roomAirPattern.TwoGradPatrn.InterpolationMode == UserDefinedPatternMode.Invalid:
            ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
        roomAirPattern.TwoGradPatrn.UpperBoundTempScale = ipsc.rNumericArgs[6]
        roomAirPattern.TwoGradPatrn.LowerBoundTempScale = ipsc.rNumericArgs[7]
        roomAirPattern.TwoGradPatrn.UpperBoundHeatRateScale = ipsc.rNumericArgs[8]
        roomAirPattern.TwoGradPatrn.LowerBoundHeatRateScale = ipsc.rNumericArgs[9]
        if roomAirPattern.TwoGradPatrn.HiGradient == roomAirPattern.TwoGradPatrn.LowGradient:
            ShowWarningError(state, f"Upper and lower gradients equal, use {cTempPatternConstGradientObject} instead ")
            ShowContinueError(state, f"Entered in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
        if (roomAirPattern.TwoGradPatrn.UpperBoundTempScale == roomAirPattern.TwoGradPatrn.LowerBoundTempScale) and ((roomAirPattern.TwoGradPatrn.InterpolationMode == UserDefinedPatternMode.OutdoorDryBulb) or (roomAirPattern.TwoGradPatrn.InterpolationMode == UserDefinedPatternMode.ZoneAirTemp) or (roomAirPattern.TwoGradPatrn.InterpolationMode == UserDefinedPatternMode.DeltaOutdoorZone)):
            ShowSevereError(state, f"Error in temperature scale in {ipsc.cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}")
            ErrorsFound = True
        if (roomAirPattern.TwoGradPatrn.HiGradient == roomAirPattern.TwoGradPatrn.LowGradient) and ((roomAirPattern.TwoGradPatrn.InterpolationMode == UserDefinedPatternMode.SensibleCooling) or (roomAirPattern.TwoGradPatrn.InterpolationMode == UserDefinedPatternMode.SensibleHeating)):
            ShowSevereError(state, f"Error in load scale in {ipsc.cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}")
            ErrorsFound = True

    ipsc.cCurrentModuleObject = cTempPatternNDHeightObject
    for ObjNum in range(1, state.dataRoomAir.NumNonDimensionalHeight+1):
        var thisPattern = state.dataRoomAir.NumConstantGradient + state.dataRoomAir.NumTwoGradientInterp + ObjNum
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, ObjNum, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, Status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var roomAirPattern = state.dataRoomAir.AirPattern[thisPattern-1]
        roomAirPattern.PatternMode = UserDefinedPatternType.NonDimenHeight
        roomAirPattern.Name = ipsc.cAlphaArgs[0]
        roomAirPattern.PatrnID = ipsc.rNumericArgs[0]
        roomAirPattern.DeltaTstat = ipsc.rNumericArgs[1]
        roomAirPattern.DeltaTleaving = ipsc.rNumericArgs[2]
        roomAirPattern.DeltaTexhaust = ipsc.rNumericArgs[3]
        var NumPairs = builtins.floor((Float64(NumNumbers) - 4.0) / 2.0)
        roomAirPattern.VertPatrn.ZetaPatrn.allocate(NumPairs)
        roomAirPattern.VertPatrn.DeltaTaiPatrn.allocate(NumPairs)
        roomAirPattern.VertPatrn.ZetaPatrn = 0.0
        roomAirPattern.VertPatrn.DeltaTaiPatrn = 0.0
        for i in range(NumPairs):
            roomAirPattern.VertPatrn.ZetaPatrn[i] = ipsc.rNumericArgs[2*i + 4]
            roomAirPattern.VertPatrn.DeltaTaiPatrn[i] = ipsc.rNumericArgs[2*i + 5]
        for i in range(1, NumPairs):
            if roomAirPattern.VertPatrn.ZetaPatrn[i] < roomAirPattern.VertPatrn.ZetaPatrn[i-1]:
                ShowSevereError(state, f"Zeta values not in increasing order in {ipsc.cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}")
                ErrorsFound = True

    ipsc.cCurrentModuleObject = cTempPatternSurfMapObject
    for ObjNum in range(1, state.dataRoomAir.NumSurfaceMapping+1):
        var thisPattern = state.dataRoomAir.NumConstantGradient + state.dataRoomAir.NumTwoGradientInterp + state.dataRoomAir.NumNonDimensionalHeight + ObjNum
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, ObjNum, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, Status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var roomAirPattern = state.dataRoomAir.AirPattern[thisPattern-1]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        roomAirPattern.PatternMode = UserDefinedPatternType.SurfMapTemp
        roomAirPattern.Name = ipsc.cAlphaArgs[0]
        roomAirPattern.PatrnID = ipsc.rNumericArgs[0]
        roomAirPattern.DeltaTstat = ipsc.rNumericArgs[1]
        roomAirPattern.DeltaTleaving = ipsc.rNumericArgs[2]
        roomAirPattern.DeltaTexhaust = ipsc.rNumericArgs[3]
        var NumPairs = NumNumbers - 4
        if NumPairs != (NumAlphas - 1):
            ShowSevereError(state, f"Error in number of entries in {ipsc.cCurrentModuleObject} object: {ipsc.cAlphaArgs[0]}")
            ErrorsFound = True
        roomAirPattern.MapPatrn.SurfName.allocate(NumPairs)
        roomAirPattern.MapPatrn.DeltaTai.allocate(NumPairs)
        roomAirPattern.MapPatrn.SurfID.allocate(NumPairs)
        roomAirPattern.MapPatrn.SurfName = ""
        roomAirPattern.MapPatrn.DeltaTai = 0.0
        roomAirPattern.MapPatrn.SurfID = 0
        for i in range(1, NumPairs+1):
            roomAirPattern.MapPatrn.SurfName[i-1] = ipsc.cAlphaArgs[i]  # i+1 after shift? careful
            # In C++: ipsc->cAlphaArgs(i+1) for i=1..NumPairs
            roomAirPattern.MapPatrn.DeltaTai[i-1] = ipsc.rNumericArgs[i+3]
            roomAirPattern.MapPatrn.SurfID[i-1] = Util.FindItemInList(ipsc.cAlphaArgs[i], state.dataSurface.Surface)
            if roomAirPattern.MapPatrn.SurfID[i-1] == 0:
                ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[i], ipsc.cAlphaArgs[i])
                ErrorsFound = True
        roomAirPattern.MapPatrn.NumSurfs = NumPairs

    if state.dataErrTracking.TotalRoomAirPatternTooLow > 0:
        ShowWarningError(state, f"GetUserDefinedPatternData: RoomAirModelUserTempPattern: {state.dataErrTracking.TotalRoomAirPatternTooLow} problem(s) in non-dimensional height calculations, too low surface height(s) in relation to floor height of zone(s).")
        ShowContinueError(state, "...Use OutputDiagnostics,DisplayExtraWarnings; to see details.")
        state.dataErrTracking.TotalWarningErrors += state.dataErrTracking.TotalRoomAirPatternTooLow
    if state.dataErrTracking.TotalRoomAirPatternTooHigh > 0:
        ShowWarningError(state, f"GetUserDefinedPatternData: RoomAirModelUserTempPattern: {state.dataErrTracking.TotalRoomAirPatternTooHigh} problem(s) in non-dimensional height calculations, too high surface height(s) in relation to ceiling height of zone(s).")
        ShowContinueError(state, "...Use OutputDiagnostics,DisplayExtraWarnings; to see details.")
        state.dataErrTracking.TotalWarningErrors += state.dataErrTracking.TotalRoomAirPatternTooHigh

    for i in range(1, state.dataGlobal.NumOfZones+1):
        if state.dataRoomAir.AirPatternZoneInfo[i-1].IsUsed:
            var found = Util.FindItemInList(state.dataRoomAir.AirPatternZoneInfo[i-1].ZoneName, state.dataZoneEquip.ZoneEquipConfig, &EquipConfiguration.ZoneName)
            if found != 0:
                state.dataRoomAir.AirPatternZoneInfo[i-1].ZoneNodeID = state.dataZoneEquip.ZoneEquipConfig[found-1].ZoneNode
                if allocated(state.dataZoneEquip.ZoneEquipConfig[found-1].ExhaustNode):
                    state.dataRoomAir.AirPatternZoneInfo[i-1].ExhaustAirNodeID.allocate(state.dataZoneEquip.ZoneEquipConfig[found-1].NumExhaustNodes)
                    state.dataRoomAir.AirPatternZoneInfo[i-1].ExhaustAirNodeID = state.dataZoneEquip.ZoneEquipConfig[found-1].ExhaustNode
            state.dataRoomAir.AirPatternZoneInfo[i-1].ZoneHeight = state.dataHeatBal.Zone[i-1].CeilingHeight

def GetAirNodeData(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    alias routineName = "GetAirNodeData"
    var NumAlphas: Int
    var NumNumbers: Int
    var Status: Int
    if not state.dataRoomAir.DispVent1NodeModelUsed:
        return
    var ipsc = state.dataIPShortCut
    state.dataRoomAir.TotNumOfZoneAirNodes.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.TotNumOfAirNodes = 0
    state.dataRoomAir.TotNumOfZoneAirNodes = 0
    ipsc.cCurrentModuleObject = "RoomAir:Node"
    state.dataRoomAir.TotNumOfAirNodes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    if state.dataRoomAir.TotNumOfAirNodes <= 0:
        ShowSevereError(state, f"No {ipsc.cCurrentModuleObject} objects found in input.")
        ShowContinueError(state, f"The OneNodeDisplacementVentilation model requires {ipsc.cCurrentModuleObject} objects")
        ErrorsFound = True
        return
    state.dataRoomAir.AirNode.allocate(state.dataRoomAir.TotNumOfAirNodes)
    for AirNodeNum in range(1, state.dataRoomAir.TotNumOfAirNodes+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, AirNodeNum, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, Status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var airNode = state.dataRoomAir.AirNode[AirNodeNum-1]
        airNode.Name = ipsc.cAlphaArgs[0]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, airNode.Name)
        airNode.ZoneName = ipsc.cAlphaArgs[2]
        airNode.ZonePtr = Util.FindItemInList(airNode.ZoneName, state.dataHeatBal.Zone)
        if airNode.ZonePtr == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
            ErrorsFound = True
        else:
            var NumOfSurfs = 0
            for spaceNum in state.dataHeatBal.Zone[airNode.ZonePtr-1].spaceIndexes:
                var thisSpace = state.dataHeatBal.space[spaceNum-1]
                NumOfSurfs += thisSpace.HTSurfaceLast - thisSpace.HTSurfaceFirst + 1
            airNode.SurfMask.allocate(NumOfSurfs)
        airNode.ClassType = static_cast[AirNodeType](getEnumValue(airNodeTypeNamesUC, Util.makeUPPER(ipsc.cAlphaArgs[1])))
        if airNode.ClassType == AirNodeType.Invalid:
            ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
        airNode.Height = ipsc.rNumericArgs[0]
        var NumSurfsInvolved = NumAlphas - 3
        airNode.SurfMask = False
        if NumSurfsInvolved <= 0:
            if airNode.ClassType == AirNodeType.Floor or airNode.ClassType == AirNodeType.Ceiling or airNode.ClassType == AirNodeType.Mundt or airNode.ClassType == AirNodeType.Plume or airNode.ClassType == AirNodeType.Rees:
                ShowSevereError(state, f"GetAirNodeData: {ipsc.cCurrentModuleObject}=\"{airNode.Name}\" invalid air node specification.")
                ShowContinueError(state, f"Mundt Room Air Model: No surface names specified.  Air node=\"{airNode.Name}\" requires surfaces associated with it.")
                ErrorsFound = True
            continue
        if airNode.ClassType == AirNodeType.Inlet or airNode.ClassType == AirNodeType.Control or airNode.ClassType == AirNodeType.Return or airNode.ClassType == AirNodeType.Plume:
            ShowWarningError(state, f"GetAirNodeData: {ipsc.cCurrentModuleObject}=\"{airNode.Name}\" invalid linkage")
            ShowContinueError(state, f"Mundt Room Air Model: No surface names needed.  Air node=\"{airNode.Name}\" does not relate to any surfaces.")
            continue
        var zone = state.dataHeatBal.Zone[airNode.ZonePtr-1]
        var NumOfSurfs_ = 0
        for spaceNum in zone.spaceIndexes:
            var thisSpace = state.dataHeatBal.space[spaceNum-1]
            NumOfSurfs_ += thisSpace.HTSurfaceLast - thisSpace.HTSurfaceFirst + 1
        if NumSurfsInvolved > NumOfSurfs_:
            ShowFatalError(state, f"GetAirNodeData: Mundt Room Air Model: Number of surfaces connected to {airNode.Name} is greater than number of surfaces in {zone.Name}")
            return
        var SurfCount = 0
        for ListSurfNum in range(4, NumAlphas+1):
            var thisSurfinZone = 0
            for spaceNum in zone.spaceIndexes:
                var thisSpace = state.dataHeatBal.space[spaceNum-1]
                for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast+1):
                    thisSurfinZone += 1
                    if ipsc.cAlphaArgs[ListSurfNum-1] == state.dataSurface.Surface[SurfNum-1].Name:
                        airNode.SurfMask[thisSurfinZone-1] = True
                        SurfCount += 1
                        break
                if SurfCount > 0:
                    break
        if NumSurfsInvolved != SurfCount:
            ShowWarningError(state, f"GetAirNodeData: Mundt Room Air Model: Some surface names specified for {airNode.Name} are not in {zone.Name}")
    # for AirNodeNum
    for AirNodeNum in range(1, state.dataRoomAir.TotNumOfAirNodes+1):
        var airNode = state.dataRoomAir.AirNode[AirNodeNum-1]
        if state.dataRoomAir.AirModel[airNode.ZonePtr-1].AirModel == RoomAirModel.DispVent1Node:
            state.dataRoomAir.TotNumOfZoneAirNodes[airNode.ZonePtr-1] += 1

def GetMundtData(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    alias routineName = "GetMundtData"
    var NumAlphas: Int
    var NumNumbers: Int
    var Status: Int
    var NumOfMundtContrl: Int
    var ipsc = state.dataIPShortCut
    if not state.dataRoomAir.DispVent1NodeModelUsed:
        return
    state.dataRoomAir.ConvectiveFloorSplit.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.InfiltratFloorSplit.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.ConvectiveFloorSplit = 0.0
    state.dataRoomAir.InfiltratFloorSplit = 0.0
    var cCurrentModuleObject = ipsc.cCurrentModuleObject
    cCurrentModuleObject = "RoomAirSettings:OneNodeDisplacementVentilation"
    NumOfMundtContrl = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if NumOfMundtContrl > state.dataGlobal.NumOfZones:
        ShowSevereError(state, f"Too many {cCurrentModuleObject} objects in input file")
        ShowContinueError(state, f"There cannot be more {cCurrentModuleObject} objects than number of zones.")
        ErrorsFound = True
    if NumOfMundtContrl == 0:
        ShowWarningError(state, f"No {cCurrentModuleObject} objects found, program assumes no convection or infiltration gains near floors")
        return
    for ControlNum in range(1, NumOfMundtContrl+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, ControlNum, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, Status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, "")
        var ZoneNum = Util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)
        if ZoneNum == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            ErrorsFound = True
            continue
        if state.dataRoomAir.AirModel[ZoneNum-1].AirModel != RoomAirModel.DispVent1Node:
            ShowSevereError(state, f"Zone specified=\"{ipsc.cAlphaArgs[0]}\", Air Model type is not OneNodeDisplacementVentilation.")
            ShowContinueError(state, f"Air Model Type for zone={roomAirModelNamesUC[state.dataRoomAir.AirModel[ZoneNum-1].AirModel.ordinal()]}")
            ErrorsFound = True
            continue
        state.dataRoomAir.ConvectiveFloorSplit[ZoneNum-1] = ipsc.rNumericArgs[0]
        state.dataRoomAir.InfiltratFloorSplit[ZoneNum-1] = ipsc.rNumericArgs[1]

def GetDisplacementVentData(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    alias routineName = "GetDisplacementVentData"
    var IOStat: Int
    var NumAlpha: Int
    var NumNumber: Int
    var ipsc = state.dataIPShortCut
    if not state.dataRoomAir.UCSDModelUsed:
        return
    ipsc.cCurrentModuleObject = "RoomAirSettings:ThreeNodeDisplacementVentilation"
    state.dataRoomAir.TotDispVent3Node = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    if state.dataRoomAir.TotDispVent3Node <= 0:
        return
    state.dataRoomAir.ZoneDispVent3Node.allocate(state.dataRoomAir.TotDispVent3Node)
    for Loop in range(1, state.dataRoomAir.TotDispVent3Node+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlpha, ipsc.rNumericArgs, NumNumber, IOStat, _, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var zoneDV3N = state.dataRoomAir.ZoneDispVent3Node[Loop-1]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        zoneDV3N.ZonePtr = Util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)
        if zoneDV3N.ZonePtr == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            ErrorsFound = True
        else:
            state.dataRoomAir.IsZoneDispVent3Node[zoneDV3N.ZonePtr-1] = True
        if ipsc.lAlphaFieldBlanks[1]:
            ShowSevereEmptyField(state, eoh, ipsc.cAlphaFieldNames[1])
            ErrorsFound = True
        else:
            zoneDV3N.gainsSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[1])
            if zoneDV3N.gainsSched == None:
                ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
                ErrorsFound = True
        zoneDV3N.NumPlumesPerOcc = ipsc.rNumericArgs[0]
        zoneDV3N.ThermostatHeight = ipsc.rNumericArgs[1]
        zoneDV3N.ComfortHeight = ipsc.rNumericArgs[2]
        zoneDV3N.TempTrigger = ipsc.rNumericArgs[3]

def GetCrossVentData(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    alias routineName = "GetCrossVentData"
    var IOStat: Int
    var NumAlpha: Int
    var NumNumber: Int
    var ipsc = state.dataIPShortCut
    if not state.dataRoomAir.UCSDModelUsed:
        return
    ipsc.cCurrentModuleObject = "RoomAirSettings:CrossVentilation"
    state.dataRoomAir.TotCrossVent = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    if state.dataRoomAir.TotCrossVent <= 0:
        return
    state.dataRoomAir.ZoneCrossVent.allocate(state.dataRoomAir.TotCrossVent)
    for Loop in range(1, state.dataRoomAir.TotCrossVent+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlpha, ipsc.rNumericArgs, NumNumber, IOStat, _, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var zoneCV = state.dataRoomAir.ZoneCrossVent[Loop-1]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        zoneCV.ZonePtr = Util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)
        if zoneCV.ZonePtr == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            ErrorsFound = True
        else:
            state.dataRoomAir.IsZoneCrossVent[zoneCV.ZonePtr-1] = True
        if ipsc.lAlphaFieldBlanks[1]:
            ShowSevereEmptyField(state, eoh, ipsc.cAlphaFieldNames[1])
            ErrorsFound = True
        else:
            zoneCV.gainsSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[1])
            if zoneCV.gainsSched == None:
                ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
                ErrorsFound = True
        if ipsc.lAlphaFieldBlanks[2]:
            for Loop2 in range(1, state.dataHeatBal.TotPeople+1):
                if state.dataHeatBal.People[Loop2-1].ZonePtr != zoneCV.ZonePtr:
                    continue
                if not state.dataHeatBal.People[Loop2-1].Fanger:
                    continue
                ShowSevereEmptyField(state, eoh, ipsc.cAlphaFieldNames[2])
                ErrorsFound = True
        else:
            zoneCV.VforComfort = static_cast[Comfort](getEnumValue(comfortNamesUC, Util.makeUPPER(ipsc.cAlphaArgs[2])))
            if zoneCV.VforComfort == Comfort.Invalid:
                ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
                ErrorsFound = True
        if zoneCV.ZonePtr == 0:
            continue
        if Util.FindItemInList(state.dataHeatBal.Zone[zoneCV.ZonePtr-1].Name, state.afn.MultizoneZoneData, &AirflowNetwork.MultizoneZoneProp.ZoneName) == 0:
            ShowSevereError(state, f"Problem with {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
            ShowContinueError(state, "AirflowNetwork airflow model must be active in this zone")
            ErrorsFound = True
        for iLink in range(1, state.afn.NumOfLinksMultiZone+1):
            var mzSurfaceData = state.afn.MultizoneSurfaceData[iLink-1]
            var nodeNum1 = mzSurfaceData.NodeNums[0]
            var nodeNum2 = mzSurfaceData.NodeNums[1]
            if state.dataSurface.Surface[mzSurfaceData.SurfNum-1].Zone == zoneCV.ZonePtr or (state.afn.AirflowNetworkNodeData[nodeNum2-1].EPlusZoneNum == zoneCV.ZonePtr and state.afn.AirflowNetworkNodeData[nodeNum1-1].EPlusZoneNum > 0) or (state.afn.AirflowNetworkNodeData[nodeNum2-1].EPlusZoneNum > 0 and state.afn.AirflowNetworkNodeData[nodeNum1-1].EPlusZoneNum == zoneCV.ZonePtr):
                var compNum = state.afn.AirflowNetworkLinkageData[iLink-1].CompNum
                var typeNum = state.afn.AirflowNetworkCompData[compNum-1].TypeNum
                if state.afn.AirflowNetworkCompData[compNum-1].CompTypeNum == AirflowNetwork.iComponentTypeNum.SCR:
                    if state.afn.MultizoneSurfaceCrackData[typeNum-1].exponent != 0.50:
                        state.dataRoomAir.AirModel[zoneCV.ZonePtr-1].AirModel = RoomAirModel.Mixing
                        ShowWarningError(state, f"Problem with {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
                        ShowWarningError(state, f"Roomair model will not be applied for Zone={ipsc.cAlphaArgs[0]}.")
                        ShowContinueError(state, f"AirflowNetwrok:Multizone:Surface crack object must have an air flow coefficient = 0.5, value was={state.afn.MultizoneSurfaceCrackData[typeNum-1].exponent:.2f}")

def GetUFADZoneData(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    alias routineName = "GetUFADZoneData"
    var IOStat: Int
    var NumAlpha: Int
    var NumNumber: Int
    if not state.dataRoomAir.UCSDModelUsed:
        state.dataRoomAir.TotUFADInt = 0
        state.dataRoomAir.TotUFADExt = 0
        return
    var ipsc = state.dataIPShortCut
    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionInterior"
    state.dataRoomAir.TotUFADInt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionExterior"
    state.dataRoomAir.TotUFADExt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    if state.dataRoomAir.TotUFADInt <= 0 and state.dataRoomAir.TotUFADExt <= 0:
        return
    state.dataRoomAir.ZoneUFAD.allocate(state.dataRoomAir.TotUFADInt + state.dataRoomAir.TotUFADExt)
    state.dataRoomAir.ZoneUFADPtr.dimension(state.dataGlobal.NumOfZones, 0)
    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionInterior"
    for Loop in range(1, state.dataRoomAir.TotUFADInt+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlpha, ipsc.rNumericArgs, NumNumber, IOStat, _, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var zoneUI = state.dataRoomAir.ZoneUFAD[Loop-1]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        zoneUI.ZoneName = ipsc.cAlphaArgs[0]
        zoneUI.ZonePtr = Util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)
        state.dataRoomAir.ZoneUFADPtr[zoneUI.ZonePtr-1] = Loop
        if zoneUI.ZonePtr == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            ErrorsFound = True
        else:
            state.dataRoomAir.IsZoneUFAD[zoneUI.ZonePtr-1] = True
            state.dataRoomAir.ZoneUFADPtr[zoneUI.ZonePtr-1] = Loop
        zoneUI.DiffuserType = static_cast[Diffuser](getEnumValue(diffuserNamesUC, Util.makeUPPER(ipsc.cAlphaArgs[1])))
        if zoneUI.DiffuserType == Diffuser.Invalid:
            ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
        zoneUI.DiffusersPerZone = ipsc.rNumericArgs[0]
        zoneUI.PowerPerPlume = ipsc.rNumericArgs[1]
        zoneUI.DiffArea = ipsc.rNumericArgs[2]
        zoneUI.DiffAngle = ipsc.rNumericArgs[3]
        zoneUI.ThermostatHeight = ipsc.rNumericArgs[4]
        zoneUI.ComfortHeight = ipsc.rNumericArgs[5]
        zoneUI.TempTrigger = ipsc.rNumericArgs[6]
        zoneUI.TransHeight = ipsc.rNumericArgs[7]
        zoneUI.A_Kc = ipsc.rNumericArgs[8]
        zoneUI.B_Kc = ipsc.rNumericArgs[9]
        zoneUI.C_Kc = ipsc.rNumericArgs[10]
        zoneUI.D_Kc = ipsc.rNumericArgs[11]
        zoneUI.E_Kc = ipsc.rNumericArgs[12]

    ipsc.cCurrentModuleObject = "RoomAirSettings:UnderFloorAirDistributionExterior"
    for Loop in range(1, state.dataRoomAir.TotUFADExt+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlpha, ipsc.rNumericArgs, NumNumber, IOStat, _, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var zoneUE = state.dataRoomAir.ZoneUFAD[Loop-1 + state.dataRoomAir.TotUFADInt]
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        zoneUE.ZoneName = ipsc.cAlphaArgs[0]
        zoneUE.ZonePtr = Util.FindItemInList(ipsc.cAlphaArgs[0], state.dataHeatBal.Zone)
        if zoneUE.ZonePtr == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            ErrorsFound = True
        else:
            state.dataRoomAir.IsZoneUFAD[zoneUE.ZonePtr-1] = True
            state.dataRoomAir.ZoneUFADPtr[zoneUE.ZonePtr-1] = Loop + state.dataRoomAir.TotUFADInt
        zoneUE.DiffuserType = static_cast[Diffuser](getEnumValue(diffuserNamesUC, Util.makeUPPER(ipsc.cAlphaArgs[1])))
        if zoneUE.DiffuserType == Diffuser.Invalid:
            ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
        zoneUE.DiffusersPerZone = ipsc.rNumericArgs[0]
        zoneUE.PowerPerPlume = ipsc.rNumericArgs[1]
        zoneUE.DiffArea = ipsc.rNumericArgs[2]
        zoneUE.DiffAngle = ipsc.rNumericArgs[3]
        zoneUE.ThermostatHeight = ipsc.rNumericArgs[4]
        zoneUE.ComfortHeight = ipsc.rNumericArgs[5]
        zoneUE.TempTrigger = ipsc.rNumericArgs[6]
        zoneUE.TransHeight = ipsc.rNumericArgs[7]
        zoneUE.A_Kc = ipsc.rNumericArgs[8]
        zoneUE.B_Kc = ipsc.rNumericArgs[9]
        zoneUE.C_Kc = ipsc.rNumericArgs[10]
        zoneUE.D_Kc = ipsc.rNumericArgs[11]
        zoneUE.E_Kc = ipsc.rNumericArgs[12]

def GetRoomAirflowNetworkData(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    alias routineName = "GetRoomAirflowNetworkData"
    var NumAlphas: Int
    var NumNumbers: Int
    var status: Int
    var TotNumOfRAFNNodeSurfLists: Int
    var TotNumOfRAFNNodeGainsLists: Int
    var TotNumOfRAFNNodeHVACLists: Int
    var TotNumEquip: Int
    var IntEquipFound: Bool
    var ipsc = state.dataIPShortCut
    ipsc.cCurrentModuleObject = "RoomAirSettings:AirflowNetwork"
    state.dataRoomAir.NumOfRoomAFNControl = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    if state.dataRoomAir.NumOfRoomAFNControl == 0:
        return
    if state.dataRoomAir.NumOfRoomAFNControl > state.dataGlobal.NumOfZones:
        ShowSevereError(state, f"Too many {ipsc.cCurrentModuleObject} objects in input file")
        ShowContinueError(state, f"There cannot be more {ipsc.cCurrentModuleObject} objects than number of zones.")
        ErrorsFound = True
    if not allocated(state.dataRoomAir.AFNZoneInfo):
        state.dataRoomAir.AFNZoneInfo.allocate(state.dataGlobal.NumOfZones)
    for Loop in range(1, state.dataRoomAir.NumOfRoomAFNControl+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, status, _, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        var ZoneNum = Util.FindItemInList(ipsc.cAlphaArgs[1], state.dataHeatBal.Zone, state.dataGlobal.NumOfZones)
        if ZoneNum == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
            continue
        if state.dataRoomAir.AirModel[ZoneNum-1].AirModel != RoomAirModel.AirflowNetwork:
            ShowSevereError(state, f"GetRoomAirflowNetworkData: Zone specified='{ipsc.cAlphaArgs[0]}', Air Model type is not AirflowNetwork.")
            ShowContinueError(state, f"Air Model Type for zone ={roomAirModelNamesUC[state.dataRoomAir.AirModel[ZoneNum-1].AirModel.ordinal()]}")
            ErrorsFound = True
            continue
        var roomAFNZoneInfo = state.dataRoomAir.AFNZoneInfo[ZoneNum-1]
        roomAFNZoneInfo.ZoneID = ZoneNum
        roomAFNZoneInfo.IsUsed = True
        roomAFNZoneInfo.Name = ipsc.cAlphaArgs[0]
        roomAFNZoneInfo.ZoneName = ipsc.cAlphaArgs[1]
        roomAFNZoneInfo.NumOfAirNodes = NumAlphas - 3
        if roomAFNZoneInfo.NumOfAirNodes > 0:
            roomAFNZoneInfo.Node.allocate(roomAFNZoneInfo.NumOfAirNodes)
        else:
            ShowSevereError(state, f"GetRoomAirflowNetworkData: Incomplete input in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
            ErrorsFound = True
        for iAirNode in range(1, roomAFNZoneInfo.NumOfAirNodes+1):
            roomAFNZoneInfo.Node[iAirNode-1].Name = ipsc.cAlphaArgs[iAirNode+2]
        roomAFNZoneInfo.ControlAirNodeID = Util.FindItemInList(ipsc.cAlphaArgs[2], roomAFNZoneInfo.Node, roomAFNZoneInfo.NumOfAirNodes)
        if roomAFNZoneInfo.ControlAirNodeID == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[2], ipsc.cAlphaArgs[2])
            ErrorsFound = True
            continue
        roomAFNZoneInfo.totNumSurfs = 0
        for spaceNum in state.dataHeatBal.Zone[ZoneNum-1].spaceIndexes:
            var thisSpace = state.dataHeatBal.space[spaceNum-1]
            roomAFNZoneInfo.totNumSurfs += thisSpace.HTSurfaceLast - thisSpace.HTSurfaceFirst + 1
    # end for Loop

    ipsc.cCurrentModuleObject = "RoomAir:Node:AirflowNetwork"
    state.dataRoomAir.TotNumOfRoomAFNNodes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    for Loop in range(1, state.dataRoomAir.TotNumOfRoomAFNNodes+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, status, _, ipsc.lAlphaFieldBlanks, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        var ZoneNum = Util.FindItemInList(ipsc.cAlphaArgs[1], state.dataHeatBal.Zone, state.dataGlobal.NumOfZones)
        if ZoneNum == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
            continue
        var roomAFNZoneInfo = state.dataRoomAir.AFNZoneInfo[ZoneNum-1]
        var RAFNNodeNum = Util.FindItemInList(ipsc.cAlphaArgs[0], roomAFNZoneInfo.Node, roomAFNZoneInfo.NumOfAirNodes)
        if RAFNNodeNum == 0:
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            ErrorsFound = True
            continue
        var roomAFNZoneNode = roomAFNZoneInfo.Node[RAFNNodeNum-1]
        roomAFNZoneNode.ZoneVolumeFraction = ipsc.rNumericArgs[0]
        if not ipsc.lAlphaFieldBlanks[2]:
            roomAFNZoneNode.NodeSurfListName = ipsc.cAlphaArgs[2]
        else:
            roomAFNZoneNode.HasSurfacesAssigned = False
        if not ipsc.lAlphaFieldBlanks[3]:
            roomAFNZoneNode.NodeIntGainsListName = ipsc.cAlphaArgs[3]
        else:
            roomAFNZoneNode.HasIntGainsAssigned = False
        if not ipsc.lAlphaFieldBlanks[4]:
            roomAFNZoneNode.NodeHVACListName = ipsc.cAlphaArgs[4]
        else:
            roomAFNZoneNode.HasHVACAssigned = False
    # end for Loop

    ipsc.cCurrentModuleObject = "RoomAir:Node:AirflowNetwork:AdjacentSurfaceList"
    TotNumOfRAFNNodeSurfLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    for Loop in range(1, TotNumOfRAFNNodeSurfLists+1):
        var foundList = False
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        for iZone in range(1, state.dataGlobal.NumOfZones+1):
            var RAFNNodeNum = 0
            var roomAFNZoneInfo = state.dataRoomAir.AFNZoneInfo[iZone-1]
            if roomAFNZoneInfo.NumOfAirNodes > 0:
                RAFNNodeNum = Util.FindItemInList(ipsc.cAlphaArgs[0], roomAFNZoneInfo.Node, &AFNAirNodeNested.NodeSurfListName, roomAFNZoneInfo.NumOfAirNodes)
            if RAFNNodeNum == 0:
                continue
            foundList = True
            var NumSurfsThisNode = NumAlphas - 1
            var NumOfSurfs = 0
            for spaceNum in state.dataHeatBal.Zone[iZone-1].spaceIndexes:
                var thisSpace = state.dataHeatBal.space[spaceNum-1]
                NumOfSurfs += thisSpace.HTSurfaceLast - thisSpace.HTSurfaceFirst + 1
            var roomAFNZoneNode = roomAFNZoneInfo.Node[RAFNNodeNum-1]
            if allocated(roomAFNZoneNode.SurfMask):
                ShowSevereError(state, f"GetRoomAirflowNetworkData: Invalid {ipsc.cAlphaFieldNames[0]} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, f"Entered in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, "Duplicate RoomAir:Node:AirflowNetwork:AdjacentSurfaceList name.")
                ErrorsFound = True
                continue
            roomAFNZoneNode.SurfMask.allocate(roomAFNZoneInfo.totNumSurfs)
            roomAFNZoneNode.SurfMask = False
            roomAFNZoneNode.HasSurfacesAssigned = True
            var SurfCount = 0
            var thisSurfinZone = 0
            for ListSurfNum in range(2, NumAlphas+1):
                for spaceNum in state.dataHeatBal.Zone[iZone-1].spaceIndexes:
                    var thisSpace = state.dataHeatBal.space[spaceNum-1]
                    for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast+1):
                        thisSurfinZone += 1
                        if ipsc.cAlphaArgs[ListSurfNum-1] == state.dataSurface.Surface[SurfNum-1].Name:
                            roomAFNZoneNode.SurfMask[thisSurfinZone-1] = True
                            SurfCount += 1
                            break
                    if SurfCount > 0:
                        break
            if NumSurfsThisNode != SurfCount:
                ShowSevereError(state, f"GetRoomAirflowNetworkData: Invalid {ipsc.cAlphaFieldNames[0]} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, f"Entered in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, "Some surface names were not found in the zone")
                ErrorsFound = True
        if not foundList:
            ShowSevereError(state, f"GetRoomAirflowNetworkData: Invalid {ipsc.cAlphaFieldNames[0]} = {ipsc.cAlphaArgs[0]}")
            ShowContinueError(state, f"Entered in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
            ShowContinueError(state, "Did not find a RoomAir:Node:AirflowNetwork object that references this object")
            ErrorsFound = True
    # end for Loop (SurfLists)

    ipsc.cCurrentModuleObject = "RoomAir:Node:AirflowNetwork:InternalGains"
    TotNumOfRAFNNodeGainsLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    for Loop in range(1, TotNumOfRAFNNodeGainsLists+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ipsc.cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        if mod(NumAlphas + NumNumbers - 1, 3) != 0:
            ShowSevereError(state, f"GetRoomAirflowNetworkData: For {ipsc.cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}")
            ShowContinueError(state, f"Extensible field set are not evenly divisible by 3. Number of data entries = {NumAlphas + NumNumbers - 1}")
            ErrorsFound = True
            break
        for iZone in range(1, state.dataGlobal.NumOfZones+1):
            var roomAFNZoneInfo = state.dataRoomAir.AFNZoneInfo[iZone-1]
            var RAFNNodeNum = 0
            if roomAFNZoneInfo.NumOfAirNodes > 0:
                RAFNNodeNum = Util.FindItemInList(ipsc.cAlphaArgs[0], roomAFNZoneInfo.Node, &AFNAirNodeNested.NodeIntGainsListName, roomAFNZoneInfo.NumOfAirNodes)
            if RAFNNodeNum == 0:
                continue
            var numInputGains = (NumAlphas + NumNumbers - 1) // 3
            var numSpacesInZone = state.dataHeatBal.Zone[iZone-1].numSpaces
            var maxNumGains = numInputGains * numSpacesInZone
            var roomAFNZoneNode = roomAFNZoneInfo.Node[RAFNNodeNum-1]
            if allocated(roomAFNZoneNode.IntGain):
                ShowSevereError(state, f"GetRoomAirflowNetworkData: Invalid {ipsc.cAlphaFieldNames[0]} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, f"Entered in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, f"Duplicate {ipsc.cCurrentModuleObject} name.")
                ErrorsFound = True
                continue
            roomAFNZoneNode.IntGain.allocate(maxNumGains)
            roomAFNZoneNode.IntGainsDeviceIndices.allocate(maxNumGains)
            roomAFNZoneNode.intGainsDeviceSpaces.allocate(maxNumGains)
            roomAFNZoneNode.IntGainsFractions.allocate(maxNumGains)
            roomAFNZoneNode.HasIntGainsAssigned = True
            var numGainsFound = 0
            for gainsLoop in range(1, numInputGains+1):
                var intGain = roomAFNZoneNode.IntGain[gainsLoop-1]
                intGain.type = static_cast[DataHeatBalance.IntGainType](getEnumValue(DataHeatBalance.IntGainTypeNamesUC, Util.makeUPPER(ipsc.cAlphaArgs[gainsLoop*2 - 1])))  # careful index: in C++ gainsLoop*2
                # In C++: ipsc->cAlphaArgs(gainsLoop*2) (since 1-indexed), here gainsLoop*2-1 (0-indexed)
                if intGain.type == DataHeatBalance.IntGainType.Invalid:
                    ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[gainsLoop*2 - 1], ipsc.cAlphaArgs[gainsLoop*2 - 1])
                    ErrorsFound = True
                    continue
                intGain.Name = ipsc.cAlphaArgs[gainsLoop*2]  # +1? Actually cAlphaArgs(gainsLoop*2+1) in C++ (1-indexed). 0-indexed: gainsLoop*2
                var gainFound = False
                for spaceNum in state.dataHeatBal.Zone[iZone-1].spaceIndexes:
                    var intGainIndex = InternalHeatGains.GetInternalGainDeviceIndex(state, spaceNum, intGain.type, intGain.Name)
                    if intGainIndex >= 0:
                        gainFound = True
                        numGainsFound += 1
                        roomAFNZoneNode.intGainsDeviceSpaces[numGainsFound-1] = spaceNum
                        roomAFNZoneNode.IntGainsDeviceIndices[numGainsFound-1] = intGainIndex
                        roomAFNZoneNode.IntGainsFractions[numGainsFound-1] = ipsc.rNumericArgs[gainsLoop-1]  # rNumericArgs(gainsLoop) 1-indexed -> gainsLoop-1
                if gainFound:
                    roomAFNZoneNode.NumIntGains = numGainsFound
                else:
                    ShowSevereError(state, f"GetRoomAirflowNetworkData: Invalid {ipsc.cAlphaFieldNames[gainsLoop*2]} = {ipsc.cAlphaArgs[gainsLoop*2]}")
                    ShowContinueError(state, f"Entered in {ipsc.cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
                    ShowContinueError(state, "Internal gain did not match correctly")
                    ErrorsFound = True
    # end for Loop (GainsLists)

    var cCurrentModuleObject = "RoomAir:Node:AirflowNetwork:HVACEquipment"
    TotNumOfRAFNNodeHVACLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    for Loop in range(1, TotNumOfRAFNNodeHVACLists+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, Loop, ipsc.cAlphaArgs, NumAlphas, ipsc.rNumericArgs, NumNumbers, status, _, _, ipsc.cAlphaFieldNames, ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, ipsc.cAlphaArgs[0])
        if mod(NumAlphas + NumNumbers - 1, 4) != 0:
            ShowSevereError(state, f"GetRoomAirflowNetworkData: For {cCurrentModuleObject}: {ipsc.cAlphaArgs[0]}")
            ShowContinueError(state, f"Extensible field set are not evenly divisible by 4. Number of data entries = {NumAlphas + NumNumbers - 1}")
            ErrorsFound = True
            break
        for iZone in range(1, state.dataGlobal.NumOfZones+1):
            var roomAFNZoneInfo = state.dataRoomAir.AFNZoneInfo[iZone-1]
            var RAFNNodeNum = 0
            if roomAFNZoneInfo.NumOfAirNodes > 0:
                RAFNNodeNum = Util.FindItemInList(ipsc.cAlphaArgs[0], roomAFNZoneInfo.Node, &AFNAirNodeNested.NodeHVACListName, roomAFNZoneInfo.NumOfAirNodes)
            if RAFNNodeNum == 0:
                continue
            var roomAFNNode = roomAFNZoneInfo.Node[RAFNNodeNum-1]
            if allocated(roomAFNNode.HVAC):
                ShowSevereError(state, f"GetRoomAirflowNetworkData: Invalid {ipsc.cAlphaFieldNames[0]} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, f"Entered in {cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}")
                ShowContinueError(state, f"Duplicate {cCurrentModuleObject} name.")
                ErrorsFound = True
                continue
            roomAFNNode.NumHVACs = (NumAlphas + NumNumbers - 1) // 4
            roomAFNNode.HVAC.allocate(roomAFNNode.NumHVACs)
            roomAFNNode.HasHVACAssigned = True
            for iEquip in range(1, roomAFNNode.NumHVACs+1):
                var iEquipArg = 2 + (iEquip - 1) * 2  # 1-indexed alpha arg index
                var roomAFNNodeHVAC = roomAFNNode.HVAC[iEquip-1]
                # In C++: zoneEquipType = getEnumValue(zoneEquipTypeNamesUC, ipsc->cAlphaArgs(iEquipArg))
                roomAFNNodeHVAC.zoneEquipType = static_cast[DataZoneEquipment.ZoneEquipType](getEnumValue(DataZoneEquipment.zoneEquipTypeNamesUC, ipsc.cAlphaArgs[iEquipArg-1]))
                if roomAFNNodeHVAC.zoneEquipType == DataZoneEquipment.ZoneEquipType.Invalid:
                    ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[iEquipArg-1], ipsc.cAlphaArgs[iEquipArg-1])
                    ErrorsFound = True
                # In C++: Name = ipsc->cAlphaArgs(3 + (iEquip-1)*2)
                roomAFNNodeHVAC.Name = ipsc.cAlphaArgs[3 + (iEquip-1)*2 - 1]  # 0-indexed
                TotNumEquip = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ipsc.cAlphaArgs[iEquipArg-1])
                if TotNumEquip == 0:
                    ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[iEquipArg-1], ipsc.cAlphaArgs[iEquipArg-1])
                    ErrorsFound = True
                # In C++: SupplyFraction = ipsc->rNumericArgs(iEquipArg), ReturnFraction = same
                roomAFNNodeHVAC.SupplyFraction = ipsc.rNumericArgs[iEquipArg-1]
                roomAFNNodeHVAC.ReturnFraction = ipsc.rNumericArgs[iEquipArg-1]
                for this